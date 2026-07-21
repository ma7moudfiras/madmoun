import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/account/account_page.dart';
import '../features/admin/admin_shell.dart';
import '../features/admin/pages/admin_claims_page.dart';
import '../features/admin/pages/admin_dashboard_page.dart';
import '../features/admin/pages/admin_reservations_page.dart';
import '../features/admin/pages/admin_review_page.dart';
import '../features/admin/pages/admin_shops_page.dart';
import '../features/admin/pages/admin_templates_page.dart';
import '../features/auth/login_page.dart';
import '../features/auth/register_page.dart';
import '../features/auth/reset_password_page.dart';
import '../features/buyer/orders_page.dart';
import '../features/buyer/reserve_page.dart';
import '../features/marketplace/device_page.dart';
import '../features/marketplace/home_page.dart';
import '../features/seller/pages/seller_claims_page.dart';
import '../features/seller/pages/seller_device_form_page.dart';
import '../features/seller/pages/seller_devices_page.dart';
import '../features/seller/pages/seller_reservations_page.dart';
import '../features/seller/pages/seller_shop_page.dart';
import '../features/seller/seller_shell.dart';
import '../features/shell/not_found_page.dart';
import '../features/shell/public_shell.dart';
import 'supabase_providers.dart';

/// Routes that require a signed-in user of any role.
const _authedPrefixes = ['/orders', '/reserve', '/seller', '/admin', '/account'];

final routerProvider = Provider<GoRouter>((ref) {
  // Subscribe to auth changes directly: the redirect below must re-run the
  // moment a session appears/disappears.
  final client = ref.watch(supabaseClientProvider);
  final refresh = ValueNotifier(0);
  // A password-recovery deep link opens a temporary session; send the user to
  // the set-new-password screen once, and only once, per recovery.
  var recovering = false;
  final subscription = client.auth.onAuthStateChange.listen((state) {
    if (state.event == AuthChangeEvent.passwordRecovery) recovering = true;
    refresh.value++;
  });
  ref.onDispose(() {
    subscription.cancel();
    refresh.dispose();
  });

  return GoRouter(
    refreshListenable: refresh,
    initialLocation: '/',
    debugLogDiagnostics: false,
    errorBuilder: (context, state) => const NotFoundPage(),
    redirect: (context, state) {
      final signedIn = ref.read(isSignedInProvider);
      final location = state.uri.path;

      if (recovering && location != '/reset-password') {
        recovering = false;
        return '/reset-password';
      }

      final needsAuth =
          _authedPrefixes.any((p) => location == p || location.startsWith('$p/'));

      if (!signedIn && needsAuth) {
        final from = Uri.encodeComponent(state.uri.toString());
        return '/login?from=$from';
      }
      if (signedIn && (location == '/login' || location == '/register')) {
        final from = state.uri.queryParameters['from'];
        return (from == null || from.isEmpty) ? '/' : Uri.decodeComponent(from);
      }
      return null;
    },
    routes: [
      ShellRoute(
        builder: (context, state, child) => PublicShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const HomePage(),
          ),
          GoRoute(
            path: '/d/:publicId',
            builder: (context, state) =>
                DevicePage(publicId: state.pathParameters['publicId']!),
          ),
          GoRoute(
            path: '/reserve/:publicId',
            builder: (context, state) =>
                ReservePage(publicId: state.pathParameters['publicId']!),
          ),
          GoRoute(
            path: '/orders',
            builder: (context, state) => const OrdersPage(),
          ),
          GoRoute(
            path: '/login',
            builder: (context, state) =>
                LoginPage(from: state.uri.queryParameters['from']),
          ),
          GoRoute(
            path: '/register',
            builder: (context, state) =>
                RegisterPage(from: state.uri.queryParameters['from']),
          ),
          GoRoute(
            path: '/reset-password',
            builder: (context, state) => const ResetPasswordPage(),
          ),
          GoRoute(
            path: '/account',
            builder: (context, state) => const AccountPage(),
          ),
        ],
      ),
      ShellRoute(
        builder: (context, state, child) =>
            SellerShell(location: state.uri.path, child: child),
        routes: [
          GoRoute(
            path: '/seller',
            builder: (context, state) => const SellerDevicesPage(),
          ),
          GoRoute(
            path: '/seller/devices/new',
            builder: (context, state) => const SellerDeviceFormPage(),
          ),
          GoRoute(
            path: '/seller/devices/:id',
            builder: (context, state) => SellerDeviceFormPage(
              deviceId: int.tryParse(state.pathParameters['id'] ?? ''),
            ),
          ),
          GoRoute(
            path: '/seller/reservations',
            builder: (context, state) => const SellerReservationsPage(),
          ),
          GoRoute(
            path: '/seller/claims',
            builder: (context, state) => const SellerClaimsPage(),
          ),
          GoRoute(
            path: '/seller/shop',
            builder: (context, state) => const SellerShopPage(),
          ),
        ],
      ),
      ShellRoute(
        builder: (context, state, child) =>
            AdminShell(location: state.uri.path, child: child),
        routes: [
          GoRoute(
            path: '/admin',
            builder: (context, state) => const AdminDashboardPage(),
          ),
          GoRoute(
            path: '/admin/shops',
            builder: (context, state) => const AdminShopsPage(),
          ),
          GoRoute(
            path: '/admin/review',
            builder: (context, state) => const AdminReviewPage(),
          ),
          GoRoute(
            path: '/admin/templates',
            builder: (context, state) => const AdminTemplatesPage(),
          ),
          GoRoute(
            path: '/admin/claims',
            builder: (context, state) => const AdminClaimsPage(),
          ),
          GoRoute(
            path: '/admin/reservations',
            builder: (context, state) => const AdminReservationsPage(),
          ),
        ],
      ),
    ],
  );
});
