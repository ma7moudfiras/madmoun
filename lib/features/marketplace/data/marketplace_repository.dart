import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/domain.dart';
import '../../../core/models.dart';
import '../../../core/supabase_providers.dart';

const listingColumns =
    'id, public_id, category, brand, model, title, description, price_minor, '
    'currency, grade, warranty_days, imei_last4, checklist, created_at, '
    'shop_id, shop_name, shop_city';

class ListingFilters {
  const ListingFilters({
    this.query,
    this.category,
    this.brand,
    this.city,
    this.currency,
    this.minMinor,
    this.maxMinor,
    this.grade,
  });

  final String? query;
  final DeviceCategory? category;
  final String? brand;
  final String? city;
  final Currency? currency;
  final int? minMinor;
  final int? maxMinor;
  final Grade? grade;

  bool get isEmpty =>
      (query == null || query!.isEmpty) &&
      category == null &&
      brand == null &&
      city == null &&
      currency == null &&
      minMinor == null &&
      maxMinor == null &&
      grade == null;

  ListingFilters copyWith({
    String? Function()? query,
    DeviceCategory? Function()? category,
    String? Function()? brand,
    String? Function()? city,
    Currency? Function()? currency,
    int? Function()? minMinor,
    int? Function()? maxMinor,
    Grade? Function()? grade,
  }) {
    return ListingFilters(
      query: query != null ? query() : this.query,
      category: category != null ? category() : this.category,
      brand: brand != null ? brand() : this.brand,
      city: city != null ? city() : this.city,
      currency: currency != null ? currency() : this.currency,
      minMinor: minMinor != null ? minMinor() : this.minMinor,
      maxMinor: maxMinor != null ? maxMinor() : this.maxMinor,
      grade: grade != null ? grade() : this.grade,
    );
  }
}

/// One page of listings plus the cursor for the next page (last id).
class ListingsPage {
  const ListingsPage({required this.items, required this.hasMore});

  final List<Listing> items;
  final bool hasMore;

  int? get nextCursor => items.isEmpty ? null : items.last.id;
}

class MarketplaceRepository {
  MarketplaceRepository(this._client);

  final SupabaseClient _client;

  static const int pageSize = 12;

  Future<ListingsPage> fetchListings({
    ListingFilters filters = const ListingFilters(),
    int? cursor,
  }) async {
    var query = _client.from('public_listings').select(listingColumns);

    if (filters.category != null) {
      query = query.eq('category', filters.category!.dbValue);
    }
    if (filters.brand != null && filters.brand!.isNotEmpty) {
      query = query.eq('brand', filters.brand!);
    }
    if (filters.city != null && filters.city!.isNotEmpty) {
      query = query.eq('shop_city', filters.city!);
    }
    if (filters.currency != null) {
      query = query.eq('currency', filters.currency!.dbValue);
    }
    if (filters.minMinor != null) {
      query = query.gte('price_minor', filters.minMinor!);
    }
    if (filters.maxMinor != null) {
      query = query.lte('price_minor', filters.maxMinor!);
    }
    if (filters.grade != null) {
      query = query.eq('grade', filters.grade!.dbValue);
    }
    final search = filters.query?.trim();
    if (search != null && search.isNotEmpty) {
      final term = search.replaceAll('%', r'\%').replaceAll(',', ' ');
      query = query.or(
        'title.ilike.%$term%,brand.ilike.%$term%,model.ilike.%$term%',
      );
    }
    if (cursor != null) {
      query = query.lt('id', cursor);
    }

    final rows = await query.order('id', ascending: false).limit(pageSize);
    final listings = (rows as List<dynamic>)
        .map((r) => Listing.fromJson(Map<String, dynamic>.from(r as Map)))
        .toList();

    final withPhotos = await _attachPhotos(listings);
    return ListingsPage(
      items: withPhotos,
      hasMore: listings.length == pageSize,
    );
  }

  Future<Listing?> fetchByPublicId(String publicId) async {
    final row = await _client
        .from('public_listings')
        .select(listingColumns)
        .eq('public_id', publicId)
        .maybeSingle();
    if (row == null) return null;
    final listing = Listing.fromJson(Map<String, dynamic>.from(row));
    final withPhotos = await _attachPhotos([listing]);
    return withPhotos.first;
  }

  Future<List<Listing>> _attachPhotos(List<Listing> listings) async {
    if (listings.isEmpty) return listings;
    final ids = listings.map((l) => l.id).toList();
    final rows = await _client
        .from('device_photos')
        .select('device_id, storage_path, sort_order')
        .inFilter('device_id', ids)
        .eq('is_deleted', false)
        .order('sort_order', ascending: true);
    final byDevice = <int, List<String>>{};
    for (final row in rows as List<dynamic>) {
      final map = Map<String, dynamic>.from(row as Map);
      byDevice
          .putIfAbsent((map['device_id'] as num).toInt(), () => [])
          .add(map['storage_path'] as String);
    }
    return [
      for (final listing in listings)
        listing.withPhotos(byDevice[listing.id] ?? const []),
    ];
  }

  Future<ImpactStats> fetchImpactStats() async {
    final rows = await _client.rpc('impact_stats') as List<dynamic>;
    if (rows.isEmpty) return const ImpactStats(devicesSaved: 0, estCo2Kg: 0);
    return ImpactStats.fromJson(Map<String, dynamic>.from(rows.first as Map));
  }

  /// Distinct brand/city values for the filter dropdowns, derived from the
  /// currently listed devices.
  Future<({List<String> brands, List<String> cities})> fetchFilterOptions() async {
    final rows = await _client
        .from('public_listings')
        .select('brand, shop_city')
        .limit(200);
    final brands = <String>{};
    final cities = <String>{};
    for (final row in rows as List<dynamic>) {
      final map = Map<String, dynamic>.from(row as Map);
      brands.add(map['brand'] as String);
      cities.add(map['shop_city'] as String);
    }
    return (
      brands: brands.toList()..sort(),
      cities: cities.toList()..sort(),
    );
  }
}

final marketplaceRepositoryProvider = Provider<MarketplaceRepository>(
  (ref) => MarketplaceRepository(ref.watch(supabaseClientProvider)),
);

final impactStatsProvider = FutureProvider<ImpactStats>(
  (ref) => ref.watch(marketplaceRepositoryProvider).fetchImpactStats(),
);

final filterOptionsProvider =
    FutureProvider<({List<String> brands, List<String> cities})>(
  (ref) => ref.watch(marketplaceRepositoryProvider).fetchFilterOptions(),
);

final listingByPublicIdProvider =
    FutureProvider.family<Listing?, String>((ref, publicId) {
  return ref.watch(marketplaceRepositoryProvider).fetchByPublicId(publicId);
});

/// Checklist item definitions, keyed lookup for labels.
final checklistTemplatesProvider =
    FutureProvider<List<ChecklistTemplate>>((ref) async {
  final rows = await ref
      .watch(supabaseClientProvider)
      .from('checklist_templates')
      .select('id, category, key, label_ar, sort_order, is_active')
      .order('sort_order', ascending: true);
  return (rows as List<dynamic>)
      .map((r) => ChecklistTemplate.fromJson(Map<String, dynamic>.from(r as Map)))
      .toList();
});
