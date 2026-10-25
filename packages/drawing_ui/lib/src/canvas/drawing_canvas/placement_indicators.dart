part of 'package:drawing_ui/src/canvas/drawing_canvas.dart';

/// Banners shown while a sticker or an image is being placed.
mixin _PlacementIndicators on DrawingCanvasGestureHandlers<DrawingCanvas> {
  Widget _buildStickerIndicator() {
    return Builder(
      builder: (context) {
        final stickerState = ref.watch(stickerPlacementProvider);
        if (!stickerState.isPlacing || stickerState.selectedEmoji == null) {
          return const SizedBox.shrink();
        }
        return Positioned(
          top: 60,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(stickerState.selectedEmoji!,
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(width: 8),
                  Text(
                    'Yerleştirmek için dokunun',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () =>
                        ref.read(stickerPlacementProvider.notifier).cancel(),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close,
                          color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageIndicator() {
    return Builder(
      builder: (context) {
        final imageState = ref.watch(imagePlacementProvider);
        if (!imageState.isPlacing) {
          return const SizedBox.shrink();
        }
        return Positioned(
          top: 60,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PhosphorIcon(ElyanotesIcons.image,
                      color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Resmi yerlesirmek icin dokunun',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () =>
                        ref.read(imagePlacementProvider.notifier).cancel(),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close,
                          color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
