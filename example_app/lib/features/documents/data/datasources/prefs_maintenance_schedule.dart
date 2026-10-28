import 'package:shared_preferences/shared_preferences.dart';
import 'package:example_app/features/documents/domain/repositories/maintenance_schedule.dart';

/// [MaintenanceSchedule] kept in SharedPreferences as epoch milliseconds.
class PrefsMaintenanceSchedule implements MaintenanceSchedule {
  PrefsMaintenanceSchedule(this._prefs);

  static const orphanSweepKey = 'maintenance.orphan_file_sweep_ms';

  final SharedPreferences _prefs;

  @override
  Future<DateTime?> lastOrphanSweep() async {
    final Object? value;
    try {
      value = _prefs.get(orphanSweepKey);
    } catch (_) {
      return null;
    }
    return value is int ? DateTime.fromMillisecondsSinceEpoch(value) : null;
  }

  @override
  Future<void> setLastOrphanSweep(DateTime time) async {
    await _prefs.setInt(orphanSweepKey, time.millisecondsSinceEpoch);
  }
}
