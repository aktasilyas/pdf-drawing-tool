import 'dart:io';

import 'package:drawing_core/drawing_core.dart' as core;
import 'package:drawing_ui/drawing_ui.dart';
import 'package:drawing_ui/src/providers/clipboard_file_refs_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

core.Page _page(
    {core.PageBackground? background, List<String> images = const []}) {
  return core.Page(
    id: 'p',
    index: 0,
    size: core.PageSize.a4Portrait,
    background: background ?? core.PageBackground.blank,
    layers: [
      core.Layer.empty('L').copyWith(images: [
        for (final path in images)
          core.ImageElement.create(
              filePath: path, x: 0, y: 0, width: 10, height: 10),
      ]),
    ],
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );
}

void main() {
  test('is empty with nothing copied', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    expect(c.read(clipboardFileRefsProvider), isEmpty);
  });

  test('collects page background and image paths, follows replacement', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    c.read(copiedPageProvider.notifier).state = _page(
      background: const core.PageBackground(
        type: core.BackgroundType.pdf,
        pdfFilePath: 'pdfs/a.pdf',
      ),
      images: ['elyanotes_images/x.png'],
    );
    expect(c.read(clipboardFileRefsProvider),
        {'pdfs/a.pdf', 'elyanotes_images/x.png'});

    c.read(copiedPageProvider.notifier).state = null;
    expect(c.read(clipboardFileRefsProvider), isEmpty);
  });

  test('collects selection clipboard images', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    c.read(selectionClipboardProvider.notifier).state = SelectionClipboardData(
      strokes: const [],
      shapes: const [],
      images: [
        core.ImageElement.create(
            filePath: 'elyanotes_images/y.png',
            x: 0,
            y: 0,
            width: 1,
            height: 1),
      ],
      originalBounds:
          const core.BoundingBox(left: 0, top: 0, right: 1, bottom: 1),
    );
    expect(c.read(clipboardFileRefsProvider), {'elyanotes_images/y.png'});
  });

  test('allFilesExist checks the resolved path', () {
    final dir = Directory.systemTemp.createTempSync('refs');
    addTearDown(() => dir.deleteSync(recursive: true));
    File('${dir.path}/a.bin').writeAsStringSync('x');
    final resolver = core.PdfPathResolver(dir.path);
    expect(allFilesExist(['a.bin'], resolver), isTrue);
    expect(allFilesExist(['a.bin', 'gone.bin'], resolver), isFalse);
    expect(allFilesExist(const [], resolver), isTrue);
  });
}
