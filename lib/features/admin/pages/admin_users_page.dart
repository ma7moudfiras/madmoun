import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain.dart';
import '../../../core/models.dart';
import '../../../core/widgets/common.dart';
import '../../../i18n/strings.g.dart';
import '../data/admin_repository.dart';

class AdminUsersPage extends ConsumerStatefulWidget {
  const AdminUsersPage({super.key});

  @override
  ConsumerState<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends ConsumerState<AdminUsersPage> {
  String _search = '';
  Timer? _debounce;
  final _controller = TextEditingController();

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400),
        () => setState(() => _search = value.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(adminUserStatsProvider);
    final users = ref.watch(adminUsersProvider(_search));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.admin.users.title,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          stats.when(
            data: (s) => _StatsRow(stats: s),
            loading: () => const Shimmer(
                child: SkeletonBox(height: 80, radius: 16)),
            error: (_, _) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _controller,
            onChanged: _onSearch,
            decoration: InputDecoration(
              hintText: t.admin.users.searchHint,
              prefixIcon: const Icon(Icons.search_rounded),
              isDense: true,
            ),
          ),
          const SizedBox(height: 16),
          AsyncView(
            value: users,
            onRetry: () => ref.invalidate(adminUsersProvider(_search)),
            skeleton: const Padding(
              padding: EdgeInsets.only(top: 24),
              child: Shimmer(child: SkeletonBox(height: 200, radius: 16)),
            ),
            data: (list) {
              if (list.isEmpty) {
                return EmptyState(
                  icon: Icons.group_off_rounded,
                  title: t.admin.users.emptyTitle,
                  body: t.admin.users.emptyBody,
                );
              }
              return Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (final (i, u) in list.indexed) ...[
                      if (i > 0) const Divider(height: 1),
                      _UserRow(user: u, search: _search),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.stats});

  final UserStats stats;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      (t.admin.users.total, '${stats.total}', Icons.group_rounded),
      (t.admin.users.buyers, '${stats.buyers}', Icons.person_rounded),
      (t.admin.users.sellers, '${stats.sellers}', Icons.storefront_rounded),
      (t.admin.users.admins, '${stats.admins}',
          Icons.admin_panel_settings_rounded),
      (t.admin.users.newLast7d, '${stats.newLast7d}',
          Icons.fiber_new_rounded),
    ];
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [for (final tile in tiles) _StatTile(tile: tile)],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.tile});

  final (String, String, IconData) tile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(tile.$3, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tile.$2,
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800)),
                Text(tile.$1,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UserRow extends ConsumerWidget {
  const _UserRow({required this.user, required this.search});

  final AdminUser user;
  final String search;

  String _roleLabel(UserRole role) => switch (role) {
        UserRole.buyer => t.admin.users.roleBuyer,
        UserRole.seller => t.admin.users.roleSeller,
        UserRole.admin => t.admin.users.roleAdmin,
      };

  Future<void> _changeRole(
      BuildContext context, WidgetRef ref, UserRole role) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.admin.users.changeRole),
        content: Text(t.admin.users.roleChangeConfirm(
            name: user.fullName ?? user.email ?? '—',
            role: _roleLabel(role))),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(t.common.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(t.common.confirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(adminRepositoryProvider).setUserRole(user.id, role);
      ref.invalidate(adminUsersProvider(search));
      ref.invalidate(adminUserStatsProvider);
      if (context.mounted) showAppSnackBar(context, t.admin.users.roleChanged);
    } catch (e) {
      if (context.mounted) showErrorSnackBar(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final joined =
        '${user.createdAt.year}-${user.createdAt.month.toString().padLeft(2, '0')}-${user.createdAt.day.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Text(
              (user.fullName ?? user.email ?? '?')
                  .characters
                  .first
                  .toUpperCase(),
              style: TextStyle(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.fullName ?? '—',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(user.email ?? '—',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text('${t.admin.users.joinedLabel}: $joined',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          DropdownButton<UserRole>(
            value: user.role,
            underline: const SizedBox.shrink(),
            borderRadius: BorderRadius.circular(12),
            items: [
              for (final r in UserRole.values)
                DropdownMenuItem(value: r, child: Text(_roleLabel(r))),
            ],
            onChanged: (r) {
              if (r != null && r != user.role) _changeRole(context, ref, r);
            },
          ),
        ],
      ),
    );
  }
}
