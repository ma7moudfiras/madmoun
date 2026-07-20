import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain.dart';
import '../../../core/models.dart';
import '../../../core/widgets/common.dart';
import '../../../i18n/strings.g.dart';
import '../data/admin_repository.dart';
import '../widgets/reason_dialog.dart';

class AdminShopsPage extends ConsumerStatefulWidget {
  const AdminShopsPage({super.key});

  @override
  ConsumerState<AdminShopsPage> createState() => _AdminShopsPageState();
}

class _AdminShopsPageState extends ConsumerState<AdminShopsPage> {
  bool _showAll = false;

  ShopStatus? get _filter => _showAll ? null : ShopStatus.pending;

  Future<void> _approve(Shop shop) async {
    try {
      await ref
          .read(adminRepositoryProvider)
          .setShopStatus(shop.id, ShopStatus.approved);
      _refresh();
      if (mounted) showAppSnackBar(context, t.admin.shops.approvedMsg);
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    }
  }

  Future<void> _reject(Shop shop) async {
    final reason = await promptReason(
      context,
      title: t.admin.shops.rejectTitle,
      hint: t.admin.shops.rejectHint,
      confirmLabel: t.admin.shops.reject,
    );
    if (reason == null || !mounted) return;
    try {
      await ref
          .read(adminRepositoryProvider)
          .setShopStatus(shop.id, ShopStatus.rejected, reason: reason);
      _refresh();
      if (mounted) showAppSnackBar(context, t.admin.shops.rejectedMsg);
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    }
  }

  void _refresh() {
    ref.invalidate(adminShopsProvider);
    ref.invalidate(adminDashboardProvider);
  }

  @override
  Widget build(BuildContext context) {
    final shops = ref.watch(adminShopsProvider(_filter));
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Row(
            children: [
              Text(t.admin.shops.title,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const Spacer(),
              FilterChip(
                label: Text(t.admin.shops.showAll),
                selected: _showAll,
                onSelected: (v) => setState(() => _showAll = v),
              ),
            ],
          ),
        ),
        Expanded(
          child: AsyncView(
            value: shops,
            onRetry: _refresh,
            data: (list) {
              if (list.isEmpty) {
                return EmptyState(
                  icon: Icons.storefront_rounded,
                  title: t.admin.shops.emptyTitle,
                  body: t.admin.shops.emptyBody,
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(24),
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, i) => _ShopCard(
                  shop: list[i],
                  onApprove: () => _approve(list[i]),
                  onReject: () => _reject(list[i]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ShopCard extends StatelessWidget {
  const _ShopCard({
    required this.shop,
    required this.onApprove,
    required this.onReject,
  });

  final Shop shop;
  final VoidCallback onApprove;
  final VoidCallback onReject;

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
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(shop.name,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(
                        '${shop.city}${shop.phoneE164 != null ? ' · ${shop.phoneE164}' : ''}',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                StatusChip.shop(context, shop.status),
              ],
            ),
            if (shop.status == ShopStatus.rejected &&
                shop.rejectionReason != null) ...[
              const SizedBox(height: 8),
              Text(
                t.seller.onboarding
                    .rejectedReason(reason: shop.rejectionReason!),
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.error),
              ),
            ],
            if (shop.status == ShopStatus.pending) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  FilledButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: Text(t.admin.shops.approve),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: Text(t.admin.shops.reject),
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
