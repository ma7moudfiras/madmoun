import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain.dart';
import '../../../core/models.dart';
import '../../../core/widgets/common.dart';
import '../../../i18n/strings.g.dart';
import '../data/admin_repository.dart';

class AdminClaimsPage extends ConsumerWidget {
  const AdminClaimsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final claims = ref.watch(adminClaimsProvider);
    return AsyncView(
      value: claims,
      onRetry: () => ref.invalidate(adminClaimsProvider),
      data: (list) {
        if (list.isEmpty) {
          return EmptyState(
            icon: Icons.gavel_rounded,
            title: t.admin.claims.emptyTitle,
            body: t.admin.claims.emptyBody,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(24),
          itemCount: list.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, i) => _ClaimCard(claim: list[i]),
        );
      },
    );
  }
}

class _ClaimCard extends ConsumerStatefulWidget {
  const _ClaimCard({required this.claim});

  final WarrantyClaim claim;

  @override
  ConsumerState<_ClaimCard> createState() => _ClaimCardState();
}

class _ClaimCardState extends ConsumerState<_ClaimCard> {
  late final TextEditingController _note =
      TextEditingController(text: widget.claim.resolutionNote ?? '');
  bool _busy = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _update(ClaimStatus status) async {
    setState(() => _busy = true);
    try {
      await ref.read(adminRepositoryProvider).updateClaim(
            widget.claim.id,
            status,
            note: _note.text.trim().isEmpty ? null : _note.text.trim(),
          );
      ref.invalidate(adminClaimsProvider);
      ref.invalidate(adminDashboardProvider);
      if (mounted) showAppSnackBar(context, t.admin.claims.updated);
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final claim = widget.claim;
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
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
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
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: t.admin.claims.resolutionLabel,
                hintText: t.admin.claims.resolutionHint,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (claim.status == ClaimStatus.open)
                  OutlinedButton.icon(
                    onPressed: _busy ? null : () => _update(ClaimStatus.inReview),
                    icon: const Icon(Icons.search_rounded, size: 18),
                    label: Text(t.admin.claims.setInReview),
                  ),
                FilledButton.icon(
                  onPressed: _busy ? null : () => _update(ClaimStatus.resolved),
                  icon: const Icon(Icons.check_circle_rounded, size: 18),
                  label: Text(t.admin.claims.resolve),
                ),
                TextButton.icon(
                  onPressed: _busy ? null : () => _update(ClaimStatus.rejected),
                  icon: const Icon(Icons.block_rounded, size: 18),
                  label: Text(t.admin.claims.reject),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
