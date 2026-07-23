import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../i18n/strings.g.dart';

/// One block of an info/legal page: an optional bold heading and a body.
class InfoSection {
  const InfoSection({this.heading, required this.body});
  final String? heading;
  final String body;
}

/// Simple, readable static content page (how-it-works, FAQ, terms, privacy).
class InfoPage extends StatelessWidget {
  const InfoPage({
    super.key,
    required this.title,
    required this.sections,
    this.footnote,
  });

  final String title;
  final List<InfoSection> sections;
  final String? footnote;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              if (footnote != null) ...[
                const SizedBox(height: 6),
                Text(
                  footnote!,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
              const SizedBox(height: 20),
              for (final s in sections) ...[
                if (s.heading != null) ...[
                  Text(
                    s.heading!,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                ],
                Text(s.body,
                    style: theme.textTheme.bodyLarge?.copyWith(height: 1.75)),
                const SizedBox(height: 20),
              ],
              const SizedBox(height: 12),
              const SiteFooter(),
            ],
          ),
        ),
      ),
    );
  }
}

/// The four static pages, assembled from translations.
InfoPage howItWorksPage() => InfoPage(
      title: t.info.howTitle,
      sections: [
        InfoSection(body: t.info.howIntro),
        InfoSection(heading: t.info.howStep1Title, body: t.info.howStep1Body),
        InfoSection(heading: t.info.howStep2Title, body: t.info.howStep2Body),
        InfoSection(heading: t.info.howStep3Title, body: t.info.howStep3Body),
        InfoSection(body: t.info.howTrust),
      ],
    );

InfoPage faqPage() => InfoPage(
      title: t.info.faqTitle,
      sections: [
        InfoSection(heading: t.info.faqQ1, body: t.info.faqA1),
        InfoSection(heading: t.info.faqQ2, body: t.info.faqA2),
        InfoSection(heading: t.info.faqQ3, body: t.info.faqA3),
        InfoSection(heading: t.info.faqQ4, body: t.info.faqA4),
        InfoSection(heading: t.info.faqQ5, body: t.info.faqA5),
        InfoSection(heading: t.info.faqQ6, body: t.info.faqA6),
      ],
    );

InfoPage termsPage() => InfoPage(
      title: t.info.termsTitle,
      footnote: t.info.termsUpdated,
      sections: [InfoSection(body: t.info.termsBody)],
    );

InfoPage privacyPage() => InfoPage(
      title: t.info.privacyTitle,
      footnote: t.info.privacyUpdated,
      sections: [InfoSection(body: t.info.privacyBody)],
    );

/// Footer with links to the info/legal pages; shared by Home and info pages.
class SiteFooter extends StatelessWidget {
  const SiteFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final links = <(String, String)>[
      ('/how-it-works', t.info.howTitle),
      ('/faq', t.info.faqTitle),
      ('/terms', t.info.termsTitle),
      ('/privacy', t.info.privacyTitle),
    ];
    final muted = theme.textTheme.bodySmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 4,
            runSpacing: 0,
            children: [
              for (final l in links)
                TextButton(
                  onPressed: () => context.go(l.$1),
                  child: Text(l.$2),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(t.info.footerTagline, style: muted, textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(t.info.footerRights, style: muted, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
