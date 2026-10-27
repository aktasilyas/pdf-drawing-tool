import 'package:flutter/material.dart' hide Page;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import 'package:drawing_ui/src/providers/providers.dart';
import 'infinite_background_sections.dart';
import 'page_options_widgets.dart';

/// Background options panel for infinite/whiteboard canvas mode.
/// Shows two sections: background pattern and background color.
class InfiniteBackgroundPanel extends ConsumerWidget {
  const InfiniteBackgroundPanel({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final page = ref.watch(currentPageProvider);
    final bg = page.background;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Header(onClose: onClose),
        pageOptionsDivider(cs),
        InfiniteBackgroundPatternSection(background: bg),
        pageOptionsDivider(cs),
        InfiniteBackgroundColorSection(background: bg),
        const SizedBox(height: 12),
      ],
    );

    return Material(
      color: cs.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      elevation: 8,
      shadowColor: cs.shadow.withValues(alpha: 0.26),
      child: SizedBox(width: 280, child: content),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 8, 10),
      child: Row(children: [
        Expanded(
            child: Text('Arka Plan',
                style: textTheme.titleMedium?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface))),
        IconButton(
          icon: PhosphorIcon(PhosphorIconsLight.x,
              size: 20, color: cs.onSurfaceVariant),
          onPressed: onClose,
          visualDensity: VisualDensity.compact,
        ),
      ]),
    );
  }
}
