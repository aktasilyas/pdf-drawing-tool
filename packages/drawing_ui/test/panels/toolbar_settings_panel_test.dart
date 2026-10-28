import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drawing_ui/drawing_ui.dart';
import 'package:drawing_ui/src/widgets/compact_visibility_switch.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Widget createTestWidget() {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 600,
            child: ToolbarSettingsPanel(),
          ),
        ),
      ),
    );
  }

  testWidgets('displays panel', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(find.byType(ToolbarSettingsPanel), findsOneWidget);
  });

  testWidgets('displays header icon and text', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(find.byIcon(ElyanotesIcons.settings), findsOneWidget);
    expect(find.text('Araç Çubuğu Ayarları'), findsOneWidget);
  });

  testWidgets('displays two tabs', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Araçlar'), findsOneWidget);
    expect(find.text('Ek Araçlar'), findsOneWidget);
    expect(find.byType(TabBar), findsOneWidget);
  });

  testWidgets('extra tools tab shows Cetvel and Ses Kaydı', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Tap "Ek Araçlar" tab
    await tester.tap(find.text('Ek Araçlar'));
    await tester.pumpAndSettle();

    expect(find.text('Cetvel'), findsOneWidget);
    expect(find.text('Ses Kaydı'), findsOneWidget);
  });

  testWidgets('displays reset button', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(
      find.widgetWithText(OutlinedButton, 'Varsayılana Sıfırla'),
      findsOneWidget,
    );
    expect(find.byIcon(ElyanotesIcons.rotate), findsOneWidget);
  });

  testWidgets('no overflow at text scale 1.3 in the 340dp panel',
      (tester) async {
    // A 390x844 phone at 1.3x text: the panel keeps 340dp and its lists
    // scroll instead of overflowing.
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1.3),
            ),
            child: child!,
          ),
          home: const Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: ToolbarSettingsPanel(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(ToolbarSettingsPanel)).width, 340);
    expect(
      MediaQuery.textScalerOf(
        tester.element(find.byType(ToolbarSettingsPanel)),
      ).scale(10),
      closeTo(13, 0.01),
    );

    await tester.tap(find.text('Ek Araçlar'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping the switch area toggles tool visibility',
      (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    bool firstValue() => tester.widget<Switch>(find.byType(Switch).first).value;
    final before = firstValue();
    // Tap the edge of the 48dp hit area, outside the scaled switch.
    final area = tester.getRect(find.byType(CompactVisibilitySwitch).first);
    await tester.tapAt(area.topLeft + const Offset(2, 2));
    await tester.pumpAndSettle();
    expect(firstValue(), !before);
  });
}
