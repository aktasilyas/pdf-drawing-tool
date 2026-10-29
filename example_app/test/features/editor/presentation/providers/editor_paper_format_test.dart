import 'package:dartz/dartz.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/drawing_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:example_app/core/errors/failures.dart';
import 'package:example_app/features/documents/domain/entities/document_info.dart';
import 'package:example_app/features/documents/domain/repositories/document_repository.dart';
import 'package:example_app/features/documents/presentation/providers/documents_provider.dart';
import 'package:example_app/features/editor/editor.dart';

class _MockDocumentRepository extends Mock implements DocumentRepository {}

// PDF export gets the open notebook's paper size (#454).
void main() {
  late _MockDocumentRepository repo;
  late ProviderContainer container;
  late DrawingDocument doc;

  DocumentInfo info(double widthMm, double heightMm) => DocumentInfo(
        id: doc.id,
        title: 'Notes',
        templateId: 'blank',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
        paperWidthMm: widthMm,
        paperHeightMm: heightMm,
      );

  PDFPageFormat? format() => container.read(exportPageFormatProvider);

  setUp(() {
    repo = _MockDocumentRepository();
    container = ProviderContainer(overrides: [
      documentRepositoryProvider.overrideWithValue(repo),
    ]);
    doc = DrawingDocument.emptyMultiPage('Notes');
    startEditorSession(container.read, doc);
  });

  tearDown(() => container.dispose());

  test('an A5 notebook exports at 148 x 210 mm', () async {
    when(() => repo.getDocument(doc.id))
        .thenAnswer((_) async => Right(info(148, 210)));

    await loadExportPaperFormat(container.read, doc.id);

    expect(format()?.width, closeTo(419.53, 0.01));
    expect(format()?.height, closeTo(595.28, 0.01));
  });

  test('a landscape notebook keeps its stored, swapped size', () async {
    when(() => repo.getDocument(doc.id))
        .thenAnswer((_) async => Right(info(297, 210)));

    await loadExportPaperFormat(container.read, doc.id);

    expect(format()?.width, closeTo(841.89, 0.01));
    expect(format()?.height, closeTo(595.28, 0.01));
  });

  test('a result for a notebook that is no longer open is dropped', () async {
    when(() => repo.getDocument('other'))
        .thenAnswer((_) async => Right(info(148, 210)));

    await loadExportPaperFormat(container.read, 'other');

    expect(format(), isNull);
  });

  test('a failed lookup clears the previous notebook size', () async {
    container.read(exportPageFormatProvider.notifier).state = PDFPageFormat.a4;
    when(() => repo.getDocument(doc.id))
        .thenAnswer((_) async => const Left(CacheFailure('gone')));

    await loadExportPaperFormat(container.read, doc.id);

    expect(format(), isNull);
  });
}
