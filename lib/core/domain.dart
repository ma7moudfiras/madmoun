/// Core business domain for Madmoun.
///
/// Single source of truth for money arithmetic, condition grading,
/// commission, phone normalization, and public id generation. Pure Dart,
/// no Flutter/Supabase imports, fully unit-tested.
library;

import 'dart:math';

// ---------------------------------------------------------------------------
// Currency & Money
// ---------------------------------------------------------------------------

enum Currency {
  ils('ILS', '₪'),
  usd('USD', r'$');

  const Currency(this.dbValue, this.symbol);

  final String dbValue;
  final String symbol;

  static Currency fromDb(String value) => Currency.values.firstWhere(
        (c) => c.dbValue == value,
        orElse: () => throw ArgumentError('Unknown currency: $value'),
      );
}

/// Thrown when combining two [Money] values of different currencies.
class CurrencyMismatchException implements Exception {
  const CurrencyMismatchException(this.a, this.b);

  final Currency a;
  final Currency b;

  @override
  String toString() =>
      'CurrencyMismatchException: ${a.dbValue} vs ${b.dbValue}';
}

/// An amount of money in integer minor units (agorot / cents).
/// Never uses floating point for amounts.
class Money implements Comparable<Money> {
  const Money(this.minor, this.currency);

  /// The amount in minor units (1/100 of the major unit).
  final int minor;
  final Currency currency;

  static const int minorPerMajor = 100;

  Money operator +(Money other) {
    _ensureSameCurrency(other);
    return Money(minor + other.minor, currency);
  }

  Money operator -(Money other) {
    _ensureSameCurrency(other);
    return Money(minor - other.minor, currency);
  }

  bool operator <(Money other) {
    _ensureSameCurrency(other);
    return minor < other.minor;
  }

  bool operator >(Money other) {
    _ensureSameCurrency(other);
    return minor > other.minor;
  }

  /// Commission in minor units at [percentTenths] tenths of a percent
  /// (100 = 10.0%). Integer arithmetic, rounds half away from zero to match
  /// the database's `round(numeric)`.
  Money commission(int percentTenths) {
    if (percentTenths < 0) {
      throw ArgumentError.value(percentTenths, 'percentTenths');
    }
    final product = minor * percentTenths;
    return Money((product + 500) ~/ 1000, currency);
  }

  /// Formats as an Arabic-friendly price string, e.g. `₪ 1,250` or
  /// `$ 349.50`. Whole amounts drop the decimals.
  String format() {
    final major = minor ~/ minorPerMajor;
    final rest = minor.remainder(minorPerMajor).abs();
    final grouped = _group(major);
    final amount =
        rest == 0 ? grouped : '$grouped.${rest.toString().padLeft(2, '0')}';
    return '${currency.symbol} $amount';
  }

  static String _group(int value) {
    final sign = value < 0 ? '-' : '';
    final digits = value.abs().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return '$sign$buffer';
  }

  void _ensureSameCurrency(Money other) {
    if (currency != other.currency) {
      throw CurrencyMismatchException(currency, other.currency);
    }
  }

  @override
  int compareTo(Money other) {
    _ensureSameCurrency(other);
    return minor.compareTo(other.minor);
  }

  @override
  bool operator ==(Object other) =>
      other is Money && other.minor == minor && other.currency == currency;

  @override
  int get hashCode => Object.hash(minor, currency);

  @override
  String toString() => 'Money($minor ${currency.dbValue})';
}

/// Platform commission: 10.0%, expressed in tenths of a percent.
const int defaultCommissionPercentTenths = 100;

// ---------------------------------------------------------------------------
// Checklist & grading
// ---------------------------------------------------------------------------

enum ChecklistResult {
  pass('pass'),
  minorIssue('minorIssue'),
  fail('fail');

  const ChecklistResult(this.dbValue);

  final String dbValue;

