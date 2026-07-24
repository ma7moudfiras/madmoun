import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models.dart';
import '../../../core/supabase_providers.dart';

class BuyerRepository {
  BuyerRepository(this._client);

  final SupabaseClient _client;

  static const int pageSize = 10;

  /// The only reservation path: atomic RPC that locks + snapshots + flips.
  Future<String> reserveDevice({
    required int deviceId,
    required String phoneE164,
    required String city,
    String? note,
    String? address,
  }) async {
    final result = await _client.rpc('reserve_device', params: {
      'p_device_id': deviceId,
      'p_phone': phoneE164,
      'p_city': city,
      'p_note': note,
      'p_address': address,
    });
    return (result as Map)['reservation_public_id'] as String;
  }

  Future<List<Reservation>> fetchMyReservations({int? cursor}) async {
    final uid = _client.auth.currentUser!.id;
    var query = _client
        .from('reservations')
        .select(
            '*, devices(title, public_id, device_photos(storage_path, is_deleted, sort_order))')
        .eq('buyer_id', uid);
    if (cursor != null) query = query.lt('id', cursor);
    final rows = await query.order('id', ascending: false).limit(pageSize);
    return (rows as List<dynamic>)
        .map((r) => Reservation.fromJson(Map<String, dynamic>.from(r as Map)))
        .toList();
  }

  Future<List<WarrantyClaim>> fetchMyClaims() async {
    final uid = _client.auth.currentUser!.id;
    final rows = await _client
        .from('warranty_claims')
        .select('*, devices(title, public_id)')
        .eq('opened_by', uid)
        .order('id', ascending: false)
        .limit(50);
    return (rows as List<dynamic>)
        .map((r) => WarrantyClaim.fromJson(Map<String, dynamic>.from(r as Map)))
        .toList();
  }

  /// Buyer confirms receipt: out_for_delivery -> delivered, which activates the
  /// warranty and records the completed sale. RLS + the reservation trigger
  /// guarantee only the owning buyer can do this and only from the right state.
  Future<void> confirmReceipt(int reservationId) async {
    final rows = await _client
        .from('reservations')
        .update({'status': 'delivered'})
        .eq('id', reservationId)
        .select('id');
    if (rows.isEmpty) {
      throw Exception('UPDATE_FORBIDDEN');
    }
  }

  Future<void> openClaim({
    required int deviceId,
    required int reservationId,
    required String description,
  }) async {
    await _client.from('warranty_claims').insert({
      'device_id': deviceId,
      'reservation_id': reservationId,
      'opened_by': _client.auth.currentUser!.id,
      'description': description,
    });
  }
}

final buyerRepositoryProvider = Provider<BuyerRepository>(
  (ref) => BuyerRepository(ref.watch(supabaseClientProvider)),
);

final myClaimsProvider = FutureProvider<List<WarrantyClaim>>(
  (ref) => ref.watch(buyerRepositoryProvider).fetchMyClaims(),
);
