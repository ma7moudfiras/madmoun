import 'package:supabase_flutter/supabase_flutter.dart';

/// Where to land after a successful sign-in: an explicit `from` deep link
/// wins; otherwise route by role — admins manage the site, sellers run
/// their shop, buyers browse the marketplace.
Future<String> postLoginDestination(SupabaseClient client, String? from) async {
  if (from != null && from.isNotEmpty) {
    return Uri.decodeComponent(from);
  }
  final uid = client.auth.currentUser?.id;
  if (uid == null) return '/';
  try {
    final row = await client
        .from('profiles')
        .select('role')
        .eq('id', uid)
        .maybeSingle();
    return switch (row?['role'] as String?) {
      'admin' => '/admin',
      'seller' => '/seller',
      _ => '/',
    };
  } catch (_) {
    return '/';
  }
}