  static ChecklistResult fromDb(String value) =>
      ChecklistResult.values.firstWhere(
        (r) => r.dbValue == value,
        orElse: () => throw ArgumentError('Unknown checklist result: $value'),
      );
}

/// One answered checklist item as stored in `devices.checklist` jsonb.
class ChecklistEntry {
  const ChecklistEntry({required this.key, required this.result, this.note});

  final String key;
  final ChecklistResult result;
  final String? note;

  Map<String, dynamic> toJson() => {
        'key': key,
        'result': result.dbValue,
        if (note != null && note!.isNotEmpty) 'note': note,
      };

  static ChecklistEntry fromJson(Map<String, dynamic> json) => ChecklistEntry(
        key: json['key'] as String,
        result: ChecklistResult.fromDb(json['result'] as String),
        note: json['note'] as String?,
      );
}

enum Grade {
  excellent('excellent'),
  veryGood('very_good'),
  good('good'),
  fair('fair');

  const Grade(this.dbValue);

  final String dbValue;

  static Grade fromDb(String value) => Grade.values.firstWhere(
        (g) => g.dbValue == value,
        orElse: () => throw ArgumentError('Unknown grade: $value'),
      );
}

/// Grades a device from its inspection results:
/// any failure caps the grade at [Grade.fair]; otherwise up to two minor
/// issues is [Grade.veryGood], more is [Grade.good], and a clean sheet is
/// [Grade.excellent].
Grade gradeOf(Iterable<ChecklistResult> results) {
  var minorIssues = 0;
  for (final result in results) {
    if (result == ChecklistResult.fail) return Grade.fair;
    if (result == ChecklistResult.minorIssue) minorIssues++;
  }
  if (minorIssues == 0) return Grade.excellent;
  if (minorIssues <= 2) return Grade.veryGood;
  return Grade.good;
}

// ---------------------------------------------------------------------------
// Phone normalization
// ---------------------------------------------------------------------------

/// Normalizes a Palestinian phone number to E.164.
///
/// Accepts `+970`/`+972` internationals (also `00`-prefixed or without `+`),
/// and local `0`-prefixed numbers which default to `+970`. Separators
/// (spaces, dashes, dots, parentheses) and Arabic-Indic digits are accepted.
/// Returns `null` when the input cannot be a valid number.
String? normalizePhone(String input) {
  var raw = toWesternDigits(input.trim());
  raw = raw.replaceAll(RegExp(r'[\s\-\.\(\)]'), '');
  if (raw.isEmpty) return null;

  if (raw.startsWith('00')) {
    raw = '+${raw.substring(2)}';
  }

  String digits;
  if (raw.startsWith('+')) {
    digits = raw.substring(1);
  } else if (raw.startsWith('970') || raw.startsWith('972')) {
    digits = raw;
  } else if (raw.startsWith('0')) {
    // Local format: 059… mobile or 02… landline, defaulting to +970.
    digits = '970${raw.substring(1)}';
  } else {
    return null;
  }

  if (!RegExp(r'^[0-9]+$').hasMatch(digits)) return null;
  if (digits.length < 8 || digits.length > 15) return null;

  if (digits.startsWith('970') || digits.startsWith('972')) {
    // National significant number for PS/IL is 8-9 digits.
    final national = digits.substring(3);
    if (national.length < 8 || national.length > 9) return null;
    if (national.startsWith('0')) return null;
  }

  return '+$digits';
}

/// Converts Arabic-Indic (٠١٢٣...) and Eastern Arabic-Indic (۰۱۲۳...) digits
/// to plain ASCII digits. Shared by phone normalization and search.
String toWesternDigits(String input) {
  const arabicIndic = '٠١٢٣٤٥٦٧٨٩';
  const easternArabicIndic = '۰۱۲۳۴۵۶۷۸۹';
  final buffer = StringBuffer();
  for (final rune in input.runes) {
    final char = String.fromCharCode(rune);
    final a = arabicIndic.indexOf(char);
    final e = easternArabicIndic.indexOf(char);
    if (a >= 0) {
      buffer.write(a);
    } else if (e >= 0) {
      buffer.write(e);
    } else {
      buffer.write(char);
    }
  }
  return buffer.toString();
}

