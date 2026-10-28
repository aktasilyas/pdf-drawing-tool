/// Remembers when background maintenance last ran successfully.
abstract class MaintenanceSchedule {
  /// When the orphaned-file sweep last succeeded, or null if never (or the
  /// stored value is unreadable).
  Future<DateTime?> lastOrphanSweep();

  Future<void> setLastOrphanSweep(DateTime time);
}
