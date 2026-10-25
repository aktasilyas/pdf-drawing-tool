/// Pure helpers that strip personal data from crash report text.
library;

/// Maximum length of a scrubbed message.
const int kMaxScrubbedLength = 1024;

final RegExp _uriPattern = RegExp(r'''(?:file|content|https?)://[^\s'"]*''');
final RegExp _singleQuoted = RegExp(r"'[^'\n]*'");
final RegExp _doubleQuoted = RegExp(r'"[^"\n]*"');
final RegExp _windowsPath = RegExp(r'''(?<!\w)[A-Za-z]:[\\/][^\s'"]*''');
final RegExp _posixPath = RegExp(r'''(?<![\w.:])(?:/[^\s/'"()<>,;]+){2,}''');
final RegExp _email = RegExp(r'[\w.+-]+@[\w-]+(?:\.[\w-]+)+');
final RegExp _fileName = RegExp(
  r'(?<![\w.:/<])[\w-]+(?:\.[\w-]+)*'
  r'\.(?:pdf|png|jpe?g|gif|webp|heic|json|db|sqlite|txt|elya)\b',
  caseSensitive: false,
);
final RegExp _sqlParameters = RegExp(r'parameters:[^\n]*');

String _scrubPaths(String input) {
  return input
      .replaceAll(_uriPattern, '<uri>')
      .replaceAll(_windowsPath, '<path>')
      .replaceAll(_posixPath, '<path>');
}

/// Removes URIs, quoted strings (often note or file titles), absolute file
/// paths, bare file names, email addresses and SQL parameter lists from
/// [input], then truncates it.
///
/// Idempotent. `package:` and `dart:` frames are left intact.
String scrubPii(String input) {
  var out = _scrubPaths(input);
  out = out
      .replaceAll(_singleQuoted, "'<redacted>'")
      .replaceAll(_doubleQuoted, '"<redacted>"');
  out = out
      .replaceAll(_email, '<email>')
      .replaceAll(_fileName, '<file>')
      .replaceAll(_sqlParameters, 'parameters: <redacted>');
  if (out.length > kMaxScrubbedLength) {
    out = out.substring(0, kMaxScrubbedLength);
  }
  return out;
}

/// Scrubs URIs and absolute paths from [stack] only.
///
/// Quoted text is kept because native stack headers (for example
/// `build_id: '...'`) are needed to symbolize the trace.
StackTrace scrubStackTrace(StackTrace stack) {
  return StackTrace.fromString(_scrubPaths(stack.toString()));
}
