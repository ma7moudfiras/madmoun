import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain.dart';
import '../../../core/widgets/common.dart';
import '../../../i18n/strings.g.dart';
import '../data/admin_repository.dart';

class AdminReservationsPage extends ConsumerWidget {
  const AdminReservationsPage({super.key});

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
                          DataCell(Text(r.buyerPhone)),
                          DataCell(StatusChip.reservation(context, r.status)),
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
