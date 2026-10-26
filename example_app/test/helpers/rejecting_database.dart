import 'package:example_app/core/core.dart';

/// Makes every insert and update on the library tables fail, like a
/// storage layer that rejects writes. Rows already present stay readable.
Future<void> rejectLibraryWrites(AppDatabase db) async {
  for (final table in [
    'documents',
    'folders',
    'document_contents',
    'trashed_pages',
  ]) {
    for (final op in ['INSERT', 'UPDATE']) {
      await db.customStatement(
        'CREATE TRIGGER reject_${op}_$table BEFORE $op ON $table '
        "BEGIN SELECT RAISE(ABORT, 'write rejected'); END",
      );
    }
  }
}
