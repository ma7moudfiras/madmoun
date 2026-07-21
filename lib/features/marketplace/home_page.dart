import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/domain.dart';
import '../../core/models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../i18n/strings.g.dart';
import 'data/marketplace_repository.dart';
import 'widgets/listing_card.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  ListingFilters _filters = const ListingFilters();
  final List<Listing> _items = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = false;
  bool _filtersExpanded = false;
  Object? _error;
  Timer? _searchDebounce;
  final _searchController = TextEditingController();
  final _minPrice = TextEditingController();
  final _maxPrice = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Restore the previous Home view instantly if we've been here before;
    // the images are still in Flutter's ImageCache so there's no reload flash.
    final snap = ref.read(homeSnapshotProvider);
    if (snap.loaded) {
      _items.addAll(snap.items);
      _filters = snap.filters;
      _hasMore = snap.hasMore;
      _searchController.text = snap.search;
      _minPrice.text = snap.minPrice;
      _maxPrice.text = snap.maxPrice;
      _loading = false;
    } else {
      _reload();
    }
  }

  void _saveSnapshot() {
    final snap = ref.read(homeSnapshotProvider);
    snap
      ..items = List.of(_items)
      ..hasMore = _hasMore
      ..loaded = true
      ..filters = _filters
      ..search = _searchController.text
      ..minPrice = _minPrice.text
      ..maxPrice = _maxPrice.text;
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _minPrice.dispose();
    _maxPrice.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await ref
          .read(marketplaceRepositoryProvider)
          .fetchListings(filters: _filters);
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(page.items);
        _hasMore = page.hasMore;
        _loading = false;
      });
      _saveSnapshot();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _items.isEmpty) return;
    setState(() => _loadingMore = true);
    try {
      final page = await ref
          .read(marketplaceRepositoryProvider)
          .fetchListings(filters: _filters, cursor: _items.last.id);
      if (!mounted) return;
      setState(() {
        _items.addAll(page.items);
        _hasMore = page.hasMore;
        _loadingMore = false;
      });
      _saveSnapshot();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
      showErrorSnackBar(context, e);
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 450), () {
      _filters = _filters.copyWith(query: () => value);
      _reload();
    });
  }

  void _applyPriceRange() {
    int? toMinor(String text) {
      final major = int.tryParse(text.trim());
      return major == null ? null : major * Money.minorPerMajor;
    }

    _filters = _filters.copyWith(
      minMinor: () => toMinor(_minPrice.text),
      maxMinor: () => toMinor(_maxPrice.text),
    );
    _reload();
  }

  void _clearFilters() {
    _searchController.clear();
    _minPrice.clear();
    _maxPrice.clear();
    setState(() => _filters = const ListingFilters());
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final columns = width >= 1200
        ? 4
        : width >= 900
            ? 3
            : width >= 600
                ? 2
                : 1;

    // Derive the card height from its real width so the image never squeezes
    // the content: card width = viewport - horizontal padding - inter-column
    // gaps, image is 16:10, and the text block needs a fixed budget.
    const horizontalPadding = 48.0;
    const columnGap = 16.0;
    final cardWidth =
        (width - horizontalPadding - columnGap * (columns - 1)) / columns;
    final cardExtent = cardWidth / (16 / 10) + 150;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _Hero(searchController: _searchController, onSearchChanged: _onSearchChanged)),
        SliverToBoxAdapter(child: _buildFilterBar(context)),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          sliver: _buildResults(columns, cardExtent),
        ),
        if (_hasMore && !_loading)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: Center(
                child: OutlinedButton.icon(
                  onPressed: _loadingMore ? null : _loadMore,
                  icon: _loadingMore
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.expand_more_rounded),
                  label: Text(t.common.showMore),
                ),
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  Widget _buildResults(int columns, double cardExtent) {
    if (_loading) {
      return SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          mainAxisExtent: cardExtent,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => const ListingCardSkeleton(),
          childCount: columns * 2,
        ),
      );
    }
    if (_error != null) {
      return SliverToBoxAdapter(
        child: ErrorSurface(error: _error!, onRetry: _reload),
      );
    }
    if (_items.isEmpty) {
      return SliverToBoxAdapter(
        child: EmptyState(
          icon: Icons.devices_other_rounded,
          title: t.home.emptyTitle,
          body: t.home.emptyBody,
          action: _filters.isEmpty
              ? null
              : OutlinedButton(
                  onPressed: _clearFilters,
                  child: Text(t.home.clearFilters),
                ),
        ),
      );
    }
    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        mainAxisExtent: cardExtent,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final listing = _items[index];
          return ListingCard(
            listing: listing,
            onTap: () => context.go('/d/${listing.publicId}'),
          );
        },
        childCount: _items.length,
      ),
    );
  }

  int get _activeFilterCount {
    var count = 0;
    if (_filters.category != null) count++;
    if (_filters.brand != null) count++;
    if (_filters.city != null) count++;
    if (_filters.currency != null) count++;
    if (_filters.grade != null) count++;
    if (_filters.minMinor != null || _filters.maxMinor != null) count++;
    return count;
  }

  /// Compact by default: a single toggle row; the dropdowns only unfold on
  /// demand so the grid stays above the fold.
  Widget _buildFilterBar(BuildContext context) {
    final active = _activeFilterCount;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TextButton.icon(
                onPressed: () =>
                    setState(() => _filtersExpanded = !_filtersExpanded),
                icon: Icon(
                  _filtersExpanded
                      ? Icons.expand_less_rounded
                      : Icons.tune_rounded,
                  size: 18,
                ),
                label: Text(
                  active > 0
                      ? '${t.home.filters} ($active)'
                      : t.home.filters,
                ),
              ),
              if (active > 0 || (_filters.query?.isNotEmpty ?? false))
                TextButton.icon(
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
                  label: Text(t.home.clearFilters),
                ),
            ],
          ),
          if (_filtersExpanded) ...[
            const SizedBox(height: 4),
            _buildFilterControls(context),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterControls(BuildContext context) {
    final options = ref.watch(filterOptionsProvider).valueOrNull;
    return Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _dropdown<DeviceCategory>(
            label: t.home.categoryFilter,
            value: _filters.category,
            items: DeviceCategory.values,
            display: (c) => t.enums.category[c.dbValue] ?? c.dbValue,
            onChanged: (v) {
              _filters = _filters.copyWith(category: () => v);
              _reload();
            },
          ),
          if (options != null && options.brands.isNotEmpty)
            _dropdown<String>(
              label: t.home.brandFilter,
              value: _filters.brand,
              items: options.brands,
              display: (b) => b,
              onChanged: (v) {
                _filters = _filters.copyWith(brand: () => v);
                _reload();
              },
            ),
          if (options != null && options.cities.isNotEmpty)
            _dropdown<String>(
              label: t.home.cityFilter,
              value: _filters.city,
              items: options.cities,
              display: (c) => c,
              onChanged: (v) {
                _filters = _filters.copyWith(city: () => v);
                _reload();
              },
            ),
          _dropdown<Currency>(
            label: t.home.currencyFilter,
            value: _filters.currency,
            items: Currency.values,
            display: (c) => t.enums.currency[c.dbValue] ?? c.dbValue,
            onChanged: (v) {
              _filters = _filters.copyWith(currency: () => v);
              _reload();
            },
          ),
          _dropdown<Grade>(
            label: t.home.gradeFilter,
            value: _filters.grade,
            items: Grade.values,
            display: (g) => t.enums.grade[g.dbValue] ?? g.dbValue,
            onChanged: (v) {
              _filters = _filters.copyWith(grade: () => v);
              _reload();
            },
          ),
          SizedBox(
            width: 110,
            child: TextField(
              controller: _minPrice,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: t.home.minPrice,
                isDense: true,
              ),
              onSubmitted: (_) => _applyPriceRange(),
            ),
          ),
          SizedBox(
            width: 110,
            child: TextField(
              controller: _maxPrice,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: t.home.maxPrice,
                isDense: true,
              ),
              onSubmitted: (_) => _applyPriceRange(),
            ),
          ),
          IconButton(
            tooltip: t.common.search,
            onPressed: _applyPriceRange,
            icon: const Icon(Icons.check_rounded),
          ),
        ]);
  }

  Widget _dropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required String Function(T) display,
    required ValueChanged<T?> onChanged,
  }) {
    return SizedBox(
      width: 160,
      child: DropdownButtonFormField<T?>(
        value: value,
        decoration: InputDecoration(labelText: label, isDense: true),
        items: [
          DropdownMenuItem<T?>(value: null, child: Text(t.common.all)),
          for (final item in items)
            DropdownMenuItem<T?>(value: item, child: Text(display(item))),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

class _Hero extends ConsumerWidget {
  const _Hero({required this.searchController, required this.onSearchChanged});

  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final impact = ref.watch(impactStatsProvider);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.surface,
          ],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              children: [
                Text(
                  t.home.heroTitle,
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryDark,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  t.home.heroSubtitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                impact.when(
                  data: (stats) => Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      _ImpactChip(
                        icon: Icons.recycling_rounded,
                        label: t.home
                            .impactDevices(count: '${stats.devicesSaved}'),
                      ),
                      _ImpactChip(
                        icon: Icons.eco_rounded,
                        label: t.home.impactCo2(kg: '${stats.estCo2Kg}'),
                      ),
                    ],
                  ),
                  loading: () => const Shimmer(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SkeletonBox(width: 180, height: 32, radius: 16),
                        SizedBox(width: 12),
                        SkeletonBox(width: 180, height: 32, radius: 16),
                      ],
                    ),
                  ),
                  error: (_, _) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: searchController,
                  onChanged: onSearchChanged,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: t.home.searchHint,
                    prefixIcon: const Icon(Icons.search_rounded),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ImpactChip extends StatelessWidget {
  const _ImpactChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: colors.successTint,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: colors.success),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: colors.success,
            ),
          ),
        ],
      ),
    );
  }
}
