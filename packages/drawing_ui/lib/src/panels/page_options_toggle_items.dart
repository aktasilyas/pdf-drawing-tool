import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/theme/theme.dart';

/// Toggle switch item for settings.
class PageOptionsToggleItem extends StatelessWidget {
  const PageOptionsToggleItem({
    super.key,
    required this.icon,
    required this.label,
    this.subtitle,
    required this.value,
    required this.onChanged,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: compact ? 40 : 48),
      child: Padding(
        padding:
            EdgeInsets.symmetric(horizontal: compact ? ChromeSpacing.lg : 20),
        child: Row(
          children: [
            PhosphorIcon(icon, size: compact ? 20 : 22, color: cs.onSurface),
            SizedBox(width: compact ? ChromeSpacing.md : ChromeSpacing.lg),
            Expanded(
              child: subtitle != null
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label,
                            style: compact
                                ? Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                        fontSize: 13, color: cs.onSurface)
                                : Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                        fontSize: 15, color: cs.onSurface)),
                        Text(subtitle!,
                            style: compact
                                ? Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(color: cs.onSurfaceVariant)
                                : Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: cs.onSurfaceVariant)),
                      ],
                    )
                  : Text(label,
                      style: compact
                          ? Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(fontSize: 13, color: cs.onSurface)
                          : Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontSize: 15, color: cs.onSurface)),
            ),
            Switch.adaptive(
              value: value,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

/// Scroll direction toggle for page options settings.
class ScrollDirectionItem extends ConsumerWidget {
  const ScrollDirectionItem(
      {super.key, required this.onClose, this.compact = false});
  final VoidCallback onClose;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final direction = ref.watch(scrollDirectionProvider);
    final isHorizontal = direction == Axis.horizontal;
    return PageOptionsToggleItem(
      icon: isHorizontal
          ? ElyanotesIcons.scrollDirection
          : ElyanotesIcons.scrollDirectionVertical,
      label: 'Kaydırma yönü',
      subtitle: isHorizontal ? 'Yatay' : 'Dikey',
      value: isHorizontal,
      onChanged: (v) => ref.read(scrollDirectionProvider.notifier).state =
          v ? Axis.horizontal : Axis.vertical,
      compact: compact,
    );
  }
}
