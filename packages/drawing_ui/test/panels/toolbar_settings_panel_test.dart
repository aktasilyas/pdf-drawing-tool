import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drawing_ui/src/panels/toolbar_settings_panel.dart';
import 'package:drawing_ui/src/providers/toolbar_config_provider.dart';

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
      child: MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 600,
            child: SingleChildScrollView(
              child: ToolbarSettingsPanel(),
            ),
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

    expect(find.byIcon(Icons.settings), findsOneWidget);
    expect(find.text('Araç Çubuğu Ayarları'), findsOneWidget);
  });

  testWidgets('displays quick access section', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Hızlı Erişim Çubuğu'), findsOneWidget);
    expect(find.byType(Switch), findsWidgets);
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
    expect(find.byIcon(Icons.restore), findsOneWidget);
  });
}
