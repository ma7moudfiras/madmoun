import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models.dart';
import '../../../core/supabase_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../../../i18n/strings.g.dart';

/// Photo from the device-photos bucket with placeholder + error fallback.
class DevicePhotoImage extends ConsumerWidget {
  const DevicePhotoImage({super.key, this.path, this.fit = BoxFit.cover});

  final String? path;
  final BoxFit fit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (path == null) return const _PhotoFallback();
    // Seed data may store absolute image URLs; stored uploads are bucket paths.
    final url = path!.startsWith('http')
        ? path!
        : ref.watch(photoUrlProvider)(path!);
    return Image.network(
      url,
      fit: fit,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const Shimmer(
            child: SkeletonBox(height: double.infinity, radius: 0));
      },
      errorBuilder: (context, error, stack) => const _PhotoFallback(),
    );
  }
}

class _PhotoFallback extends StatelessWidget {
  const _PhotoFallback();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: scheme.primaryContainer,
      alignment: Alignment.center,
      child: Icon(
        Icons.devices_rounded,
        size: 48,
        color: scheme.onPrimaryContainer,
      ),
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
              child: DevicePhotoImage(path: listing.coverPhotoPath),
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
