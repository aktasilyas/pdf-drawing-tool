import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
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
          Text('Resim Ekle', style: TextStyle(
            fontSize: 15, fontWeight: FontWeight.w600, color: cs.onSurface)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ImageSourceButton(
                  icon: StarNoteIcons.images,
                  label: 'Album',
                  onTap: () => _pickFromAlbum(context, ref),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ImageSourceButton(
                  icon: StarNoteIcons.camera,
                  label: 'Kamera',
                  onTap: () => _takePhoto(context, ref),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _CompactLockedSection(
            title: 'Bulut Depolama',
            onTap: () => _showPremiumPrompt(context),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFromAlbum(BuildContext context, WidgetRef ref) async {
    await _pickImage(context, ref, ImageSource.gallery);
  }

  Future<void> _takePhoto(BuildContext context, WidgetRef ref) async {
    await _pickImage(context, ref, ImageSource.camera);
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

  void _showPremiumPrompt(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bulut depolama icin abonelik gerekli'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

/// Compact locked section.
class _CompactLockedSection extends StatelessWidget {
  const _CompactLockedSection({
    required this.title,
    required this.onTap,
  });

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            PhosphorIcon(StarNoteIcons.cloud, size: 14, color: Colors.grey),
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF666666),
              ),
            ),
            const Spacer(),
            PhosphorIcon(StarNoteIcons.lock, size: 12, color: Colors.orange),
          ],
        ),
      ),
    );
  }
}

/// Button for image source selection - compact.
class _ImageSourceButton extends StatelessWidget {
  const _ImageSourceButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF4A9DFF).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: const Color(0xFF4A9DFF).withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: const Color(0xFF4A9DFF)),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Color(0xFF4A9DFF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
