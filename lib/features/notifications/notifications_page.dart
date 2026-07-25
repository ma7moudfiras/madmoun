import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/common.dart';
import '../../i18n/strings.g.dart';
import 'data/notifications_repository.dart';

/// Localizes a notification kind (a snake_case string from the DB trigger).
String notificationText(String kind, String? ref) {
  final r = ref ?? '';
  return switch (kind) {
    'new_order_shop' => t.notif.kinds.newOrderShop(ref: r),
    'order_confirmed_buyer' => t.notif.kinds.orderConfirmedBuyer(ref: r),
    'order_confirmed_admin' => t.notif.kinds.orderConfirmedAdmin(ref: r),
    'out_for_delivery_buyer' => t.notif.kinds.outForDeliveryBuyer(ref: r),
    'delivered_shop' => t.notif.kinds.deliveredShop(ref: r),
    'delivered_admin' => t.notif.kinds.deliveredAdmin(ref: r),
    'cancelled_buyer' => t.notif.kinds.cancelledBuyer(ref: r),
    'cancelled_shop' => t.notif.kinds.cancelledShop(ref: r),
    _ => r,
  };
}

/// Bell with an unread badge; refreshes itself on a light timer so the count
/// stays current without a realtime subscription.
class NotificationBell extends ConsumerStatefulWidget {
  const NotificationBell({super.key});

  @override
  ConsumerState<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends ConsumerState<NotificationBell> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) ref.invalidate(notificationsProvider);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = ref.watch(unreadCountProvider);
    final icon = IconButton(
      tooltip: t.notif.title,
      onPressed: () => context.go('/notifications'),
      icon: const Icon(Icons.notifications_rounded),
    );
    if (count == 0) return icon;
    return Badge(
      label: Text(count > 99 ? '99+' : '$count'),
      offset: const Offset(-6, 6),
      child: icon,
    );
  }
}

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    // Opening the feed marks everything read, then re-fetches so the badge clears.
    Future.microtask(() async {
      await ref.read(notificationsRepositoryProvider).markAllRead();
      ref.invalidate(notificationsProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notifications = ref.watch(notificationsProvider);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.notif.title,
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              AsyncView(
                value: notifications,
                onRetry: () => ref.invalidate(notificationsProvider),
                skeleton:
                    const Shimmer(child: SkeletonBox(height: 200, radius: 16)),
                data: (list) {
                  if (list.isEmpty) {
                    return EmptyState(
                      icon: Icons.notifications_off_rounded,
                      title: t.notif.emptyTitle,
                      body: t.notif.emptyBody,
                    );
                  }
                  return Card(
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        for (final (i, n) in list.indexed) ...[
                          if (i > 0) const Divider(height: 1),
                          _NotificationRow(notification: n),
                        ],
                      ],
                    ),
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

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({required this.notification});

  final AppNotification notification;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final d = notification.createdAt;
    final date =
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    return Container(
      color: notification.isRead
          ? null
          : theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.circle,
              size: 9,
              color: notification.isRead
                  ? theme.colorScheme.outlineVariant
                  : theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notificationText(notification.kind, notification.ref),
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 4),
                Text(date,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
