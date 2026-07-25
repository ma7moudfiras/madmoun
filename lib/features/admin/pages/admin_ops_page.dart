import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain.dart';
import '../../../core/models.dart';
import '../../../core/widgets/common.dart';
import '../../../i18n/strings.g.dart';
import '../data/admin_repository.dart';
import '../data/order_dispatch.dart';

/// One place to run the whole pipeline: every order grouped by the stage that
/// needs the founder's attention, with the right action on each card.
class AdminOpsPage extends ConsumerWidget {
  const AdminOpsPage({super.key});

  void _refresh(WidgetRef ref) {
    ref.invalidate(adminReservationsProvider);
    ref.invalidate(adminCommissionSummaryProvider);
  }

  Future<void> _setStatus(BuildContext context, WidgetRef ref, int id,
      ReservationStatus status, String message) async {
    try {
      await ref.read(adminRepositoryProvider).setReservationStatus(id, status);
      _refresh(ref);
      if (context.mounted) showAppSnackBar(context, message);
    } catch (e) {
      if (context.mounted) showErrorSnackBar(context, e);
    }
  }

  Future<void> _dispatch(
      BuildContext context, WidgetRef ref, Reservation r) async {
    await openCourierWhatsApp(r);
    if (!context.mounted) return;
    await _setStatus(context, ref, r.id, ReservationStatus.outForDelivery,
        t.admin.reservations.dispatched);
  }

  Future<void> _settle(BuildContext context, WidgetRef ref, int id) async {
    try {
      await ref.read(adminRepositoryProvider).settleReservation(id);
      _refresh(ref);
      if (context.mounted) showAppSnackBar(context, t.admin.ledger.settled);
    } catch (e) {
      if (context.mounted) showErrorSnackBar(context, e);
    }
  }

  Future<void> _cancel(
      BuildContext context, WidgetRef ref, Reservation r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.admin.ops.cancelAction),
        content: Text(t.admin.ops.cancelConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(t.common.back),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(t.admin.ops.cancelAction),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await _setStatus(context, ref, r.id, ReservationStatus.cancelled,
        t.admin.ops.cancelled);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reservations = ref.watch(adminReservationsProvider);
    final summary = ref.watch(adminCommissionSummaryProvider);
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: () async => _refresh(ref),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.admin.ops.title,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(t.admin.ops.subtitle,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 16),
            AsyncView(
              value: reservations,
              onRetry: () => _refresh(ref),
              skeleton:
                  const Shimmer(child: SkeletonBox(height: 260, radius: 16)),
              data: (list) {
                final pending = list
                    .where((r) => r.status == ReservationStatus.pending)
                    .toList();
                final confirmed = list
                    .where((r) => r.status == ReservationStatus.confirmed)
                    .toList();
                final outForDelivery = list
                    .where(
                        (r) => r.status == ReservationStatus.outForDelivery)
                    .toList();
                final toSettle = list
                    .where((r) =>
                        r.status == ReservationStatus.delivered &&
                        r.settlementStatus != 'settled')
                    .toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SummaryRow(
                      counts: [
                        (t.admin.ops.stageNew, pending.length),
                        (t.admin.ops.stageToDispatch, confirmed.length),
                        (t.admin.ops.stageOutForDelivery,
                            outForDelivery.length),
                        (t.admin.ops.stageToSettle, toSettle.length),
                      ],
                      commission: summary.valueOrNull ?? const [],
                    ),
                    const SizedBox(height: 20),
                    _Stage(
                      title: t.admin.ops.stageToDispatch,
                      items: confirmed,
                      actions: (r) => [
                        FilledButton.icon(
                          onPressed: () => _dispatch(context, ref, r),
                          icon: const Icon(Icons.chat_rounded, size: 16),
                          label: Text(t.admin.reservations.dispatch),
                        ),
                        _cancelButton(context, ref, r),
                      ],
                    ),
                    _Stage(
                      title: t.admin.ops.stageOutForDelivery,
                      items: outForDelivery,
                      actions: (r) => [
                        OutlinedButton(
                          onPressed: () => _setStatus(
                              context,
                              ref,
                              r.id,
                              ReservationStatus.delivered,
                              t.admin.reservations.markedDelivered),
                          child: Text(t.admin.reservations.markDelivered),
                        ),
                        _cancelButton(context, ref, r),
                      ],
                    ),
                    _Stage(
                      title: t.admin.ops.stageToSettle,
                      items: toSettle,
                      actions: (r) => [
                        FilledButton.icon(
                          onPressed: () => _settle(context, ref, r.id),
                          icon: const Icon(
                              Icons.account_balance_wallet_rounded, size: 16),
                          label: Text(t.admin.ledger.settleAction),
                        ),
                      ],
                    ),
                    _Stage(
                      title: t.admin.ops.stageNew,
                      hint: t.admin.ops.awaitingShop,
                      items: pending,
                      actions: (r) => [_cancelButton(context, ref, r)],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _cancelButton(BuildContext context, WidgetRef ref, Reservation r) {
    return TextButton.icon(
      onPressed: () => _cancel(context, ref, r),
      icon: const Icon(Icons.cancel_outlined, size: 16),
      label: Text(t.admin.ops.cancelAction),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.counts, required this.commission});

  final List<(String, int)> counts;
  final List<CommissionSummary> commission;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[
      for (final (label, n) in counts) _StatChip(label: label, value: '$n'),
    ];
    final pending = commission.where((c) => c.pending.minor > 0).toList();
    if (pending.isEmpty) {
      chips.add(_StatChip(
          label: t.admin.ops.pendingCommission, value: '0', highlight: true));
    } else {
      for (final c in pending) {
        chips.add(_StatChip(
            label: t.admin.ops.pendingCommission,
            value: c.pending.format(),
            highlight: true));
      }
    }
    return Wrap(spacing: 12, runSpacing: 12, children: chips);
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip(
      {required this.label, required this.value, this.highlight = false});

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: highlight
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: highlight ? theme.colorScheme.primary : null)),
          Text(label,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _Stage extends StatelessWidget {
  const _Stage({
    required this.title,
    required this.items,
    required this.actions,
    this.hint,
  });

  final String title;
  final List<Reservation> items;
  final List<Widget> Function(Reservation) actions;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 11,
                backgroundColor: theme.colorScheme.secondaryContainer,
                child: Text('${items.length}',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSecondaryContainer)),
              ),
            ],
          ),
          if (hint != null) ...[
            const SizedBox(height: 2),
            Text(hint!,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
          const SizedBox(height: 10),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (final (i, r) in items.indexed) ...[
                  if (i > 0) const Divider(height: 1),
                  _OrderRow(reservation: r, actions: actions(r)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  const _OrderRow({required this.reservation, required this.actions});

  final Reservation reservation;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
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
                  '${reservation.publicId} · ${reservation.deliveryCity} · ${reservation.price.format()}',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Wrap(
            spacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: actions,
          ),
        ],
      ),
    );
  }
}
