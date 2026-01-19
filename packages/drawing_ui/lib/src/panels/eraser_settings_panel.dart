import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart' as core;
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/panels/tool_panel.dart';

void _writeDebugLog({
  required String hypothesisId,
  required String message,
  Map<String, Object?> data = const {},
}) {
  try {
    final file = File(
      r'c:\Users\aktas\source\repos\starnote_drawing_workspace\.cursor\debug.log',
    );
    final payload = {
      'sessionId': 'debug-session',
      'runId': 'run1',
      'hypothesisId': hypothesisId,
      'location': 'panels/eraser_settings_panel.dart',
      'message': message,
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    file.writeAsStringSync(
      '${jsonEncode(payload)}\n',
      mode: FileMode.append,
    );
  } catch (_) {}
}

/// Settings panel for eraser tools.
///
/// Allows configuring eraser mode, size, and various options.
/// All changes update MOCK state only - no real drawing effect.
class EraserSettingsPanel extends ConsumerWidget {
  const EraserSettingsPanel({
    super.key,
    this.onClose,
  });

  /// Callback when panel is closed.
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(eraserSettingsProvider);
    final columnKey = GlobalKey();
    final buttonKey = GlobalKey();
    final showSizeSlider = settings.mode != EraserMode.lasso;

    // #region agent log - H1/H2/H3: Panel build
    _writeDebugLog(
      hypothesisId: 'H1',
      message: 'eraser_panel_build',
      data: {
        'mode': settings.mode.name,
        'showSizeSlider': showSizeSlider,
      },
    );
    // #endregion

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final columnBox = columnKey.currentContext?.findRenderObject() as RenderBox?;
      final buttonBox = buttonKey.currentContext?.findRenderObject() as RenderBox?;
      if (columnBox != null && buttonBox != null) {
        // #region agent log - H2: Panel layout sizes
        _writeDebugLog(
          hypothesisId: 'H2',
          message: 'eraser_panel_layout',
          data: {
            'panelHeight': columnBox.size.height,
            'panelWidth': columnBox.size.width,
            'buttonHeight': buttonBox.size.height,
            'buttonWidth': buttonBox.size.width,
          },
        );
        // #endregion
      }
    });

    return ToolPanel(
      title: 'Silgi',
      onClose: onClose,
      child: Column(
        key: columnKey,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mode selector
          _EraserModeSelector(
            selectedMode: settings.mode,
            onModeSelected: (mode) {
              ref.read(eraserSettingsProvider.notifier).setMode(mode);
            },
          ),
          const SizedBox(height: 8),

          // Size slider (only for pixel and stroke eraser)
          if (showSizeSlider)
            _CompactSizeSlider(
              label: 'Boyut',
              value: settings.size,
              min: 5.0,
              max: 100.0,
              onChanged: (value) {
                ref.read(eraserSettingsProvider.notifier).setSize(value);
              },
            ),
          const SizedBox(height: 8),

          // Options - compact toggles
          _CompactToggle(
            label: 'Basınç hassasiyeti',
            value: settings.pressureSensitive,
            onChanged: (value) {
              ref.read(eraserSettingsProvider.notifier).setPressureSensitive(value);
            },
          ),
          _CompactToggle(
            label: 'Sadece vurgulayıcı sil',
            value: settings.eraseOnlyHighlighter,
            onChanged: (value) {
              ref.read(eraserSettingsProvider.notifier).setEraseOnlyHighlighter(value);
            },
          ),
          _CompactToggle(
            label: 'Sadece bant sil',
            value: settings.eraseBandOnly,
            onChanged: (value) {
              ref.read(eraserSettingsProvider.notifier).setEraseBandOnly(value);
            },
          ),
          _CompactToggle(
            label: 'Otomatik kaldır',
            value: settings.autoLift,
            onChanged: (value) {
              ref.read(eraserSettingsProvider.notifier).setAutoLift(value);
            },
          ),
          const SizedBox(height: 8),

          // Clear page button (destructive action)
          _CompactActionButton(
            key: buttonKey,
            label: 'Sayfayı Temizle',
            icon: Icons.delete_outline,
            isDestructive: true,
            onPressed: () => _showClearConfirmation(context, ref),
          ),
        ],
      ),
    );
  }

  void _showClearConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sayfayı Temizle?'),
        content: const Text(
          'Bu sayfa içeriğini tamamen silecek. '
          'Bu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Clear active layer
              _clearActivePage(ref);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Temizle'),
          ),
        ],
      ),
    );
  }

  void _clearActivePage(WidgetRef ref) {
    final document = ref.read(documentProvider);
    final layerIndex = document.activeLayerIndex;
    
    // Clear all strokes, shapes, and texts from active layer
    ref.read(historyManagerProvider.notifier).execute(
      core.ClearLayerCommand(layerIndex: layerIndex),
    );
  }
}

/// Compact size slider
class _CompactSizeSlider extends StatelessWidget {
  const _CompactSizeSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF666666),
              ),
            ),
            const Spacer(),
            Text(
              '${value.toInt()}px',
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF999999),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        SizedBox(
          height: 22,
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
              activeTrackColor: const Color(0xFF4A9DFF),
              inactiveTrackColor: Colors.grey.shade200,
              thumbColor: const Color(0xFF4A9DFF),
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

/// Compact toggle row
class _CompactToggle extends StatelessWidget {
  const _CompactToggle({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF444444),
              ),
            ),
          ),
          Transform.scale(
            scale: 0.65,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: const Color(0xFF4A9DFF),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact action button
class _CompactActionButton extends StatelessWidget {
  const _CompactActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isDestructive = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? Colors.red : const Color(0xFF4A9DFF);
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Selector for eraser modes - compact version.
class _EraserModeSelector extends StatelessWidget {
  const _EraserModeSelector({
    required this.selectedMode,
    required this.onModeSelected,
  });

  final EraserMode selectedMode;
  final ValueChanged<EraserMode> onModeSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _EraserModeOption(
            mode: EraserMode.pixel,
            icon: Icons.auto_fix_normal,
            label: 'Piksel',
            isSelected: selectedMode == EraserMode.pixel,
            onTap: () => onModeSelected(EraserMode.pixel),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: _EraserModeOption(
            mode: EraserMode.stroke,
            icon: Icons.cleaning_services,
            label: 'Çizgi',
            isSelected: selectedMode == EraserMode.stroke,
            onTap: () => onModeSelected(EraserMode.stroke),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: _EraserModeOption(
            mode: EraserMode.lasso,
            icon: Icons.gesture,
            label: 'Kement',
            isSelected: selectedMode == EraserMode.lasso,
            onTap: () => onModeSelected(EraserMode.lasso),
            isPremium: true,
          ),
        ),
      ],
    );
  }
}

/// A single eraser mode option button - compact version.
class _EraserModeOption extends StatelessWidget {
  const _EraserModeOption({
    required this.mode,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.isPremium = false,
  });

  final EraserMode mode;
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isPremium;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4A9DFF).withValues(alpha: 0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: isSelected ? const Color(0xFF4A9DFF) : Colors.grey.shade300,
            width: isSelected ? 1.2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isSelected ? const Color(0xFF4A9DFF) : Colors.grey.shade600,
                ),
                if (isPremium)
                  const Positioned(
                    top: -2,
                    right: -2,
                    child: Icon(
                      Icons.lock,
                      size: 9,
                      color: Colors.orange,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? const Color(0xFF4A9DFF) : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
