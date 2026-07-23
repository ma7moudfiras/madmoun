import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/domain.dart';
import '../../core/supabase_providers.dart';
import '../../core/widgets/common.dart';
import '../../i18n/strings.g.dart';

/// Admin chrome, role-gated in the UI (RLS enforces it at the DB regardless).
class AdminShell extends ConsumerWidget {
  const AdminShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profile = ref.watch(profileProvider);

    final destinations = <_Dest>[
      _Dest('/admin', Icons.dashboard_rounded, t.admin.navDashboard),
      _Dest('/admin/shops', Icons.storefront_rounded, t.admin.navShops),
      _Dest('/admin/review', Icons.fact_check_rounded, t.admin.navReview),
      _Dest('/admin/templates', Icons.checklist_rounded, t.admin.navTemplates),
      _Dest('/admin/claims', Icons.gavel_rounded, t.admin.navClaims),
      _Dest('/admin/reservations', Icons.receipt_long_rounded,
          t.admin.navReservations),
      _Dest('/admin/ledger', Icons.account_balance_wallet_rounded,
          t.admin.navLedger),
      _Dest('/admin/users', Icons.group_rounded, t.admin.navUsers),
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
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.admin_panel_settings_rounded,
              color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(t.admin.title, style: theme.appBarTheme.titleTextStyle),
        ],
      ),
      actions: [
        TextButton.icon(
          onPressed: () => context.go('/'),
          icon: const Icon(Icons.storefront_outlined, size: 18),
          label: Text(t.common.marketplace),
        ),
        IconButton(
          tooltip: t.common.accountSettings,
          onPressed: () => context.go('/account'),
          icon: const Icon(Icons.manage_accounts_rounded),
        ),
        IconButton(
          tooltip: t.common.signOut,
          onPressed: () {
            // Navigate home first so the auth-change redirect doesn't bounce
            // an authed route to /login before we leave the dashboard.
            context.go('/');
            ref.read(supabaseClientProvider).auth.signOut();
          },
          icon: const Icon(Icons.logout_rounded),
        ),
        const SizedBox(width: 8),
      ],
    );

    return AsyncView(
      value: profile,
      onRetry: () => ref.invalidate(profileProvider),
      data: (data) {
        if (data?.role != UserRole.admin) {
          return Scaffold(
            appBar: appBar,
            body: EmptyState(
              icon: Icons.lock_rounded,
              title: t.admin.forbiddenTitle,
              body: t.admin.forbiddenBody,
              action: FilledButton(
                onPressed: () => context.go('/'),
                child: Text(t.common.backHome),
              ),
            ),
          );
        }

        final isWide = MediaQuery.sizeOf(context).width >= 900;
        if (isWide) {
          return Scaffold(
            appBar: appBar,
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: selectedIndex(),
                  onDestinationSelected: (i) =>
                      context.go(destinations[i].path),
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
                Expanded(child: child),
              ],
            ),
          );
        }

        return Scaffold(
          appBar: appBar,
          drawer: Drawer(
            child: SafeArea(
              child: ListView(
                children: [
                  for (var i = 0; i < destinations.length; i++)
                    ListTile(
                      leading: Icon(destinations[i].icon),
                      title: Text(destinations[i].label),
                      selected: selectedIndex() == i,
                      onTap: () {
                        Navigator.of(context).pop();
                        context.go(destinations[i].path);
                      },
                    ),
                ],
              ),
            ),
          ),
          body: child,
        );
      },
    );
  }
}

class _Dest {
  const _Dest(this.path, this.icon, this.label);
  final String path;
  final IconData icon;
  final String label;
}
