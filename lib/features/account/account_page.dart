import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/domain.dart';
import '../../core/models.dart';
import '../../core/supabase_providers.dart';
import '../../core/widgets/common.dart';
import '../../i18n/strings.g.dart';
import 'account_repository.dart';

class AccountPage extends ConsumerWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final user = ref.watch(currentUserProvider);
    return AsyncView(
      value: profile,
      onRetry: () => ref.invalidate(profileProvider),
      data: (data) => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  t.account.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                _ProfileCard(profile: data),
                const SizedBox(height: 16),
                _EmailCard(currentEmail: user?.email ?? '—'),
                const SizedBox(height: 16),
                const _PasswordCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Card scaffold with a title and body used by each account section.
class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child, this.subtitle});

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _ProfileCard extends ConsumerStatefulWidget {
  const _ProfileCard({required this.profile});

  final Profile? profile;

  @override
  ConsumerState<_ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends ConsumerState<_ProfileCard> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name = TextEditingController(
    text: widget.profile?.fullName ?? '',
  );
  late final TextEditingController _phone = TextEditingController(
    text: widget.profile?.phoneE164 ?? '',
  );
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final phone = _phone.text.trim().isEmpty
          ? null
          : normalizePhone(_phone.text);
      await ref
          .read(accountRepositoryProvider)
          .updateProfile(fullName: _name.text.trim(), phoneE164: phone);
      ref.invalidate(profileProvider);
      if (mounted) showAppSnackBar(context, t.account.profileSaved);
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = widget.profile?.role;
    return _SectionCard(
      title: t.account.profileSection,
      subtitle: t.account.profileHint,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (role != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Icon(
                      Icons.badge_rounded,
                      size: 18,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${t.account.roleLabel}: ${_roleLabel(role)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            TextFormField(
              textDirection: TextDirection.rtl,
              controller: _name,
              decoration: InputDecoration(labelText: t.common.fullNameLabel),
              validator: (v) => (v == null || v.trim().length < 2)
                  ? t.common.requiredField
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              textDirection: TextDirection.rtl,
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: '${t.common.phoneLabel} (${t.common.optional})',
                hintText: t.common.phoneHint,
              ),
              validator: (v) =>
                  (v != null &&
                      v.trim().isNotEmpty &&
                      normalizePhone(v) == null)
                  ? t.common.invalidPhone
                  : null,
            ),
            const SizedBox(height: 16),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: FilledButton(
                onPressed: _busy ? null : _save,
                child: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(t.account.saveProfile),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _roleLabel(UserRole role) => switch (role) {
    UserRole.admin => t.common.adminPanel,
    UserRole.seller => t.common.sellerPortal,
    UserRole.buyer => t.common.myOrders,
  };
}

class _EmailCard extends ConsumerStatefulWidget {
  const _EmailCard({required this.currentEmail});

  final String currentEmail;

  @override
  ConsumerState<_EmailCard> createState() => _EmailCardState();
}

class _EmailCardState extends ConsumerState<_EmailCard> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(accountRepositoryProvider)
          .changeEmail(_email.text.trim(), redirectTo: Uri.base.origin);
      if (mounted) {
        _email.clear();
        showAppSnackBar(context, t.account.emailChangeSent);
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: t.account.emailSection,
      subtitle: t.account.currentEmail(email: widget.currentEmail),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              textDirection: TextDirection.rtl,
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(labelText: t.account.newEmailLabel),
              validator: (v) =>
                  (v == null || !v.contains('@')) ? t.auth.invalidEmail : null,
            ),
            const SizedBox(height: 16),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: OutlinedButton(
                onPressed: _busy ? null : _submit,
                child: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(t.account.changeEmail),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PasswordCard extends ConsumerStatefulWidget {
  const _PasswordCard();

  @override
  ConsumerState<_PasswordCard> createState() => _PasswordCardState();
}

class _PasswordCardState extends ConsumerState<_PasswordCard> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  bool _obscure = true;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await ref.read(accountRepositoryProvider).changePassword(_password.text);
      if (mounted) {
        _password.clear();
        _confirm.clear();
        showAppSnackBar(context, t.account.passwordChanged);
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: t.account.passwordSection,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              textDirection: TextDirection.rtl,
              controller: _password,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: t.account.newPasswordLabel,
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                  ),
                ),
              ),
              validator: (v) =>
                  (v == null || v.length < 6) ? t.auth.weakPassword : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              textDirection: TextDirection.rtl,
              controller: _confirm,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: t.account.confirmPasswordLabel,
              ),
              validator: (v) =>
                  v != _password.text ? t.account.passwordMismatch : null,
            ),
            const SizedBox(height: 16),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: FilledButton(
                onPressed: _busy ? null : _submit,
                child: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(t.account.changePassword),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
