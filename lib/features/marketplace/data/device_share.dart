import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/models.dart';
import '../../../core/widgets/common.dart';
import '../../../i18n/strings.g.dart';

/// The canonical, shareable URL for a device. Link-preview crawlers
/// (WhatsApp, Facebook, Twitter) are served a prerendered page with the
/// device photo and price by `api/og/[id]` (see vercel.json), while real
/// visitors land on the Flutter app as usual.
String deviceShareUrl(String publicId) =>
    Uri.base.replace(path: '/d/$publicId', query: '').toString();

/// Bottom sheet with the share destinations that matter for this audience:
/// WhatsApp first, then a plain link copy, then the platform share sheet.
Future<void> shareDevice(BuildContext context, Listing listing) async {
  final link = deviceShareUrl(listing.publicId);
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Text(
              t.device.shareSheetTitle,
              style: Theme.of(sheetContext)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.chat_rounded),
            title: Text(t.device.shareWhatsapp),
            onTap: () {
              Navigator.of(sheetContext).pop();
              _shareViaWhatsapp(listing, link);
            },
          ),
          ListTile(
            leading: const Icon(Icons.link_rounded),
            title: Text(t.device.shareCopyLink),
            onTap: () async {
              Navigator.of(sheetContext).pop();
              await Clipboard.setData(ClipboardData(text: link));
              if (context.mounted) {
                showAppSnackBar(context, t.device.shareCopied);
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.ios_share_rounded),
            title: Text(t.device.shareMore),
            onTap: () {
              Navigator.of(sheetContext).pop();
              SharePlus.instance.share(
                ShareParams(uri: Uri.parse(link), title: listing.title),
              );
            },
          ),
        ],
      ),
    ),
  );
}

Future<void> _shareViaWhatsapp(Listing listing, String link) async {
  final text = t.device.shareWhatsappText(
    title: listing.title,
    price: listing.price.format(),
    link: link,
  );
  final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}');
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}
