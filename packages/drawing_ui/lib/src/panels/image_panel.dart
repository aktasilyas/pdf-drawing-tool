import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_ui/src/panels/tool_panel.dart';

/// Settings panel for the image insertion tool.
///
/// Displays recent images and options to add from album or camera.
/// All interactions are MOCKED - no real image insertion.
class ImagePanel extends ConsumerWidget {
  const ImagePanel({
    super.key,
    this.onClose,
  });

  /// Callback when panel is closed.
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ToolPanel(
      title: 'Resim Ekle',
      onClose: onClose,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Source buttons - compact
          Row(
            children: [
              Expanded(
                child: _ImageSourceButton(
                  icon: Icons.photo_library,
                  label: 'Albüm',
                  onTap: () => _pickFromAlbum(context),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ImageSourceButton(
                  icon: Icons.camera_alt,
                  label: 'Kamera',
                  onTap: () => _takePhoto(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Recent images - compact
          const Text(
            'Son Resimler',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 8),
          _RecentImagesGrid(
            onImageSelected: (index) {
              // MOCK: Would insert image
              onClose?.call();
            },
          ),
          const SizedBox(height: 12),

          // Cloud images (premium) - compact
          _CompactLockedSection(
            title: 'Bulut Depolama',
            onTap: () => _showPremiumPrompt(context),
          ),
        ],
      ),
    );
  }

  void _pickFromAlbum(BuildContext context) {
    // MOCK: Would open image picker
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fotoğraf albümü açılacak'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _takePhoto(BuildContext context) {
    // MOCK: Would open camera
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Kamera açılacak'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _showPremiumPrompt(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bulut depolama için abonelik gerekli'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

/// Compact locked section
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
            const Icon(Icons.cloud, size: 14, color: Colors.grey),
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF666666),
              ),
            ),
            const Spacer(),
            const Icon(Icons.lock, size: 12, color: Colors.orange),
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
          border: Border.all(color: const Color(0xFF4A9DFF).withValues(alpha: 0.3)),
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

/// Grid of recent images (mock placeholders) - compact.
class _RecentImagesGrid extends StatelessWidget {
  const _RecentImagesGrid({
    required this.onImageSelected,
  });

  final ValueChanged<int> onImageSelected;

  @override
  Widget build(BuildContext context) {
    // MOCK: Generate placeholder images
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
      ),
      itemCount: 8,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () => onImageSelected(index),
          child: Container(
            decoration: BoxDecoration(
              color: _getMockImageColor(index),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Icon(
                Icons.image,
                size: 20,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getMockImageColor(int index) {
    final colors = [
      Colors.blue.shade300,
      Colors.green.shade300,
      Colors.orange.shade300,
      Colors.purple.shade300,
      Colors.teal.shade300,
      Colors.pink.shade300,
      Colors.indigo.shade300,
      Colors.amber.shade300,
    ];
    return colors[index % colors.length];
  }
}
