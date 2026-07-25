/// Mirrors the SQL `normalize_ar()` function exactly (see the
/// arabic_search_normalization migration) so a client-typed search term
/// matches `devices.search_text` regardless of which orthographic variant
/// the user typed (إيفون / آيفون / ايفون all normalize the same way).
///
/// Every Arabic code point is written as a \uXXXX escape rather than a
/// literal combining/variant character, since those are easy to mis-copy
/// as invisible marks in source — the escapes are grep-able and unambiguous.
library;

import 'domain.dart' show toWesternDigits;

final _diacriticsAndTatweel = RegExp(
  '[ًٌٍَُِّْٰـ]',
);
final _alefVariants = RegExp('[أآإٱ]');
const _alef = 'ا';
const _alefMaksura = 'ى';
const _ya = 'ي';
const _taMarbuta = 'ة';
const _ha = 'ه';
final _whitespace = RegExp(r'\s+');

String normalizeArabic(String input) {
  // Arabic-Indic digits (١٤) must become ASCII (14) before anything else —
  // devices are titled with ASCII digits ("iPhone 14"), and a buyer typing
  // "ايفون ١٤" is extremely common.
  var s = toWesternDigits(input).toLowerCase();
  s = s.replaceAll(_diacriticsAndTatweel, '');
  s = s.replaceAll(_alefVariants, _alef);
  s = s.replaceAll(_alefMaksura, _ya);
  s = s.replaceAll(_taMarbuta, _ha);
  s = s.replaceAll(_whitespace, ' ');
  return s;
}

/// Device titles/brands/models are written in Latin script ("iPhone 13
/// Pro..."), but Arabic-speaking buyers naturally type the brand/model in
/// Arabic ("ايفون"). normalizeArabic() alone can't bridge that — it only
/// unifies different Arabic *spellings* of the same word, not a transliterated
/// word against its Latin original. This is a small, hand-maintained
/// dictionary of the electronics brand/model names that actually show up in
/// this catalog; new entries are cheap to add as new brands appear.
const _arabicToLatinTerms = <String, String>{
  'ايفون': 'iphone',
  'ابل': 'apple',
  'ماك بوك': 'macbook',
  'ماكبوك': 'macbook',
  'ايباد': 'ipad',
  'سامسونج': 'samsung',
  'سامسونغ': 'samsung',
  'جالكسي': 'galaxy',
  'غالكسي': 'galaxy',
  'هواوي': 'huawei',
  'شاومي': 'xiaomi',
  'شياومي': 'xiaomi',
  'ريدمي': 'redmi',
  'اوبو': 'oppo',
  'فيفو': 'vivo',
  'نوكيا': 'nokia',
  'لينوفو': 'lenovo',
  'ديل': 'dell',
  'ايسوس': 'asus',
  'اسوس': 'asus',
  'ايسر': 'acer',
  'لابتوب': 'laptop',
  'موبايل': 'mobile',
  'جوال': 'mobile',
};

/// Longest keys first, so a substring match never gets pre-empted by a
/// shorter key contained within a longer one.
final _arabicToLatinKeysByLength = _arabicToLatinTerms.keys.toList()
  ..sort((a, b) => b.length.compareTo(a.length));

/// Translates every known Arabic brand/model word found anywhere in
/// [normalizedQuery] to its Latin form — as a plain substring replacement,
/// not a whole-word match, so it doesn't matter whether the buyer typed a
/// space ("ايفون 14"), no space at all ("ايفون14"), or the brand alone
/// ("ايفون"). Numbers and words already in Arabic (colors, sizes) are left
/// untouched. Returns null when nothing needed translating, so callers can
/// skip the extra search clause entirely.
String? translateArabicSearchTerm(String normalizedQuery) {
  var result = normalizedQuery;
  var changed = false;
  for (final key in _arabicToLatinKeysByLength) {
    if (result.contains(key)) {
      result = result.replaceAll(key, '${_arabicToLatinTerms[key]} ');
      changed = true;
    }
  }
  if (!changed) return null;
  return result.replaceAll(_whitespace, ' ').trim();
}
