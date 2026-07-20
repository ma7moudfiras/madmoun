import 'package:supabase_flutter/supabase_flutter.dart';

import '../i18n/strings.g.dart';

/// Maps backend errors (state-machine raises, RPC guards, auth failures)
/// to the Arabic strings defined in the errors section of the catalog.
String arabicErrorMessage(Object error) {
  final known = t.errors;

  String? lookup(String text) {
    for (final entry in known.entries) {
      if (text.contains(entry.key)) return entry.value;
    }
    return null;
  }

  if (error is PostgrestException) {
    final mapped = lookup(error.message);
    if (mapped != null) return mapped;
    // RLS insert violations surface as a policy error; the only insert a
    // seller can be blocked on this way is adding devices pre-approval.
    if (error.code == '42501' || error.message.contains('row-level security')) {
      return known['SHOP_NOT_APPROVED'] ?? t.common.genericError;
    }
    return t.common.genericError;
  }

  if (error is AuthException) {
    final message = error.message.toLowerCase();
    if (message.contains('invalid login credentials')) {
      return t.auth.invalidCredentials;
    }
    if (message.contains('already registered') ||
        message.contains('already been registered')) {
      return t.auth.emailInUse;
    }
    if (message.contains('password')) return t.auth.weakPassword;
    if (message.contains('email')) return t.auth.invalidEmail;
    return t.common.genericError;
  }

  final text = error.toString();
  final mapped = lookup(text);
  if (mapped != null) return mapped;
  if (text.contains('SocketException') ||
      text.contains('Failed to fetch') ||
      text.contains('ClientException')) {
    return t.common.networkError;
  }
  return t.common.genericError;
}
