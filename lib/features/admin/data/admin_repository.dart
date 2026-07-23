import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/domain.dart';
import '../../../core/models.dart';
import '../../../core/supabase_providers.dart';

class AdminRepository {
  AdminRepository(this._client);

  final SupabaseClient _client;

  Future<AdminDashboardStats> fetchDashboard() async {
    final result = await _client.rpc('admin_dashboard_stats');
    return AdminDashboardStats.fromJson(Map<String, dynamic>.from(result as Map));
  }

  Future<List<Shop>> fetchShops({ShopStatus? status}) async {
    final rows = await _client.rpc('admin_shops', params: {
      'p_status': status?.dbValue,
    }) as List<dynamic>;
    return rows
        .map((r) => Shop.fromJson(Map<String, dynamic>.from(r as Map)))
        .toList();
  }

  Future<void> setShopStatus(int shopId, ShopStatus status,
      {String? reason}) async {
    await _client.rpc('admin_set_shop_status', params: {
      'p_shop_id': shopId,
      'p_status': status.dbValue,
      'p_reason': reason,
    });
  }

  Future<List<SellerDevice>> fetchDevicesInReview() async {
    final rows = await _client
        .from('devices')
        .select(
            'id, public_id, shop_id, category, brand, model, title, description, '
            'price_minor, currency, grade, warranty_days, imei_last4, checklist, '
            'status, rejection_reason, created_at, '
            'device_photos(id, device_id, storage_path, sort_order, is_deleted)')
        .eq('status', 'under_inspection')
        .order('id', ascending: false)
        .limit(50);
    return (rows as List<dynamic>)
        .map((r) => SellerDevice.fromJson(Map<String, dynamic>.from(r as Map)))
        .toList();
  }

  Future<void> reviewDevice(int deviceId,
      {required bool approve, String? reason}) async {
    await _client.rpc('admin_review_device', params: {
      'p_device_id': deviceId,
      'p_approve': approve,
      'p_reason': reason,
    });
  }

  Future<List<ChecklistTemplate>> fetchTemplates() async {
    final rows = await _client
        .from('checklist_templates')
        .select('id, category, key, label_ar, sort_order, is_active')
        .order('category', ascending: true)
        .order('sort_order', ascending: true);
    return (rows as List<dynamic>)
        .map((r) =>
            ChecklistTemplate.fromJson(Map<String, dynamic>.from(r as Map)))
        .toList();
  }

  Future<void> upsertTemplate({
    int? id,
    required DeviceCategory category,
    required String key,
    required String labelAr,
    required int sortOrder,
    required bool isActive,
  }) async {
    if (id == null) {
      await _client.from('checklist_templates').insert({
        'category': category.dbValue,
        'key': key,
        'label_ar': labelAr,
        'sort_order': sortOrder,
        'is_active': isActive,
      });
    } else {
      await _client.from('checklist_templates').update({
        'label_ar': labelAr,
        'sort_order': sortOrder,
        'is_active': isActive,
      }).eq('id', id);
    }
  }

  Future<List<WarrantyClaim>> fetchClaims() async {
    final rows = await _client
        .from('warranty_claims')
        .select('*, devices(title, public_id)')
        .order('id', ascending: false)
        .limit(100);
    return (rows as List<dynamic>)
        .map((r) => WarrantyClaim.fromJson(Map<String, dynamic>.from(r as Map)))
        .toList();
  }

  Future<void> updateClaim(int claimId, ClaimStatus status,
      {String? note}) async {
    await _client.rpc('admin_update_claim', params: {
      'p_claim_id': claimId,
      'p_status': status.dbValue,
      'p_resolution_note': note,
    });
  }

  Future<List<Reservation>> fetchAllReservations({int? cursor}) async {
    var query = _client
        .from('reservations')
        .select('*, devices(title, public_id)');
    if (cursor != null) query = query.lt('id', cursor);
    final rows = await query.order('id', ascending: false).limit(30);
    return (rows as List<dynamic>)
        .map((r) => Reservation.fromJson(Map<String, dynamic>.from(r as Map)))
        .toList();
  }

  /// Platform-side reservation transitions (dispatch to courier, or confirm
  /// receipt on the buyer's behalf). The reservation trigger authorizes admins
  /// for every managed-flow transition.
  Future<void> setReservationStatus(int id, ReservationStatus status) async {
    final rows = await _client
        .from('reservations')
        .update({'status': status.dbValue})
        .eq('id', id)
        .select('id');
    if (rows.isEmpty) throw Exception('UPDATE_FORBIDDEN');
  }

  Future<UserStats> fetchUserStats() async {
    final result = await _client.rpc('admin_user_stats');
    return UserStats.fromJson(Map<String, dynamic>.from(result as Map));
  }

  Future<List<AdminUser>> fetchUsers({String? search}) async {
    final rows = await _client.rpc('admin_list_users', params: {
      'p_search': (search == null || search.isEmpty) ? null : search,
    }) as List<dynamic>;
    return rows
        .map((r) => AdminUser.fromJson(Map<String, dynamic>.from(r as Map)))
        .toList();
  }

  Future<void> setUserRole(String userId, UserRole role) async {
    await _client.rpc('admin_set_role', params: {
      'p_user_id': userId,
      'p_role': role.dbValue,
    });
  }
}

final adminRepositoryProvider = Provider<AdminRepository>(
  (ref) => AdminRepository(ref.watch(supabaseClientProvider)),
);

final adminDashboardProvider =
    FutureProvider<AdminDashboardStats>(
  (ref) => ref.watch(adminRepositoryProvider).fetchDashboard(),
);

final adminShopsProvider = FutureProvider
    .family<List<Shop>, ShopStatus?>((ref, status) {
  return ref.watch(adminRepositoryProvider).fetchShops(status: status);
});

final adminReviewQueueProvider =
    FutureProvider<List<SellerDevice>>(
  (ref) => ref.watch(adminRepositoryProvider).fetchDevicesInReview(),
);

final adminTemplatesProvider =
    FutureProvider<List<ChecklistTemplate>>(
  (ref) => ref.watch(adminRepositoryProvider).fetchTemplates(),
);

final adminClaimsProvider = FutureProvider<List<WarrantyClaim>>(
  (ref) => ref.watch(adminRepositoryProvider).fetchClaims(),
);

final adminReservationsProvider =
    FutureProvider<List<Reservation>>(
  (ref) => ref.watch(adminRepositoryProvider).fetchAllReservations(),
);

final adminUserStatsProvider = FutureProvider<UserStats>(
  (ref) => ref.watch(adminRepositoryProvider).fetchUserStats(),
);

final adminUsersProvider =
    FutureProvider.family<List<AdminUser>, String>((ref, search) {
  return ref.watch(adminRepositoryProvider).fetchUsers(search: search);
});
