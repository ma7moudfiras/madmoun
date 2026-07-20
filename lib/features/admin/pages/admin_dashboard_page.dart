import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models.dart';
import '../../../core/widgets/common.dart';
import '../../../i18n/strings.g.dart';
import '../data/admin_repository.dart';

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(adminDashboardProvider);
    return AsyncView(
      value: stats,
      onRetry: () => ref.invalidate(adminDashboardProvider),
      skeleton: const _DashboardSkeleton(),
      data: (data) => _Dashboard(stats: data),
    );
  }
}

class _Dashboard extends StatelessWidget {
  const _Dashboard({required this.stats});

  final AdminDashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final columns = width >= 1100 ? 3 : (width >= 700 ? 2 : 1);
    final cards = [
      _StatCardData(t.admin.dashboard.pendingShops, '${stats.pendingShops}',
          Icons.storefront_rounded, '/admin/shops'),
      _StatCardData(
          t.admin.dashboard.devicesInReview,
          '${stats.devicesInReview}',
          Icons.fact_check_rounded,
          '/admin/review'),
      _StatCardData(
          t.admin.dashboard.activeReservations,
          '${stats.activeReservations}',
          Icons.receipt_long_rounded,
          '/admin/reservations'),
      _StatCardData(t.admin.dashboard.openClaims, '${stats.openClaims}',
          Icons.gavel_rounded, '/admin/claims'),
      _StatCardData(t.admin.dashboard.devicesSaved,
          '${stats.impact.devicesSaved}', Icons.recycling_rounded, null),
      _StatCardData(t.admin.dashboard.co2Avoided, '${stats.impact.estCo2Kg}',
          Icons.eco_rounded, null),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: GridView.count(
        crossAxisCount: columns,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.9,
        children: [for (final c in cards) _StatCard(data: c)],
      ),
    );
  }
}

class _StatCardData {
  const _StatCardData(this.label, this.value, this.icon, this.route);
  final String label;
  final String value;
  final IconData icon;
  final String? route;
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.data});

  final _StatCardData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: data.route == null ? null : () => context.go(data.route!),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(data.icon,
                    color: theme.colorScheme.onPrimaryContainer),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      data.value,
                      style: theme.textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      data.label,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      padding: const EdgeInsets.all(24),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.9,
      children: List.generate(
        6,
        (_) => const Shimmer(child: SkeletonBox(height: 100, radius: 16)),
      ),
    );
  }
}
