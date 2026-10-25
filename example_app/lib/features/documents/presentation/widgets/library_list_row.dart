/// Shared 64dp row used by the library list view.
library;

import 'package:drawing_ui/drawing_ui.dart' show ElyanotesIcons;
import 'package:flutter/material.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/features/documents/presentation/widgets/library_tile_parts.dart';

/// Flat list row: 36x48 thumbnail, title + meta, trailing favorite star and
/// caret (or the selection checkbox while selecting).
class LibraryListRow extends StatelessWidget {
  const LibraryListRow({
    super.key,
    required this.thumbnail,
    required this.title,
    required this.meta,
    required this.onTap,
    required this.onLongPress,
    this.isSelected = false,
    this.isSelectionMode = false,
    this.isFavorite = false,
    this.onFavoriteTap,
  });

  /// Row height.
  static const double height = 64;

  /// Thumbnail size.
  static const Size thumbnailSize = Size(36, 48);

  /// Divider indent: `md + thumbnail + md`.
  static const double dividerIndent = AppSpacing.md + 36 + AppSpacing.md;

  final Widget thumbnail;
  final String title;
  final String meta;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool isSelected;
  final bool isSelectionMode;
  final bool isFavorite;
  final VoidCallback? onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final radius = BorderRadius.circular(AppRadius.md);

    return Material(
      color: isSelected ? palette.accentContainer : Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: radius,
        splashFactory: NoSplash.splashFactory,
        highlightColor: palette.textPrimary.withValues(alpha: 0.06),
        child: SizedBox(
          height: height,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                SizedBox.fromSize(size: thumbnailSize, child: thumbnail),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: AppTypography.titleLarge
                            .copyWith(color: palette.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        meta,
                        style: AppTypography.caption.copyWith(
                          color: palette.textMuted,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (isSelectionMode)
                  LibrarySelectionCheckbox(isSelected: isSelected)
                else ...[
                  if (isFavorite)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onFavoriteTap,
                      child: SizedBox.square(
                        dimension: AppSpacing.minTouchTarget,
                        child: Icon(
                          ElyanotesIcons.libraryStarFill,
                          size: AppIconSize.sm,
                          color: palette.textMuted,
                        ),
                      ),
                    ),
                  Icon(
                    ElyanotesIcons.libraryCaretRight,
                    size: AppIconSize.sm,
                    color: palette.textDisabled,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
