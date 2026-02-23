import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/models/selection_action.dart';
import 'package:drawing_ui/src/providers/document_provider.dart';
import 'package:drawing_ui/src/providers/selection_actions_provider.dart';
import 'package:drawing_ui/src/providers/canvas_transform_provider.dart';
import 'package:drawing_ui/src/theme/starnote_icons.dart';
import 'package:drawing_ui/src/widgets/selection_overflow_menu.dart';
import 'package:drawing_ui/src/widgets/selection_toolbar_buttons.dart';
import 'package:drawing_ui/src/widgets/compact_color_picker.dart';

/// Floating horizontal toolbar for selection actions.
///
/// Positioned below (or above) the selection bounding box.
/// The overflow menu opens as an Overlay, automatically positioned
/// to stay within screen bounds (shifts up/down/left as needed).
class SelectionToolbar extends ConsumerStatefulWidget {
  final Selection selection;
  const SelectionToolbar({super.key, required this.selection});

  @override
  ConsumerState<SelectionToolbar> createState() => _SelectionToolbarState();
}

class _SelectionToolbarState extends ConsumerState<SelectionToolbar> {
  OverlayEntry? _overflowEntry;
  final _moreKey = GlobalKey();

  bool get _isOverflowOpen => _overflowEntry != null;

  @override
  void dispose() {
    _overflowEntry?.remove();
    _overflowEntry = null;
    super.dispose();
  }

  int _getSelectedColor() {
    final doc = ref.read(documentProvider);
    final layer = doc.layers[doc.activeLayerIndex];
    for (final id in widget.selection.selectedStrokeIds) {
      final s = layer.getStrokeById(id);
      if (s != null) return s.style.color;
    }
    for (final id in widget.selection.selectedTextIds) {
      final t = layer.getTextById(id);
      if (t != null) return t.color;
    }
    return 0xFF000000;
  }

  @override
  Widget build(BuildContext context) {
    final transform = ref.watch(canvasTransformProvider);
    final bounds = widget.selection.bounds;

    final centerX =
        (bounds.left + bounds.right) / 2 * transform.zoom + transform.offset.dx;
    final bottomY = bounds.bottom * transform.zoom + transform.offset.dy + 12;
    final topY = bounds.top * transform.zoom + transform.offset.dy - 60;

    final screenHeight = MediaQuery.of(context).size.height;
    final useTop = bottomY + 52 > screenHeight - 48;
    final menuY = useTop ? topY : bottomY;

    final config = buildSelectionActionConfig(ref, widget.selection);
    final buttonCount = config.toolbarActions.length + 1;
    const buttonWidth = 40.0;
    final toolbarWidth = buttonCount * buttonWidth + 16;
    final screenWidth = MediaQuery.of(context).size.width;

    final rawLeft = centerX - toolbarWidth / 2;
    final clampedLeft = rawLeft.clamp(8.0, screenWidth - toolbarWidth - 8.0);

    return Positioned(
      left: clampedLeft,
      top: menuY,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) {},
        child: Material(
          color: Colors.transparent,
          child: _buildToolbarPill(config),
        ),
      ),
    );
  }

  Widget _buildToolbarPill(SelectionActionConfig config) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final action in config.toolbarActions)
            SelectionToolbarButton(
              action: action,
              onTap: () => _handleAction(action),
            ),
          Container(
            key: _moreKey,
            child: SelectionToolbarIconButton(
              icon: StarNoteIcons.more,
              tooltip: 'Daha fazla',
              onTap: () => _toggleOverflow(config),
              isActive: _isOverflowOpen,
            ),
          ),
        ],
      ),
    );
  }

  // ── Overflow menu (Overlay-based, auto-positioned) ──

  void _toggleOverflow(SelectionActionConfig config) {
    if (_isOverflowOpen) { _closeOverflow(); return; }
    _openOverflow(config);
  }

  void _openOverflow(SelectionActionConfig config) {
    final box = _moreKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;

    final btnPos = box.localToGlobal(Offset.zero);
    final btnSize = box.size;
    final screen = MediaQuery.of(context).size;
    final estH = _estOverflowHeight(config);
    const menuW = 230.0;
    const pad = 8.0;

    // Horizontal: prefer right of "..." button, fallback left
    var left = btnPos.dx + btnSize.width + 6;
    if (left + menuW > screen.width - pad) left = btnPos.dx - menuW - 6;
    left = left.clamp(pad, screen.width - menuW - pad);

    // Vertical: align with button top, shift up if it overflows bottom
    var top = btnPos.dy;
    if (top + estH > screen.height - pad) top = screen.height - estH - pad;
    if (top < pad) top = pad;

    _overflowEntry = OverlayEntry(
      builder: (_) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _closeOverflow,
        child: SizedBox.expand(
          child: Stack(children: [
            Positioned(
              left: left,
              top: top,
              child: GestureDetector(
                onTap: () {}, // absorb taps on menu itself
                child: SelectionOverflowMenu(
                  topRowActions: config.topRowActions,
                  actions: config.overflowActions,
                  onActionTap: (a) {
                    _closeOverflow();
                    a.onExecute?.call();
                  },
                ),
              ),
            ),
          ]),
        ),
      ),
    );
    Overlay.of(context).insert(_overflowEntry!);
    setState(() {});
  }

  void _closeOverflow() {
    _overflowEntry?.remove();
    _overflowEntry = null;
    if (mounted) setState(() {});
  }

  double _estOverflowHeight(SelectionActionConfig config) {
    final normals =
        config.overflowActions.where((a) => !a.isDestructive).length;
    final destructives =
        config.overflowActions.where((a) => a.isDestructive).length;
    double h = 0;
    if (config.topRowActions.isNotEmpty) h += 91;
    h += normals * 48 + (normals > 1 ? normals - 1 : 0);
    if (destructives > 0) h += 1 + destructives * 48;
    return h.clamp(0, 480);
  }

  // ── Action handlers ──

  void _handleAction(SelectionAction action) {
    if (!action.isEnabled) return;
    if (action.id == 'color') { _openColorPicker(); return; }
    action.onExecute?.call();
  }

  void _openColorPicker() {
    final currentColor = Color(_getSelectedColor());
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => Material(
        color: Colors.black.withValues(alpha: 137.0 / 255.0),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => entry.remove(),
          child: Center(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 320,
                  maxHeight: MediaQuery.of(ctx).size.height * 0.85,
                ),
                child: CompactColorPicker(
                  selectedColor: currentColor,
                  onColorSelected: (color) {
                    executeColorChange(
                        ref, widget.selection, color.toARGB32());
                    entry.remove();
                  },
                  onClose: () => entry.remove(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(entry);
  }
}
