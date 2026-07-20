import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models.dart';
import '../../../core/widgets/common.dart';
import '../../../i18n/strings.g.dart';
import '../data/seller_repository.dart';

final sellerClaimsProvider =
    FutureProvider.autoDispose<List<WarrantyClaim>>((ref) {
  ref.watch(myShopProvider);
  return ref.watch(sellerRepositoryProvider).fetchClaims();
});

class SellerClaimsPage extends ConsumerWidget {
  const SellerClaimsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final claims = ref.watch(sellerClaimsProvider);
    return AsyncView(
      value: claims,
      onRetry: () => ref.invalidate(sellerClaimsProvider),
      data: (list) {
        if (list.isEmpty) {
          return EmptyState(
            icon: Icons.build_circle_rounded,
            title: t.seller.claims.emptyTitle,
            body: t.seller.claims.emptyBody,
          );
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(sellerClaimsProvider),
          child: ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _ClaimCard(claim: list[i]),
          ),
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
  late final TextEditingController _response =
      TextEditingController(text: widget.claim.shopResponse ?? '');
  bool _busy = false;

  @override
  void dispose() {
    _response.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_response.text.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(sellerRepositoryProvider)
          .respondToClaim(widget.claim.id, _response.text.trim());
      ref.invalidate(sellerClaimsProvider);
      if (mounted) showAppSnackBar(context, t.seller.claims.responded);
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
            if (claim.resolutionNote != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  t.orders.claimResolution(note: claim.resolutionNote!),
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _response,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: t.seller.claims.respondLabel,
                hintText: t.seller.claims.respondHint,
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: FilledButton.icon(
                onPressed: _busy ? null : _submit,
                icon: _busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.reply_rounded, size: 18),
                label: Text(t.seller.claims.respondSubmit),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
