import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/common.dart';
import '../../i18n/strings.g.dart';
import '../marketplace/widgets/listing_card.dart';
import 'data/favorites_repository.dart';

/// Bookmarked devices a buyer wants to compare/decide on later. Sold or
/// unlisted favorites just drop out — the repository joins live listings.
class FavoritesPage extends ConsumerWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoriteListingsProvider);
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final columns = width >= 1200
        ? 4
        : width >= 900
        ? 3
        : width >= 600
        ? 2
        : 1;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.favorites.title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              AsyncView(
                value: favorites,
                onRetry: () => ref.invalidate(favoriteListingsProvider),
                skeleton: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: columns * 2,
                  itemBuilder: (context, index) => const ListingCardSkeleton(),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return EmptyState(
                      icon: Icons.favorite_border_rounded,
                      title: t.favorites.emptyTitle,
                      body: t.favorites.emptyBody,
                      action: FilledButton(
                        onPressed: () => context.go('/'),
                        child: Text(t.favorites.browseCta),
                      ),
                    );
                  }
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final listing = items[index];
                      return ListingCard(
                        listing: listing,
                        onTap: () => context.go('/d/${listing.publicId}'),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
