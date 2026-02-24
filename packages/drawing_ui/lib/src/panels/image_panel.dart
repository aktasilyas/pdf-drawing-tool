import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:drawing_ui/src/theme/theme.dart';
import 'package:drawing_ui/src/providers/drawing_providers.dart';
import 'package:drawing_ui/src/providers/image_provider.dart';

/// Settings panel for the image insertion tool.
///
/// Displays options to add images from album or camera.
/// Selected images enter placement mode (tap canvas to place).
class ImagePanel extends ConsumerWidget {
  const ImagePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resim Ekle',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Galeriden veya kamerayla resim ekleyin',
            style: TextStyle(
              fontSize: 11,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          _ImageSourceTile(
            icon: StarNoteIcons.images,
            label: 'Galeriden Se\u00e7',
            subtitle: 'Alb\u00fcmden bir resim se\u00e7in',
            onTap: () => _pickImage(context, ref, ImageSource.gallery),
          ),
          const SizedBox(height: 8),
          _ImageSourceTile(
            icon: StarNoteIcons.camera,
            label: 'Foto\u011fraf \u00c7ek',
            subtitle: 'Kamera ile yeni foto\u011fraf \u00e7ekin',
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
    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;

    // Copy to app documents directory for persistence
    final appDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory('${appDir.path}/starnote_images');
    if (!imagesDir.existsSync()) {
      imagesDir.createSync(recursive: true);
    }

    final ext = picked.path.split('.').last;
    final fileName = '${DateTime.now().microsecondsSinceEpoch}.$ext';
    final destPath = '${imagesDir.path}/$fileName';
    await File(picked.path).copy(destPath);

    // Enter placement mode
    ref.read(imagePlacementProvider.notifier).selectImagePath(destPath);

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
