import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart' show DocumentType;

import 'package:example_app/core/config/feature_flags.dart';
import 'package:example_app/core/theme/index.dart';
import 'package:example_app/features/documents/domain/entities/document_info.dart';
import 'package:example_app/features/documents/domain/entities/folder.dart';
import 'package:example_app/features/documents/presentation/providers/documents_provider.dart';
import 'package:example_app/features/documents/presentation/providers/folders_provider.dart';
import 'package:example_app/features/premium/premium.dart';

/// Library fixtures (docs/specs/51-library-screen.md §11). Dates are fixed so
/// renders are deterministic.

Folder _folder(
  String id,
  String name,
  int colorIndex,
  int documents, {
  String? parentId,
  bool favorite = false,
}) =>
    Folder(
      id: id,
      name: name,
      parentId: parentId,
      colorValue: AppColors.folderColors[colorIndex].toARGB32(),
      createdAt: DateTime(2026, 9, 1),
      documentCount: documents,
      isFavorite: favorite,
    );

final List<Folder> libraryFolders = [
  _folder('f-ders', 'Ders Notları', 9, 12),
  _folder('f-projeler', 'Projeler', 5, 4, favorite: true),
  _folder('f-okuma', 'Okuma', 11, 0),
  _folder('f-biyoloji', 'Biyoloji', 9, 3, parentId: 'f-ders'),
];

/// Document [n] (1-based) updated `n - 1` days before 2026-10-21.
DocumentInfo _doc(
  int n,
  String title,
  int pages, {
  String? coverId,
  String templateId = 'blank',
  String paperColor = 'Sarı kağıt',
  DocumentType type = DocumentType.notebook,
  bool isPortrait = true,
  bool favorite = false,
}) {
  final updated = DateTime(2026, 10, 21).subtract(Duration(days: n - 1));
  return DocumentInfo(
    id: 'doc-$n',
    title: title,
    templateId: templateId,
    createdAt: updated,
    updatedAt: updated,
    pageCount: pages,
    isFavorite: favorite,
    paperColor: paperColor,
    isPortrait: isPortrait,
    documentType: type,
    coverId: coverId,
    hasCover: coverId != null,
  );
}

final List<DocumentInfo> libraryRootDocuments = [
  _doc(1, 'Biyoloji', 24, coverId: 'linen_sage', favorite: true),
  _doc(2, 'Toplantı Notları', 6, coverId: 'leather_navy'),
  _doc(3, 'Günlük', 31, coverId: 'kraft_natural'),
  _doc(4, 'Matematik Ödev 3', 3,
      templateId: 'small_grid', paperColor: 'Krem kağıt'),
  _doc(5, 'Çok uzun bir defter adı kısaltma testi için', 1,
      coverId: 'leather_oxblood'),
  _doc(6, 'Beyaz Tahta', 1, type: DocumentType.whiteboard),
  _doc(7, 'Sunum Taslağı', 2, templateId: 'thin_lined', isPortrait: false),
  _doc(8, 'Fizik', 12, coverId: 'felt_mustard', favorite: true),
];

/// Synchronous provider overrides so [DocumentsScreen] pumps without GetIt
/// or Drift.
List<Override> libraryOverrides({bool empty = false, bool selection = false}) {
  final folders = empty ? <Folder>[] : libraryFolders;
  final docs = empty ? <DocumentInfo>[] : libraryRootDocuments;
  return [
    foldersProvider.overrideWith((ref) => folders),
    documentsProvider.overrideWith(
      (ref, folderId) => folderId == null ? docs : const <DocumentInfo>[],
    ),
    favoriteDocumentsProvider
        .overrideWith((ref) => docs.where((d) => d.isFavorite).toList()),
    favoriteFoldersProvider
        .overrideWith((ref) => folders.where((f) => f.isFavorite).toList()),
    totalDocumentCountProvider.overrideWith((ref) => docs.length),
    featureFlagsProvider.overrideWithValue(FeatureFlags.allOff),
    if (selection) ...[
      selectionModeProvider.overrideWith((ref) => true),
      selectedDocumentsProvider.overrideWith((ref) => {'doc-1', 'doc-4'}),
      selectedFoldersProvider.overrideWith((ref) => {'f-projeler'}),
    ],
  ];
}
