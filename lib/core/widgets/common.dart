import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../i18n/strings.g.dart';
import '../domain.dart';
import '../errors.dart';
import '../theme/app_theme.dart';

/// Simple two-color shimmer used by all loading skeletons.
class Shimmer extends StatefulWidget {
  const Shimmer({super.key, required this.child});

  final Widget child;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: AlignmentDirectional.centerStart,
              end: AlignmentDirectional.centerEnd,
              colors: [
                colors.shimmerBase,
                colors.shimmerHighlight,
                colors.shimmerBase,
              ],
              stops: const [0.25, 0.5, 0.75],
              transform:
                  _SlideGradientTransform(percent: _controller.value),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _SlideGradientTransform extends GradientTransform {
  const _SlideGradientTransform({required this.percent});

  final double percent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * (percent * 2 - 1), 0, 0);
}

class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height = 16,
    this.radius = 8,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.appColors.shimmerBase,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Polished empty state with icon, title, body and optional action.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.action,
  });

  final IconData icon;
  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon,
                    size: 40, color: theme.colorScheme.onPrimaryContainer),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                body,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              if (action != null) ...[
                const SizedBox(height: 20),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Error surface with Arabic message + retry.
class ErrorSurface extends StatelessWidget {
  const ErrorSurface({super.key, required this.error, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 12),
            Text(
              arabicErrorMessage(error),
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(t.common.retry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Standard mapping from an [AsyncValue] to skeleton/error/data.
class AsyncView<T> extends StatelessWidget {
  const AsyncView({
    super.key,
    required this.value,
    required this.data,
    this.skeleton,
    this.onRetry,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final Widget? skeleton;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: data,
      error: (e, _) => ErrorSurface(error: e, onRetry: onRetry),
      loading: () =>
          skeleton ?? const Center(child: CircularProgressIndicator()),
    );
  }
}

/// Colored chip for any status enum.
class StatusChip extends StatelessWidget {
  const StatusChip._(this.label, this.background, this.foreground,
      {super.key});

  final String label;
  final Color background;
  final Color foreground;

  factory StatusChip.device(BuildContext context, DeviceStatus status,
      {Key? key}) {
    final colors = context.appColors;
    final theme = Theme.of(context).colorScheme;
    final label = t.enums.deviceStatus[status.dbValue] ?? status.dbValue;
    return switch (status) {
      DeviceStatus.listed =>
        StatusChip._(label, colors.successTint, colors.success, key: key),
      DeviceStatus.reserved || DeviceStatus.underInspection =>
        StatusChip._(label, colors.warningTint, theme.onSurface, key: key),
      DeviceStatus.rejected =>
        StatusChip._(label, colors.dangerTint, theme.error, key: key),
      DeviceStatus.sold ||
      DeviceStatus.warrantyActive ||
      DeviceStatus.warrantyClosed =>
        StatusChip._(label, theme.primaryContainer, theme.onPrimaryContainer,
            key: key),
      _ => StatusChip._(
          label, theme.surfaceContainerHighest, theme.onSurfaceVariant,
          key: key),
    };
  }

  factory StatusChip.reservation(
      BuildContext context, ReservationStatus status,
      {Key? key}) {
    final colors = context.appColors;
    final theme = Theme.of(context).colorScheme;
    final label = t.enums.reservationStatus[status.dbValue] ?? status.dbValue;
    return switch (status) {
      ReservationStatus.pending =>
        StatusChip._(label, colors.warningTint, theme.onSurface, key: key),
      ReservationStatus.confirmed =>
        StatusChip._(label, theme.primaryContainer, theme.onPrimaryContainer,
            key: key),
      ReservationStatus.delivered =>
        StatusChip._(label, colors.successTint, colors.success, key: key),
      ReservationStatus.cancelled => StatusChip._(
          label, theme.surfaceContainerHighest, theme.onSurfaceVariant,
          key: key),
    };
  }

  factory StatusChip.shop(BuildContext context, ShopStatus status,
      {Key? key}) {
    final colors = context.appColors;
    final theme = Theme.of(context).colorScheme;
    final label = t.enums.shopStatus[status.dbValue] ?? status.dbValue;
    return switch (status) {
      ShopStatus.approved =>
        StatusChip._(label, colors.successTint, colors.success, key: key),
      ShopStatus.pending =>
        StatusChip._(label, colors.warningTint, theme.onSurface, key: key),
      ShopStatus.rejected =>
        StatusChip._(label, colors.dangerTint, theme.error, key: key),
    };
  }

  factory StatusChip.claim(BuildContext context, ClaimStatus status,
      {Key? key}) {
    final colors = context.appColors;
    final theme = Theme.of(context).colorScheme;
    final label = t.enums.claimStatus[status.dbValue] ?? status.dbValue;
    return switch (status) {
      ClaimStatus.open =>
        StatusChip._(label, colors.warningTint, theme.onSurface, key: key),
      ClaimStatus.inReview =>
        StatusChip._(label, theme.primaryContainer, theme.onPrimaryContainer,
            key: key),
      ClaimStatus.resolved =>
        StatusChip._(label, colors.successTint, colors.success, key: key),
      ClaimStatus.rejected =>
        StatusChip._(label, colors.dangerTint, theme.error, key: key),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
      ),
    );
  }
}

/// Condition grade badge (ممتاز / جيد جدًا / …).
class GradeBadge extends StatelessWidget {
  const GradeBadge(this.grade, {super.key});

  final Grade grade;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;
    final (background, foreground) = switch (grade) {
      Grade.excellent => (colors.successTint, colors.success),
      Grade.veryGood => (scheme.primaryContainer, scheme.onPrimaryContainer),
      Grade.good => (colors.warningTint, scheme.onSurface),
      Grade.fair =>
        (scheme.surfaceContainerHighest, scheme.onSurfaceVariant),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        t.enums.grade[grade.dbValue] ?? grade.dbValue,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }
}

/// Icon for a checklist result (pass / minor issue / fail).
class ChecklistResultIcon extends StatelessWidget {
  const ChecklistResultIcon(this.result, {super.key, this.size = 20});

  final ChecklistResult result;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;
    return switch (result) {
      ChecklistResult.pass => Icon(Icons.check_circle_rounded,
          color: colors.success, size: size),
      ChecklistResult.minorIssue =>
        Icon(Icons.error_rounded, color: colors.warning, size: size),
      ChecklistResult.fail =>
        Icon(Icons.cancel_rounded, color: scheme.error, size: size),
    };
  }
}

void showAppSnackBar(BuildContext context, String message,
    {bool isError = false}) {
  final scheme = Theme.of(context).colorScheme;
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? scheme.error : null,
      ),
    );
}

void showErrorSnackBar(BuildContext context, Object error) =>
    showAppSnackBar(context, arabicErrorMessage(error), isError: true);
