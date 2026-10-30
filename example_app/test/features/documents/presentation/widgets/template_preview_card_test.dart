import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/features/documents/presentation/widgets/template_preview_card.dart';

import '../../../../helpers/l10n.dart';

/// Labels here are arbitrary on purpose: the card reads whatever label the
/// caller passes (localized Cover / Paper in the new-notebook flow).
Widget _host({required bool coverSelected, ValueChanged<bool>? onPick}) {
  return localizedApp(
    theme: AppTheme.light,
    locale: const Locale('en'),
    home: Scaffold(
      body: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TemplatePreviewCard(
              label: 'Front',
              isSelected: coverSelected,
              width: 90,
              height: 120,
              onTap: () => onPick?.call(true),
              child: const ColoredBox(color: Colors.white),
            ),
            const SizedBox(width: AppSpacing.sm),
            TemplatePreviewCard(
              label: 'Sheet',
              isSelected: !coverSelected,
              width: 90,
              height: 120,
              onTap: () => onPick?.call(false),
              child: const ColoredBox(color: Colors.white),
            ),
          ],
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('cards are named buttons with their selection state',
      (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_host(coverSelected: true));

    expect(find.bySemanticsLabel('Front'), findsOneWidget);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Front')),
      isSemantics(
        label: 'Front',
        isButton: true,
        isSelected: true,
        hasTapAction: true,
      ),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Sheet')),
      isSemantics(
        label: 'Sheet',
        isButton: true,
        hasSelectedState: true,
        isSelected: false,
        hasTapAction: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('semantic tap reports which card was picked', (tester) async {
    final handle = tester.ensureSemantics();
    final picks = <bool>[];
    await tester.pumpWidget(_host(coverSelected: true, onPick: picks.add));

    tester.semantics.tap(find.bySemanticsLabel('Sheet'));
    tester.semantics.tap(find.bySemanticsLabel('Front'));
    expect(picks, [false, true]);
    handle.dispose();
  });

  testWidgets('meets tap-target and label guidelines', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_host(coverSelected: false));

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });

  testWidgets('selected border and caption use the palette accent',
      (tester) async {
    await tester.pumpWidget(_host(coverSelected: true));

    final caption = tester.widget<Text>(find.text('Front'));
    expect(caption.style?.color, AppPalette.light.accent);
    final other = tester.widget<Text>(find.text('Sheet'));
    expect(other.style?.color, AppPalette.light.textMuted);
  });
}
