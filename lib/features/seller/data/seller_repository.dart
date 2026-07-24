import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/domain.dart';
import '../../../core/models.dart';
import '../../../core/supabase_providers.dart';

const _deviceColumns =
    'id, public_id, shop_id, category, brand, model, title, description, '
    'price_minor, currency, grade, warranty_days, imei_last4, checklist, '
    'status, rejection_reason, created_at, '
    'device_photos(id, device_id, storage_path, sort_order, is_deleted)';

class SellerRepository {
  SellerRepository(this._client);

  final SupabaseClient _client;

  static const int pageSize = 20;

  Future<Shop?> fetchMyShop() async {
    final rows = await _client.rpc('my_shop') as List<dynamic>;
    if (rows.isEmpty) return null;
    return Shop.fromJson(Map<String, dynamic>.from(rows.first as Map));
  }

  Future<void> createShop({
    required String name,
    required String city,
    required String phoneE164,
    String? address,
  }) async {
    await _client.from('shops').insert({
      'name': name,
      'city': city,
      'phone_e164': phoneE164,
      'address': address,
    });
  }

  Future<void> updateShop({
    required int id,
    required String name,
    required String city,
    required String phoneE164,
    String? address,
  }) async {
    await _client.from('shops').update({
      'name': name,
      'city': city,
      'phone_e164': phoneE164,
      'address': address,
    }).eq('id', id);
  }

  Future<List<SellerDevice>> fetchMyDevices(int shopId, {int? cursor}) async {
    var query =
        _client.from('devices').select(_deviceColumns).eq('shop_id', shopId);
    if (cursor != null) query = query.lt('id', cursor);
    final rows = await query.order('id', ascending: false).limit(pageSize);
    return (rows as List<dynamic>)
        .map((r) => SellerDevice.fromJson(Map<String, dynamic>.from(r as Map)))
        .toList();
  }

  Future<SellerDevice?> fetchDevice(int id) async {
    final row = await _client
        .from('devices')
        .select(_deviceColumns)
        .eq('id', id)
        .maybeSingle();
    return row == null
        ? null
        : SellerDevice.fromJson(Map<String, dynamic>.from(row));
  }

  Future<int> createDeviceDraft({
    required int shopId,
    required DeviceCategory category,
    required String brand,
    required String model,
    required String title,
    String? description,
    required int priceMinor,
    required Currency currency,
    Grade? grade,
    required int warrantyDays,
    String? imei,
    required List<ChecklistEntry> checklist,
  }) async {
    final row = await _client
        .from('devices')
        .insert({
          'shop_id': shopId,
          'category': category.dbValue,
          'brand': brand,
          'model': model,
          'title': title,
          'description': description,
          'price_minor': priceMinor,
          'currency': currency.dbValue,
          'grade': grade?.dbValue,
          'warranty_days': warrantyDays,
          'imei': imei,
          'checklist': checklist.map((e) => e.toJson()).toList(),
        })
        .select('id')
        .single();
    return (row['id'] as num).toInt();
  }

  Future<void> updateDeviceDraft({
    required int id,
    required DeviceCategory category,
    required String brand,
    required String model,
    required String title,
    String? description,
    required int priceMinor,
    required Currency currency,
    Grade? grade,
    required int warrantyDays,
    String? imei,
    required List<ChecklistEntry> checklist,
  }) async {
    final update = {
      'category': category.dbValue,
      'brand': brand,
      'model': model,
      'title': title,
      'description': description,
      'price_minor': priceMinor,
      'currency': currency.dbValue,
      'grade': grade?.dbValue,
      'warranty_days': warrantyDays,
      'checklist': checklist.map((e) => e.toJson()).toList(),
    };
    // Only overwrite IMEI when a new value is supplied (the last-4 is all we
    // ever read back, so a blank field must not wipe the stored number).
    if (imei != null && imei.isNotEmpty) update['imei'] = imei;
    await _client.from('devices').update(update).eq('id', id);
  }

  Future<void> setDeviceStatus(int id, DeviceStatus status) async {
    final rows = await _client
        .from('devices')
        .update({'status': status.dbValue})
        .eq('id', id)
        .select('id');
    _ensureUpdated(rows);
  }

  Future<void> deleteDraft(int id) async {
    await _client.from('devices').delete().eq('id', id);
  }

  // ----- reservations on the seller's devices -----

  /// Scoped to the caller's own shop: RLS also lets buyers/admins read
  /// reservations, so without the filter this portal view would show rows
  /// the seller has no authority over.
  Future<List<Reservation>> fetchIncomingReservations(int shopId,
      {int? cursor}) async {
    // Opaque model: the shop must not learn the buyer's identity, so the
    // buyer phone and free-text delivery note are deliberately not selected.
    var query = _client
        .from('reservations')
        .select(
            'id, public_id, device_id, buyer_id, delivery_city, price_minor, '
            'currency, commission_percent, commission_minor, status, created_at, '
            'updated_at, devices!inner(title, public_id, shop_id, '
            'device_photos(storage_path, is_deleted, sort_order))')
        .eq('devices.shop_id', shopId);
    if (cursor != null) query = query.lt('id', cursor);
    final rows = await query.order('id', ascending: false).limit(pageSize);
    return (rows as List<dynamic>)
        .map((r) => Reservation.fromJson(Map<String, dynamic>.from(r as Map)))
        .toList();
  }

  Future<void> setReservationStatus(int id, ReservationStatus status) async {
    final rows = await _client
        .from('reservations')
        .update({'status': status.dbValue})
        .eq('id', id)
        .select('id');
    _ensureUpdated(rows);
  }

  // ----- warranty claims on the seller's devices -----

  Future<List<WarrantyClaim>> fetchClaims(int shopId) async {
    final rows = await _client
        .from('warranty_claims')
        .select('*, devices!inner(title, public_id, shop_id)')
        .eq('devices.shop_id', shopId)
        .order('id', ascending: false)
        .limit(50);
    return (rows as List<dynamic>)
        .map((r) => WarrantyClaim.fromJson(Map<String, dynamic>.from(r as Map)))
        .toList();
  }

  Future<void> respondToClaim(int id, String response) async {
    final rows = await _client
        .from('warranty_claims')
        .update({'shop_response': response})
        .eq('id', id)
        .select('id');
    _ensureUpdated(rows);
  }

  /// PostgREST reports success even when RLS matched zero rows; surface
  /// that as a real error instead of a silent no-op.
  void _ensureUpdated(dynamic rows) {
    if (rows is List && rows.isEmpty) {
      throw Exception('UPDATE_FORBIDDEN');
    }
  }
}

final sellerRepositoryProvider = Provider<SellerRepository>(
  (ref) => SellerRepository(ref.watch(supabaseClientProvider)),
);

final myShopProvider = FutureProvider<Shop?>(
  (ref) {
    ref.watch(currentUserProvider);
    return ref.watch(sellerRepositoryProvider).fetchMyShop();
  },
);
