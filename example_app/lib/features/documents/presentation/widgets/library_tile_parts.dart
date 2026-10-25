import 'package:flutter/material.dart';
import 'package:drawing_ui/drawing_ui.dart' show ElyanotesIcons;

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/features/documents/domain/entities/document_info.dart';
import 'package:example_app/features/documents/domain/entities/folder.dart';
import 'package:example_app/features/documents/presentation/widgets/document_card_helpers.dart';

/// Round selection marker on the top-right of a tile's cover board.
class LibrarySelectionCheckbox extends StatelessWidget {
  const LibrarySelectionCheckbox({super.key, required this.isSelected});

  final bool isSelected;

  static const double size = 24;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return AnimatedContainer(
      duration: AppDurations.fast,
      curve: AppCurves.enter,
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected
            ? palette.accent
            : palette.surfaceElevated.withValues(alpha: 0.92),
        border: Border.all(
          color: isSelected ? palette.accent : palette.textMuted,
          width: 1.5,
        ),
      ),
      child: isSelected
          ? Icon(
              ElyanotesIcons.libraryCheck,
              size: AppIconSize.sm,
              color: palette.onAccent,
            )
          : null,
    );
  }
}

/// Filled star disc shown on favorite tiles (48dp hit area).
class LibraryFavoriteBadge extends StatelessWidget {
  const LibraryFavoriteBadge({super.key, required this.onTap});

  final VoidCallback? onTap;

  /// Hit area edge.
  static const double hitSize = AppSpacing.minTouchTarget;

  /// Visible disc edge.
  static const double discSize = 24;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return SizedBox(
      width: hitSize,
      height: hitSize,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: Container(
            width: discSize,
            height: discSize,
            decoration: BoxDecoration(
              color: palette.surfaceElevated,
              shape: BoxShape.circle,
            ),
            child: Icon(
              ElyanotesIcons.libraryStarFill,
              size: AppIconSize.sm,
              color: palette.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Title + meta block under a tile's cover. The whole block (including the
/// `sm` gap above the title) is the tap target for the item menu.
class LibraryTileInfo extends StatelessWidget {
  const LibraryTileInfo({
    super.key,
    required this.title,
    required this.meta,
    this.onTap,
    this.showCaret = true,
    this.caretKey,
  });

  final String title;
  final String meta;
  final VoidCallback? onTap;
  final bool showCaret;
  final Key? caretKey;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSpacing.minTouchTarget),
        child: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: AppTypography.titleLarge
                          .copyWith(color: palette.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (showCaret)
                    Padding(
                      padding: const EdgeInsets.only(left: AppSpacing.xs),
                      child: Icon(
                        ElyanotesIcons.libraryCaretDown,
                        key: caretKey,
                        size: AppIconSize.sm,
                        color: palette.textMuted,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxs),
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
      ),
    );
  }
}

/// Meta line texts for library tiles.
abstract final class LibraryMeta {
  static String document(DocumentInfo d) =>
      '${DocumentDateFormatter.format(d.updatedAt)}'
      '${d.pageCount > 1 ? ' · ${d.pageCount} sayfa' : ''}';

  static String folder(Folder f) => '${f.documentCount} belge';
}
