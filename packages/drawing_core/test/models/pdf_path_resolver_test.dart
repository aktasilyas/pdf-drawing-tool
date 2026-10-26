import 'package:drawing_core/drawing_core.dart';
import 'package:test/test.dart';

void main() {
  const resolver = PdfPathResolver('/data/user/0/new.pkg/app_flutter');

  group('PdfPathResolver.toStored', () {
    test('stores files under <root>/pdfs relative', () {
      expect(
        resolver.toStored('/data/user/0/new.pkg/app_flutter/pdfs/a.pdf'),
        'pdfs/a.pdf',
      );
    });

    test('ignores a trailing separator on the root', () {
      const r = PdfPathResolver('/root/');
      expect(r.toStored('/root/pdfs/a.pdf'), 'pdfs/a.pdf');
    });

    test('leaves paths outside <root>/pdfs unchanged', () {
      expect(resolver.toStored('/tmp/a.pdf'), '/tmp/a.pdf');
      expect(
        resolver.toStored('/data/user/0/new.pkg/app_flutter/pdfs/x/a.pdf'),
        '/data/user/0/new.pkg/app_flutter/pdfs/x/a.pdf',
      );
    });

    test('handles Windows separators', () {
      const win = PdfPathResolver(r'C:\Users\me\Documents');
      expect(win.toStored(r'C:\Users\me\Documents\pdfs\a.pdf'), 'pdfs/a.pdf');
    });

    test('passthrough returns the input', () {
      expect(PdfPathResolver.passthrough.toStored('/x/pdfs/a.pdf'),
          '/x/pdfs/a.pdf');
    });
  });

  group('PdfPathResolver.resolve', () {
    test('joins a relative path to the root', () {
      expect(
        resolver.resolve('pdfs/a.pdf'),
        '/data/user/0/new.pkg/app_flutter/pdfs/a.pdf',
      );
    });

    test('re-roots a legacy absolute path by its pdfs/<name> suffix', () {
      expect(
        resolver.resolve('/data/user/0/old.pkg/app_flutter/pdfs/a.pdf'),
        '/data/user/0/new.pkg/app_flutter/pdfs/a.pdf',
      );
    });

    test('re-roots a legacy Windows drive path', () {
      expect(
        resolver.resolve(r'C:\Old\Docs\pdfs\a.pdf'),
        '/data/user/0/new.pkg/app_flutter/pdfs/a.pdf',
      );
    });

    test('leaves other absolute paths unchanged', () {
      expect(resolver.resolve('/tmp/a.pdf'), '/tmp/a.pdf');
      expect(resolver.resolve('/tmp/other/a.pdf'), '/tmp/other/a.pdf');
    });

    test('does not escape the root through ..', () {
      expect(resolver.resolve('../a.pdf'), '../a.pdf');
    });

    test('passthrough returns the input', () {
      expect(PdfPathResolver.passthrough.resolve('pdfs/a.pdf'), 'pdfs/a.pdf');
    });

    test('toStored then resolve round-trips', () {
      const abs = '/data/user/0/new.pkg/app_flutter/pdfs/a.pdf';
      expect(resolver.resolve(resolver.toStored(abs)), abs);
    });
  });
}
