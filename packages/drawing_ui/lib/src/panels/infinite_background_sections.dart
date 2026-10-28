import 'package:drawing_core/drawing_core.dart';
import 'package:flutter/material.dart' hide Page;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:drawing_ui/src/l10n/l10n.dart';
import 'infinite_background_chips.dart';
import 'infinite_background_logic.dart';

typedef _Label = String Function(TemplateStrings strings);

/// Pattern selection: Düz, Noktalı, Izgara.
class InfiniteBackgroundPatternSection extends ConsumerWidget {
  const InfiniteBackgroundPatternSection({super.key, required this.background});
  final PageBackground background;

  static final _options = <(_Label, InfiniteBackgroundPattern)>[
    ((s) => s.patternPlain, InfiniteBackgroundPattern.plain),
    ((s) => s.patternDotted, InfiniteBackgroundPattern.dotted),
    ((s) => s.patternGrid, InfiniteBackgroundPattern.grid),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = InfiniteBackgroundBuilder.patternOf(background);
    final actions = ref.read(infiniteBackgroundActionsProvider);
    final s = context.drawingStrings.templates;
    return _Section(
      title: s.backgroundPattern,
      chips: [
        for (final (label, pattern) in _options)
          InfiniteBackgroundPatternChip(
            label: label(s),
            pattern: pattern,
            isSelected: current == pattern,
            onTap: () => actions.applyPattern(pattern),
          ),
      ],
    );
  }
}

/// Colour selection: Beyaz, Sarı, Siyah.
class InfiniteBackgroundColorSection extends ConsumerWidget {
  const InfiniteBackgroundColorSection({super.key, required this.background});
  final PageBackground background;

  static final _options = <(_Label, int)>[
    ((s) => s.colorWhite, InfiniteBackgroundColors.white),
    ((s) => s.colorYellow, InfiniteBackgroundColors.yellow),
    ((s) => s.colorBlack, InfiniteBackgroundColors.black),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = InfiniteBackgroundColors.groupOf(background.color);
    final actions = ref.read(infiniteBackgroundActionsProvider);
    final s = context.drawingStrings.templates;
    return _Section(
      title: s.backgroundColor,
      chips: [
        for (final (label, color) in _options)
          InfiniteBackgroundColorChip(
            label: label(s),
            color: color,
            isSelected: current == color,
            onTap: () => actions.applyColor(color),
          ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.chips});
  final String title;
  final List<Widget> chips;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontSize: 13, color: cs.onSurfaceVariant)),
          ),
          Row(children: [
            for (var i = 0; i < chips.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              chips[i],
            ],
          ]),
        ],
      ),
    );
  }
}
