import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/theme/starnote_icons.dart';

/// Floating zoom control bar with lock, percentage, favorite star, and chips.
///
/// Shows the current zoom percentage (relative to baselineZoom),
/// a lock toggle (disables pinch zoom), a favorite star (saves current %),
/// and quick-access chips for favorite zoom levels.
class ZoomControlBar extends ConsumerWidget {
  const ZoomControlBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transform = ref.watch(canvasTransformProvider);
    final percentage = transform.displayPercentage.round();
    final isLocked = ref.watch(zoomLockedProvider);
    final favorites = ref.watch(favoriteZoomsProvider);
    final isFavorite = favorites.contains(percentage);
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _BarIconButton(
            icon: isLocked ? StarNoteIcons.lockFilled : StarNoteIcons.lockOpen,
            isActive: isLocked,
            onTap: () =>
                ref.read(zoomLockedProvider.notifier).state = !isLocked,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '$percentage%',
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _BarIconButton(
            icon: isFavorite ? StarNoteIcons.starFilled : StarNoteIcons.star,
            isActive: isFavorite,
            onTap: () => ref
                .read(favoriteZoomsProvider.notifier)
                .toggleFavorite(percentage),
          ),
          Container(
            width: 1,
            height: 24,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            color: cs.outlineVariant,
          ),
          ...favorites.map(
            (z) => Padding(
              padding: const EdgeInsets.only(right: 4),
              child: _FavoriteChip(
                percentage: z,
                isActive: percentage == z,
                onTap: () => _goToFavorite(ref, transform, z),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _goToFavorite(WidgetRef ref, CanvasTransform transform, int percent) {
    final targetZoom = transform.baselineZoom * percent / 100;
    final viewportSize = ref.read(canvasViewportSizeProvider);
    final page = ref.read(currentPageProvider);
    final pageSize = Size(page.size.width, page.size.height);

    if (viewportSize == Size.zero) return;

    ref.read(canvasTransformProvider.notifier).goToZoom(
          targetZoom: targetZoom,
          viewportSize: viewportSize,
          pageSize: pageSize,
        );
  }
}

/// Icon button used in the zoom control bar.
class _BarIconButton extends StatelessWidget {
  const _BarIconButton({
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 48,
        height: 48,
        child: Center(
          child: PhosphorIcon(
            icon,
            size: StarNoteIcons.actionSize,
            color: isActive ? cs.primary : cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// Chip button for a favorite zoom level.
class _FavoriteChip extends StatelessWidget {
  const _FavoriteChip({
    required this.percentage,
    required this.isActive,
    required this.onTap,
  });

  final int percentage;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? cs.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '$percentage%',
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            color: isActive ? cs.onPrimaryContainer : cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
