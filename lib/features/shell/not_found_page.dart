import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/common.dart';
import '../../i18n/strings.g.dart';

class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: EmptyState(
        icon: Icons.search_off_rounded,
        title: t.common.notFoundTitle,
        body: t.common.notFoundBody,
        action: FilledButton(
          onPressed: () => context.go('/'),
          child: Text(t.common.backHome),
        ),
      ),
    );
  }
}
