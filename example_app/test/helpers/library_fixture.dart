import 'package:drawing_core/drawing_core.dart' show PdfPathResolver;
import 'package:drift/drift.dart' show QueryExecutor;
import 'package:drift/native.dart';
import 'package:example_app/core/core.dart';
import 'package:example_app/features/documents/documents.dart';

/// Real repositories over one Drift database (in memory unless [executor]).
class LibraryFixture {
  final AppDatabase db;
  late final DocumentLocalDatasourceImpl documentDs;
  late final FolderLocalDatasourceImpl folderDs;
  late final TrashedPageLocalDatasourceImpl trashDs;
  late final DocumentRepositoryImpl documents;
  late final FolderRepositoryImpl folders;
  late final PageTrashRepositoryImpl pageTrash;

  LibraryFixture([
    QueryExecutor? executor,
    PdfPathResolver pdfPaths = PdfPathResolver.passthrough,
  ]) : db = AppDatabase(executor ?? NativeDatabase.memory()) {
    final runner = DriftTransactionRunner(db);
    documentDs = DocumentLocalDatasourceImpl(db, pdfPaths);
    folderDs = FolderLocalDatasourceImpl(db);
    trashDs = TrashedPageLocalDatasourceImpl(db);
    documents = DocumentRepositoryImpl(documentDs, folderDs, runner);
    folders = FolderRepositoryImpl(folderDs, documentDs, runner);
    pageTrash = PageTrashRepositoryImpl(trashDs, documentDs, runner);
  }

  Future<void> close() => db.close();
}
