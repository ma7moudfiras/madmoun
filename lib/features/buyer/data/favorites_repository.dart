import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models.dart';
import '../../../core/supabase_providers.dart';
import '../../marketplace/data/marketplace_repository.dart';

/// Buyer wishlist: bookmark a device to compare/decide later without
/// committing. Purely personal — RLS scopes every row to its own user.
class FavoritesRepository {
  FavoritesRepository(this._client);

  final SupabaseClient _client;

  Future<Set<int>> fetchFavoriteDeviceIds() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return const {};
    final rows = await _client
        .from('favorites')
        .select('device_id')
        .eq('user_id', uid);
    return (rows as List<dynamic>)
        .map(
          (r) =>
              (Map<String, dynamic>.from(r as Map)['device_id'] as num)
                  .toInt(),
        )
        .toSet();
  }

  Future<void> addFavorite(int deviceId) async {
    await _client.from('favorites').insert({
      'user_id': _client.auth.currentUser!.id,
      'device_id': deviceId,
    });
  }

  Future<void> removeFavorite(int deviceId) async {
    await _client
        .from('favorites')
        .delete()
        .eq('user_id', _client.auth.currentUser!.id)
        .eq('device_id', deviceId);
  }

  /// Currently-listed favorited devices, newest-favorited first. A device
  /// that's no longer listed (sold/removed) naturally drops out since this
  /// joins against the same public_listings view the marketplace browses.
  Future<List<Listing>> fetchFavoriteListings() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return const [];
    final favRows = await _client
        .from('favorites')
        .select('device_id')
        .eq('user_id', uid)
        .order('id', ascending: false);
    final ids = (favRows as List<dynamic>)
        .map(
          (r) =>
              (Map<String, dynamic>.from(r as Map)['device_id'] as num)
                  .toInt(),
        )
        .toList();
    if (ids.isEmpty) return const [];

    final rows = await _client
        .from('public_listings')
        .select(listingColumns)
        .inFilter('id', ids);
    final listings = (rows as List<dynamic>)
        .map((r) => Listing.fromJson(Map<String, dynamic>.from(r as Map)))
        .toList();
    final byId = {for (final l in listings) l.id: l};
    final ordered = [for (final id in ids) if (byId[id] != null) byId[id]!];

    final photoRows = await _client
        .from('device_photos')
        .select('device_id, storage_path, sort_order')
        .inFilter('device_id', ids)
        .eq('is_deleted', false)
        .order('sort_order', ascending: true);
    final photosByDevice = <int, List<String>>{};
    for (final row in photoRows as List<dynamic>) {
      final map = Map<String, dynamic>.from(row as Map);
      photosByDevice
          .putIfAbsent((map['device_id'] as num).toInt(), () => [])
          .add(map['storage_path'] as String);
    }
    return [
      for (final listing in ordered)
        listing.withPhotos(photosByDevice[listing.id] ?? const []),
    ];
  }
}

final favoritesRepositoryProvider = Provider<FavoritesRepository>(
  (ref) => FavoritesRepository(ref.watch(supabaseClientProvider)),
);

final favoriteIdsProvider = FutureProvider<Set<int>>(
  (ref) => ref.watch(favoritesRepositoryProvider).fetchFavoriteDeviceIds(),
);

final favoriteListingsProvider = FutureProvider<List<Listing>>(
  (ref) => ref.watch(favoritesRepositoryProvider).fetchFavoriteListings(),
);
