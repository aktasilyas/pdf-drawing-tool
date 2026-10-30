import 'dart:convert';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:drawing_core/drawing_core.dart' as core;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:example_app/core/core.dart';
import 'package:example_app/core/theme/index.dart';
import 'package:example_app/features/documents/domain/entities/document_info.dart';
import 'package:example_app/features/documents/domain/repositories/document_repository.dart';
import 'package:example_app/features/documents/presentation/providers/document_list_providers.dart';
import 'package:example_app/features/documents/presentation/widgets/document_preview.dart';
import 'package:example_app/features/documents/presentation/widgets/library_page_thumbnail.dart';

class _MockRepo extends Mock implements DocumentRepository {}

/// 1x1 transparent PNG.
final Uint8List _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA'
  '60e6kgAAAABJRU5ErkJggg==',
);

DocumentInfo _doc({String? thumbnailPath}) => DocumentInfo(
      id: 'doc-1',
      title: 'Doc',
      templateId: 'blank',
      createdAt: DateTime(2026, 10, 1),
      updatedAt: DateTime(2026, 10, 1),
      hasCover: false,
      documentType: core.DocumentType.pdf,
      thumbnailPath: thumbnailPath,
    );

Widget _app(_MockRepo repo, DocumentInfo doc, ImageProvider image) {
  return ProviderScope(
    overrides: [
      documentRepositoryProvider.overrideWithValue(repo),
      libraryThumbnailImageProvider.overrideWithValue((_) => image),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 110,
            height: 160,
            child: LibraryPageThumbnail(document: doc),
          ),
        ),
      ),
    ),
  );
}

void main() {
  late _MockRepo repo;

  setUp(() {
    repo = _MockRepo();
    when(() => repo.getFirstPageBackground(any())).thenAnswer(
      (_) async => const Right<Failure, core.PageBackground?>(null),
    );
  });

  testWidgets('thumbnail path: image shown, document content never read',
      (tester) async {
    await tester.pumpWidget(
      _app(repo, _doc(thumbnailPath: 'thumbs/doc-1.png'), MemoryImage(_png)),
    );
    await tester.pump();

    expect(find.byType(Image), findsOneWidget);
    expect(find.byType(DocumentPreview), findsNothing);
    verifyNever(() => repo.getFirstPageBackground(any()));
    verifyNever(() => repo.getDocumentContent(any()));
    verifyNever(() => repo.getDrawingDocument(any()));
  });

  testWidgets('no thumbnail path: first page background is read once',
      (tester) async {
    await tester.pumpWidget(_app(repo, _doc(), MemoryImage(_png)));
    await tester.pump();

    expect(find.byType(DocumentPreview), findsOneWidget);
    verify(() => repo.getFirstPageBackground('doc-1')).called(1);
  });

  testWidgets('undecodable thumbnail falls back to the document preview',
      (tester) async {
    final bad = MemoryImage(Uint8List.fromList(const [1, 2, 3, 4]));
    await tester.pumpWidget(
      _app(repo, _doc(thumbnailPath: 'thumbs/doc-1.png'), bad),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pump();

    expect(find.byType(DocumentPreview), findsOneWidget);
  });
}
