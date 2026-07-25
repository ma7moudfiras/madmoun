import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/domain.dart';
import '../../core/models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../i18n/strings.g.dart';
import '../marketplace/data/marketplace_repository.dart';
import 'data/buyer_repository.dart';

class ReservePage extends ConsumerWidget {
  const ReservePage({super.key, required this.publicId});

  final String publicId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listing = ref.watch(listingByPublicIdProvider(publicId));
    return AsyncView(
      value: listing,
      onRetry: () => ref.invalidate(listingByPublicIdProvider(publicId)),
      data: (data) {
        if (data == null) {
          return EmptyState(
            icon: Icons.devices_other_rounded,
            title: t.device.notAvailableTitle,
            body: t.device.notAvailableBody,
            action: FilledButton(
              onPressed: () => context.go('/'),
              child: Text(t.common.backHome),
            ),
          );
        }
        return _ReserveForm(listing: data);
      },
    );
  }
}

class _ReserveForm extends ConsumerStatefulWidget {
  const _ReserveForm({required this.listing});

  final Listing listing;

  @override
  ConsumerState<_ReserveForm> createState() => _ReserveFormState();
}

class _ReserveFormState extends ConsumerState<_ReserveForm> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _city = TextEditingController();
  final _address = TextEditingController();
  final _note = TextEditingController();
  bool _busy = false;
  String? _reservationId;

  @override
  void dispose() {
    _phone.dispose();
    _city.dispose();
    _address.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final normalized = normalizePhone(_phone.text)!;
    setState(() => _busy = true);
    try {
      final id = await ref
          .read(buyerRepositoryProvider)
          .reserveDevice(
            deviceId: widget.listing.id,
            phoneE164: normalized,
            city: _city.text.trim(),
            address: _address.text.trim(),
            note: _note.text.trim().isEmpty ? null : _note.text.trim(),
          );
      if (!mounted) return;
      setState(() => _reservationId = id);
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_reservationId != null) {
      return _SuccessView(reservationId: _reservationId!);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      t.reserve.title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      t.reserve.deviceSummary(title: widget.listing.title),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.listing.price.format(),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Divider(height: 32),
                    TextFormField(
                      textDirection: TextDirection.rtl,
                      controller: _phone,
                      autofocus: true,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: t.common.phoneLabel,
                        hintText: t.common.phoneHint,
                        helperText: t.reserve.phoneHelp,
                      ),
                      validator: (v) => normalizePhone(v ?? '') == null
                          ? t.common.invalidPhone
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      textDirection: TextDirection.rtl,
                      controller: _city,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: t.common.cityLabel,
                        helperText: t.reserve.cityHelp,
                      ),
                      validator: (v) => (v == null || v.trim().length < 2)
                          ? t.common.requiredField
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      textDirection: TextDirection.rtl,
                      controller: _address,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: t.reserve.addressLabel,
                        helperText: t.reserve.addressHelp,
                      ),
                      validator: (v) => (v == null || v.trim().length < 3)
                          ? t.common.requiredField
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      textDirection: TextDirection.rtl,
                      controller: _note,
                      maxLines: 3,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        labelText:
                            '${t.common.noteLabel} (${t.common.optional})',
                        hintText: t.reserve.noteHint,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _busy ? null : _submit,
                      icon: _busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check_circle_rounded),
                      label: Text(t.reserve.submit),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView({required this.reservationId});

  final String reservationId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.appColors;
    final steps = [
      t.reserve.whatNext1,
      t.reserve.whatNext2,
      t.reserve.whatNext3,
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 64,
                    color: colors.success,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    t.reserve.successTitle,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t.reserve.successBody(id: reservationId),
                    style: theme.textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const Divider(height: 32),
                  Text(
                    t.reserve.whatNextTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final (i, step) in steps.indexed)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: theme.colorScheme.primaryContainer,
                            child: Text(
                              '${i + 1}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              step,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.go('/orders'),
                    child: Text(t.reserve.goToOrders),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () => context.go('/'),
                    child: Text(t.common.backHome),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
