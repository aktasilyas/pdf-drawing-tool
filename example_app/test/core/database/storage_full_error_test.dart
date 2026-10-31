import 'dart:io';
import 'dart:math';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:example_app/core/core.dart';

import '../../helpers/library_fixture.dart';

/// Makes the next large write to [db] fail with SQLITE_FULL: the database may
/// not grow past the pages it already has.
Future<void> capDatabaseSize(AppDatabase db) async {
  await db.customStatement('CREATE TABLE filler (x BLOB)');
  await db.customStatement('PRAGMA max_page_count = 1');
}

Future<void> writeLargeBlob(AppDatabase db) =>
    db.customStatement('INSERT INTO filler VALUES (zeroblob(1000000))');

Future<Object> errorOf(Future<void> Function() action) async {
  try {
    await action();
  } catch (e) {
    return e;
  }
  fail('expected the write to fail');
}

void main() {
  test('SQLITE_FULL from SQLite is storage full', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await capDatabaseSize(db);

    final error = await errorOf(() => writeLargeBlob(db));
    expect(error, isA<SqliteException>());
    expect(isStorageFull(error), isTrue);
    expect(isStorageFull(CacheException('save', originalError: error)), isTrue);
  });

  test('SQLITE_FULL from the background isolate is storage full', () async {
    final dir = await Directory.systemTemp.createTemp('storage_full');
    addTearDown(() => dir.delete(recursive: true));
    final db = AppDatabase(
      NativeDatabase.createInBackground(File('${dir.path}/app.db')),
    );
    addTearDown(db.close);
    await capDatabaseSize(db);

    final error = await errorOf(() => writeLargeBlob(db));
    expect(isStorageFull(error), isTrue, reason: '$error');
  });

  test('disk-full file errors are storage full, others are not', () {
    const full = FileSystemException(
      'Cannot write',
      '/notes/a.pdf',
      OSError('No space left on device', 28),
    );
    const denied = FileSystemException(
      'Cannot write',
      '/notes/a.pdf',
      OSError('Permission denied', 13),
    );
    expect(isStorageFull(full), isTrue);
    expect(isStorageFull(denied), isFalse);
    expect(isStorageFull(StateError('boom')), isFalse);
    expect(isStorageFull(const CacheException('Document not found')), isFalse);
    expect(isStorageFull(null), isFalse);
    // Serialized remote causes are plain text.
    const remoteFull = 'SqliteException(13): database or disk is full';
    expect(isStorageFull(remoteFull), isTrue);
    expect(isStorageFull('SqliteException(19): constraint failed'), isFalse);
  });

  test('cacheFailureFor picks the failure type', () {
    const full = FileSystemException('x', '', OSError('', 28));
    expect(cacheFailureFor(full, 'm'), const StorageFullFailure('m'));
    expect(cacheFailureFor(StateError('x'), 'm'), const CacheFailure('m'));
  });

  test('saving content on a full database fails with StorageFullFailure',
      () async {
    final fx = LibraryFixture();
    addTearDown(fx.close);
    final created = await fx.documents.createDocument(
      title: 'Doc',
      templateId: 'blank',
    );
    final doc = created.getOrElse(() => throw StateError('create failed'));
    await capDatabaseSize(fx.db);

    final random = Random(1);
    final noise = String.fromCharCodes(
      List.generate(300000, (_) => 33 + random.nextInt(90)),
    );
    final result = await fx.documents.saveDocumentContent(
      id: doc.id,
      content: {
        'id': doc.id,
        'pages': [
          {'id': 'p0', 'index': 0, 'noise': noise},
        ],
      },
    );

    expect(result.fold((f) => f, (_) => null), isA<StorageFullFailure>());
  });
}
