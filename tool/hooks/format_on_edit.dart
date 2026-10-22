// PostToolUse hook: formats a Dart file right after Claude edits it.
// Reads the hook payload from stdin; always exits 0 so it never blocks work.
import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  try {
    final payload = jsonDecode(await stdin.transform(utf8.decoder).join());
    final input = (payload is Map ? payload['tool_input'] : null);
    final path = input is Map ? input['file_path'] as String? : null;
    if (path == null || !path.endsWith('.dart')) return;
    if (path.endsWith('.g.dart') || path.endsWith('.freezed.dart')) return;
    if (!File(path).existsSync()) return;
    await Process.run('dart', ['format', path], runInShell: true);
  } catch (_) {
    // Formatting is best-effort; never fail the edit.
  }
  exit(0);
}
