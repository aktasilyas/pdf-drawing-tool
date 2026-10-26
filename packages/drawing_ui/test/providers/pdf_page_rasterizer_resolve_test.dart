import 'dart:typed_data';

import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/providers/pdf_page_cache.dart';
import 'package:drawing_ui/src/providers/pdf_path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ProviderContainer containerWith(
    PdfPathResolver resolver,
    List<String> seen,
  ) {
    final container = ProviderContainer(overrides: [
      pdfPathResolverProvider.overrideWithValue(resolver),
      pdfFileRasterizerProvider.overrideWithValue((path, page, quality) async {
        seen.add(path);
        return Uint8List.fromList([1]);
      }),
    ]);
    addTearDown(container.dispose);
    return container;
  }

  test('rasterizer receives the path resolved against the documents root',
      () async {
    final seen = <String>[];
    final container = containerWith(const PdfPathResolver('/docs'), seen);

    await container.read(pdfPageRasterizerProvider)('pdfs/x.pdf', 1, 1.5);

    expect(seen, ['/docs/pdfs/x.pdf']);
  });

  test('a legacy absolute path is re-rooted before rasterising', () async {
    final seen = <String>[];
    final container = containerWith(const PdfPathResolver('/docs'), seen);

    await container.read(pdfPageRasterizerProvider)(
      '/data/user/0/old.pkg/files/pdfs/x.pdf',
      2,
      1.5,
    );

    expect(seen, ['/docs/pdfs/x.pdf']);
  });

  test('the default resolver leaves the path unchanged', () async {
    final seen = <String>[];
    final container = containerWith(PdfPathResolver.passthrough, seen);

    await container.read(pdfPageRasterizerProvider)('/tmp/x.pdf', 1, 1.5);

    expect(seen, ['/tmp/x.pdf']);
  });
}
