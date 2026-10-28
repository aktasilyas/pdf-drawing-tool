import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:example_app/features/documents/documents.dart';

void main() {
  const key = 'maintenance.orphan_file_sweep_ms';

  Future<PrefsMaintenanceSchedule> schedule(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    return PrefsMaintenanceSchedule(await SharedPreferences.getInstance());
  }

  test('is null when nothing is stored', () async {
    expect(await (await schedule({})).lastOrphanSweep(), isNull);
  });

  test('round-trips the time', () async {
    final s = await schedule({});
    final time = DateTime.fromMillisecondsSinceEpoch(1780000000000);

    await s.setLastOrphanSweep(time);

    expect(await s.lastOrphanSweep(), time);
  });

  test('a value of the wrong type reads as null', () async {
    expect(await (await schedule({key: 'oops'})).lastOrphanSweep(), isNull);
  });
}
