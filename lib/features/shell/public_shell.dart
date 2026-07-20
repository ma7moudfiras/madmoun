import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/domain.dart';
import '../../core/supabase_providers.dart';
import '../../i18n/strings.g.dart';

/// Top-level chrome for the public marketplace: brand, nav, account menu.
class PublicShell extends ConsumerWidget {
  const PublicShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signedIn = ref.watch(isSignedInProvider);
    final role = ref.watch(userRoleProvider);
    final theme = Theme.of(context);
    final isWide = MediaQuery.sizeOf(context).width >= 720;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: InkWell(
          onTap: () => context.go('/'),
          borderRadius: BorderRadius.circular(8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.verified_rounded, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                t.common.appName,
                style: theme.appBarTheme.titleTextStyle,
              ),
            ],
          ),
        ),
        actions: [
          if (isWide) ...[
            TextButton(
              onPressed: () => context.go('/'),
              child: Text(t.common.marketplace),
            ),
            if (signedIn)
              TextButton(
                onPressed: () => context.go('/orders'),
                child: Text(t.common.myOrders),
              ),
            TextButton(
              onPressed: () => context.go('/seller'),
              child: Text(t.common.sellerPortal),
            ),
            if (role == UserRole.admin)
              TextButton(
                onPressed: () => context.go('/admin'),
                child: Text(t.common.adminPanel),
              ),
            const SizedBox(width: 8),
          ],
          if (!signedIn)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 16),
              child: FilledButton(
                onPressed: () => context.go('/login'),
                child: Text(t.common.login),
              ),
            )
          else
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: _AccountMenu(showCompactNav: !isWide),
            ),
          if (!signedIn && !isWide)
            _CompactNav(signedIn: signedIn, role: role),
        ],
      ),
      body: child,
    );
  }
}

class _AccountMenu extends ConsumerWidget {
  const _AccountMenu({required this.showCompactNav});

  final bool showCompactNav;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(userRoleProvider);
    return PopupMenuButton<String>(
      tooltip: t.common.myOrders,
      icon: CircleAvatar(
        radius: 16,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Icon(
          Icons.person_rounded,
          size: 20,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
      onSelected: (value) async {
        switch (value) {
          case 'orders':
            context.go('/orders');
          case 'seller':
            context.go('/seller');
          case 'admin':
            context.go('/admin');
          case 'signout':
            await ref.read(supabaseClientProvider).auth.signOut();
            if (context.mounted) context.go('/');
        }
      },
      itemBuilder: (context) => [
        if (showCompactNav) ...[
          PopupMenuItem(value: 'orders', child: Text(t.common.myOrders)),
          PopupMenuItem(value: 'seller', child: Text(t.common.sellerPortal)),
          if (role == UserRole.admin)
            PopupMenuItem(value: 'admin', child: Text(t.common.adminPanel)),
          const PopupMenuDivider(),
        ],
        PopupMenuItem(value: 'signout', child: Text(t.common.signOut)),
      ],
    );
  }
}

class _CompactNav extends StatelessWidget {
  const _CompactNav({required this.signedIn, required this.role});

  final bool signedIn;
  final UserRole? role;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.menu_rounded),
      onSelected: (value) => context.go(value),
      itemBuilder: (context) => [
        PopupMenuItem(value: '/', child: Text(t.common.marketplace)),
        PopupMenuItem(value: '/seller', child: Text(t.common.sellerPortal)),
      ],
    );
  }
}
