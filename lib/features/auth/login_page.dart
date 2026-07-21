import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase_providers.dart';
import '../../core/widgets/common.dart';
import '../../i18n/strings.g.dart';
import 'auth_destination.dart';
import 'auth_form_card.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key, this.from});

  final String? from;

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final client = ref.read(supabaseClientProvider);
      await client.auth.signInWithPassword(
        email: _email.text.trim(),
        password: _password.text,
      );
      final destination = await postLoginDestination(client, widget.from);
      if (mounted) context.go(destination);
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _googleSignIn() async {
    try {
      await ref.read(supabaseClientProvider).auth.signInWithOAuth(
            OAuthProvider.google,
          );
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final from = widget.from;
    final registerUri = from == null || from.isEmpty
        ? '/register'
        : '/register?from=$from';

    return AuthFormCard(
      title: t.auth.loginTitle,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _email,
              autofocus: true,
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
              autofillHints: const [AutofillHints.password],
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
                  (v == null || v.isEmpty) ? t.common.requiredField : null,
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
                  : Text(t.auth.submitLogin),
            ),
            if (Env.googleAuthEnabled) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _googleSignIn,
                icon: const Icon(Icons.account_circle_rounded),
                label: Text(t.auth.googleSignIn),
              ),
            ],
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.go(registerUri),
              child: Text(t.auth.toRegister),
            ),
          ],
        ),
      ),
    );
  }
}
