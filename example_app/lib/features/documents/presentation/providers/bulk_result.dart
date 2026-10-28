/// Outcome of a multi-selection library operation.
///
/// Bulk operations try every id; one failure does not stop the rest, so the
/// caller learns exactly which ids succeeded and which have to stay selected.
class BulkResult {
  const BulkResult({
    this.succeeded = const [],
    this.failed = const [],
  });

  /// Ids the operation was applied to.
  final List<String> succeeded;

  /// Ids the operation failed for, in input order.
  final List<String> failed;

  /// Number of ids that were tried.
  int get total => succeeded.length + failed.length;

  bool get hasFailures => failed.isNotEmpty;
}
