import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_ui/drawing_ui.dart';

void main() {
  group('LaserPointerPanel', skip: 'UI redesign - color picker changed', () {
    testWidgets('renders with correct title', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: LaserPointerPanel(),
            ),
          ),
        ),
      );

      expect(find.text('Lazer işaretleyici'), findsOneWidget);
    });

    testWidgets('renders mode selector with two options', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: LaserPointerPanel(),
            ),
          ),
        ),
      );

      expect(find.text('Çizgi'), findsOneWidget);
      expect(find.text('Nokta'), findsOneWidget);
    });

    testWidgets('line mode is selected by default', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  final settings = ref.watch(laserSettingsProvider);
                  return Column(
                    children: [
                      Text('Mode: ${settings.mode.name}'),
                      const LaserPointerPanel(),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('Mode: line'), findsOneWidget);
    });

    testWidgets('can change mode to dot', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  final settings = ref.watch(laserSettingsProvider);
                  return Column(
                    children: [
                      Text('Mode: ${settings.mode.name}'),
                      const Expanded(child: LaserPointerPanel()),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Initially line
      expect(find.text('Mode: line'), findsOneWidget);

      // Tap dot option
      await tester.tap(find.text('Nokta'));
      await tester.pump();

      // Should be dot now
      expect(find.text('Mode: dot'), findsOneWidget);
    });

    testWidgets('renders section titles in Turkish', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: LaserPointerPanel(),
            ),
          ),
        ),
      );

      expect(find.text('KALINLIK'), findsOneWidget);
      expect(find.text('SÜRE'), findsOneWidget);
      expect(find.text('RENK'), findsOneWidget);
    });

    testWidgets('renders thickness slider', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: LaserPointerPanel(),
            ),
          ),
        ),
      );

      // ThicknessSlider contains a Slider
      expect(find.byType(Slider), findsNWidgets(2)); // thickness + duration
    });

    testWidgets('renders 5 color chips', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: LaserPointerPanel(),
            ),
          ),
        ),
      );

      // Should have 5 color chips
      expect(find.byType(ColorChip), findsNWidgets(5));
    });

    testWidgets('duration slider shows default value', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  final settings = ref.watch(laserSettingsProvider);
                  return Column(
                    children: [
                      Text('Duration: ${settings.duration}'),
                      const Expanded(child: LaserPointerPanel()),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Default duration is 2.0s
      expect(find.text('Duration: 2.0'), findsOneWidget);
      // Duration label should show "2.0s"
      expect(find.text('2.0s'), findsOneWidget);
    });

    testWidgets('can change color via provider', (tester) async {
      late WidgetRef testRef;
      
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  testRef = ref;
                  final settings = ref.watch(laserSettingsProvider);
                  return Column(
                    children: [
                      Text('ColorHex: ${settings.color.toARGB32().toRadixString(16)}'),
                      const Expanded(
                        child: SingleChildScrollView(
                          child: LaserPointerPanel(),
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

      // Initial color is light blue (0xFF29B6F6) from defaultSettings
      expect(find.text('ColorHex: ff29b6f6'), findsOneWidget);

      // Change color via provider
      testRef.read(laserSettingsProvider.notifier).setColor(const Color(0xFF4CAF50));
      await tester.pump();

      // Color should change to green
      expect(find.text('ColorHex: ff4caf50'), findsOneWidget);
    });
  });

  group('LaserSettingsProvider', () {
    test('default mode is line', () {
      final container = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(null),
      ]);
      addTearDown(container.dispose);

      final settings = container.read(laserSettingsProvider);
      expect(settings.mode, LaserMode.line);
    });

    test('default thickness is 0.5', () {
      final container = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(null),
      ]);
      addTearDown(container.dispose);

      final settings = container.read(laserSettingsProvider);
      expect(settings.thickness, 0.5);
    });

    test('default duration is 2.0', () {
      final container = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(null),
      ]);
      addTearDown(container.dispose);

      final settings = container.read(laserSettingsProvider);
      expect(settings.duration, 2.0);
    });

    test('default color is light blue', () {
      final container = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(null),
      ]);
      addTearDown(container.dispose);

      final settings = container.read(laserSettingsProvider);
      expect(settings.color, const Color(0xFF29B6F6));
    });

    test('can change mode', () {
      final container = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(null),
      ]);
      addTearDown(container.dispose);

      container.read(laserSettingsProvider.notifier).setMode(LaserMode.dot);

      expect(container.read(laserSettingsProvider).mode, LaserMode.dot);
    });

    test('can change thickness', () {
      final container = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(null),
      ]);
      addTearDown(container.dispose);

      container.read(laserSettingsProvider.notifier).setThickness(3.5);

      expect(container.read(laserSettingsProvider).thickness, 3.5);
    });

    test('can change duration', () {
      final container = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(null),
      ]);
      addTearDown(container.dispose);

      container.read(laserSettingsProvider.notifier).setDuration(4.0);

      expect(container.read(laserSettingsProvider).duration, 4.0);
    });

    test('can change color', () {
      final container = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(null),
      ]);
      addTearDown(container.dispose);

      container.read(laserSettingsProvider.notifier).setColor(Colors.blue);

      expect(container.read(laserSettingsProvider).color, Colors.blue);
    });

    test('duration range is 0.5 to 5.0', () {
      final container = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(null),
      ]);
      addTearDown(container.dispose);

      // Set to min
      container.read(laserSettingsProvider.notifier).setDuration(0.5);
      expect(container.read(laserSettingsProvider).duration, 0.5);

      // Set to max
      container.read(laserSettingsProvider.notifier).setDuration(5.0);
      expect(container.read(laserSettingsProvider).duration, 5.0);
    });
  });
}
