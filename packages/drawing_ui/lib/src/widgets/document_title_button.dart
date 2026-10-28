/// Self-contained document title pill with popover menu.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import 'package:drawing_ui/src/l10n/l10n.dart';
import 'package:drawing_ui/src/panels/document_options_panel.dart';
import 'package:drawing_ui/src/theme/theme.dart';
import 'package:drawing_ui/src/toolbar/chrome_icon_button.dart';
import 'package:drawing_ui/src/widgets/popover_panel.dart';

/// Tappable title pill that opens a [DocumentOptionsPanel] popover.
///
/// Self-contained: owns its own [PopoverController] and anchor key,
/// so it works in both [ToolbarNavLeft] and [TopNavigationBar] without
/// threading state through the hierarchy.
class DocumentTitleButton extends ConsumerStatefulWidget {
  const DocumentTitleButton({
    super.key,
    this.title,
    required this.onRename,
    required this.onDelete,
    this.maxWidth = 160,
  });

  final String? title;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final double maxWidth;

  @override
  ConsumerState<DocumentTitleButton> createState() =>
      _DocumentTitleButtonState();
}

class _DocumentTitleButtonState extends ConsumerState<DocumentTitleButton> {
  final PopoverController _popover = PopoverController();
  final GlobalKey _anchorKey = GlobalKey();
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  void dispose() {
    _popover.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_popover.isShowing) {
      _popover.hide();
      return;
    }
    _popover.show(
      context: context,
      anchorKey: _anchorKey,
      maxWidth: 240,
      onDismiss: () {},
      child: DocumentOptionsPanel(
        onRename: widget.onRename,
        onDelete: widget.onDelete,
        onClose: () => _popover.hide(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = ChromePalette.of(context);
    final textTheme = Theme.of(context).textTheme;
    final strings = context.drawingStrings;
    final title = widget.title;
    final label =
        (title == null || title.isEmpty) ? strings.toolbar.untitled : title;
    final fill = _pressed
        ? palette.textPrimary.withValues(alpha: ChromeIconButton.pressedAlpha)
        : palette.textPrimary.withValues(alpha: 0);

    return Tooltip(
      message: strings.pages.documentOptions,
      child: Semantics(
        label: label,
        button: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _toggle,
          onTapDown: (_) => _setPressed(true),
          onTapUp: (_) => _setPressed(false),
          onTapCancel: () => _setPressed(false),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: ChromeSizes.minTouchTarget,
              maxWidth: widget.maxWidth,
            ),
            child: Center(
              widthFactor: 1,
              child: Container(
                key: _anchorKey,
                height: ChromeIconButton.visualSize,
                padding: const EdgeInsets.symmetric(
                  horizontal: ChromeSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: fill,
                  borderRadius: BorderRadius.circular(ChromeRadius.md),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          fontSize: 13,
                          color: palette.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: ChromeSpacing.xs),
                    PhosphorIcon(
                      ElyanotesIcons.caretDown,
                      size: ChromeIconSizes.sm,
                      color: palette.textMuted,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
