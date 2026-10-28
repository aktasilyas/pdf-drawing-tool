/// Turkish-aware text helpers for library search and name sorting.
///
/// Dart's `toLowerCase()` is locale-unaware (`'İ'` → `i̇`, `'I'` → `i`) and
/// `String.compareTo` orders by code unit, so Ç/Ş/Ü land after Z and
/// upper-case names before lower-case ones. These helpers fix both by hand,
/// without a collation dependency.
library;

/// Lower-cases [value] the Turkish way (`I` → `ı`, `İ` → `i`) and trims it.
/// Diacritics are kept, so "is" does not match "iş".
String foldForSearch(String value) =>
    value.trim().replaceAll('I', 'ı').replaceAll('İ', 'i').toLowerCase();

/// Whether [text] contains [query], case-insensitively (Turkish-aware).
/// An empty or blank [query] matches everything.
bool matchesSearch(String text, String query) =>
    foldForSearch(text).contains(foldForSearch(query));

/// Compares names case-insensitively in Turkish alphabetical order
/// (a b c ç d e f g ğ h ı i j k l m n o ö p q r s ş t u ü v w x y z).
/// Names that differ only in case are ordered by their raw text so the
/// order is stable.
int compareNames(String a, String b) {
  final keyA = _collationKey(a);
  final keyB = _collationKey(b);
  final length = keyA.length < keyB.length ? keyA.length : keyB.length;
  for (var i = 0; i < length; i++) {
    final diff = keyA[i] - keyB[i];
    if (diff != 0) return diff;
  }
  final byLength = keyA.length - keyB.length;
  return byLength != 0 ? byLength : a.compareTo(b);
}

const _alphabet = 'abcçdefgğhıijklmnoöpqrsştuüvwxyz';

/// Circumflex vowels sort like their base letter.
const _baseLetter = {'â': 'a', 'î': 'i', 'û': 'u'};

/// Weight base for alphabet letters; above every ASCII digit and symbol.
const _letterBase = 0x1000;

/// Weight base for other characters; after every alphabet letter.
const _otherBase = 0x2000;

List<int> _collationKey(String value) {
  final key = <int>[];
  for (final rune in foldForSearch(value).runes) {
    final char = String.fromCharCode(rune);
    final index = _alphabet.indexOf(_baseLetter[char] ?? char);
    if (index >= 0) {
      key.add(_letterBase + index);
    } else if (rune < 0x80) {
      key.add(rune);
    } else {
      key.add(_otherBase + rune);
    }
  }
  return key;
}
