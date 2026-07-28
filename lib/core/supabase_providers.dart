import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'domain.dart';
import 'models.dart';

/// Build-time configuration. The anon key is public by design; both values
/// can be overridden with --dart-define at build time.
abstract final class Env {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://dutmsyjwrueyyrdeccol.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR1dG1zeWp3cnVleXlyZGVjY29sIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQ0Nzk4NDAsImV4cCI6MjEwMDA1NTg0MH0.wk_Y_1ZXcOKCj_09PNNn5uqDFQ5_hzbFqjUdlhrlXXA',
  );

  /// Google OAuth ships only when the OAuth client is configured upstream.
  static const bool googleAuthEnabled =
      bool.fromEnvironment('ENABLE_GOOGLE_AUTH');

  /// Apple OAuth ships only when the Services ID is configured upstream.
  static const bool appleAuthEnabled =
      bool.fromEnvironment('ENABLE_APPLE_AUTH');
}

/// The only place in the app that touches [Supabase.instance].
final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => Supabase.instance.client,
);

/// Emits on sign-in/sign-out/token refresh.
final authStateProvider = StreamProvider<AuthState>(
  (ref) => ref.watch(supabaseClientProvider).auth.onAuthStateChange,
);

final currentUserProvider = Provider<User?>((ref) {
  ref.watch(authStateProvider);
  return ref.watch(supabaseClientProvider).auth.currentUser;
});

final isSignedInProvider = Provider<bool>(
  (ref) => ref.watch(currentUserProvider) != null,
);

/// The signed-in user's profile row (role, name, phone). Null when anonymous.
final profileProvider = FutureProvider<Profile?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  final client = ref.watch(supabaseClientProvider);
  final row = await client
      .from('profiles')
      .select('id, role, full_name, phone_e164, created_at')
      .eq('id', user.id)
      .maybeSingle();
  return row == null ? null : Profile.fromJson(row);
});

final userRoleProvider = Provider<UserRole?>(
  (ref) => ref.watch(profileProvider).valueOrNull?.role,
);

/// Public URL for a photo inside the device-photos bucket.
final photoUrlProvider = Provider<String Function(String path)>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return (path) => client.storage.from('device-photos').getPublicUrl(path);
});
