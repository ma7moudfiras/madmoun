import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/domain.dart';
import '../../core/models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../i18n/strings.g.dart';
import '../marketplace/widgets/listing_card.dart';
import 'data/buyer_repository.dart';

class OrdersPage extends ConsumerStatefulWidget {
  const OrdersPage({super.key});

  @override
  ConsumerState<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends ConsumerState<OrdersPage> {
  final List<Reservation> _items = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await ref
          .read(buyerRepositoryProvider)
          .fetchMyReservations();
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(items);
        _hasMore = items.length == BuyerRepository.pageSize;
        _loading = false;
      });
      ref.invalidate(myClaimsProvider);
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
      final items = await ref
          .read(buyerRepositoryProvider)
          .fetchMyReservations(cursor: _items.last.id);
      if (!mounted) return;
      setState(() {
        _items.addAll(items);
        _hasMore = items.length == BuyerRepository.pageSize;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
      showErrorSnackBar(context, e);
    }
  }

  Future<void> _confirmReceipt(Reservation reservation) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.orders.confirmReceiptAction),
        content: Text(t.orders.confirmReceiptBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(t.common.back),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(t.orders.confirmReceiptAction),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(buyerRepositoryProvider).confirmReceipt(reservation.id);
      if (!mounted) return;
      showAppSnackBar(context, t.orders.receiptConfirmed);
      _reload();
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    }
  }

  Future<void> _openClaim(Reservation reservation) async {
    final description = await showDialog<String>(
      context: context,
      builder: (context) => const _ClaimDialog(),
    );
    if (description == null || !mounted) return;
    try {
      await ref
          .read(buyerRepositoryProvider)
          .openClaim(
            deviceId: reservation.deviceId,
            reservationId: reservation.id,
            description: description,
          );
      if (!mounted) return;
      showAppSnackBar(context, t.orders.claimSubmitted);
      ref.invalidate(myClaimsProvider);
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loading) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: const [
          Shimmer(child: SkeletonBox(height: 120, radius: 16)),
          SizedBox(height: 12),
          Shimmer(child: SkeletonBox(height: 120, radius: 16)),
        ],
      );
    }
    if (_error != null) {
      return ErrorSurface(error: _error!, onRetry: _reload);
    }
    if (_items.isEmpty) {
      return EmptyState(
        icon: Icons.receipt_long_rounded,
        title: t.orders.emptyTitle,
        body: t.orders.emptyBody,
        action: FilledButton(
          onPressed: () => context.go('/'),
          child: Text(t.orders.browseCta),
        ),
      );
    }

    final claims = ref.watch(myClaimsProvider).valueOrNull ?? const [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.orders.title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              for (final reservation in _items) ...[
                _ReservationCard(
                  reservation: reservation,
                  onOpenClaim: () => _openClaim(reservation),
                  onConfirmReceipt:
                      reservation.status == ReservationStatus.outForDelivery
                      ? () => _confirmReceipt(reservation)
                      : null,
                ),
                const SizedBox(height: 12),
              ],
              if (_hasMore)
                Center(
                  child: OutlinedButton(
                    onPressed: _loadingMore ? null : _loadMore,
                    child: Text(t.common.showMore),
                  ),
                ),
              if (claims.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  t.orders.claimsTitle,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                for (final claim in claims) ...[
                  _ClaimCard(claim: claim),
                  const SizedBox(height: 12),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ReservationCard extends StatelessWidget {
  const _ReservationCard({
    required this.reservation,
    required this.onOpenClaim,
    this.onConfirmReceipt,
  });

  final Reservation reservation;
  final VoidCallback onOpenClaim;
  final VoidCallback? onConfirmReceipt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 72,
                    height: 72,
                    child: DevicePhotoImage(path: reservation.deviceCoverPath),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reservation.deviceTitle ??
                            reservation.devicePublicId ??
                            '—',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${t.orders.reservationLabel}: ${reservation.publicId}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        reservation.price.format(),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusChip.reservation(context, reservation.status),
              ],
            ),
            const SizedBox(height: 14),
            _OrderProgressTracker(status: reservation.status),
            if (onConfirmReceipt != null) ...[
              const SizedBox(height: 12),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: FilledButton.icon(
                  onPressed: onConfirmReceipt,
                  icon: const Icon(Icons.inventory_2_rounded, size: 18),
                  label: Text(t.orders.confirmReceiptAction),
                ),
              ),
            ],
            if (reservation.status == ReservationStatus.delivered) ...[
              const SizedBox(height: 12),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: OutlinedButton.icon(
                  onPressed: onOpenClaim,
                  icon: const Icon(Icons.build_circle_rounded, size: 18),
                  label: Text(t.orders.openClaim),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A compact dot-and-line progress bar complementing the text StatusChip —
/// lets a buyer see at a glance how far along their order is without reading.
/// Cancelled is a terminal side-state, not a step on this line.
class _OrderProgressTracker extends StatelessWidget {
  const _OrderProgressTracker({required this.status});

  final ReservationStatus status;

  static const _steps = [
    ReservationStatus.pending,
    ReservationStatus.confirmed,
    ReservationStatus.outForDelivery,
    ReservationStatus.delivered,
  ];

  static const _icons = {
    ReservationStatus.pending: Icons.hourglass_top_rounded,
    ReservationStatus.confirmed: Icons.storefront_rounded,
    ReservationStatus.outForDelivery: Icons.local_shipping_rounded,
    ReservationStatus.delivered: Icons.home_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.appColors;

    if (status == ReservationStatus.cancelled) {
      return Row(
        children: [
          Icon(Icons.cancel_rounded, size: 18, color: theme.colorScheme.error),
          const SizedBox(width: 8),
          Text(
            t.enums.reservationStatus[status.dbValue] ?? status.dbValue,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    final currentIndex = _steps.indexOf(status);
    return Row(
      children: [
        for (final (i, step) in _steps.indexed) ...[
          if (i > 0)
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                color: i <= currentIndex
                    ? colors.success
                    : theme.colorScheme.outlineVariant,
              ),
            ),
          Tooltip(
            message: t.enums.reservationStatus[step.dbValue] ?? step.dbValue,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i <= currentIndex
                    ? colors.success
                    : theme.colorScheme.surfaceContainerHighest,
              ),
              child: Icon(
                _icons[step],
                size: 15,
                color: i <= currentIndex
                    ? Colors.white
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ClaimCard extends StatelessWidget {
  const _ClaimCard({required this.claim});

  final WarrantyClaim claim;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    claim.deviceTitle ?? claim.devicePublicId ?? '—',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                StatusChip.claim(context, claim.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(claim.description, style: theme.textTheme.bodyMedium),
            if (claim.shopResponse != null) ...[
              const SizedBox(height: 8),
              Text(
                t.orders.shopResponse(note: claim.shopResponse!),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (claim.resolutionNote != null) ...[
              const SizedBox(height: 4),
              Text(
                t.orders.claimResolution(note: claim.resolutionNote!),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ClaimDialog extends StatefulWidget {
  const _ClaimDialog();

  @override
  State<_ClaimDialog> createState() => _ClaimDialogState();
}

class _ClaimDialogState extends State<_ClaimDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(t.orders.claimTitle),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 400,
          child: TextFormField(
            textDirection: TextDirection.rtl,
            controller: _controller,
            autofocus: true,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: t.orders.claimDescriptionLabel,
              hintText: t.orders.claimDescriptionHint,
            ),
            validator: (v) => (v == null || v.trim().length < 5)
                ? t.common.requiredField
                : null,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(t.common.cancel),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop(_controller.text.trim());
            }
          },
          child: Text(t.common.confirm),
        ),
      ],
    );
  }
}
