import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain.dart';
import '../../../core/models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../../../i18n/strings.g.dart';
import '../data/admin_repository.dart';

class AdminLedgerPage extends ConsumerWidget {
  const AdminLedgerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(adminCommissionSummaryProvider);
    final settlements = ref.watch(adminSettlementsProvider);
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.admin.ledger.title,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(t.admin.ledger.subtitle,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 16),
          summary.when(
            data: (rows) {
              if (rows.isEmpty) {
                return EmptyState(
                  icon: Icons.account_balance_wallet_rounded,
                  title: t.admin.ledger.emptyTitle,
                  body: t.admin.ledger.emptyBody,
                );
              }
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [for (final s in rows) _SummaryCard(summary: s)],
              );
            },
            loading: () =>
                const Shimmer(child: SkeletonBox(height: 120, radius: 16)),
            error: (_, _) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 24),
          Text(t.admin.ledger.ordersTitle,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          AsyncView(
            value: settlements,
            onRetry: () => ref.invalidate(adminSettlementsProvider),
            skeleton: const Shimmer(child: SkeletonBox(height: 200, radius: 16)),
            data: (list) {
              if (list.isEmpty) {
                return EmptyState(
                  icon: Icons.receipt_long_rounded,
                  title: t.admin.ledger.emptyTitle,
                  body: t.admin.ledger.emptyBody,
                );
              }
              return Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (final (i, r) in list.indexed) ...[
                      if (i > 0) const Divider(height: 1),
                      _SettlementRow(reservation: r),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary});

  final CommissionSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 260,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.admin.ledger.currencyOrders(
                currency: t.enums.currency[summary.currency.dbValue] ??
                    summary.currency.dbValue,
                count: '${summary.orders}'),
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 10),
          Text(t.admin.ledger.pendingCommission,
              style: theme.textTheme.bodySmall),
          Text(
            summary.pending.format(),
            style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.check_circle_rounded,
                  size: 15, color: context.appColors.success),
              const SizedBox(width: 4),
              Text(
                t.admin.ledger.settledLabel(amount: summary.settled.format()),
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettlementRow extends ConsumerWidget {
  const _SettlementRow({required this.reservation});

  final Reservation reservation;

  Future<void> _settle(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.admin.ledger.settleAction),
        content: Text(t.admin.ledger.settleConfirm(
            amount: Money(reservation.commissionMinor, reservation.price.currency)
                .format())),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(t.common.back),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(t.admin.ledger.settleAction),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(adminRepositoryProvider).settleReservation(reservation.id);
      ref.invalidate(adminSettlementsProvider);
      ref.invalidate(adminCommissionSummaryProvider);
      if (context.mounted) showAppSnackBar(context, t.admin.ledger.settled);
    } catch (e) {
      if (context.mounted) showErrorSnackBar(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currency = reservation.price.currency;
    final commission = Money(reservation.commissionMinor, currency);
    final settled = reservation.settlementStatus == 'settled';
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reservation.deviceTitle ?? reservation.publicId,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                  '${reservation.publicId} · ${t.admin.ledger.priceLabel(amount: reservation.price.format())} · '
                  '${t.admin.ledger.netLabel(amount: reservation.netToShop.format())}',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(commission.format(),
                  style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.primary)),
              Text(t.admin.ledger.commissionLabel,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
          const SizedBox(width: 12),
          if (settled)
            Chip(
              avatar: Icon(Icons.check_rounded,
                  size: 16, color: context.appColors.success),
              label: Text(t.admin.ledger.statusSettled),
              visualDensity: VisualDensity.compact,
            )
          else
            FilledButton(
              onPressed: () => _settle(context, ref),
              child: Text(t.admin.ledger.settleAction),
            ),
        ],
      ),
    );
  }
}
