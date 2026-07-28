import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/domain.dart';
import '../../../core/supabase_providers.dart';
import '../../../i18n/strings.g.dart';
import '../data/favorites_repository.dart';

/// Heart toggle for bookmarking a device to compare/decide later. Browsing
/// never requires an account, but favoriting does — tapping while signed out
/// sends the buyer to login and back, same gate as reserving.
class FavoriteButton extends ConsumerWidget {
  const FavoriteButton({
    super.key,
    required this.deviceId,
    this.size = 22,
    this.compact = false,
  });

  final int deviceId;
  final double size;

  /// Shrinks the tap target below Material's default 48x48 minimum — needed
  /// when overlaying this on a small card thumbnail instead of a full toolbar.
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Admins manage the platform, not a wishlist — same rule the nav links
    // already follow (public_shell.dart), enforced here too since this
    // button is reachable from any listing regardless of the signed-in role.
    if (ref.watch(userRoleProvider) == UserRole.admin) {
      return const SizedBox.shrink();
    }
    final signedIn = ref.watch(isSignedInProvider);
    final favoriteIds = ref.watch(favoriteIdsProvider).valueOrNull ?? const {};
    final isFavorite = favoriteIds.contains(deviceId);

    return IconButton(
      tooltip: isFavorite ? t.device.unfavorite : t.device.favorite,
      icon: Icon(
        isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        color: isFavorite ? Colors.red : null,
        size: size,
      ),
      padding: compact ? const EdgeInsets.all(6) : const EdgeInsets.all(8),
      constraints: compact
          ? BoxConstraints(minWidth: size + 12, minHeight: size + 12)
          : null,
      visualDensity: compact ? VisualDensity.compact : null,
      onPressed: () => _toggle(context, ref, signedIn, isFavorite),
    );
  }

  Future<void> _toggle(
    BuildContext context,
    WidgetRef ref,
    bool signedIn,
    bool isFavorite,
  ) async {
    if (!signedIn) {
      final from = Uri.encodeComponent(GoRouterState.of(context).uri.toString());
      context.go('/login?from=$from');
      return;
    }
    final repo = ref.read(favoritesRepositoryProvider);
    try {
      if (isFavorite) {
        await repo.removeFavorite(deviceId);
      } else {
        await repo.addFavorite(deviceId);
      }
      ref.invalidate(favoriteIdsProvider);
      ref.invalidate(favoriteListingsProvider);
    } catch (_) {
      // Best-effort: a transient failure just leaves the heart unchanged.
    }
  }
}
