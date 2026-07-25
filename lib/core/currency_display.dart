/// Buyer-facing currency display toggle: ILS is the only currency ever
/// stored or charged (COD, commission, ledger — everything stays in ILS).
/// This is a purely presentational, non-stored conversion so a buyer who
/// thinks in dollars can see an approximate USD figure while browsing.
library;

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import 'domain.dart';

/// The buyer's chosen display currency for browsing. Defaults to ILS (the
/// real, stored currency); switching to USD never changes what's charged.
final displayCurrencyProvider = StateProvider<Currency>((ref) => Currency.ils);

/// Live ILS -> USD rate (how many USD 1 ILS is worth), fetched from a free,
/// no-key exchange-rate API. Null if the fetch fails — callers fall back to
/// showing the real ILS amount rather than guessing a rate.
final exchangeRateProvider = FutureProvider<double?>((ref) => fetchIlsToUsdRate());

Future<double?> fetchIlsToUsdRate() async {
  try {
    final response = await http
        .get(Uri.parse('https://open.er-api.com/v6/latest/ILS'))
        .timeout(const Duration(seconds: 6));
    if (response.statusCode != 200) return null;
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final rates = json['rates'] as Map<String, dynamic>?;
    final usd = rates?['USD'];
    return usd is num ? usd.toDouble() : null;
  } catch (_) {
    return null;
  }
}

/// Formats [ilsAmount] (always the real, stored value) for display in
/// [target]. In ILS, or if the live rate isn't available yet, this is just
/// the plain formatted ILS amount. In USD it's a "≈" prefixed conversion —
/// never the actual amount owed, which stays in ILS at checkout.
String formatForDisplay(Money ilsAmount, Currency target, double? ilsToUsdRate) {
  if (target == Currency.ils || ilsToUsdRate == null) {
    return ilsAmount.format();
  }
  final usdMinor = (ilsAmount.minor * ilsToUsdRate).round();
  return '≈ ${Money(usdMinor, Currency.usd).format()}';
}
