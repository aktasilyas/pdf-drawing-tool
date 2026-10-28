import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drawing_ui/drawing_ui.dart';
import 'package:drawing_ui/src/panels/add_page_panel_widgets.dart';
import 'package:drawing_ui/src/widgets/compact_visibility_switch.dart';

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

  testWidgets('toolbar settings panel meets tap target guidelines on both tabs',
      (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester, const ToolbarSettingsPanel());
    await tester.pumpAndSettle();
    expect(find.byTooltip('Kapat'), findsOneWidget);
    expectAccessible(tester);

    await tester.tap(find.text('Ek Araçlar'));
    await tester.pumpAndSettle();
    expect(find.text('Cetvel'), findsOneWidget);
    expectAccessible(tester);
    handle.dispose();
  });

  testWidgets('toolbar settings rows have 48dp drag handle and switch',
      (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester, const ToolbarSettingsPanel());
    await tester.pumpAndSettle();
    final dragHandle = find.byType(ReorderableDragStartListener).first;
    expect(tester.getSize(dragHandle), const Size(48, 48));
    final toggle = find.byType(CompactVisibilitySwitch).first;
    expect(tester.getSize(toggle), const Size(48, 48));
    final widget = tester.widget<CompactVisibilitySwitch>(toggle);
    expect(widget.label, isNotEmpty);
    expect(
      tester.getSemantics(toggle),
      containsSemantics(
        label: widget.label,
        hasToggledState: true,
        isToggled: widget.value,
        hasTapAction: true,
      ),
    );
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
