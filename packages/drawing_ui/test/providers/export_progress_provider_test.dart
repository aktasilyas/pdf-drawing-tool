import 'package:drawing_ui/drawing_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('complete keeps the count of pages missing their PDF', () {
    final progress = ExportProgressNotifier();
    addTearDown(progress.dispose);

    progress.start(3);
    progress.complete('1.0 MB', pagesMissingBackground: 2);

    expect(progress.state.status, ExportProgressStatus.completed);
    expect(progress.state.pagesMissingBackground, 2);
  });

  test('a new export starts with no missing pages', () {
    final progress = ExportProgressNotifier();
    addTearDown(progress.dispose);

    progress.start(1);
    progress.complete('1.0 MB', pagesMissingBackground: 1);
    progress.start(1);

    expect(progress.state.pagesMissingBackground, 0);
  });

  test('complete without missing pages reports none', () {
    final progress = ExportProgressNotifier();
    addTearDown(progress.dispose);

    progress.start(1);
    progress.complete('1.0 MB');

    expect(progress.state.pagesMissingBackground, 0);
  });
}
