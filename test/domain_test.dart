import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:madmoun/core/domain.dart';

void main() {
  group('Money', () {
    test('adds and subtracts amounts of the same currency', () {
      const a = Money(1000, Currency.ils);
      const b = Money(250, Currency.ils);
      expect((a + b).minor, 1250);
      expect((a - b).minor, 750);
      expect((a + b).currency, Currency.ils);
    });

    test('throws CurrencyMismatchException when currencies differ', () {
      const ils = Money(100, Currency.ils);
      const usd = Money(100, Currency.usd);
      expect(() => ils + usd, throwsA(isA<CurrencyMismatchException>()));
      expect(() => ils - usd, throwsA(isA<CurrencyMismatchException>()));
      expect(() => ils < usd, throwsA(isA<CurrencyMismatchException>()));
      expect(() => ils.compareTo(usd),
          throwsA(isA<CurrencyMismatchException>()));
    });

    test('commission rounds half away from zero like the database', () {
      // 10.0% of 15 minor units = 1.5 -> 2
      expect(const Money(15, Currency.ils).commission(100).minor, 2);
      // 10.0% of 14 = 1.4 -> 1
      expect(const Money(14, Currency.ils).commission(100).minor, 1);
      // 10.0% of 5 = 0.5 -> 1
      expect(const Money(5, Currency.usd).commission(100).minor, 1);
      // 10.0% of 120000 (1,200.00) = 12000 exactly
      expect(
          const Money(120000, Currency.ils).commission(100).minor, 12000);
      // 12.5% of 1000 = 125
      expect(const Money(1000, Currency.ils).commission(125).minor, 125);
      // 0% commission is zero
      expect(const Money(9999, Currency.ils).commission(0).minor, 0);
    });

    test('commission keeps the currency and rejects negative percents', () {
      final c = const Money(120000, Currency.usd).commission(100);
      expect(c.currency, Currency.usd);
      expect(() => const Money(1, Currency.ils).commission(-1),
          throwsArgumentError);
    });

    test('default platform commission is 10.0%', () {
      expect(defaultCommissionPercentTenths, 100);
      expect(
        const Money(89900, Currency.usd)
            .commission(defaultCommissionPercentTenths)
            .minor,
        8990,
      );
    });

    test('formats whole and fractional amounts with grouping', () {
      expect(const Money(120000, Currency.ils).format(), '₪ 1,200');
      expect(const Money(34950, Currency.usd).format(), r'$ 349.50');
      expect(const Money(99, Currency.ils).format(), '₪ 0.99');
      expect(const Money(123456789, Currency.usd).format(), r'$ 1,234,567.89');
    });

    test('equality and ordering', () {
      expect(const Money(100, Currency.ils), const Money(100, Currency.ils));
      expect(const Money(100, Currency.ils) == const Money(100, Currency.usd),
          isFalse);
      expect(
          const Money(200, Currency.ils) > const Money(100, Currency.ils),
          isTrue);
      expect(
          const Money(50, Currency.ils) < const Money(100, Currency.ils),
          isTrue);
    });
  });

  group('gradeOf', () {
    test('all pass -> excellent', () {
      expect(
        gradeOf(List.filled(6, ChecklistResult.pass)),
        Grade.excellent,
      );
    });

    test('empty checklist -> excellent (vacuously clean)', () {
      expect(gradeOf(const []), Grade.excellent);
    });

    test('one minor issue -> veryGood', () {
      expect(
        gradeOf([
          ChecklistResult.pass,
          ChecklistResult.minorIssue,
          ChecklistResult.pass,
        ]),
        Grade.veryGood,
      );
    });

    test('two minor issues -> veryGood', () {
      expect(
        gradeOf([
          ChecklistResult.minorIssue,
          ChecklistResult.minorIssue,
          ChecklistResult.pass,
        ]),
        Grade.veryGood,
      );
    });

    test('three minor issues -> good', () {
      expect(
        gradeOf(List.filled(3, ChecklistResult.minorIssue)),
        Grade.good,
      );
    });

    test('any fail -> fair regardless of the rest', () {
      expect(
        gradeOf([
          ChecklistResult.pass,
          ChecklistResult.pass,
          ChecklistResult.fail,
        ]),
        Grade.fair,
      );
      expect(
        gradeOf([
          ChecklistResult.minorIssue,
          ChecklistResult.fail,
          ChecklistResult.minorIssue,
          ChecklistResult.minorIssue,
        ]),
        Grade.fair,
      );
    });
  });

  group('normalizePhone', () {
    test('local Palestinian mobile defaults to +970', () {
      expect(normalizePhone('0599123456'), '+970599123456');
      expect(normalizePhone('059-912-3456'), '+970599123456');
      expect(normalizePhone('059 912 3456'), '+970599123456');
    });

    test('already-international +970 and +972 pass through', () {
      expect(normalizePhone('+970599123456'), '+970599123456');
      expect(normalizePhone('+972501234567'), '+972501234567');
    });

    test('00 and bare country-code prefixes are normalized', () {
      expect(normalizePhone('00970599123456'), '+970599123456');
      expect(normalizePhone('970599123456'), '+970599123456');
      expect(normalizePhone('972501234567'), '+972501234567');
    });

    test('landlines normalize too', () {
      expect(normalizePhone('022967777'), '+97022967777');
    });

    test('Arabic-Indic digits are accepted', () {
      expect(normalizePhone('٠٥٩٩١٢٣٤٥٦'), '+970599123456');
    });

    test('invalid inputs return null', () {
      expect(normalizePhone(''), isNull);
      expect(normalizePhone('abc'), isNull);
      expect(normalizePhone('+970'), isNull);
      expect(normalizePhone('599123456'), isNull); // no leading 0/+/country
      expect(normalizePhone('+9705991234567890'), isNull); // too long
      expect(normalizePhone('+9700599123456'), isNull); // 0 after country code
    });
  });

  group('generatePublicId', () {
    test('matches the MD-XXXXX format with the safe alphabet', () {
      final id = generatePublicId('MD');
      expect(publicIdPattern.hasMatch(id), isTrue, reason: id);
    });

    test('never contains ambiguous characters', () {
      final rng = Random(42);
      for (var i = 0; i < 500; i++) {
        final id = generatePublicId('RS', random: rng);
        expect(id, isNot(matches(RegExp('[01OIL]'))));
        expect(id.length, 8);
        expect(id.startsWith('RS-'), isTrue);
      }
    });

    test('is deterministic with a seeded random', () {
      expect(
        generatePublicId('MD', random: Random(7)),
        generatePublicId('MD', random: Random(7)),
      );
    });
  });

  group('db enum round-trips', () {
    test('every enum maps to and from its db value', () {
      for (final v in Currency.values) {
        expect(Currency.fromDb(v.dbValue), v);
      }
      for (final v in Grade.values) {
        expect(Grade.fromDb(v.dbValue), v);
      }
      for (final v in ChecklistResult.values) {
        expect(ChecklistResult.fromDb(v.dbValue), v);
      }
      for (final v in DeviceCategory.values) {
        expect(DeviceCategory.fromDb(v.dbValue), v);
      }
      for (final v in DeviceStatus.values) {
        expect(DeviceStatus.fromDb(v.dbValue), v);
      }
      for (final v in ShopStatus.values) {
        expect(ShopStatus.fromDb(v.dbValue), v);
      }
      for (final v in ReservationStatus.values) {
        expect(ReservationStatus.fromDb(v.dbValue), v);
      }
      for (final v in ClaimStatus.values) {
        expect(ClaimStatus.fromDb(v.dbValue), v);
      }
      for (final v in UserRole.values) {
        expect(UserRole.fromDb(v.dbValue), v);
      }
    });

    test('unknown db values throw', () {
      expect(() => Currency.fromDb('EUR'), throwsArgumentError);
      expect(() => DeviceStatus.fromDb('nope'), throwsArgumentError);
    });
  });

  group('ChecklistEntry json', () {
    test('round-trips', () {
      const entry = ChecklistEntry(
        key: 'battery_health',
        result: ChecklistResult.minorIssue,
        note: 'بطارية 84%',
      );
      final restored = ChecklistEntry.fromJson(entry.toJson());
      expect(restored.key, 'battery_health');
      expect(restored.result, ChecklistResult.minorIssue);
      expect(restored.note, 'بطارية 84%');
    });

    test('omits empty note', () {
      const entry = ChecklistEntry(key: 'screen', result: ChecklistResult.pass);
      expect(entry.toJson().containsKey('note'), isFalse);
    });
  });
}
