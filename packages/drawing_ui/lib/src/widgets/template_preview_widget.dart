import 'package:flutter/material.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/painters/template_pattern_painter.dart';

/// Template önizleme widget'ı.
/// Tema renklerini otomatik alır, hardcoded renk kullanmaz.
class TemplatePreviewWidget extends StatelessWidget {
  final Template template;
  final Size? size;
  final Color? lineColorOverride;
  final Color? backgroundColorOverride;
  final BorderRadius? borderRadius;
  final bool showBorder;

  const TemplatePreviewWidget({
    super.key,
    required this.template,
    this.size,
    this.lineColorOverride,
    this.backgroundColorOverride,
    this.borderRadius,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Tema renklerini kullan, override varsa onu al
    final lineColor = lineColorOverride ?? colorScheme.outlineVariant;
    final backgroundColor = backgroundColorOverride ?? colorScheme.surface;
    final borderColor = colorScheme.outline.withValues(alpha: 0.3);

    return Container(
      width: size?.width,
      height: size?.height,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(8),
        border: showBorder ? Border.all(color: borderColor, width: 1) : null,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: CustomPaint(
        painter: TemplatePatternPainter.fromTemplate(
          template,
          lineColor: lineColor,
          backgroundColor: backgroundColor,
          pageSize: size ?? const Size(200, 280),
        ),
        size: size ?? Size.infinite,
      ),
    );
  }
}
