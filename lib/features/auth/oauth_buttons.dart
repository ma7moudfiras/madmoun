import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase_providers.dart';
import '../../core/widgets/common.dart';
import '../../i18n/strings.g.dart';

/// Google/Apple sign-in buttons shared by login and register — both just
/// call [signInWithOAuth], which signs up on first use. Ships nothing until
/// the corresponding provider is configured upstream (see [Env]).
class OAuthButtons extends ConsumerWidget {
  const OAuthButtons({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!Env.googleAuthEnabled && !Env.appleAuthEnabled) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(t.auth.orDivider),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 16),
        if (Env.googleAuthEnabled)
          OutlinedButton.icon(
            onPressed: () => _signIn(context, ref, OAuthProvider.google),
            icon: const Icon(Icons.account_circle_rounded),
            label: Text(t.auth.googleSignIn),
          ),
        if (Env.googleAuthEnabled && Env.appleAuthEnabled)
          const SizedBox(height: 12),
        if (Env.appleAuthEnabled)
          OutlinedButton.icon(
            onPressed: () => _signIn(context, ref, OAuthProvider.apple),
            icon: const Icon(Icons.apple_rounded),
            label: Text(t.auth.appleSignIn),
          ),
      ],
    );
  }

  Future<void> _signIn(
    BuildContext context,
    WidgetRef ref,
    OAuthProvider provider,
  ) async {
    try {
      await ref.read(supabaseClientProvider).auth.signInWithOAuth(provider);
    } catch (e) {
      if (context.mounted) showErrorSnackBar(context, e);
    }
  }
}
