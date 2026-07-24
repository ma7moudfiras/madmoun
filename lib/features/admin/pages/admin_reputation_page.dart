import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../../../i18n/strings.g.dart';
import '../data/admin_repository.dart';

/// Internal-only trust signal per shop, computed from real transactions
/// (deliveries, cancellations, warranty claims, device review outcomes).
/// Never surfaced to buyers or sellers — the opaque model stays intact.
class AdminReputationPage extends ConsumerWidget {
  const AdminReputationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reputation = ref.watch(adminShopReputationProvider);
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.admin.reputation.title,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(t.admin.reputation.subtitle,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 16),
          AsyncView(
            value: reputation,
            onRetry: () => ref.invalidate(adminShopReputationProvider),
            skeleton: const Shimmer(child: SkeletonBox(height: 240, radius: 16)),
            data: (list) {
              if (list.isEmpty) {
                return EmptyState(
                  icon: Icons.shield_outlined,
                  title: t.admin.reputation.emptyTitle,
                  body: t.admin.reputation.emptyBody,
                );
              }
              return Column(
                children: [
                  for (final r in list) ...[
                    _ReputationCard(reputation: r),
                    const SizedBox(height: 12),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TierStyle {
  const _TierStyle(this.label, this.color, this.icon);
  final String label;
  final Color color;
  final IconData icon;
}

_TierStyle _tierStyle(BuildContext context, String tier) {
  final colors = context.appColors;
  final theme = Theme.of(context);
  switch (tier) {
    case 'excellent':
      return _TierStyle(t.admin.reputation.tierExcellent, colors.success,
          Icons.verified_rounded);
    case 'good':
      return _TierStyle(
          t.admin.reputation.tierGood, colors.success, Icons.check_circle_rounded);
    case 'watch':
      return _TierStyle(
          t.admin.reputation.tierWatch, colors.warning, Icons.error_outline_rounded);
    case 'critical':
      return _TierStyle(t.admin.reputation.tierCritical, theme.colorScheme.error,
          Icons.report_rounded);
    default:
      return _TierStyle(t.admin.reputation.tierNew,
          theme.colorScheme.onSurfaceVariant, Icons.hourglass_empty_rounded);
  }
}

String _pct(double rate) => '${(rate * 100).round()}%';

class _ReputationCard extends StatelessWidget {
  const _ReputationCard({required this.reputation});

  final ShopReputation reputation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = _tierStyle(context, reputation.tier);
    final isNew = reputation.tier == 'new';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(reputation.shopName,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    Text(reputation.shopCity,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(style.icon, size: 16, color: style.color),
                      const SizedBox(width: 4),
                      Text(style.label,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: style.color, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  if (!isNew)
                    Text('${t.admin.reputation.trustScore}: ${reputation.trustScore.round()}',
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800, color: style.color)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Stat(t.admin.reputation.completedOrders, '${reputation.completedOrders}'),
              _Stat(t.admin.reputation.cancelledOrders, '${reputation.cancelledOrders}'),
              _Stat(t.admin.reputation.activeOrders, '${reputation.activeOrders}'),
              _Stat(t.admin.reputation.claims, '${reputation.claims}'),
              _Stat(
                  t.admin.reputation.devicesRejected(submitted: '${reputation.devicesSubmitted}'),
                  '${reputation.devicesRejected}'),
            ],
          ),
          if (!isNew && (reputation.completedOrders + reputation.cancelledOrders) > 0) ...[
            const SizedBox(height: 8),
            Text(
              '${t.admin.reputation.cancellationRate(rate: _pct(reputation.cancellationRate))} · '
              '${t.admin.reputation.claimRate(rate: _pct(reputation.claimRate))} · '
              '${t.admin.reputation.rejectionRate(rate: _pct(reputation.rejectionRate))}',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
          if (isNew) ...[
            const SizedBox(height: 8),
            Text(t.admin.reputation.insufficientData,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text('$label: $value', style: theme.textTheme.bodySmall),
    );
  }
}
