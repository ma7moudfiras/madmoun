import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/supabase_providers.dart';
import '../../core/widgets/common.dart';
import '../../i18n/strings.g.dart';
import 'auth_form_card.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key, this.from});

  final String? from;

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _obscure = true;

  @override
  void dispose() {
    _fullName.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final response = await ref.read(supabaseClientProvider).auth.signUp(
        email: _email.text.trim(),
        password: _password.text,
        data: {'full_name': _fullName.text.trim()},
      );
      if (!mounted) return;
      if (response.session == null) {
        // Confirmation may be required upstream; the DB pre-confirms emails
        // for the MVP, so an immediate sign-in normally succeeds.
        try {
          await ref.read(supabaseClientProvider).auth.signInWithPassword(
                email: _email.text.trim(),
                password: _password.text,
              );
        } catch (_) {
          if (mounted) {
            showAppSnackBar(context, t.auth.confirmEmailSent);
            context.go('/login');
          }
        }
      }
      // Otherwise the router redirect takes over.
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final from = widget.from;
    final loginUri =
        from == null || from.isEmpty ? '/login' : '/login?from=$from';

    return AuthFormCard(
      title: t.auth.registerTitle,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _fullName,
              autofocus: true,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              decoration: InputDecoration(labelText: t.common.fullNameLabel),
              validator: (v) => (v == null || v.trim().length < 2)
                  ? t.common.requiredField
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              decoration: InputDecoration(labelText: t.common.emailLabel),
              validator: (v) => (v == null || !v.contains('@'))
                  ? t.auth.invalidEmail
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _password,
              obscureText: _obscure,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: t.common.passwordLabel,
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(_obscure
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded),
                ),
              ),
              validator: (v) =>
                  (v == null || v.length < 6) ? t.auth.weakPassword : null,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(t.auth.submitRegister),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.go(loginUri),
              child: Text(t.auth.toLogin),
            ),
          ],
        ),
      ),
    );
  }
}
