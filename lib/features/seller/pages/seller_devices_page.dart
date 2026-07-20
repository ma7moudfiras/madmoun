import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/domain.dart';
import '../../../core/models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../../../i18n/strings.g.dart';
import '../../marketplace/widgets/listing_card.dart';
import '../data/seller_repository.dart';

/// Provider that pages the seller's devices; invalidated after any mutation.
final sellerDevicesProvider =
    FutureProvider.autoDispose<List<SellerDevice>>((ref) {
  ref.watch(myShopProvider);
  return ref.watch(sellerRepositoryProvider).fetchMyDevices();
});

class SellerDevicesPage extends ConsumerWidget {
  const SellerDevicesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shop = ref.watch(myShopProvider).valueOrNull;
    // The shell hides this tab pre-approval, but guard direct navigation too.
    if (shop == null || shop.status != ShopStatus.approved) {
      return EmptyState(
        icon: Icons.storefront_rounded,
        title: t.seller.onboarding.pendingTitle,
        body: t.seller.onboarding.pendingBody,
        action: FilledButton(
          onPressed: () => context.go('/seller/shop'),
          child: Text(t.seller.navShop),
        ),
      );
    }

    final devices = ref.watch(sellerDevicesProvider);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/seller/devices/new'),
        icon: const Icon(Icons.add_rounded),
        label: Text(t.seller.devices.add),
      ),
      body: AsyncView(
        value: devices,
        onRetry: () => ref.invalidate(sellerDevicesProvider),
        skeleton: ListView(
          padding: const EdgeInsets.all(24),
          children: const [
            Shimmer(child: SkeletonBox(height: 96, radius: 16)),
            SizedBox(height: 12),
            Shimmer(child: SkeletonBox(height: 96, radius: 16)),
          ],
        ),
        data: (list) {
          if (list.isEmpty) {
            return EmptyState(
              icon: Icons.devices_rounded,
              title: t.seller.devices.emptyTitle,
              body: t.seller.devices.emptyBody,
              action: FilledButton.icon(
                onPressed: () => context.go('/seller/devices/new'),
                icon: const Icon(Icons.add_rounded),
                label: Text(t.seller.devices.add),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(sellerDevicesProvider),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 96),
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) =>
                  _DeviceRow(device: list[i]),
            ),
          );
        },
      ),
    );
  }
}

class _DeviceRow extends ConsumerWidget {
  const _DeviceRow({required this.device});

  final SellerDevice device;

  Future<void> _submit(BuildContext context, WidgetRef ref) async {
    try {
      await ref
          .read(sellerRepositoryProvider)
          .setDeviceStatus(device.id, DeviceStatus.underInspection);
      ref.invalidate(sellerDevicesProvider);
      if (context.mounted) {
        showAppSnackBar(context, t.seller.devices.submittedForInspection);
      }
    } catch (e) {
      if (context.mounted) showErrorSnackBar(context, e);
    }
  }

  Future<void> _relist(BuildContext context, WidgetRef ref) async {
    try {
      await ref
          .read(sellerRepositoryProvider)
          .setDeviceStatus(device.id, DeviceStatus.draft);
      ref.invalidate(sellerDevicesProvider);
    } catch (e) {
      if (context.mounted) showErrorSnackBar(context, e);
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.seller.devices.deleteDraft),
        content: Text(t.seller.devices.deleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(t.common.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(t.seller.devices.deleteDraft),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(sellerRepositoryProvider).deleteDraft(device.id);
      ref.invalidate(sellerDevicesProvider);
      if (context.mounted) {
        showAppSnackBar(context, t.seller.devices.deleted);
      }
    } catch (e) {
      if (context.mounted) showErrorSnackBar(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final photoCount = device.photos.length;
    final isDraft = device.status == DeviceStatus.draft;
    final isRejected = device.status == DeviceStatus.rejected;
    final canEdit = isDraft || isRejected;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 72,
                    height: 72,
                    child: DevicePhotoImage(
                      path: device.photos.isEmpty
                          ? null
                          : device.photos.first.storagePath,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device.title,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${device.publicId} · ${device.price.format()}',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          StatusChip.device(context, device.status),
                          if (device.grade != null) GradeBadge(device.grade!),
                          Text(
                            t.seller.devices.photosCount(count: '$photoCount'),
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (isRejected && device.rejectionReason != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.appColors.dangerTint,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  t.seller.devices
                      .rejectionReason(reason: device.rejectionReason!),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.error),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (canEdit)
                  OutlinedButton.icon(
                    onPressed: () =>
                        context.go('/seller/devices/${device.id}'),
                    icon: const Icon(Icons.edit_rounded, size: 18),
                    label: Text(t.seller.deviceForm.editTitle),
                  ),
                if (isDraft)
                  FilledButton.icon(
                    onPressed: () => _submit(context, ref),
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: Text(t.seller.devices.submitForInspection),
                  ),
                if (isRejected)
                  FilledButton.icon(
                    onPressed: () => _relist(context, ref),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: Text(t.seller.devices.backToDraft),
                  ),
                if (isDraft)
                  TextButton.icon(
                    onPressed: () => _delete(context, ref),
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: Text(t.seller.devices.deleteDraft),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
