import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/currency_display.dart';
import '../../core/domain.dart';
import '../../core/models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../i18n/strings.g.dart';
import '../buyer/widgets/favorite_button.dart';
import 'data/device_share.dart';
import 'data/marketplace_repository.dart';
import 'widgets/listing_card.dart';

class DevicePage extends ConsumerWidget {
  const DevicePage({super.key, required this.publicId});

  final String publicId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listing = ref.watch(listingByPublicIdProvider(publicId));
    return AsyncView(
      value: listing,
      onRetry: () => ref.invalidate(listingByPublicIdProvider(publicId)),
      skeleton: const _DeviceSkeleton(),
      data: (data) {
        if (data == null) {
          return EmptyState(
            icon: Icons.devices_other_rounded,
            title: t.device.notAvailableTitle,
            body: t.device.notAvailableBody,
            action: FilledButton(
              onPressed: () => context.go('/'),
              child: Text(t.common.backHome),
            ),
          );
        }
        return _DeviceDetails(listing: data);
      },
    );
  }
}

class _DeviceDetails extends ConsumerStatefulWidget {
  const _DeviceDetails({required this.listing});

  final Listing listing;

  @override
  ConsumerState<_DeviceDetails> createState() => _DeviceDetailsState();
}

class _DeviceDetailsState extends ConsumerState<_DeviceDetails> {
  int _photoIndex = 0;

  @override
  Widget build(BuildContext context) {
    final listing = widget.listing;
    final theme = Theme.of(context);
    final isWide = MediaQuery.sizeOf(context).width >= 900;

    final gallery = _Gallery(
      paths: listing.photoPaths,
      index: _photoIndex,
      onSelect: (i) => setState(() => _photoIndex = i),
      brand: listing.brand,
      category: listing.category,
    );

    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (listing.grade != null) GradeBadge(listing.grade!),
                  Chip(
                    avatar: const Icon(Icons.category_rounded, size: 16),
                    label: Text(
                        t.enums.category[listing.category.dbValue] ??
                            listing.category.dbValue),
                  ),
                  Chip(
                    avatar: const Icon(Icons.verified_user_rounded, size: 16),
                    label: Text(t.common
                        .warrantyDays(days: '${listing.warrantyDays}')),
                  ),
                ],
              ),
            ),
            FavoriteButton(deviceId: listing.id),
            IconButton(
              tooltip: t.device.shareCta,
              onPressed: () => shareDevice(context, listing),
              icon: const Icon(Icons.share_rounded),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          listing.title,
          style: theme.textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          '${listing.brand} · ${listing.model}',
          style: theme.textTheme.titleMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        Text(
          formatForDisplay(listing.price, ref.watch(displayCurrencyProvider),
              ref.watch(exchangeRateProvider).valueOrNull),
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Icon(Icons.verified_rounded,
                size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              t.device.sellerGeneric,
              style: theme.textTheme.bodyLarge,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 16,
          runSpacing: 4,
          children: [
            Text(
              '${t.device.publicIdLabel}: ${listing.publicId}',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            if (listing.imeiLast4 != null)
              Text(
                '${listing.category == DeviceCategory.mobile ? t.device.imeiLabel : t.device.serialLabel}: '
                '···${listing.imeiLast4}',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => context.go('/reserve/${listing.publicId}'),
            icon: const Icon(Icons.shopping_bag_rounded),
            label: Text(t.device.reserveCta),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.verified_user_rounded,
                    color: context.appColors.success),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    t.device.warrantyBody(days: '${listing.warrantyDays}'),
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: gallery),
                    const SizedBox(width: 32),
                    Expanded(flex: 4, child: info),
                  ],
                )
              else ...[
                gallery,
                const SizedBox(height: 24),
                info,
              ],
              const SizedBox(height: 32),
              _ChecklistSection(listing: listing),
              if (listing.description != null &&
                  listing.description!.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  t.device.descriptionTitle,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(listing.description!,
                    style: theme.textTheme.bodyLarge),
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _Gallery extends StatelessWidget {
  const _Gallery({
    required this.paths,
    required this.index,
    required this.onSelect,
    this.brand,
    this.category,
  });

  final List<String> paths;
  final int index;
  final ValueChanged<int> onSelect;
  final String? brand;
  final DeviceCategory? category;

  @override
  Widget build(BuildContext context) {
    final current = paths.isEmpty ? null : paths[index.clamp(0, paths.length - 1)];
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: DevicePhotoImage(
              path: current,
              fit: BoxFit.contain,
              brand: brand,
              category: category,
            ),
          ),
        ),
        if (paths.length > 1) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 64,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: paths.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final selected = i == index;
                return InkWell(
                  onTap: () => onSelect(i),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 84,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outline,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: DevicePhotoImage(
                        path: paths[i],
                        brand: brand,
                        category: category,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _ChecklistSection extends ConsumerWidget {
  const _ChecklistSection({required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final templates = ref.watch(checklistTemplatesProvider).valueOrNull;
    final labels = <String, String>{
      for (final template in templates ?? <ChecklistTemplate>[])
        if (template.category == listing.category)
          template.key: template.labelAr,
    };

    if (listing.checklist.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.device.checklistTitle,
          style:
              theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              for (final (i, entry) in listing.checklist.indexed) ...[
                if (i > 0) const Divider(height: 1),
                ListTile(
                  leading: ChecklistResultIcon(entry.result),
                  title: Text(labels[entry.key] ?? entry.key),
                  subtitle: entry.note == null ? null : Text(entry.note!),
                  trailing: Text(
                    t.enums.checklistResult[entry.result.dbValue] ??
                        entry.result.dbValue,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _DeviceSkeleton extends StatelessWidget {
  const _DeviceSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Shimmer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SkeletonBox(height: 360, radius: 16),
                SizedBox(height: 24),
                SkeletonBox(width: 320, height: 28),
                SizedBox(height: 12),
                SkeletonBox(width: 200, height: 20),
                SizedBox(height: 12),
                SkeletonBox(width: 140, height: 32),
                SizedBox(height: 24),
                SkeletonBox(height: 48, radius: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
