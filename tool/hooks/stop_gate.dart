// Stop hook: Claude may not finish a turn while changed Dart code has analyzer
// errors or failing related tests.
//
// Scope is deliberately narrow to stay fast and to ignore pre-existing issues:
// - files changed vs origin/main (committed, staged, unstaged, untracked)
// - `flutter analyze` (errors only) on those files, per package
// - tests: changed *_test.dart files + the mirror test of each changed lib file
//
// Exit 2 + stderr blocks the stop and shows Claude the failure. After
// [_maxBlocks] consecutive blocks it lets the turn end to avoid loops.
import 'dart:convert';
import 'dart:io';

const _maxBlocks = 3;
const _counterFile = '.claude/.stop_gate_count';

Future<void> main() async {
  final root = Directory.current.path;
  if (!await _hasTool('flutter')) exit(0);

  final changed = await _changedDartFiles();
  if (changed.isEmpty) {
    _resetCounter();
    exit(0);
  }

  final failures = <String>[];
  for (final entry in _groupByPackage(changed, root).entries) {
    final pkg = entry.key;
    final files = entry.value;
    final rel = files.map((f) => _relative(f, pkg)).toList();

    final analyze = await _run(
      'flutter',
      ['analyze', '--no-pub', '--no-fatal-infos', '--no-fatal-warnings', ...rel],
      pkg,
    );
    if (analyze.exitCode != 0) {
      failures.add('ANALYZE ${_relative(pkg, root)}\n${_tail(analyze)}');
    }

    final tests = _relatedTests(files, pkg);
    if (tests.isEmpty) continue;
    final isFlutter = File('$pkg/pubspec.yaml')
        .readAsStringSync()
        .contains(RegExp(r'sdk:\s*flutter'));
    final test = await _run(
      isFlutter ? 'flutter' : 'dart',
      ['test', ...tests.map((t) => _relative(t, pkg))],
      pkg,
    );
    if (test.exitCode != 0) {
      failures.add('TEST ${_relative(pkg, root)}\n${_tail(test)}');
    }
  }

  if (failures.isEmpty) {
    _resetCounter();
    exit(0);
  }

  final blocks = _bumpCounter();
  if (blocks > _maxBlocks) {
    _resetCounter();
    stderr.writeln('stop_gate: still failing after $_maxBlocks attempts; '
        'letting the turn end. Tell the user exactly what is still broken.');
    exit(0);
  }
  stderr.writeln('stop_gate: fix these before finishing '
      '(attempt $blocks/$_maxBlocks):\n\n${failures.join('\n\n')}');
  exit(2);
}

Future<List<String>> _changedDartFiles() async {
  final sets = <String>{};
  Future<void> collect(List<String> args) async {
    final r = await _run('git', args, Directory.current.path);
    if (r.exitCode == 0) {
      sets.addAll(LineSplitter.split(r.stdout as String).where((l) => l.isNotEmpty));
    }
  }

  final base = await _run('git', ['merge-base', 'HEAD', 'origin/main'],
      Directory.current.path);
  if (base.exitCode == 0) {
    await collect(['diff', '--name-only', (base.stdout as String).trim()]);
  }
  await collect(['diff', '--name-only', 'HEAD']);
  await collect(['ls-files', '--others', '--exclude-standard']);

  return sets
      .where((f) => f.endsWith('.dart'))
      .where((f) => !f.endsWith('.g.dart') && !f.endsWith('.freezed.dart'))
      .map((f) => File(f).absolute.path)
      .where((f) => File(f).existsSync())
      .toList();
}

Map<String, List<String>> _groupByPackage(List<String> files, String root) {
  final out = <String, List<String>>{};
  for (final f in files) {
    var dir = File(f).parent;
    while (!File('${dir.path}/pubspec.yaml').existsSync() &&
        dir.path.length > root.length) {
      dir = dir.parent;
    }
    if (!File('${dir.path}/pubspec.yaml').existsSync()) continue;
    out.putIfAbsent(dir.path, () => []).add(f);
  }
  return out;
}

Set<String> _relatedTests(List<String> files, String pkg) {
  final tests = <String>{};
  for (final f in files) {
    final rel = _relative(f, pkg).replaceAll('\\', '/');
    if (rel.startsWith('test/') && rel.endsWith('_test.dart')) {
      tests.add(f);
    } else if (rel.startsWith('lib/')) {
      final stem = rel
          .substring(4)
          .replaceFirst(RegExp(r'^src/'), '')
          .replaceFirst(RegExp(r'\.dart$'), '_test.dart');
      for (final candidate in ['$pkg/test/$stem', '$pkg/test/src/$stem']) {
        if (File(candidate).existsSync()) tests.add(candidate);
      }
    }
  }
  return tests;
}

Future<bool> _hasTool(String name) async {
  try {
    final r = await Process.run(name, ['--version'], runInShell: true);
    return r.exitCode == 0;
  } catch (_) {
    return false;
  }
}

Future<ProcessResult> _run(String exe, List<String> args, String cwd) =>
    Process.run(exe, args, workingDirectory: cwd, runInShell: true);

String _relative(String path, String from) {
  final p = path.replaceAll('\\', '/');
  final f = from.replaceAll('\\', '/');
  return p.startsWith('$f/') ? p.substring(f.length + 1) : p;
}

String _tail(ProcessResult r, [int lines = 40]) {
  final all = '${r.stdout}\n${r.stderr}'.trim().split('\n');
  return all.length <= lines ? all.join('\n') : all.sublist(all.length - lines).join('\n');
}

int _bumpCounter() {
  final f = File(_counterFile);
  final n = (f.existsSync() ? int.tryParse(f.readAsStringSync().trim()) : 0) ?? 0;
  f
    ..createSync(recursive: true)
    ..writeAsStringSync('${n + 1}');
  return n + 1;
}

void _resetCounter() {
  final f = File(_counterFile);
  if (f.existsSync()) f.deleteSync();
}
