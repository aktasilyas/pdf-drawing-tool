import 'package:drift/native.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:example_app/core/core.dart';

void main() {
  late AppDatabase db;
  late LocalTransactionRunner runner;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    runner = DriftTransactionRunner(db);
  });
  tearDown(() => db.close());

  Future<void> insertFolder(String id) => db.into(db.folders).insert(
        FoldersCompanion.insert(
          id: id,
          name: id,
          createdAt: DateTime(2026),
        ),
      );

  test('commits all writes and returns the result', () async {
    final r = await runner.run(() async {
      await insertFolder('a');
      await insertFolder('b');
      return 7;
    });
    expect(r, 7);
    expect(await db.select(db.folders).get(), hasLength(2));
  });

  test('rolls back every write when the action throws', () async {
    await expectLater(
      runner.run(() async {
        await insertFolder('a');
        throw StateError('boom');
      }),
      throwsStateError,
    );
    expect(await db.select(db.folders).get(), isEmpty);
  });
}
