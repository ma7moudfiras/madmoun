import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/domain.dart';
import '../../../core/models.dart';
import '../../../core/supabase_providers.dart';
import '../../../core/text_normalize.dart';

// Madmoun is a managed, opaque intermediary: the buyer never sees the shop's
// identity, contact, or location — only the device and its inspection.
const listingColumns =
    'id, public_id, category, brand, model, title, description, price_minor, '
    'currency, grade, warranty_days, imei_last4, checklist, created_at, '
    'shop_id';

/// How the marketplace grid is ordered. [newest] is the default and matches
/// the old id-descending behaviour.
enum ListingSort { newest, priceLowHigh, priceHighLow }

class ListingFilters {
  const ListingFilters({
    this.query,
    this.category,
    this.brand,
    this.minMinor,
    this.maxMinor,
    this.grade,
    this.sort = ListingSort.newest,
  });

  final String? query;
  final DeviceCategory? category;
  final String? brand;
  final int? minMinor;
  final int? maxMinor;
  final Grade? grade;
  final ListingSort sort;

  /// Sort is not a "filter" — it never counts toward the active-filter badge
  /// or the clear-filters affordance.
  bool get isEmpty =>
      (query == null || query!.isEmpty) &&
      category == null &&
      brand == null &&
      minMinor == null &&
      maxMinor == null &&
      grade == null;

  ListingFilters copyWith({
    String? Function()? query,
    DeviceCategory? Function()? category,
    String? Function()? brand,
    int? Function()? minMinor,
    int? Function()? maxMinor,
    Grade? Function()? grade,
    ListingSort? sort,
  }) {
    return ListingFilters(
      query: query != null ? query() : this.query,
      category: category != null ? category() : this.category,
      brand: brand != null ? brand() : this.brand,
      minMinor: minMinor != null ? minMinor() : this.minMinor,
      maxMinor: maxMinor != null ? maxMinor() : this.maxMinor,
      grade: grade != null ? grade() : this.grade,
      sort: sort ?? this.sort,
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
    int offset = 0,
  }) async {
    var query = _client.from('public_listings').select(listingColumns);

    if (filters.category != null) {
      query = query.eq('category', filters.category!.dbValue);
    }
    if (filters.brand != null && filters.brand!.isNotEmpty) {
      query = query.eq('brand', filters.brand!);
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
      // search_text is pre-normalized (diacritics/tatweel stripped, alef and
      // ya/ta-marbuta variants unified) so a query for one spelling of a word
      // — إيفون vs آيفون vs ايفون — matches all of them. Normalize the typed
      // term the same way before comparing.
      final term = normalizeArabic(search).replaceAll('%', r'\%');
      // Titles/brands/models are stored in Latin script ("iPhone 13 Pro…"),
      // so an Arabic query for the same device ("ايفون") needs its own
      // brand/model words translated before it can match anything.
      final translated = translateArabicSearchTerm(term)?.replaceAll('%', r'\%');
      if (translated != null && translated != term) {
        query = query.or('search_text.ilike.%$term%,search_text.ilike.%$translated%');
      } else {
        query = query.ilike('search_text', '%$term%');
      }
    }
    // Offset pagination (the catalogue is small) so any sort order paginates
    // correctly; every sort has `id` as a stable tiebreaker.
    var ordered = switch (filters.sort) {
      ListingSort.newest => query.order('id', ascending: false),
      ListingSort.priceLowHigh =>
        query.order('price_minor', ascending: true).order('id', ascending: false),
      ListingSort.priceHighLow =>
        query.order('price_minor', ascending: false).order('id', ascending: false),
    };
    final rows = await ordered.range(offset, offset + pageSize - 1);
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

  /// Distinct brand values for the filter dropdown, derived from the
  /// currently listed devices.
  Future<List<String>> fetchFilterOptions() async {
    final rows =
        await _client.from('public_listings').select('brand').limit(200);
    final brands = <String>{};
    for (final row in rows as List<dynamic>) {
      brands.add(Map<String, dynamic>.from(row as Map)['brand'] as String);
    }
    return brands.toList()..sort();
  }
}

final marketplaceRepositoryProvider = Provider<MarketplaceRepository>(
  (ref) => MarketplaceRepository(ref.watch(supabaseClientProvider)),
);

/// In-memory snapshot of the last Home view. Restoring it on re-entry avoids
/// the refetch + skeleton flash + image reload that made returning to Home
/// flicker every time.
class HomeSnapshot {
  List<Listing> items = const [];
  bool hasMore = false;
  bool loaded = false;
  ListingFilters filters = const ListingFilters();
  String search = '';
  String minPrice = '';
  String maxPrice = '';
}

final homeSnapshotProvider = Provider<HomeSnapshot>((ref) => HomeSnapshot());

final impactStatsProvider = FutureProvider<ImpactStats>(
  (ref) => ref.watch(marketplaceRepositoryProvider).fetchImpactStats(),
);

final filterOptionsProvider = FutureProvider<List<String>>(
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
