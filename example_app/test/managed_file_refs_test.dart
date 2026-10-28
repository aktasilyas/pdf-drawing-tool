import 'package:flutter_test/flutter_test.dart';
import 'package:example_app/features/documents/data/datasources/managed_file_paths.dart';

void main() {
  test('finds relative paths in JSON', () {
    expect(
      managedFileRefsIn(
        '{"filePath":"elyanotes_images/a.png","p":"pdfs/b.pdf"}',
      ),
      {'elyanotes_images/a.png', 'pdfs/b.pdf'},
    );
  });

  test('finds absolute Unix paths by their parent directory', () {
    expect(
      managedFileRefsIn('"/data/user/0/app/files/elyanotes_images/a b.png"'),
      {'elyanotes_images/a b.png'},
    );
  });

  test('finds JSON-escaped Windows paths', () {
    expect(
      managedFileRefsIn(r'"C:\\Users\\me\\Documents\\pdfs\\doc.pdf"'),
      {'pdfs/doc.pdf'},
    );
  });

  test('a bare path at the start of the text matches', () {
    expect(managedFileRefsIn('pdfs/x.pdf'), {'pdfs/x.pdf'});
  });

  test('ignores other directories and look-alike names', () {
    expect(managedFileRefsIn('"/sdcard/Download/a.png"'), isEmpty);
    expect(managedFileRefsIn('"mypdfs/a.pdf"'), isEmpty);
    expect(managedFileRefsIn('"pdfs"'), isEmpty);
    expect(managedFileRefsIn(''), isEmpty);
  });
}
