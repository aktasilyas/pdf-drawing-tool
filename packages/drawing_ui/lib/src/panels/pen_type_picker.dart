import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_ui/src/models/models.dart';
import 'package:drawing_ui/src/panels/pen_type_tile.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/toolbar/toolbar_layout_mode.dart';

// Mirrors AppSpacing (drawing_ui cannot import example_app).
const double _kSm = 8;
const double _kMd = 12;
const double _kLg = 16;
const double _kTabletTileWidth = 64;
const double _kMinTileWidth = 60;

/// Horizontal row of the five pen presets, each with a live stroke preview.
///
/// Order is fixed: fountain, ballpoint, brush, highlighter, pencil. Selected
/// means the current tool equals the tile's tool (legacy tools select none).
class PenTypePicker extends ConsumerWidget {
  const PenTypePicker({super.key, this.onPenSelected, this.padding});

  final ValueChanged<ToolType>? onPenSelected;

  /// Overrides the default padding (use [EdgeInsets.zero] when embedded).
  final EdgeInsets? padding;

  static const _pens = [
    (ToolType.fountainPen, 'Dolma Kalem'),
    (ToolType.ballpointPen, 'Tükenmez Kalem'),
    (ToolType.brushPen, 'Fırça Kalem'),
    (ToolType.highlighter, 'Fosforlu Kalem'),
    (ToolType.pencil, 'Kurşun Kalem'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(currentToolProvider);
    final tablet =
        MediaQuery.sizeOf(context).width >= ToolbarLayoutMode.compactBreakpoint;
    final insets = padding ??
        EdgeInsets.symmetric(horizontal: tablet ? _kMd : _kLg, vertical: _kMd);

    Widget tile(ToolType tool, String label) => PenTypeTile(
          tool: tool,
          label: label,
          selected: tool == current,
          onTap: () {
            ref.read(currentToolProvider.notifier).selectTool(tool);
            onPenSelected?.call(tool);
          },
        );

    const tiles = _pens;

    return Semantics(
      container: true,
      label: 'Kalem türü',
      child: Padding(
        padding: insets,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final gaps = _kSm * (tiles.length - 1);
            final perTile = (constraints.maxWidth - gaps) / tiles.length;
            Widget gap() => const SizedBox(width: _kSm);
            if (tablet && perTile >= _kTabletTileWidth ||
                !tablet && perTile >= _kMinTileWidth) {
              return Row(
                mainAxisSize: tablet ? MainAxisSize.min : MainAxisSize.max,
                children: [
                  for (var i = 0; i < tiles.length; i++) ...[
                    if (i > 0) gap(),
                    tablet
                        ? SizedBox(
                            width: _kTabletTileWidth,
                            child: tile(tiles[i].$1, tiles[i].$2),
                          )
                        : Expanded(child: tile(tiles[i].$1, tiles[i].$2)),
                  ],
                ],
              );
            }
            // Too narrow: scroll instead of shrinking the tiles.
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var i = 0; i < tiles.length; i++) ...[
                    if (i > 0) gap(),
                    SizedBox(
                      width: _kMinTileWidth,
                      child: tile(tiles[i].$1, tiles[i].$2),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
