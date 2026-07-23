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
            // Admins only manage the platform: no orders, no seller portal.
            if (signedIn && role != UserRole.admin)
              TextButton(
                onPressed: () => context.go('/orders'),
                child: Text(t.common.myOrders),
              ),
            if (role != UserRole.admin)
              TextButton(
                onPressed: () => context.go('/seller'),
                child: Text(t.common.sellerPortal),
              ),
            if (role == UserRole.admin)
              TextButton(
                onPressed: () => context.go('/admin'),
                child: Text(t.common.adminPanel),
              ),
            const _InfoMenu(),
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
      tooltip: t.common.account,
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
          case 'account':
            context.go('/account');
          case 'orders':
            context.go('/orders');
          case 'seller':
            context.go('/seller');
          case 'admin':
            context.go('/admin');
          case 'signout':
            context.go('/');
            await ref.read(supabaseClientProvider).auth.signOut();
        }
      },
      itemBuilder: (context) => [
        if (showCompactNav) ...[
          if (role != UserRole.admin)
            PopupMenuItem(value: 'orders', child: Text(t.common.myOrders)),
          if (role != UserRole.admin)
            PopupMenuItem(value: 'seller', child: Text(t.common.sellerPortal)),
          if (role == UserRole.admin)
            PopupMenuItem(value: 'admin', child: Text(t.common.adminPanel)),
          const PopupMenuDivider(),
        ],
        PopupMenuItem(value: 'account', child: Text(t.common.accountSettings)),
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
        const PopupMenuDivider(),
        PopupMenuItem(value: '/how-it-works', child: Text(t.info.howTitle)),
        PopupMenuItem(value: '/faq', child: Text(t.info.faqTitle)),
        PopupMenuItem(value: '/terms', child: Text(t.info.termsTitle)),
        PopupMenuItem(value: '/privacy', child: Text(t.info.privacyTitle)),
      ],
    );
  }
}

/// A compact "معلومات" dropdown in the top bar linking to the static pages.
class _InfoMenu extends StatelessWidget {
  const _InfoMenu();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).appBarTheme.foregroundColor ??
        Theme.of(context).colorScheme.onSurface;
    return PopupMenuButton<String>(
      tooltip: t.info.menuLabel,
      onSelected: (value) => context.go(value),
      itemBuilder: (context) => [
        PopupMenuItem(value: '/how-it-works', child: Text(t.info.howTitle)),
        PopupMenuItem(value: '/faq', child: Text(t.info.faqTitle)),
        PopupMenuItem(value: '/terms', child: Text(t.info.termsTitle)),
        PopupMenuItem(value: '/privacy', child: Text(t.info.privacyTitle)),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(t.info.menuLabel,
                style: TextStyle(color: color, fontWeight: FontWeight.w500)),
            Icon(Icons.arrow_drop_down_rounded, color: color, size: 20),
          ],
        ),
      ),
    );
  }
}
