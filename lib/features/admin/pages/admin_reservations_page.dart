import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/domain.dart';
import '../../../core/models.dart';
import '../../../core/widgets/common.dart';
import '../../../i18n/strings.g.dart';
import '../data/admin_repository.dart';

class AdminReservationsPage extends ConsumerWidget {
  const AdminReservationsPage({super.key});

  Future<void> _setStatus(BuildContext context, WidgetRef ref, int id,
      ReservationStatus status, String successMessage) async {
    try {
      await ref.read(adminRepositoryProvider).setReservationStatus(id, status);
      ref.invalidate(adminReservationsProvider);
      if (context.mounted) showAppSnackBar(context, successMessage);
    } catch (e) {
      if (context.mounted) showErrorSnackBar(context, e);
    }
  }

  /// A complete pickup + dropoff brief for the courier, sent to whichever
  /// WhatsApp contact the admin picks (wa.me with no number opens the picker).
  String _courierBrief(Reservation r) {
    final d = t.admin.dispatch;
    final pickup = [r.shopName, r.shopCity, r.shopAddress]
        .whereType<String>()
        .where((e) => e.isNotEmpty)
        .join(' — ');
    final dropoff = [r.deliveryCity, r.deliveryAddress]
        .whereType<String>()
        .where((e) => e.isNotEmpty)
        .join(' — ');
    final b = StringBuffer()
      ..writeln(d.msgTitle)
      ..writeln('${d.order}: ${r.publicId}');
    if (r.deviceTitle != null) b.writeln('${d.device}: ${r.deviceTitle}');
    b.writeln('');
    b.writeln('📦 ${d.pickup}:');
    if (pickup.isNotEmpty) b.writeln(pickup);
    if (r.shopPhone != null) b.writeln('${d.phone}: ${r.shopPhone}');
    b.writeln('');
    b.writeln('🏠 ${d.dropoff}:');
    if (dropoff.isNotEmpty) b.writeln(dropoff);
    if (r.buyerPhone != null) b.writeln('${d.phone}: ${r.buyerPhone}');
    if (r.deliveryNote != null) b.writeln('${d.note}: ${r.deliveryNote}');
    b.writeln('');
    b.write('💵 ${d.collect}: ${r.price.format()}');
    return b.toString();
  }

  Future<void> _dispatch(
      BuildContext context, WidgetRef ref, Reservation r) async {
    final uri = Uri.parse(
        'https://wa.me/?text=${Uri.encodeComponent(_courierBrief(r))}');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!context.mounted) return;
    await _setStatus(context, ref, r.id, ReservationStatus.outForDelivery,
        t.admin.reservations.dispatched);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reservations = ref.watch(adminReservationsProvider);
    final theme = Theme.of(context);
    return AsyncView(
      value: reservations,
      onRetry: () => ref.invalidate(adminReservationsProvider),
      data: (list) {
        if (list.isEmpty) {
          return EmptyState(
            icon: Icons.receipt_long_rounded,
            title: t.admin.reservations.emptyTitle,
            body: t.admin.reservations.emptyBody,
          );
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.admin.reservations.title,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              Card(
                clipBehavior: Clip.antiAlias,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: [
                      DataColumn(label: Text(t.orders.reservationLabel)),
                      DataColumn(label: Text(t.device.publicIdLabel)),
                      DataColumn(label: Text(t.common.priceLabel)),
                      DataColumn(label: Text(t.admin.reservations.commission)),
                      DataColumn(label: Text(t.common.cityLabel)),
                      DataColumn(label: Text(t.common.phoneLabel)),
                      const DataColumn(label: Text('')),
                    ],
                    rows: [
                      for (final r in list)
                        DataRow(cells: [
                          DataCell(Text(r.publicId)),
                          DataCell(Text(r.devicePublicId ?? '—')),
                          DataCell(Text(r.price.format())),
                          DataCell(Text(
                              Money(r.commissionMinor, r.price.currency)
                                  .format())),
                          DataCell(Text(r.deliveryCity)),
                          DataCell(Text(r.buyerPhone ?? '—')),
                          DataCell(Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              StatusChip.reservation(context, r.status),
                              if (r.status == ReservationStatus.confirmed) ...[
                                const SizedBox(width: 8),
                                FilledButton.icon(
                                  onPressed: () => _dispatch(context, ref, r),
                                  icon: const Icon(Icons.chat_rounded, size: 16),
                                  label: Text(t.admin.reservations.dispatch),
                                ),
                              ] else if (r.status ==
                                  ReservationStatus.outForDelivery) ...[
                                const SizedBox(width: 8),
                                OutlinedButton(
                                  onPressed: () => _setStatus(
                                      context,
                                      ref,
                                      r.id,
                                      ReservationStatus.delivered,
                                      t.admin.reservations.markedDelivered),
                                  child:
                                      Text(t.admin.reservations.markDelivered),
                                ),
                              ],
                            ],
                          )),
                        ]),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
