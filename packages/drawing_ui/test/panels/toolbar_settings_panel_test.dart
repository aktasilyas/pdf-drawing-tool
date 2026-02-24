import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drawing_ui/drawing_ui.dart';

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

    expect(find.byIcon(StarNoteIcons.settings), findsOneWidget);
    expect(find.text('Araç Çubuğu Ayarları'), findsOneWidget);
  });

  testWidgets('displays extra tools section', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Ek Araçlar'), findsOneWidget);
    expect(find.text('Cetvel'), findsOneWidget);
    expect(find.text('Ses Kaydı'), findsOneWidget);
  });

  testWidgets('displays tools section', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Araçlar'), findsOneWidget);
  });

  testWidgets('displays reset button', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(find.widgetWithText(OutlinedButton, 'Varsayılana Sıfırla'), findsOneWidget);
    expect(find.byIcon(StarNoteIcons.rotate), findsOneWidget);
  });
}
