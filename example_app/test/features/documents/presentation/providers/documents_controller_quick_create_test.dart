import 'package:dartz/dartz.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:example_app/features/documents/domain/entities/paper_color.dart';

import 'documents_controller_harness.dart';

void main() {
  setUpAll(registerDocumentsFallbacks);

  late DocumentsHarness h;

  setUp(() => h = DocumentsHarness());
  tearDown(() => h.dispose());

  void stubCreate(Either<dynamic, dynamic> result) {
    when(() => h.repo.createDocument(
          title: any(named: 'title'),
          templateId: any(named: 'templateId'),
          folderId: any(named: 'folderId'),
          paperColor: any(named: 'paperColor'),
          isPortrait: any(named: 'isPortrait'),
          documentType: any(named: 'documentType'),
          coverId: any(named: 'coverId'),
          hasCover: any(named: 'hasCover'),
          paperWidthMm: any(named: 'paperWidthMm'),
          paperHeightMm: any(named: 'paperHeightMm'),
        )).thenAnswer((_) async => result.map((_) => testDocument).leftMap(
        (_) => failure));
  }

  void verifyCreate({
    required String title,
    required String templateId,
    required DocumentType type,
    String? folderId,
  }) {
    verify(() => h.repo.createDocument(
          title: title,
          templateId: templateId,
          folderId: folderId,
          paperColor: PaperColor.white.storageKey,
          isPortrait: true,
          documentType: type,
          coverId: null,
          hasCover: true,
          paperWidthMm: 210.0,
          paperHeightMm: 297.0,
        )).called(1);
  }

  group('createQuickNote', () {
    test('creates a thin-lined white quick note in the folder', () async {
      stubCreate(const Right(null));
      final id = await h.controller.createQuickNote(title: 'Q', folderId: 'f1');
      expect(id, testDocument.id);
      verifyCreate(
        title: 'Q',
        templateId: 'thin_lined',
        type: DocumentType.quickNote,
        folderId: 'f1',
      );
    });

    test('failure returns null', () async {
      stubCreate(const Left(failure));
      expect(await h.controller.createQuickNote(title: 'Q'), isNull);
      expect(h.state, isA<AsyncError<void>>());
    });
  });

  group('createWhiteboard', () {
    test('creates a blank white whiteboard in the folder', () async {
      stubCreate(const Right(null));
      final id = await h.controller.createWhiteboard(title: 'W', folderId: 'f2');
      expect(id, testDocument.id);
      verifyCreate(
        title: 'W',
        templateId: 'blank',
        type: DocumentType.whiteboard,
        folderId: 'f2',
      );
    });

    test('failure returns null', () async {
      stubCreate(const Left(failure));
      expect(await h.controller.createWhiteboard(title: 'W'), isNull);
      expect(h.state, isA<AsyncError<void>>());
    });
  });
}
