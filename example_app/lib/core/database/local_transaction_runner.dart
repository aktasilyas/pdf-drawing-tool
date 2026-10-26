import 'package:example_app/core/database/app_database.dart';

/// Runs several local writes as one atomic unit.
///
/// If [action] throws, every write made inside it is rolled back.
abstract class LocalTransactionRunner {
  Future<T> run<T>(Future<T> Function() action);
}

/// [LocalTransactionRunner] backed by a Drift transaction.
class DriftTransactionRunner implements LocalTransactionRunner {
  final AppDatabase _db;

  DriftTransactionRunner(this._db);

  @override
  Future<T> run<T>(Future<T> Function() action) => _db.transaction(action);
}
