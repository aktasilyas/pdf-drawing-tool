/// Finds user-facing string literals that bypass localization.
///
/// A literal is flagged when it contains a Turkish letter, or when it is a
/// non-empty literal directly after `Text(` or a UI-copy named argument
/// (`title:`, `label:`, `tooltip:` ...). Opt out per line with a trailing
/// `// l10n-ignore` comment (brand names, e-mail addresses, symbols).
library;

const _copyArguments = [
  'title',
  'subtitle',
  'label',
  'hintText',
  'labelText',
  'message',
  'tooltip',
  'semanticsLabel',
  'semanticLabel',
  'hint',
  'confirmLabel',
  'cancelLabel',
];

final _turkishLetter = RegExp('[çğıöşüÇĞİÖŞÜ]');
final _interpolation = RegExp(r'\$\{[^}]*\}|\$\w+');
final _letter = RegExp(r'\p{L}', unicode: true);
final _copyContext = RegExp(
  '(?:\\bText\\(|\\b(?:${_copyArguments.join('|')}):)\\s*(?:const\\s+)?\$',
);

typedef _Literal = ({int start, int end, String body});

/// Returns the offending literals of [source] with their 1-based line.
List<({int line, String literal})> findHardcodedStrings(String source) {
  final lineStarts = <int>[0];
  for (var i = 0; i < source.length; i++) {
    if (source.codeUnitAt(i) == 0x0A) lineStarts.add(i + 1);
  }
  final found = <({int line, String literal})>[];
  for (final lit in _tokenize(source)) {
    final lineIndex = _lineIndexOf(lineStarts, lit.start);
    final lineStart = lineStarts[lineIndex];
    final lineEnd = lineIndex + 1 < lineStarts.length
        ? lineStarts[lineIndex + 1]
        : source.length;
    final lineText = source.substring(lineStart, lineEnd);
    if (lineText.contains('// l10n-ignore')) continue;
    final trimmed = lineText.trimLeft();
    if (trimmed.startsWith('import ') ||
        trimmed.startsWith('export ') ||
        trimmed.startsWith('part ')) {
      continue;
    }
    final text = lit.body.replaceAll(_interpolation, '');
    final from = lit.start < 80 ? 0 : lit.start - 80;
    final before = source.substring(from, lit.start);
    final flagged = _turkishLetter.hasMatch(text) ||
        (_letter.hasMatch(text) && _copyContext.hasMatch(before));
    if (flagged) found.add((line: lineIndex + 1, literal: lit.body));
  }
  return found;
}

int _lineIndexOf(List<int> lineStarts, int offset) {
  var lo = 0;
  var hi = lineStarts.length - 1;
  while (lo < hi) {
    final mid = (lo + hi + 1) ~/ 2;
    if (lineStarts[mid] <= offset) {
      lo = mid;
    } else {
      hi = mid - 1;
    }
  }
  return lo;
}

/// Splits [s] into string literals, skipping comments.
List<_Literal> _tokenize(String s) {
  final out = <_Literal>[];
  var i = 0;
  while (i < s.length) {
    final c = s[i];
    if (c == '/' && i + 1 < s.length && s[i + 1] == '/') {
      final nl = s.indexOf('\n', i);
      i = nl == -1 ? s.length : nl;
    } else if (c == '/' && i + 1 < s.length && s[i + 1] == '*') {
      final end = s.indexOf('*/', i + 2);
      i = end == -1 ? s.length : end + 2;
    } else if (c == "'" || c == '"') {
      final isRaw = i > 0 && s[i - 1] == 'r' && (i < 2 || !_isWord(s[i - 2]));
      final lit = _readString(s, i, isRaw: isRaw);
      out.add(lit);
      i = lit.end;
    } else {
      i++;
    }
  }
  return out;
}

/// Reads the literal opening at [open]; `end` is the index after it.
_Literal _readString(String s, int open, {required bool isRaw}) {
  final quote = s[open];
  final triple = s.startsWith(quote * 3, open);
  final delimiter = triple ? quote * 3 : quote;
  var i = open + delimiter.length;
  final bodyStart = i;
  while (i < s.length) {
    if (!isRaw && s[i] == r'\') {
      i += 2;
    } else if (!isRaw && s.startsWith(r'${', i)) {
      i = _skipInterpolation(s, i + 2);
    } else if (s.startsWith(delimiter, i)) {
      return (
        start: open,
        end: i + delimiter.length,
        body: s.substring(bodyStart, i),
      );
    } else if (!triple && s[i] == '\n') {
      break; // Unterminated: stop at the line end.
    } else {
      i++;
    }
  }
  final end = i > s.length ? s.length : i;
  return (start: open, end: end, body: s.substring(bodyStart, end));
}

/// Skips a `${ ... }` expression body (strings inside may contain braces).
int _skipInterpolation(String s, int from) {
  var depth = 1;
  var i = from;
  while (i < s.length && depth > 0) {
    final c = s[i];
    if (c == "'" || c == '"') {
      i = _readString(s, i, isRaw: false).end;
      continue;
    }
    if (c == '{') depth++;
    if (c == '}') depth--;
    i++;
  }
  return i;
}

bool _isWord(String c) => RegExp(r'\w').hasMatch(c);
