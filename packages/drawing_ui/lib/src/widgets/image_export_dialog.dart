/// Dialog for image export / share options.
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:drawing_ui/src/theme/starnote_icons.dart';

/// Supported image export formats.
enum ImageFormat {
  png('PNG', 'Kayıpsız kalite, şeffaf arka plan desteği'),
  jpg('JPG', 'Küçük dosya boyutu, fotoğraflar için ideal');

  const ImageFormat(this.label, this.description);
  final String label;
  final String description;
}

/// Image export quality presets.
enum ImageQuality {
  low(72, 'Düşük (72 DPI)'),
  medium(150, 'Orta (150 DPI)'),
  high(300, 'Yüksek (300 DPI)');

  const ImageQuality(this.dpi, this.label);
  final int dpi;
  final String label;
}

/// Configuration returned from ImageExportDialog.
class ImageExportConfig {
  final ImageFormat format;
  final ImageQuality quality;
  final bool includeBackground;
  final bool shareMode;

  const ImageExportConfig({
    this.format = ImageFormat.png,
    this.quality = ImageQuality.high,
    this.includeBackground = true,
    this.shareMode = false,
  });
}

/// Dialog for selecting image export or share options.
class ImageExportDialog extends StatefulWidget {
  const ImageExportDialog({
    super.key,
    required this.totalPages,
    this.shareMode = false,
    this.onExport,
  });

  final int totalPages;
  final bool shareMode;
  final void Function(ImageExportConfig config)? onExport;

  @override
  State<ImageExportDialog> createState() => _ImageExportDialogState();
}

class _ImageExportDialogState extends State<ImageExportDialog> {
  ImageFormat _format = ImageFormat.png;
  ImageQuality _quality = ImageQuality.high;
  bool _includeBackground = true;

  void _handleExport() {
    final config = ImageExportConfig(
      format: _format,
      quality: _quality,
      includeBackground: _includeBackground,
      shareMode: widget.shareMode,
    );
    widget.onExport?.call(config);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final title = widget.shareMode ? 'Paylaş' : 'Resim Olarak Dışa Aktar';
    final buttonLabel = widget.shareMode ? 'Paylaş' : 'Dışa Aktar';

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 520),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _DialogHeader(title: title, pageCount: widget.totalPages, cs: cs),
            const SizedBox(height: 20),
            _FormatSelector(
              selected: _format, cs: cs,
              onChanged: (f) => setState(() => _format = f),
            ),
            const SizedBox(height: 16),
            _QualitySelector(
              selected: _quality, cs: cs,
              onChanged: (q) => setState(() => _quality = q),
            ),
            const SizedBox(height: 16),
            _BackgroundToggle(
              value: _includeBackground, cs: cs,
              onChanged: (v) => setState(() => _includeBackground = v),
            ),
            const SizedBox(height: 24),
            _ActionButtons(
              cs: cs, buttonLabel: buttonLabel,
              onCancel: () => Navigator.of(context).pop(),
              onExport: _handleExport,
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogHeader extends StatelessWidget {
  const _DialogHeader({
    required this.title, required this.pageCount, required this.cs,
  });
  final String title;
  final int pageCount;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text('$pageCount sayfa',
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
      ],
    );
  }
}

class _FormatSelector extends StatelessWidget {
  const _FormatSelector({
    required this.selected, required this.cs, required this.onChanged,
  });
  final ImageFormat selected;
  final ColorScheme cs;
  final ValueChanged<ImageFormat> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Format', style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface)),
        const SizedBox(height: 8),
        Row(children: ImageFormat.values.map((fmt) {
          final isSelected = fmt == selected;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                  right: fmt != ImageFormat.values.last ? 8 : 0),
              child: _SelectableCard(
                label: fmt.label, isSelected: isSelected, cs: cs,
                onTap: () => onChanged(fmt),
              ),
            ),
          );
        }).toList()),
      ],
    );
  }
}

class _QualitySelector extends StatelessWidget {
  const _QualitySelector({
    required this.selected, required this.cs, required this.onChanged,
  });
  final ImageQuality selected;
  final ColorScheme cs;
  final ValueChanged<ImageQuality> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Kalite', style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface)),
        const SizedBox(height: 8),
        Row(children: ImageQuality.values.map((q) {
          final isSelected = q == selected;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                  right: q != ImageQuality.values.last ? 8 : 0),
              child: _SelectableCard(
                label: q.label, isSelected: isSelected, cs: cs,
                onTap: () => onChanged(q),
              ),
            ),
          );
        }).toList()),
      ],
    );
  }
}

class _SelectableCard extends StatelessWidget {
  const _SelectableCard({
    required this.label, required this.isSelected,
    required this.cs, required this.onTap,
  });
  final String label;
  final bool isSelected;
  final ColorScheme cs;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: isSelected ? cs.primaryContainer : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? cs.primary : cs.outlineVariant, width: 1),
        ),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(
          fontSize: 12, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? cs.onPrimaryContainer : cs.onSurface,
        )),
      ),
    );
  }
}

class _BackgroundToggle extends StatelessWidget {
  const _BackgroundToggle({
    required this.value, required this.cs, required this.onChanged,
  });
  final bool value;
  final ColorScheme cs;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      PhosphorIcon(StarNoteIcons.image, size: 18, color: cs.onSurfaceVariant),
      const SizedBox(width: 8),
      Expanded(child: Text('Arka planı dahil et',
          style: TextStyle(fontSize: 13, color: cs.onSurface))),
      Switch(value: value, onChanged: onChanged),
    ]);
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.cs, required this.buttonLabel,
    required this.onCancel, required this.onExport,
  });
  final ColorScheme cs;
  final String buttonLabel;
  final VoidCallback onCancel;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: onCancel,
          child: Text('İptal', style: TextStyle(color: cs.onSurfaceVariant)),
        ),
        const SizedBox(width: 12),
        FilledButton(onPressed: onExport, child: Text(buttonLabel)),
      ],
    );
  }
}
