/// Self-contained document title pill with popover menu.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:drawing_ui/src/panels/document_options_panel.dart';
import 'package:drawing_ui/src/theme/theme.dart';
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
    final colorScheme = Theme.of(context).colorScheme;
    final label = widget.title ?? 'İsimsiz Not';

    return Tooltip(
      message: 'Doküman Seçenekleri',
      child: Semantics(
        label: label,
        button: true,
        child: GestureDetector(
          key: _anchorKey,
          onTap: _toggle,
          child: Container(
            constraints: BoxConstraints(maxWidth: widget.maxWidth),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 3),
              PhosphorIcon(
                StarNoteIcons.caretDown,
                size: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
