import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain.dart';
import '../../../core/models.dart';
import '../../../core/widgets/common.dart';
import '../../../i18n/strings.g.dart';
import '../../marketplace/data/marketplace_repository.dart';
import '../../marketplace/widgets/listing_card.dart';
import '../data/admin_repository.dart';
import '../widgets/reason_dialog.dart';

class AdminReviewPage extends ConsumerWidget {
  const AdminReviewPage({super.key});

  Future<void> _approve(
      BuildContext context, WidgetRef ref, SellerDevice device) async {
    try {
      await ref
          .read(adminRepositoryProvider)
          .reviewDevice(device.id, approve: true);
      ref.invalidate(adminReviewQueueProvider);
      ref.invalidate(adminDashboardProvider);
      if (context.mounted) showAppSnackBar(context, t.admin.review.approvedMsg);
    } catch (e) {
      if (context.mounted) showErrorSnackBar(context, e);
    }
  }

  Future<void> _reject(
      BuildContext context, WidgetRef ref, SellerDevice device) async {
    final reason = await promptReason(
      context,
      title: t.admin.review.rejectTitle,
      hint: t.admin.review.rejectHint,
      confirmLabel: t.admin.review.reject,
    );
    if (reason == null || !context.mounted) return;
    try {
      await ref
          .read(adminRepositoryProvider)
          .reviewDevice(device.id, approve: false, reason: reason);
      ref.invalidate(adminReviewQueueProvider);
      ref.invalidate(adminDashboardProvider);
      if (context.mounted) showAppSnackBar(context, t.admin.review.rejectedMsg);
    } catch (e) {
      if (context.mounted) showErrorSnackBar(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(adminReviewQueueProvider);
    return AsyncView(
      value: queue,
      onRetry: () => ref.invalidate(adminReviewQueueProvider),
      data: (list) {
        if (list.isEmpty) {
          return EmptyState(
            icon: Icons.fact_check_rounded,
            title: t.admin.review.emptyTitle,
            body: t.admin.review.emptyBody,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(24),
          itemCount: list.length,
          separatorBuilder: (_, _) => const SizedBox(height: 16),
          itemBuilder: (context, i) => _ReviewCard(
            device: list[i],
            onApprove: () => _approve(context, ref, list[i]),
            onReject: () => _reject(context, ref, list[i]),
          ),
        );
      },
    );
  }
}

class _ReviewCard extends ConsumerWidget {
  const _ReviewCard({
    required this.device,
    required this.onApprove,
    required this.onReject,
  });

  final SellerDevice device;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final templates = ref.watch(checklistTemplatesProvider).valueOrNull ?? [];
    final labels = {
      for (final template in templates)
        if (template.category == device.category)
          template.key: template.labelAr,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(device.title,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ),
                if (device.grade != null) GradeBadge(device.grade!),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${device.publicId} · ${device.brand} ${device.model} · ${device.price.format()}',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            if (device.photos.isNotEmpty)
              SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: device.photos.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, i) => ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 100,
                      child: DevicePhotoImage(
                          path: device.photos[i].storagePath),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Text(t.device.checklistTitle,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            for (final entry in device.checklist)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    ChecklistResultIcon(entry.result, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(labels[entry.key] ?? entry.key)),
                    if (entry.note != null)
                      Flexible(
                        child: Text(
                          entry.note!,
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant),
                          textAlign: TextAlign.end,
                        ),
                      ),
                  ],
                ),
              ),
            if (device.imeiLast4 != null) ...[
              const SizedBox(height: 8),
              Text(
                '${device.category == DeviceCategory.mobile ? t.device.imeiLabel : t.device.serialLabel}: ···${device.imeiLast4}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
            const Divider(height: 24),
            Row(
              children: [
                FilledButton.icon(
                  onPressed: onApprove,
                  icon: const Icon(Icons.check_circle_rounded, size: 18),
                  label: Text(t.admin.review.approve),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: onReject,
                  icon: const Icon(Icons.cancel_rounded, size: 18),
                  label: Text(t.admin.review.reject),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
