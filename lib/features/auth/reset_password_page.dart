import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/supabase_providers.dart';
import '../../core/widgets/common.dart';
import '../../i18n/strings.g.dart';
import '../account/account_repository.dart';
import 'auth_destination.dart';
import 'auth_form_card.dart';

/// Landing page reached from a password-recovery email link: Supabase has
/// established a temporary recovery session, so the user just sets a new
/// password here.
class ResetPasswordPage extends ConsumerStatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
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
      final client = ref.read(supabaseClientProvider);
      await ref.read(accountRepositoryProvider).changePassword(_password.text);
      if (!mounted) return;
      showAppSnackBar(context, t.reset.updated);
      context.go(await postLoginDestination(client, null));
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final signedIn = ref.watch(isSignedInProvider);
    if (!signedIn) {
      // The recovery session hasn't been established (or link expired).
      return AuthFormCard(
        title: t.reset.newTitle,
        child: Column(
          children: [
            Text(t.common.networkError,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go('/login'),
              child: Text(t.common.login),
            ),
          ],
        ),
      );
    }
    return AuthFormCard(
      title: t.reset.newTitle,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(t.reset.newBody,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 20),
            TextFormField(
              controller: _password,
              obscureText: _obscure,
              autofocus: true,
              decoration: InputDecoration(
                labelText: t.account.newPasswordLabel,
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
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirm,
              obscureText: _obscure,
              decoration:
                  InputDecoration(labelText: t.account.confirmPasswordLabel),
              onFieldSubmitted: (_) => _submit(),
              validator: (v) =>
                  v != _password.text ? t.account.passwordMismatch : null,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(t.account.changePassword),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Forgot password" dialog: collects an email and triggers the reset email.
Future<void> showForgotPasswordDialog(BuildContext context, WidgetRef ref) async {
  final controller = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final email = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(t.reset.title),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(t.reset.body,
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(labelText: t.common.emailLabel),
              validator: (v) =>
                  (v == null || !v.contains('@')) ? t.auth.invalidEmail : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(t.common.cancel),
        ),
        FilledButton(
          onPressed: () {
            if (formKey.currentState!.validate()) {
              Navigator.of(context).pop(controller.text.trim());
            }
          },
          child: Text(t.reset.send),
        ),
      ],
    ),
  );
  controller.dispose();
  if (email == null || !context.mounted) return;
  try {
    await ref
        .read(accountRepositoryProvider)
        .sendPasswordReset(email, redirectTo: '${Uri.base.origin}/reset-password');
    if (context.mounted) showAppSnackBar(context, t.reset.sent);
  } catch (e) {
    // Do not reveal whether the email exists; show the same neutral message.
    if (context.mounted) showAppSnackBar(context, t.reset.sent);
  }
}
