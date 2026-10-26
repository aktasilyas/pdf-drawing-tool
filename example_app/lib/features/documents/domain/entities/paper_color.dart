/// Paper colour of a notebook's pages.
///
/// Documents store [storageKey] (the Turkish label used since the first
/// release). [tryParse] also accepts the ASCII spellings that the template
/// screen wrote by mistake, so those records open in their chosen colour.
library;

enum PaperColor {
  white(0xFFFFFFFF, 'Beyaz kağıt'),
  black(0xFF1A1A1A, 'Siyah kağıt'),
  cream(0xFFFFF8E7, 'Krem kağıt'),
  gray(0xFFF5F5F5, 'Gri kağıt'),
  green(0xFFE8F5E9, 'Yeşil kağıt'),
  blue(0xFFE3F2FD, 'Mavi kağıt'),

  /// Legacy default of older records; not offered at creation.
  yellow(0xFFFFFDE7, 'Sarı kağıt');

  const PaperColor(this.argb, this.storageKey);

  /// Page background colour as ARGB.
  final int argb;

  /// Value persisted in `DocumentInfo.paperColor`.
  final String storageKey;

  /// Colours offered when creating a notebook.
  static const List<PaperColor> palette = [
    white,
    black,
    cream,
    gray,
    green,
    blue,
  ];

  /// [storageKey] without Turkish diacritics (the legacy ASCII spelling).
  String get asciiKey => _fold(storageKey);

  /// The colour with [argb], or [white] when none matches.
  static PaperColor fromArgb(int argb) {
    for (final color in values) {
      if (color.argb == argb) return color;
    }
    return white;
  }

  /// Parses a stored value in either spelling; null when unknown.
  static PaperColor? tryParse(String? stored) {
    if (stored == null) return null;
    final key = _fold(stored);
    if (key.isEmpty) return null;
    if (key == 'acik gri') return gray;
    for (final color in values) {
      if (_fold(color.storageKey) == key) return color;
    }
    return null;
  }

  static const Map<String, String> _ascii = {
    'ç': 'c',
    'ğ': 'g',
    'ı': 'i',
    'ö': 'o',
    'ş': 's',
    'ü': 'u',
  };

  /// Lower-case (Turkish-aware for I/İ), trimmed, diacritics folded.
  static String _fold(String value) {
    final lower = value
        .trim()
        .replaceAll('I', 'ı')
        .replaceAll('İ', 'i')
        .toLowerCase();
    final buffer = StringBuffer();
    for (final rune in lower.runes) {
      final char = String.fromCharCode(rune);
      buffer.write(_ascii[char] ?? char);
    }
    return buffer.toString();
  }
}
