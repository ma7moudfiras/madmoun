import 'package:url_launcher/url_launcher.dart';

import '../../../core/models.dart';
import '../../../i18n/strings.g.dart';

/// A complete pickup + dropoff brief for the courier. Shared by the
/// reservations table and the ops console.
String courierBrief(Reservation r) {
  final d = t.admin.dispatch;
  final pickup = [r.shopName, r.shopCity, r.shopAddress]
      .whereType<String>()
      .where((e) => e.isNotEmpty)
      .join(' — ');
  final dropoff = [r.deliveryCity, r.deliveryAddress]
      .whereType<String>()
      .where((e) => e.isNotEmpty)
      .join(' — ');
  final b = StringBuffer()
    ..writeln(d.msgTitle)
    ..writeln('${d.order}: ${r.publicId}');
  if (r.deviceTitle != null) b.writeln('${d.device}: ${r.deviceTitle}');
  b.writeln('');
  b.writeln('📦 ${d.pickup}:');
  if (pickup.isNotEmpty) b.writeln(pickup);
  if (r.shopPhone != null) b.writeln('${d.phone}: ${r.shopPhone}');
  b.writeln('');
  b.writeln('🏠 ${d.dropoff}:');
  if (dropoff.isNotEmpty) b.writeln(dropoff);
  if (r.buyerPhone != null) b.writeln('${d.phone}: ${r.buyerPhone}');
  if (r.deliveryNote != null) b.writeln('${d.note}: ${r.deliveryNote}');
  b.writeln('');
  b.write('💵 ${d.collect}: ${r.price.format()}');
  return b.toString();
}

/// Opens WhatsApp with no recipient (wa.me/?text=…) so the admin picks the
/// courier contact, prefilled with the delivery brief.
Future<void> openCourierWhatsApp(Reservation r) async {
  final uri =
      Uri.parse('https://wa.me/?text=${Uri.encodeComponent(courierBrief(r))}');
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}
