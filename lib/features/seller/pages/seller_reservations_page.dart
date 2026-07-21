import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain.dart';
import '../../../core/models.dart';
import '../../../core/widgets/common.dart';
import '../../../i18n/strings.g.dart';
import '../../marketplace/widgets/listing_card.dart';
import '../data/seller_repository.dart';

final incomingReservationsProvider =
    FutureProvider<List<Reservation>>((ref) async {
  final shop = await ref.watch(myShopProvider.future);
  if (shop == null) return const [];
  return ref
      .watch(sellerRepositoryProvider)
      .fetchIncomingReservations(shop.id);
});

class SellerReservationsPage extends ConsumerWidget {
  const SellerReservationsPage({super.key});

  Future<void> _setStatus(
    BuildContext context,
    WidgetRef ref,
    Reservation reservation,
    ReservationStatus status,
    String successMessage,
  ) async {
    try {
      await ref
          .read(sellerRepositoryProvider)
          .setReservationStatus(reservation.id, status);
      ref.invalidate(incomingReservationsProvider);
      if (context.mounted) showAppSnackBar(context, successMessage);
    } catch (e) {
      if (context.mounted) showErrorSnackBar(context, e);
    }
  }

  Future<void> _cancel(
      BuildContext context, WidgetRef ref, Reservation reservation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.seller.reservations.cancelAction),
        content: Text(t.seller.reservations.cancelConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(t.common.back),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(t.seller.reservations.cancelAction),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await _setStatus(context, ref, reservation,
          ReservationStatus.cancelled, t.seller.reservations.cancelled);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reservations = ref.watch(incomingReservationsProvider);
    return AsyncView(
      value: reservations,
      onRetry: () => ref.invalidate(incomingReservationsProvider),
      data: (list) {
        if (list.isEmpty) {
          return EmptyState(
            icon: Icons.receipt_long_rounded,
            title: t.seller.reservations.emptyTitle,
            body: t.seller.reservations.emptyBody,
          );
        }
        return RefreshIndicator(
          onRefresh: () async =>
              ref.invalidate(incomingReservationsProvider),
          child: ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final reservation = list[i];
              return _ReservationCard(
                reservation: reservation,
                onConfirm: reservation.status == ReservationStatus.pending
                    ? () => _setStatus(context, ref, reservation,
                        ReservationStatus.confirmed,
                        t.seller.reservations.confirmed)
                    : null,
                onDeliver: reservation.status == ReservationStatus.confirmed
                    ? () => _setStatus(context, ref, reservation,
                        ReservationStatus.delivered,
                        t.seller.reservations.delivered)
                    : null,
                onCancel: (reservation.status == ReservationStatus.pending ||
                        reservation.status == ReservationStatus.confirmed)
                    ? () => _cancel(context, ref, reservation)
                    : null,
              );
            },
          ),
        );
      },
    );
  }
}

class _ReservationCard extends StatelessWidget {
  const _ReservationCard({
    required this.reservation,
    this.onConfirm,
    this.onDeliver,
    this.onCancel,
  });

  final Reservation reservation;
  final VoidCallback? onConfirm;
  final VoidCallback? onDeliver;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                    width: 64,
                    height: 64,
                    child:
                        DevicePhotoImage(path: reservation.deviceCoverPath),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reservation.deviceTitle ?? '—',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${t.orders.reservationLabel}: ${reservation.publicId} · ${reservation.price.format()}',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                StatusChip.reservation(context, reservation.status),
              ],
            ),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.phone_rounded,
              label: t.seller.reservations.buyerPhone,
              value: reservation.buyerPhone,
              copyable: true,
            ),
            _InfoRow(
              icon: Icons.location_on_rounded,
              label: t.common.cityLabel,
              value: reservation.deliveryCity,
            ),
            if (reservation.deliveryNote != null)
              _InfoRow(
                icon: Icons.sticky_note_2_rounded,
                label: t.common.noteLabel,
                value: reservation.deliveryNote!,
              ),
            if (onConfirm != null || onDeliver != null || onCancel != null) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (onConfirm != null)
                    FilledButton.icon(
                      onPressed: onConfirm,
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: Text(t.seller.reservations.confirmAction),
                    ),
                  if (onDeliver != null)
                    FilledButton.icon(
                      onPressed: onDeliver,
                      icon: const Icon(
                          Icons.local_shipping_rounded, size: 18),
                      label: Text(t.seller.reservations.deliverAction),
                    ),
                  if (onCancel != null)
                    TextButton.icon(
                      onPressed: onCancel,
                      icon: const Icon(Icons.cancel_outlined, size: 18),
                      label: Text(t.seller.reservations.cancelAction),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.copyable = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool copyable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Text('$label: ',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          Expanded(
            child: Text(value,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
