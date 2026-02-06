import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:example_app/core/theme/index.dart';
import 'package:example_app/core/widgets/layout/app_card.dart';

void main() {
  group('AppCard', () {
    Widget buildTestWidget({
      required Widget child,
      bool isDark = false,
      AppCardVariant variant = AppCardVariant.elevated,
      bool isSelected = false,
      VoidCallback? onTap,
    }) {
      return MaterialApp(
        theme: isDark ? AppTheme.dark : AppTheme.light,
        home: Scaffold(
          body: AppCard(
            variant: variant,
            isSelected: isSelected,
            onTap: onTap,
            child: child,
          ),
        ),
      );
    }

    group('Elevated Variant', () {
      group('Light Theme', () {
        testWidgets('should_use_surfaceLight_color', (tester) async {
          // Arrange & Act
          await tester.pumpWidget(
            buildTestWidget(
              child: const Text('Test'),
              variant: AppCardVariant.elevated,
              isDark: false,
            ),
          );

          // Assert
          final container = tester.widget<Container>(find.byType(Container));
          final decoration = container.decoration as BoxDecoration;
          expect(decoration.color, equals(AppColors.surfaceLight));
        });

        testWidgets('should_have_shadow_when_not_selected', (tester) async {
          // Arrange & Act
          await tester.pumpWidget(
            buildTestWidget(
              child: const Text('Test'),
              variant: AppCardVariant.elevated,
              isDark: false,
              isSelected: false,
            ),
          );

          // Assert
          final container = tester.widget<Container>(find.byType(Container));
          final decoration = container.decoration as BoxDecoration;
          expect(decoration.boxShadow, isNotNull);
          expect(decoration.boxShadow?.length, greaterThan(0));
        });

        testWidgets('should_have_primary_border_when_selected', (tester) async {
          // Arrange & Act
          await tester.pumpWidget(
            buildTestWidget(
              child: const Text('Test'),
              variant: AppCardVariant.elevated,
              isDark: false,
              isSelected: true,
            ),
          );

          // Assert
          final container = tester.widget<Container>(find.byType(Container));
          final decoration = container.decoration as BoxDecoration;
          expect(decoration.border, isNotNull);
          expect((decoration.border as Border).top.color, equals(AppColors.primary));
          expect((decoration.border as Border).top.width, equals(2));
          expect(decoration.boxShadow, isNull);
        });
      });

      group('Dark Theme', () {
        testWidgets('should_use_surfaceDark_color', (tester) async {
          // Arrange & Act
          await tester.pumpWidget(
            buildTestWidget(
              child: const Text('Test'),
              variant: AppCardVariant.elevated,
              isDark: true,
            ),
          );

          // Assert
          final container = tester.widget<Container>(find.byType(Container));
          final decoration = container.decoration as BoxDecoration;
          expect(decoration.color, equals(AppColors.surfaceDark));
        });

        testWidgets('should_have_shadow_when_not_selected', (tester) async {
          // Arrange & Act
          await tester.pumpWidget(
            buildTestWidget(
              child: const Text('Test'),
              variant: AppCardVariant.elevated,
              isDark: true,
              isSelected: false,
            ),
          );

          // Assert
          final container = tester.widget<Container>(find.byType(Container));
          final decoration = container.decoration as BoxDecoration;
          expect(decoration.boxShadow, isNotNull);
          expect(decoration.boxShadow?.length, greaterThan(0));
        });

        testWidgets('should_have_primary_border_when_selected', (tester) async {
          // Arrange & Act
          await tester.pumpWidget(
            buildTestWidget(
              child: const Text('Test'),
              variant: AppCardVariant.elevated,
              isDark: true,
              isSelected: true,
            ),
          );

          // Assert
          final container = tester.widget<Container>(find.byType(Container));
          final decoration = container.decoration as BoxDecoration;
          expect(decoration.border, isNotNull);
          expect((decoration.border as Border).top.color, equals(AppColors.primary));
          expect((decoration.border as Border).top.width, equals(2));
          expect(decoration.boxShadow, isNull);
        });
      });
    });

    group('Filled Variant', () {
      group('Light Theme', () {
        testWidgets('should_use_surfaceVariantLight_color', (tester) async {
          // Arrange & Act
          await tester.pumpWidget(
            buildTestWidget(
              child: const Text('Test'),
              variant: AppCardVariant.filled,
              isDark: false,
            ),
          );

          // Assert
          final container = tester.widget<Container>(find.byType(Container));
          final decoration = container.decoration as BoxDecoration;
          expect(decoration.color, equals(AppColors.surfaceVariantLight));
        });

        testWidgets('should_not_have_border_when_not_selected', (tester) async {
          // Arrange & Act
          await tester.pumpWidget(
            buildTestWidget(
              child: const Text('Test'),
              variant: AppCardVariant.filled,
              isDark: false,
              isSelected: false,
            ),
          );

          // Assert
          final container = tester.widget<Container>(find.byType(Container));
          final decoration = container.decoration as BoxDecoration;
          expect(decoration.border, isNull);
        });

        testWidgets('should_have_primary_border_when_selected', (tester) async {
          // Arrange & Act
          await tester.pumpWidget(
            buildTestWidget(
              child: const Text('Test'),
              variant: AppCardVariant.filled,
              isDark: false,
              isSelected: true,
            ),
          );

          // Assert
          final container = tester.widget<Container>(find.byType(Container));
          final decoration = container.decoration as BoxDecoration;
          expect(decoration.border, isNotNull);
          expect((decoration.border as Border).top.color, equals(AppColors.primary));
          expect((decoration.border as Border).top.width, equals(2));
        });
      });

      group('Dark Theme', () {
        testWidgets('should_use_surfaceVariantDark_color', (tester) async {
          // Arrange & Act
          await tester.pumpWidget(
            buildTestWidget(
              child: const Text('Test'),
              variant: AppCardVariant.filled,
              isDark: true,
            ),
          );

          // Assert
          final container = tester.widget<Container>(find.byType(Container));
          final decoration = container.decoration as BoxDecoration;
          expect(decoration.color, equals(AppColors.surfaceVariantDark));
        });

        testWidgets('should_not_have_border_when_not_selected', (tester) async {
          // Arrange & Act
          await tester.pumpWidget(
            buildTestWidget(
              child: const Text('Test'),
              variant: AppCardVariant.filled,
              isDark: true,
              isSelected: false,
            ),
          );

          // Assert
          final container = tester.widget<Container>(find.byType(Container));
          final decoration = container.decoration as BoxDecoration;
          expect(decoration.border, isNull);
        });

        testWidgets('should_have_primary_border_when_selected', (tester) async {
          // Arrange & Act
          await tester.pumpWidget(
            buildTestWidget(
              child: const Text('Test'),
              variant: AppCardVariant.filled,
              isDark: true,
              isSelected: true,
            ),
          );

          // Assert
          final container = tester.widget<Container>(find.byType(Container));
          final decoration = container.decoration as BoxDecoration;
          expect(decoration.border, isNotNull);
          expect((decoration.border as Border).top.color, equals(AppColors.primary));
          expect((decoration.border as Border).top.width, equals(2));
        });
      });
    });

    group('Outlined Variant', () {
      group('Light Theme', () {
        testWidgets('should_use_surfaceLight_color', (tester) async {
          // Arrange & Act
          await tester.pumpWidget(
            buildTestWidget(
              child: const Text('Test'),
              variant: AppCardVariant.outlined,
              isDark: false,
            ),
          );

          // Assert
          final container = tester.widget<Container>(find.byType(Container));
          final decoration = container.decoration as BoxDecoration;
          expect(decoration.color, equals(AppColors.surfaceLight));
        });

        testWidgets('should_use_outlineLight_border_when_not_selected', (tester) async {
          // Arrange & Act
          await tester.pumpWidget(
            buildTestWidget(
              child: const Text('Test'),
              variant: AppCardVariant.outlined,
              isDark: false,
              isSelected: false,
            ),
          );

          // Assert
          final container = tester.widget<Container>(find.byType(Container));
          final decoration = container.decoration as BoxDecoration;
          expect(decoration.border, isNotNull);
          expect((decoration.border as Border).top.color, equals(AppColors.outlineLight));
          expect((decoration.border as Border).top.width, equals(1));
        });

        testWidgets('should_use_primary_border_when_selected', (tester) async {
          // Arrange & Act
          await tester.pumpWidget(
            buildTestWidget(
              child: const Text('Test'),
              variant: AppCardVariant.outlined,
              isDark: false,
              isSelected: true,
            ),
          );

          // Assert
          final container = tester.widget<Container>(find.byType(Container));
          final decoration = container.decoration as BoxDecoration;
          expect(decoration.border, isNotNull);
          expect((decoration.border as Border).top.color, equals(AppColors.primary));
          expect((decoration.border as Border).top.width, equals(2));
        });
      });

      group('Dark Theme', () {
        testWidgets('should_use_surfaceDark_color', (tester) async {
          // Arrange & Act
          await tester.pumpWidget(
            buildTestWidget(
              child: const Text('Test'),
              variant: AppCardVariant.outlined,
              isDark: true,
            ),
          );

          // Assert
          final container = tester.widget<Container>(find.byType(Container));
          final decoration = container.decoration as BoxDecoration;
          expect(decoration.color, equals(AppColors.surfaceDark));
        });

        testWidgets('should_use_outlineDark_border_when_not_selected', (tester) async {
          // Arrange & Act
          await tester.pumpWidget(
            buildTestWidget(
              child: const Text('Test'),
              variant: AppCardVariant.outlined,
              isDark: true,
              isSelected: false,
            ),
          );

          // Assert
          final container = tester.widget<Container>(find.byType(Container));
          final decoration = container.decoration as BoxDecoration;
          expect(decoration.border, isNotNull);
          expect((decoration.border as Border).top.color, equals(AppColors.outlineDark));
          expect((decoration.border as Border).top.width, equals(1));
        });

        testWidgets('should_use_primary_border_when_selected', (tester) async {
          // Arrange & Act
          await tester.pumpWidget(
            buildTestWidget(
              child: const Text('Test'),
              variant: AppCardVariant.outlined,
              isDark: true,
              isSelected: true,
            ),
          );

          // Assert
          final container = tester.widget<Container>(find.byType(Container));
          final decoration = container.decoration as BoxDecoration;
          expect(decoration.border, isNotNull);
          expect((decoration.border as Border).top.color, equals(AppColors.primary));
          expect((decoration.border as Border).top.width, equals(2));
        });
      });
    });

    group('Interaction', () {
      testWidgets('should_call_onTap_when_tapped', (tester) async {
        // Arrange
        bool tapped = false;
        await tester.pumpWidget(
          buildTestWidget(
            child: const Text('Test'),
            onTap: () => tapped = true,
          ),
        );

        // Act
        await tester.tap(find.byType(AppCard));
        await tester.pump();

        // Assert
        expect(tapped, true);
      });

      testWidgets('should_render_child_content', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          buildTestWidget(
            child: const Text('Test Content'),
          ),
        );

        // Assert
        expect(find.text('Test Content'), findsOneWidget);
      });
    });
  });
}
