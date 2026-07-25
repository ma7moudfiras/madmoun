import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase_providers.dart';

/// Account/self-service actions: profile fields, email + password changes,
/// and password reset. All go through Supabase Auth / the profiles table.
class AccountRepository {
  AccountRepository(this._client);

  final SupabaseClient _client;

  Future<void> updateProfile({
    required String fullName,
    String? phoneE164,
  }) async {
    final uid = _client.auth.currentUser!.id;
    await _client.from('profiles').update({
      'full_name': fullName,
      'phone_e164': phoneE164,
    }).eq('id', uid);
    // Mirror the name into auth metadata so it survives re-provisioning.
    await _client.auth.updateUser(UserAttributes(data: {'full_name': fullName}));
  }

  /// Changes the password immediately (the caller is already authenticated).
  Future<void> changePassword(String newPassword) async {
    await _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  /// Requests an email change; Supabase emails a confirmation link to the new
  /// address, and the change only applies once it is clicked.
  Future<void> changeEmail(String newEmail, {String? redirectTo}) async {
    await _client.auth.updateUser(
      UserAttributes(email: newEmail),
      emailRedirectTo: redirectTo,
    );
  }

  Future<void> sendPasswordReset(String email, {String? redirectTo}) async {
    await _client.auth.resetPasswordForEmail(email, redirectTo: redirectTo);
  }
}

final accountRepositoryProvider = Provider<AccountRepository>(
  (ref) => AccountRepository(ref.watch(supabaseClientProvider)),
);
