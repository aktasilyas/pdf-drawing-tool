import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:drawing_ui/drawing_ui.dart' show CoverGeometry;

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/features/documents/presentation/widgets/library_tile_parts.dart';

Rect _boardRect(Size box) => CoverGeometry.of(box).cover;

/// Top-left of the selection checkbox in the cover box [box]: `sm` below the
/// box top and `sm` inside the cover board's right edge (6% of the width in
/// from the box edge), so every checkbox in a row shares one y.
Offset libraryCheckboxOffset(Size box) => Offset(
      box.width * 0.94 - AppSpacing.sm - LibrarySelectionCheckbox.size,
      AppSpacing.sm,
    );

List<Widget> _noOverlays(Rect board) => const <Widget>[];

/// Shared frame of document and folder tiles: a 3:4 cover box bottom-aligned
/// above an info block, a selection backdrop, a press scale and the
/// selection checkbox. Overlays are positioned in the cover box's
/// coordinates; [overlays] receives the cover board rect inside that box.
class LibraryTileFrame extends StatefulWidget {
  const LibraryTileFrame({
    super.key,
    required this.cover,
    required this.info,
    required this.onTap,
    required this.onLongPress,
    this.semanticLabel,
    this.isSelected = false,
    this.isSelectionMode = false,
    this.overlays = _noOverlays,
    this.artRect,
  });

  final Widget cover;
  final Widget info;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  /// Screen-reader label of the cover tap target (the item's title).
  final String? semanticLabel;

  final bool isSelected;
  final bool isSelectionMode;
  final List<Widget> Function(Rect board) overlays;

  /// Rect of the visible art inside the cover box. Defaults to the cover
  /// board; used for the checkbox and passed to [overlays].
  final Rect Function(Size box)? artRect;

  /// Scale while the tile is pressed.
  static const double pressedScale = 0.97;

  /// Width of the selection / focus ring.
  static const double ringWidth = 1.5;

  @override
  State<LibraryTileFrame> createState() => _LibraryTileFrameState();
}

class _LibraryTileFrameState extends State<LibraryTileFrame> {
  // Local state is fine here: a tile, not the ink path.
  bool _pressed = false;
  bool _focused = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      onShowFocusHighlight: (value) => setState(() => _focused = value),
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onTap();
            return null;
          },
        ),
      },
      child: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          _buildBackdrop(context),
          AnimatedScale(
            scale: _pressed ? LibraryTileFrame.pressedScale : 1,
            duration: AppDurations.instant,
            curve: AppCurves.enter,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildCover()),
                widget.info,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackdrop(BuildContext context) {
    final palette = context.palette;
    final ring = widget.isSelected || _focused;
    return Positioned(
      left: -AppSpacing.sm,
      top: -AppSpacing.sm,
      right: -AppSpacing.sm,
      bottom: -AppSpacing.sm,
      child: IgnorePointer(
        child: AnimatedContainer(
          duration: AppDurations.fast,
          curve: AppCurves.enter,
          decoration: BoxDecoration(
            color: widget.isSelected ? palette.accentContainer : null,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: ring ? palette.accent : Colors.transparent,
              width: LibraryTileFrame.ringWidth,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCover() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = math.min(
          constraints.maxWidth,
          constraints.maxHeight * 3 / 4,
        );
        final box = Size(width, width * 4 / 3);
        final art = (widget.artRect ?? _boardRect)(box);
        return Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            width: box.width,
            height: box.height,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: Semantics(
                    container: true,
                    button: true,
                    label: widget.semanticLabel,
                    onTap: widget.onTap,
                    onLongPress: widget.onLongPress,
                    excludeSemantics: true,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: widget.onTap,
                      onLongPress: widget.onLongPress,
                      onTapDown: (_) => _setPressed(true),
                      onTapUp: (_) => _setPressed(false),
                      onTapCancel: () => _setPressed(false),
                      child: widget.cover,
                    ),
                  ),
                ),
                ...widget.overlays(art),
                if (widget.isSelectionMode)
                  Positioned(
                    left: libraryCheckboxOffset(box).dx,
                    top: libraryCheckboxOffset(box).dy,
                    child: IgnorePointer(
                      child: LibrarySelectionCheckbox(
                        isSelected: widget.isSelected,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
