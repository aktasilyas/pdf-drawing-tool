import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_ui/drawing_ui.dart';

void main() {
  group('LassoSelectionPanel', () {
    testWidgets('renders with correct title', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: LassoSelectionPanel(),
            ),
          ),
        ),
      );

      expect(find.text('Kement'), findsOneWidget);
    });

    testWidgets('renders mode selector with two options', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: LassoSelectionPanel(),
            ),
          ),
        ),
      );

      expect(find.text('Serbest\nkement'), findsOneWidget);
      expect(find.text('Dikdörtgen\nkement'), findsOneWidget);
    });

    testWidgets('renders all 8 selectable type toggles', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: LassoSelectionPanel(),
            ),
          ),
        ),
      );

      // Check all Turkish labels
      expect(find.text('Şekil'), findsOneWidget);
      expect(find.text('Resim/Çıkartma'), findsOneWidget);
      expect(find.text('Bant'), findsOneWidget);
      expect(find.text('Metin kutusu'), findsOneWidget);
      expect(find.text('El yazısı'), findsOneWidget);
      expect(find.text('Vurgulayıcı'), findsOneWidget);
      expect(find.text('Bağlantı'), findsOneWidget);
      expect(find.text('Etiket'), findsOneWidget);
    });

    testWidgets('freeform mode is selected by default', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  final settings = ref.watch(lassoSettingsProvider);
                  return Column(
                    children: [
                      Text('Mode: ${settings.mode.name}'),
                      const LassoSelectionPanel(),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('Mode: freeform'), findsOneWidget);
    });

    testWidgets('can change mode to rectangle', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  final settings = ref.watch(lassoSettingsProvider);
                  return Column(
                    children: [
                      Text('Mode: ${settings.mode.name}'),
                      const Expanded(child: LassoSelectionPanel()),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Initially freeform
      expect(find.text('Mode: freeform'), findsOneWidget);

      // Tap rectangle option
      await tester.tap(find.text('Dikdörtgen\nkement'));
      await tester.pump();

      // Should be rectangle now
      expect(find.text('Mode: rectangle'), findsOneWidget);
    });

    testWidgets('highlighter toggle is OFF by default', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  final settings = ref.watch(lassoSettingsProvider);
                  final highlighterOn = 
                      settings.selectableTypes[SelectableType.highlighter] ?? false;
                  return Column(
                    children: [
                      Text('Highlighter: $highlighterOn'),
                      const Expanded(child: LassoSelectionPanel()),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Highlighter should be OFF by default
      expect(find.text('Highlighter: false'), findsOneWidget);
    });

    testWidgets('shape toggle is ON by default', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  final settings = ref.watch(lassoSettingsProvider);
                  final shapeOn = 
                      settings.selectableTypes[SelectableType.shape] ?? false;
                  return Column(
                    children: [
                      Text('Shape: $shapeOn'),
                      const Expanded(child: LassoSelectionPanel()),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Shape should be ON by default
      expect(find.text('Shape: true'), findsOneWidget);
    });

    testWidgets('can toggle selectable type', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  final settings = ref.watch(lassoSettingsProvider);
                  final shapeOn = 
                      settings.selectableTypes[SelectableType.shape] ?? false;
                  return Column(
                    children: [
                      Text('Shape: $shapeOn'),
                      const Expanded(
                        child: SingleChildScrollView(
                          child: LassoSelectionPanel(),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Initially ON
      expect(find.text('Shape: true'), findsOneWidget);

      // Find and tap the Switch for Şekil
      final switches = find.byType(Switch);
      expect(switches, findsNWidgets(8)); // 8 toggles

      // Tap the first switch (Şekil)
      await tester.tap(switches.first);
      await tester.pump();

      // Should be OFF now
      expect(find.text('Shape: false'), findsOneWidget);
    });

    testWidgets('close button calls onClose callback', (tester) async {
      bool closeCalled = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: LassoSelectionPanel(
                onClose: () => closeCalled = true,
              ),
            ),
          ),
        ),
      );

      // Find close button
      final closeButton = find.byIcon(Icons.close);
      expect(closeButton, findsOneWidget);

      await tester.tap(closeButton);
      await tester.pump();

      expect(closeCalled, true);
    });

    testWidgets('renders section title in Turkish', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: LassoSelectionPanel(),
            ),
          ),
        ),
      );

      expect(find.text('SEÇİLEBİLİR'), findsOneWidget);
    });
  });

  group('LassoSettingsProvider', () {
    test('default mode is freeform', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final settings = container.read(lassoSettingsProvider);
      expect(settings.mode, LassoMode.freeform);
    });

    test('highlighter is OFF by default, others are ON', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final settings = container.read(lassoSettingsProvider);
      
      expect(settings.selectableTypes[SelectableType.shape], true);
      expect(settings.selectableTypes[SelectableType.imageSticker], true);
      expect(settings.selectableTypes[SelectableType.tape], true);
      expect(settings.selectableTypes[SelectableType.textBox], true);
      expect(settings.selectableTypes[SelectableType.handwriting], true);
      expect(settings.selectableTypes[SelectableType.highlighter], false);
      expect(settings.selectableTypes[SelectableType.link], true);
      expect(settings.selectableTypes[SelectableType.label], true);
    });

    test('can change mode', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(lassoSettingsProvider.notifier).setMode(LassoMode.rectangle);
      
      expect(container.read(lassoSettingsProvider).mode, LassoMode.rectangle);
    });

    test('can toggle selectable type', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Initially shape is ON
      expect(
        container.read(lassoSettingsProvider).selectableTypes[SelectableType.shape],
        true,
      );

      // Turn it OFF
      container.read(lassoSettingsProvider.notifier)
          .setSelectableType(SelectableType.shape, false);
      
      expect(
        container.read(lassoSettingsProvider).selectableTypes[SelectableType.shape],
        false,
      );
    });

    test('can set all selectable types', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Turn all OFF
      container.read(lassoSettingsProvider.notifier).setAllSelectableTypes(false);
      
      final settings = container.read(lassoSettingsProvider);
      for (final type in SelectableType.values) {
        expect(settings.selectableTypes[type], false);
      }

      // Turn all ON
      container.read(lassoSettingsProvider.notifier).setAllSelectableTypes(true);
      
      final settingsOn = container.read(lassoSettingsProvider);
      for (final type in SelectableType.values) {
        expect(settingsOn.selectableTypes[type], true);
      }
    });
  });
}
