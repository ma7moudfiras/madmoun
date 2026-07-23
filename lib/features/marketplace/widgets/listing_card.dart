import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain.dart';
import '../../../core/models.dart';
import '../../../core/supabase_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../../../i18n/strings.g.dart';

/// Photo from the device-photos bucket. When there is no real photo (or it
/// fails to load) a branded, device-aware placeholder is shown instead of a
/// generic icon — it names the brand and draws the right device silhouette,
/// so demo listings look intentional rather than blank.
class DevicePhotoImage extends ConsumerWidget {
  const DevicePhotoImage({
    super.key,
    this.path,
    this.fit = BoxFit.cover,
    this.decodeWidth = 700,
    this.brand,
    this.category,
  });

  final String? path;
  final BoxFit fit;

  /// Decode the bitmap at roughly display width to cut decode time + memory
  /// (a big source of jank when many cards scroll). Null = full resolution.
  final int? decodeWidth;

  /// Context for the placeholder shown when there is no photo.
  final String? brand;
  final DeviceCategory? category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final placeholder = _DevicePlaceholder(brand: brand, category: category);
    if (path == null) return placeholder;
    // Seed data may store absolute image URLs; stored uploads are bucket paths.
    final url = path!.startsWith('http')
        ? path!
        : ref.watch(photoUrlProvider)(path!);
    // A persistent shimmer sits behind the image; the image cross-fades in
    // over it once decoded. frameBuilder is used instead of loadingBuilder
    // because on web (CanvasKit) download progress is not reported, which
    // otherwise leaves a white flash until the image pops in.
    return Stack(
      fit: StackFit.expand,
      children: [
        const Shimmer(child: SkeletonBox(height: double.infinity, radius: 0)),
        Image.network(
          url,
          fit: fit,
          gaplessPlayback: true,
          cacheWidth: decodeWidth,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded) return child;
            return AnimatedOpacity(
              opacity: frame == null ? 0 : 1,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              child: child,
            );
          },
          errorBuilder: (context, error, stack) => placeholder,
        ),
      ],
    );
  }
}

/// Branded stand-in for a missing device photo: device silhouette in an accent
/// circle over the on-brand gradient, with the brand wordmark beneath. Drawn
/// entirely in-app (no network, no stretch) so it always renders cleanly.
class _DevicePlaceholder extends StatelessWidget {
  const _DevicePlaceholder({this.brand, this.category});

  final String? brand;
  final DeviceCategory? category;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final icon = category == DeviceCategory.laptop
        ? Icons.laptop_mac_rounded
        : Icons.smartphone_rounded;
    final label = (brand != null && brand!.trim().isNotEmpty)
        ? brand!.trim()
        : t.common.appName;
    return LayoutBuilder(
      builder: (context, constraints) {
        // Scale with the card so thumbnails and full-width images both look
        // balanced; keep a sensible floor/ceiling.
        final side = constraints.biggest.shortestSide;
        final compact = side < 120;
        final circle = (side * 0.42).clamp(28.0, 96.0);
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [AppTheme.container, scheme.surface],
            ),
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: circle,
                height: circle,
                decoration: BoxDecoration(
                  color: scheme.secondaryContainer,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(icon,
                    size: circle * 0.5, color: AppTheme.primary),
              ),
              if (!compact) ...[
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryDark,
                          letterSpacing: 0.3,
                        ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class ListingCard extends StatelessWidget {
  const ListingCard({super.key, required this.listing, required this.onTap});

  final Listing listing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 16 / 10,
              child: DevicePhotoImage(
                path: listing.coverPhotoPath,
                brand: listing.brand,
                category: listing.category,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (listing.grade != null)
                          GradeBadge(listing.grade!),
                        const Spacer(),
                        Icon(Icons.location_on_rounded,
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 2),
                        Text(
                          listing.shopCity,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      listing.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Text(
                          listing.price.format(),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified_user_rounded,
                                  size: 13,
                                  color: theme
                                      .colorScheme.onSecondaryContainer),
                              const SizedBox(width: 4),
                              Text(
                                t.home.warrantyShort(
                                    days: '${listing.warrantyDays}'),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: theme
                                      .colorScheme.onSecondaryContainer,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ListingCardSkeleton extends StatelessWidget {
  const ListingCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Shimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AspectRatio(
              aspectRatio: 16 / 10,
              child: SkeletonBox(height: double.infinity, radius: 0),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SkeletonBox(width: 60, height: 20),
                  SizedBox(height: 10),
                  SkeletonBox(height: 16),
                  SizedBox(height: 6),
                  SkeletonBox(width: 140, height: 16),
                  SizedBox(height: 14),
                  SkeletonBox(width: 90, height: 22),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
