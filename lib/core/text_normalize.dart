/// Mirrors the SQL `normalize_ar()` function exactly (see the
/// arabic_search_normalization migration) so a client-typed search term
/// matches `devices.search_text` regardless of which orthographic variant
/// the user typed (إيفون / آيفون / ايفون all normalize the same way).
///
/// Every Arabic code point is written as a \uXXXX escape rather than a
/// literal combining/variant character, since those are easy to mis-copy
/// as invisible marks in source — the escapes are grep-able and unambiguous.
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
  var s = input.toLowerCase();
  s = s.replaceAll(_diacriticsAndTatweel, '');
  s = s.replaceAll(_alefVariants, _alef);
  s = s.replaceAll(_alefMaksura, _ya);
  s = s.replaceAll(_taMarbuta, _ha);
  s = s.replaceAll(_whitespace, ' ');
  return s;
}