// ---------------------------------------------------------------------------
// Public ids
// ---------------------------------------------------------------------------

/// Alphabet without visually ambiguous characters (no 0/O, 1/I/L).
const String publicIdAlphabet = '23456789ABCDEFGHJKMNPQRSTUVWXYZ';

const int publicIdLength = 5;

/// Generates a display id like `MD-7K3QF`. The database assigns the
/// authoritative id on insert; this mirrors the same format client-side.
String generatePublicId(String prefix, {Random? random}) {
  final rng = random ?? Random.secure();
  final chars = List.generate(
    publicIdLength,
    (_) => publicIdAlphabet[rng.nextInt(publicIdAlphabet.length)],
  );
  return '$prefix-${chars.join()}';
}

final RegExp publicIdPattern = RegExp('^[A-Z]{2}-[$publicIdAlphabet]{5}\$');

// ---------------------------------------------------------------------------
// Status enums (mirror the Postgres enums; labels live in slang).
// ---------------------------------------------------------------------------

enum DeviceCategory {
  mobile('mobile'),
  laptop('laptop');

  const DeviceCategory(this.dbValue);

  final String dbValue;

  static DeviceCategory fromDb(String value) =>
      DeviceCategory.values.firstWhere(
        (c) => c.dbValue == value,
        orElse: () => throw ArgumentError('Unknown category: $value'),
      );
}

enum DeviceStatus {
  draft('draft'),
  underInspection('under_inspection'),
  listed('listed'),
  reserved('reserved'),
  sold('sold'),
  warrantyActive('warranty_active'),
  warrantyClosed('warranty_closed'),
  rejected('rejected'),
  returned('returned');

  const DeviceStatus(this.dbValue);

  final String dbValue;

  static DeviceStatus fromDb(String value) => DeviceStatus.values.firstWhere(
        (s) => s.dbValue == value,
        orElse: () => throw ArgumentError('Unknown device status: $value'),
      );
}

enum ShopStatus {
  pending('pending'),
  approved('approved'),
  rejected('rejected');

  const ShopStatus(this.dbValue);

  final String dbValue;

  static ShopStatus fromDb(String value) => ShopStatus.values.firstWhere(
        (s) => s.dbValue == value,
        orElse: () => throw ArgumentError('Unknown shop status: $value'),
      );
}

enum ReservationStatus {
  pending('pending'),
  confirmed('confirmed'),
  outForDelivery('out_for_delivery'),
  delivered('delivered'),
  cancelled('cancelled');

  const ReservationStatus(this.dbValue);

  final String dbValue;

  static ReservationStatus fromDb(String value) =>
      ReservationStatus.values.firstWhere(
        (s) => s.dbValue == value,
        orElse: () => throw ArgumentError('Unknown reservation status: $value'),
      );
}

enum ClaimStatus {
  open('open'),
  inReview('in_review'),
  resolved('resolved'),
  rejected('rejected');

  const ClaimStatus(this.dbValue);

  final String dbValue;

  static ClaimStatus fromDb(String value) => ClaimStatus.values.firstWhere(
        (s) => s.dbValue == value,
        orElse: () => throw ArgumentError('Unknown claim status: $value'),
      );
}

enum UserRole {
  buyer('buyer'),
  seller('seller'),
  admin('admin');

  const UserRole(this.dbValue);

  final String dbValue;

  static UserRole fromDb(String value) => UserRole.values.firstWhere(
        (r) => r.dbValue == value,
        orElse: () => throw ArgumentError('Unknown role: $value'),
      );
}

/// CO2 estimate per saved device, mirroring the database's impact_stats().
const int co2KgPerMobile = 60;
const int co2KgPerLaptop = 250;
