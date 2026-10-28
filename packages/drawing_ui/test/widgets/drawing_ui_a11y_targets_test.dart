import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drawing_ui/drawing_ui.dart';
import 'package:drawing_ui/src/panels/add_page_panel_widgets.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Future<void> pump(WidgetTester tester, Widget child,
      {List<Override> overrides = const []}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          ...overrides,
        ],
        child: MaterialApp(
          home: Scaffold(body: SizedBox(width: 400, height: 600, child: child)),
        ),
      ),
    );
    await tester.pump();
  }

  void expectAccessible(WidgetTester tester) {
    expect(tester, meetsGuideline(androidTapTargetGuideline));
    expect(tester, meetsGuideline(labeledTapTargetGuideline));
  }

  // The panel's tab bar and tool rows are 36dp and out of scope here, so the
  // whole-tree guideline is not used; the close button is checked directly.
  testWidgets('toolbar settings panel close button is labeled and 48dp',
      (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester, const ToolbarSettingsPanel());
    final close = find.byTooltip('Kapat');
    expect(close, findsOneWidget);
    final size = tester.getSize(close);
    expect(size.width, greaterThanOrEqualTo(48));
    expect(size.height, greaterThanOrEqualTo(48));
    handle.dispose();
  });

  testWidgets('add page header close button is labeled and 48dp',
      (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester, AddPageHeader(onClose: () {}));
    expect(find.byTooltip('Kapat'), findsOneWidget);
    expectAccessible(tester);
    handle.dispose();
  });

  testWidgets('export progress cancel button is labeled and 48dp',
      (tester) async {
    final handle = tester.ensureSemantics();
    final notifier = ExportProgressNotifier()..start(10);
    await pump(
      tester,
      const Stack(children: [FloatingExportProgress()]),
      overrides: [exportProgressProvider.overrideWith((ref) => notifier)],
    );
    expect(find.byTooltip('İptal'), findsOneWidget);
    expectAccessible(tester);
    handle.dispose();
  });
}
