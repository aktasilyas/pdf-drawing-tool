import 'package:flutter_test/flutter_test.dart';

import 'helpers/app_harness.dart';
import 'robots/library_robot.dart';

void main() {
  initE2E();

  testWidgets('first launch shows the empty library', (tester) async {
    await launchApp(tester);

    final library = LibraryRobot(tester);
    await library.waitForLibrary();

    library.expectEmptyState();
  });
}
