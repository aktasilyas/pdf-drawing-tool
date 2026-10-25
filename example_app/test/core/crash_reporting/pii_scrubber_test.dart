import 'package:flutter_test/flutter_test.dart';

import 'package:example_app/core/crash_reporting/pii_scrubber.dart';

void main() {
  group('scrubPii', () {
    test('removes Android absolute paths', () {
      final out = scrubPii(
        'Failed: /data/user/0/com.elya/files/docs/report.pdf (errno 2)',
      );
      expect(out, isNot(contains('/data/user')));
      expect(out, isNot(contains('report.pdf')));
      expect(out, contains('<path>'));
      expect(out, contains('(errno 2)'));
    });

    test('removes external storage paths', () {
      final out = scrubPii('Cannot read /storage/emulated/0/x.pdf');
      expect(out, 'Cannot read <path>');
    });

    test('removes Windows paths', () {
      final out = scrubPii(r'Cannot read C:\Users\a\b.pdf');
      expect(out, 'Cannot read <path>');
    });

    test('removes content and file URIs', () {
      expect(scrubPii('open content://media/external/42'), 'open <uri>');
      expect(scrubPii('open file:///sdcard/a%20b.pdf'), 'open <uri>');
    });

    test('redacts quoted titles including spaces', () {
      final out = scrubPii(
        "Note 'My Secret Diary' and \"Tax 2024\" failed",
      );
      expect(out, "Note '<redacted>' and \"<redacted>\" failed");
    });

    test('redacts paths with spaces inside quotes', () {
      final out = scrubPii("No file '/data/user/0/app/My Note.pdf'");
      expect(out, "No file '<redacted>'");
    });

    test('removes emails', () {
      expect(scrubPii('user ada.l@example.com failed'), 'user <email> failed');
    });

    test('keeps package and dart frames intact', () {
      const frame = '#0 main (package:example_app/x.dart:12:3)\n'
          '#1 _run (dart:async/future.dart:10:5)';
      expect(scrubPii(frame), frame);
    });

    test('is idempotent', () {
      const input = "a /data/user/0/x/y.pdf 'T' b@c.de content://m/1 "
          r'C:\u\v.txt "Q"';
      final once = scrubPii(input);
      expect(scrubPii(once), once);
    });

    test('truncates long messages', () {
      final out = scrubPii('a' * 5000);
      expect(out.length, kMaxScrubbedLength);
    });

    test('handles empty input', () {
      expect(scrubPii(''), '');
    });
  });

  group('scrubStackTrace', () {
    test('removes paths and URIs but keeps package frames', () {
      final stack = StackTrace.fromString(
        '#0 read (file:///data/user/0/app/files/a.dart:1:2)\n'
        '#1 main (package:example_app/main.dart:5:6)\n'
        "build_id: 'abc123'\n",
      );
      final out = scrubStackTrace(stack).toString();
      expect(out, isNot(contains('/data/user')));
      expect(out, contains('package:example_app/main.dart:5:6'));
      expect(out, contains("build_id: 'abc123'"));
    });
  });
}
