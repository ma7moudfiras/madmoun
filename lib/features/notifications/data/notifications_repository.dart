import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase_providers.dart';

class AppNotification {
  const AppNotification({
    required this.id,
    required this.kind,
    required this.isRead,
    required this.createdAt,
    this.reservationId,
    this.ref,
  });

  final int id;
  final String kind;
  final bool isRead;
  final DateTime createdAt;
  final int? reservationId;
  final String? ref;

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: (json['id'] as num).toInt(),
        kind: json['kind'] as String,
        isRead: json['is_read'] as bool? ?? false,
        createdAt:
            DateTime.tryParse('${json['created_at']}')?.toLocal() ??
                DateTime.now(),
        reservationId: (json['reservation_id'] as num?)?.toInt(),
        ref: json['ref'] as String?,
      );
}

class NotificationsRepository {
  NotificationsRepository(this._client);

  final SupabaseClient _client;

  /// Recent notifications for the signed-in user (RLS scopes rows to them).
  Future<List<AppNotification>> fetchRecent() async {
    final rows = await _client
        .from('notifications')
        .select('id, kind, reservation_id, ref, is_read, created_at')
        .order('id', ascending: false)
        .limit(50);
    return (rows as List<dynamic>)
        .map((r) => AppNotification.fromJson(Map<String, dynamic>.from(r as Map)))
        .toList();
  }

  Future<void> markAllRead() async {
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('is_read', false);
  }
}

final notificationsRepositoryProvider = Provider<NotificationsRepository>(
  (ref) => NotificationsRepository(ref.watch(supabaseClientProvider)),
);

/// Recent notifications; auto-disposes and is refreshed by the bell's timer and
/// after the user opens the notifications page.
final notificationsProvider =
    FutureProvider.autoDispose<List<AppNotification>>((ref) async {
  if (!ref.watch(isSignedInProvider)) return const [];
  return ref.watch(notificationsRepositoryProvider).fetchRecent();
});

final unreadCountProvider = Provider.autoDispose<int>((ref) {
  final list = ref.watch(notificationsProvider).valueOrNull ?? const [];
  return list.where((n) => !n.isRead).length;
});
