import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drawing_ui/drawing_ui.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Widget buildTestWidget(
    Widget child, {
    double width = 800,
    double height = 600,
  }) {
    return ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: MaterialApp(
        home: Scaffold(
          body: DrawingThemeProvider(
            theme: const DrawingTheme(),
            child: SizedBox(width: width, height: height, child: child),
          ),
        ),
      ),
    );
  }

  // CompactToolRow (phone tool capsule) is covered by
  // test/toolbar/phone_toolbar_test.dart.

  group('ToolbarOverflowMenu', () {
    testWidgets('renders_popup_menu_button', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const ToolbarOverflowMenu(
            hiddenTools: [ToolType.shapes, ToolType.sticker],
          ),
          width: 400,
        ),
      );

      expect(find.byIcon(ElyanotesIcons.moreVert), findsOneWidget);
      expect(find.byType(PopupMenuButton<ToolType>), findsOneWidget);
    });

    testWidgets('shows_hidden_tools_on_tap', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const ToolbarOverflowMenu(
            hiddenTools: [ToolType.shapes, ToolType.sticker],
          ),
          width: 400,
        ),
      );

      await tester.tap(find.byIcon(ElyanotesIcons.moreVert));
      await tester.pumpAndSettle();

      expect(find.text('Şekiller'), findsOneWidget);
      expect(find.text('Çıkartma'), findsOneWidget);
    });
  });
}
