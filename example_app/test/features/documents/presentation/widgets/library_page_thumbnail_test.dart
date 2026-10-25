import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawing_ui/drawing_ui.dart' show CoverGeometry;

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/features/documents/domain/entities/document_info.dart';
import 'package:example_app/features/documents/presentation/widgets/library_page_thumbnail.dart';

DocumentInfo _doc({bool isPortrait = true}) => DocumentInfo(
      id: 'd',
      title: 'Sunum',
      templateId: 'thin_lined',
      createdAt: DateTime(2026, 10, 1),
      updatedAt: DateTime(2026, 10, 1),
      hasCover: false,
      isPortrait: isPortrait,
    );

Future<void> _pump(WidgetTester tester, DocumentInfo doc) {
  return tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 151,
          height: 201.6,
          child: LibraryPageThumbnail(document: doc),
        ),
      ),
    ),
  );
}

void main() {
  final board = CoverGeometry.of(const Size(151, 201.6)).cover;

  testWidgets('landscape page is wider than tall and sits on the board bottom',
      (tester) async {
    await _pump(tester, _doc(isPortrait: false));

    final page = tester.getRect(find.byKey(LibraryPageThumbnail.pageKey));
    final root = tester.getRect(find.byType(LibraryPageThumbnail));
    expect(page.width, greaterThan(page.height));
    expect(page.bottom, closeTo(root.top + board.bottom, 0.01));
    expect(page.center.dx, closeTo(root.left + board.center.dx, 0.01));
  });

  testWidgets('portrait page is taller than wide and sits on the board bottom',
      (tester) async {
    await _pump(tester, _doc());

    final page = tester.getRect(find.byKey(LibraryPageThumbnail.pageKey));
    final root = tester.getRect(find.byType(LibraryPageThumbnail));
    expect(page.height, greaterThan(page.width));
    expect(page.bottom, closeTo(root.top + board.bottom, 0.01));
    expect(page.right, lessThanOrEqualTo(root.left + board.right + 0.01));
  });

  test('pageRect is bottom-centred in the board for the given box', () {
    const box = Size(151, 201.6);
    final page = LibraryPageThumbnail.pageRect(_doc(), box);
    expect(page.bottom, closeTo(board.bottom, 0.01));
    expect(page.center.dx, closeTo(board.center.dx, 0.01));
    expect(page.height, greaterThan(page.width));
  });
}
