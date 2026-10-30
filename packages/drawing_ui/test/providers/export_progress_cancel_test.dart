// Tapping Cancel answers at once (#490).
import 'package:drawing_ui/drawing_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('requestCancel shows the cancelled state right away', () {
    final progress = ExportProgressNotifier();
    addTearDown(progress.dispose);

    progress.start(10);
    progress.updateProgress(3, 10);
    progress.requestCancel();

    expect(progress.isCancelRequested, isTrue);
    expect(progress.state.status, ExportProgressStatus.cancelled);

    // Later progress from the page still being drawn changes nothing.
    progress.updateProgress(4, 10);
    expect(progress.state.status, ExportProgressStatus.cancelled);
    expect(progress.state.currentPage, 3);
  });

  test('requestCancel without a running export does nothing', () {
    final progress = ExportProgressNotifier();
    addTearDown(progress.dispose);

    progress.requestCancel();

    expect(progress.isCancelRequested, isFalse);
    expect(progress.state.status, ExportProgressStatus.idle);
  });

  test('a new export clears an earlier cancel', () {
    final progress = ExportProgressNotifier();
    addTearDown(progress.dispose);

    progress.start(2);
    progress.requestCancel();
    progress.start(2);

    expect(progress.isCancelRequested, isFalse);
    expect(progress.state.status, ExportProgressStatus.exporting);
  });

  testWidgets('the overlay shows Cancelled as soon as Cancel is tapped',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: Stack(children: [FloatingExportProgress()])),
        ),
      ),
    );
    container.read(exportProgressProvider.notifier).start(5);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.byTooltip(const DrawingStringsTr().panels.cancel));
    await tester.pump();

    expect(find.text(const ExportStringsTr().cancelled), findsOneWidget);
    expect(
      container.read(exportProgressProvider.notifier).isCancelRequested,
      isTrue,
    );

    // The cancelled notice closes by itself.
    await tester.pump(const Duration(seconds: 2));
    expect(
      container.read(exportProgressProvider).status,
      ExportProgressStatus.idle,
    );
  });
}
