import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:example_app/core/core.dart';
import 'package:example_app/features/documents/domain/entities/document_info.dart';
import 'package:example_app/features/documents/domain/repositories/document_repository.dart';
import 'package:example_app/features/documents/presentation/providers/document_list_providers.dart';
import 'package:example_app/features/documents/presentation/widgets/document_preview.dart';

class _MockRepository extends Mock implements DocumentRepository {}

/// 1x1 transparent PNG.
final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA'
  '60e6kgAAAABJRU5ErkJggg==',
);

DocumentInfo _doc(DateTime updatedAt) => DocumentInfo(
      id: 'img',
      title: 'Görsel',
      templateId: 'blank',
      createdAt: DateTime(2026, 10, 1),
      updatedAt: updatedAt,
      hasCover: false,
      documentType: DocumentType.image,
    );

void main() {
  late _MockRepository repository;

  setUp(() => repository = _MockRepository());

  Future<void> pump(WidgetTester tester, DocumentInfo doc) {
    return tester.pumpWidget(
      ProviderScope(
        overrides: [documentRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          home: SizedBox(
            width: 120,
            height: 160,
            // A fresh widget instance per pump, like a library rebuild.
            child: DocumentPreview(document: doc.copyWith()),
          ),
        ),
      ),
    );
  }

  void answer(Either<Failure, PageBackground?> result) {
    when(() => repository.getFirstPageBackground(any()))
        .thenAnswer((_) async => result);
  }

  testWidgets('a rebuild reuses the background; a new updatedAt reloads',
      (tester) async {
    answer(Right(PageBackground.pdf(pdfData: _png, pageIndex: 0)));
    final first = DateTime(2026, 10, 2);

    await pump(tester, _doc(first));
    await tester.pumpAndSettle();
    await pump(tester, _doc(first));
    await tester.pumpAndSettle();
    verify(() => repository.getFirstPageBackground('img')).called(1);
    expect(find.byType(Image), findsOneWidget);

    await pump(tester, _doc(DateTime(2026, 10, 3)));
    await tester.pumpAndSettle();
    verify(() => repository.getFirstPageBackground('img')).called(1);
  });

  testWidgets('a corrupt document shows plain paper, no spinner',
      (tester) async {
    answer(const Left(CacheFailure('Document corrupted')));

    await pump(tester, _doc(DateTime(2026, 10, 2)));
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('a document without content shows plain paper', (tester) async {
    answer(const Right(null));

    await pump(tester, _doc(DateTime(2026, 10, 2)));
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(Image), findsNothing);
  });
}
