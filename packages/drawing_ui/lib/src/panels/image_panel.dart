import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:drawing_ui/src/l10n/drawing_strings_scope.dart';
import 'package:drawing_ui/src/theme/theme.dart';
import 'package:drawing_ui/src/providers/drawing_providers.dart';
import 'package:drawing_ui/src/providers/image_provider.dart';
import 'package:drawing_ui/src/providers/pdf_path_provider.dart';
import 'package:drawing_ui/src/services/image_import_storage.dart';

/// Longest edge (px) of an inserted photo; the picker downscales to this
/// before the file is stored, keeping aspect ratio and EXIF orientation.
const double maxStoredImageEdge = 2560;

/// Settings panel for the image insertion tool.
///
/// Displays options to add images from album or camera.
/// Selected images enter placement mode (tap canvas to place).
class ImagePanel extends ConsumerWidget {
  const ImagePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final c = context.drawingStrings.canvas;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            c.addImage,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            c.addImageHint,
            style: TextStyle(
              fontSize: 11,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          _ImageSourceTile(
            icon: ElyanotesIcons.images,
            label: c.fromGallery,
            subtitle: c.fromGalleryHint,
            onTap: () => _pickImage(context, ref, ImageSource.gallery),
          ),
          const SizedBox(height: 8),
          _ImageSourceTile(
            icon: ElyanotesIcons.camera,
            label: c.takePhoto,
            subtitle: c.takePhotoHint,
            onTap: () => _pickImage(context, ref, ImageSource.camera),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(
    BuildContext context,
    WidgetRef ref,
    ImageSource source,
  ) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: maxStoredImageEdge,
      maxHeight: maxStoredImageEdge,
    );
    if (picked == null) return;

    // Copy into the app container; persist the container-relative path.
    final appDir = await getApplicationDocumentsDirectory();
    final stored = await storeImportedImage(
      picked.path,
      documentsRoot: appDir.path,
      paths: ref.read(pdfPathResolverProvider),
    );

    // Enter placement mode
    ref.read(imagePlacementProvider.notifier).selectImagePath(stored);

    // Close the panel
    if (context.mounted) {
      ref.read(activePanelProvider.notifier).state = null;
    }
  }
}

/// A list-tile style button for image source selection.
class _ImageSourceTile extends StatelessWidget {
  const _ImageSourceTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: cs.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
