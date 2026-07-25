import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain.dart';
import '../../../core/models.dart';
import '../../../core/supabase_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../../../i18n/strings.g.dart';
import '../data/seller_repository.dart';

/// Shop onboarding + status. Handles: no shop yet (register form),
/// pending, rejected (with reason + edit), approved (edit details).
class SellerShopPage extends ConsumerWidget {
  const SellerShopPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shop = ref.watch(myShopProvider);
    return AsyncView(
      value: shop,
      onRetry: () => ref.invalidate(myShopProvider),
      data: (data) => _ShopBody(shop: data),
    );
  }
}

class _ShopBody extends ConsumerStatefulWidget {
  const _ShopBody({required this.shop});

  final Shop? shop;

  @override
  ConsumerState<_ShopBody> createState() => _ShopBodyState();
}

class _ShopBodyState extends ConsumerState<_ShopBody> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _city;
  late final TextEditingController _phone;
  late final TextEditingController _address;
  bool _busy = false;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.shop?.name ?? '');
    _city = TextEditingController(text: widget.shop?.city ?? '');
    _phone = TextEditingController(text: widget.shop?.phoneE164 ?? '');
    _address = TextEditingController(text: widget.shop?.address ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _city.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final phone = normalizePhone(_phone.text)!;
    setState(() => _busy = true);
    try {
      final repo = ref.read(sellerRepositoryProvider);
      final existing = widget.shop;
      final address = _address.text.trim().isEmpty
          ? null
          : _address.text.trim();
      if (existing == null) {
        await repo.createShop(
          name: _name.text.trim(),
          city: _city.text.trim(),
          phoneE164: phone,
          address: address,
        );
      } else {
        await repo.updateShop(
          id: existing.id,
          name: _name.text.trim(),
          city: _city.text.trim(),
          phoneE164: phone,
          address: address,
        );
      }
      ref.invalidate(myShopProvider);
      ref.invalidate(profileProvider);
      if (!mounted) return;
      setState(() => _editing = false);
      showAppSnackBar(context, t.seller.onboarding.updated);
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shop = widget.shop;
    final showForm = shop == null || _editing;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (shop != null) ...[
                _StatusBanner(shop: shop),
                const SizedBox(height: 16),
              ],
              if (showForm)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            t.seller.onboarding.title,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            t.seller.onboarding.intro,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            textDirection: TextDirection.rtl,
                            controller: _name,
                            decoration: InputDecoration(
                              labelText: t.seller.onboarding.shopNameLabel,
                            ),
                            validator: (v) => (v == null || v.trim().length < 2)
                                ? t.common.requiredField
                                : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            textDirection: TextDirection.rtl,
                            controller: _city,
                            decoration: InputDecoration(
                              labelText: t.common.cityLabel,
                            ),
                            validator: (v) => (v == null || v.trim().length < 2)
                                ? t.common.requiredField
                                : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            textDirection: TextDirection.rtl,
                            controller: _phone,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: t.common.phoneLabel,
                              hintText: t.common.phoneHint,
                            ),
                            validator: (v) => normalizePhone(v ?? '') == null
                                ? t.common.invalidPhone
                                : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            textDirection: TextDirection.rtl,
                            controller: _address,
                            decoration: InputDecoration(
                              labelText: t.seller.onboarding.addressLabel,
                              helperText: t.seller.onboarding.addressHelp,
                            ),
                          ),
                          const SizedBox(height: 24),
                          FilledButton(
                            onPressed: _busy ? null : _submit,
                            child: _busy
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    shop == null
                                        ? t.seller.onboarding.submit
                                        : t.common.save,
                                  ),
                          ),
                          if (_editing)
                            TextButton(
                              onPressed: () => setState(() => _editing = false),
                              child: Text(t.common.cancel),
                            ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() => _editing = true),
                    icon: const Icon(Icons.edit_rounded, size: 18),
                    label: Text(t.seller.onboarding.editShop),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.shop});

  final Shop shop;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (title, body, icon, color) = switch (shop.status) {
      ShopStatus.pending => (
        t.seller.onboarding.pendingTitle,
        t.seller.onboarding.pendingBody,
        Icons.hourglass_top_rounded,
        context.appColors.warning,
      ),
      ShopStatus.approved => (
        t.seller.onboarding.approvedTitle,
        shop.name,
        Icons.verified_rounded,
        context.appColors.success,
      ),
      ShopStatus.rejected => (
        t.seller.onboarding.rejectedTitle,
        t.seller.onboarding.rejectedReason(reason: shop.rejectionReason ?? '—'),
        Icons.cancel_rounded,
        theme.colorScheme.error,
      ),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      StatusChip.shop(context, shop.status),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(body, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
