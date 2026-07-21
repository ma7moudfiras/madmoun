import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/domain.dart';
import '../../core/supabase_providers.dart';
import '../../i18n/strings.g.dart';
import 'data/seller_repository.dart';
import 'pages/seller_shop_page.dart';

/// Chrome for the seller portal: brand bar + destination rail/menu. Device,
/// reservation and claim tabs only appear once the shop is approved.
class SellerShell extends ConsumerWidget {
  const SellerShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final shopAsync = ref.watch(myShopProvider);
    final shop = shopAsync.valueOrNull;
    final approved = shop?.status == ShopStatus.approved;
    final isWide = MediaQuery.sizeOf(context).width >= 820;

    // Until the shop is approved, every tab funnels into onboarding/status;
    // this also keeps buyers/admins who type seller URLs out of the tools.
    final Widget body = shopAsync.isLoading
        ? const Center(child: CircularProgressIndicator())
        : (!approved && location != '/seller/shop')
            ? const SellerShopPage()
            : child;

    final destinations = <_Dest>[
      if (approved) _Dest('/seller', Icons.devices_rounded, t.seller.navDevices),
      if (approved)
        _Dest('/seller/reservations', Icons.receipt_long_rounded,
            t.seller.navReservations),
      if (approved)
        _Dest('/seller/claims', Icons.build_circle_rounded,
            t.seller.navClaims),
      _Dest('/seller/shop', Icons.storefront_rounded, t.seller.navShop),
    ];

    int selectedIndex() {
      var best = 0;
      var bestLen = -1;
      for (var i = 0; i < destinations.length; i++) {
        final path = destinations[i].path;
        if ((location == path || location.startsWith('$path/')) &&
            path.length > bestLen) {
          best = i;
          bestLen = path.length;
        }
      }
      return best;
    }

    final appBar = AppBar(
      title: InkWell(
        onTap: () => context.go('/'),
        borderRadius: BorderRadius.circular(8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.storefront_rounded, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(t.seller.title, style: theme.appBarTheme.titleTextStyle),
          ],
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: () => context.go('/'),
          icon: const Icon(Icons.storefront_outlined, size: 18),
          label: Text(t.common.marketplace),
        ),
        IconButton(
          tooltip: t.common.signOut,
          onPressed: () async {
            await ref.read(supabaseClientProvider).auth.signOut();
            if (context.mounted) context.go('/');
          },
          icon: const Icon(Icons.logout_rounded),
        ),
        const SizedBox(width: 8),
      ],
    );

    if (isWide) {
      return Scaffold(
        appBar: appBar,
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: selectedIndex(),
              onDestinationSelected: (i) => context.go(destinations[i].path),
              labelType: NavigationRailLabelType.all,
              destinations: [
                for (final d in destinations)
                  NavigationRailDestination(
                    icon: Icon(d.icon),
                    label: Text(d.label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: appBar,
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex(),
        onDestinationSelected: (i) => context.go(destinations[i].path),
        destinations: [
          for (final d in destinations)
            NavigationDestination(icon: Icon(d.icon), label: d.label),
        ],
      ),
    );
  }
}

class _Dest {
  const _Dest(this.path, this.icon, this.label);
  final String path;
  final IconData icon;
  final String label;
}
