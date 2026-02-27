import 'package:flutter/material.dart';
import 'package:drawing_core/drawing_core.dart';

/// Kapak önizleme widget'ı - başlık gösterimli
class CoverPreviewWidget extends StatelessWidget {
  final Cover cover;
  final String? title;
  final double? width;
  final double? height;
  final bool showBorder;
  final BorderRadius? borderRadius;

  const CoverPreviewWidget({
    super.key,
    required this.cover,
    this.title,
    this.width,
    this.height,
    this.showBorder = true,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = borderRadius ?? BorderRadius.circular(8);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: radius,
        border: showBorder
            ? Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
                width: 1,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Kapak arka planı
            _buildBackground(theme),

            // Başlık
            if (cover.showTitle && title != null && title!.isNotEmpty)
              _buildTitle(theme),

            // Dekoratif çizgiler (notebook efekti)
            _buildDecoration(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground(ThemeData theme) {
    switch (cover.style) {
      case CoverStyle.solid:
        return Container(color: Color(cover.primaryColor));

      case CoverStyle.gradient:
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(cover.primaryColor),
                Color(cover.secondaryColor ?? cover.primaryColor),
              ],
            ),
          ),
        );

      case CoverStyle.pattern:
        return _buildPatternBackground();

      case CoverStyle.minimal:
        return _buildMinimalBackground(theme);

      case CoverStyle.image:
        return _buildImageBackground();
    }
  }

  Widget _buildPatternBackground() {
    final bgColor = Color(cover.primaryColor);
    
    // Desenli kapak için CustomPaint
    return CustomPaint(
      painter: _CoverPatternPainter(
        backgroundColor: bgColor,
        patternType: cover.id.contains('dots') ? 'dots' : 'lines',
      ),
    );
  }

  Widget _buildMinimalBackground(ThemeData theme) {
    final bgColor = Color(cover.primaryColor);
    final luminance = bgColor.computeLuminance();
    final surface = theme.colorScheme.surface;

    // Minimal: Açık arka plan + koyu çerçeve veya tam tersi
    final frameColor = luminance > 0.5 ? bgColor : surface;
    final backgroundColor = luminance > 0.5 ? surface : bgColor;
    
    return Container(
      color: backgroundColor,
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: frameColor.withValues(alpha: 0.3),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(
              color: frameColor.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageBackground() {
    if (cover.imagePath != null) {
      return Image.asset(
        cover.imagePath!,
        fit: BoxFit.cover,
        width: width,
        height: height,
        errorBuilder: (_, __, ___) => Container(
          color: Color(cover.primaryColor),
        ),
      );
    }
    // imagePath yoksa primaryColor fallback
    return Container(color: Color(cover.primaryColor));
  }

  Widget _buildTitle(ThemeData theme) {
    // Renk kontrastına göre başlık rengi
    final bgColor = Color(cover.primaryColor);
    final luminance = bgColor.computeLuminance();
    final titleColor = luminance > 0.5
        ? theme.colorScheme.onSurface
        : theme.colorScheme.surface;

    return Positioned(
      left: 16,
      right: 16,
      bottom: 24,
      child: Text(
        title!,
        style: TextStyle(
          color: titleColor,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
          shadows: [
            Shadow(
              color: theme.colorScheme.shadow.withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildDecoration(ThemeData theme) {
    final shadow = theme.colorScheme.shadow;
    final onSurface = theme.colorScheme.onSurface;

    // Sol kenarda notebook cilt efekti
    return Positioned(
      left: 0,
      top: 0,
      bottom: 0,
      child: Container(
        width: 12,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              shadow.withValues(alpha: 0.2),
              shadow.withValues(alpha: 0.05),
              shadow.withValues(alpha: 0),
            ],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final dotSize = 6.0;
            final minSpacing = 4.0;
            final maxDots = (constraints.maxHeight / (dotSize + minSpacing)).floor().clamp(0, 8);
            return Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                maxDots,
                (index) => Container(
                  width: dotSize,
                  height: dotSize,
                  margin: const EdgeInsets.only(left: 3),
                  decoration: BoxDecoration(
                    color: onSurface.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Kapak deseni çizen painter
class _CoverPatternPainter extends CustomPainter {
  final Color backgroundColor;
  final String patternType;

  _CoverPatternPainter({
    required this.backgroundColor,
    required this.patternType,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Arka plan
    final bgPaint = Paint()..color = backgroundColor;
    canvas.drawRect(Offset.zero & size, bgPaint);

    // Desen rengi (kontrast)
    final luminance = backgroundColor.computeLuminance();
    final patternColor = luminance > 0.5 
        ? backgroundColor.withValues(alpha: 0.3)
        : Colors.white.withValues(alpha: 0.15);

    final paint = Paint()
      ..color = patternColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    if (patternType == 'dots') {
      // Noktalı desen
      final spacing = 15.0;
      for (double x = spacing / 2; x < size.width; x += spacing) {
        for (double y = spacing / 2; y < size.height; y += spacing) {
          canvas.drawCircle(
            Offset(x, y),
            1.5,
            Paint()
              ..color = patternColor
              ..style = PaintingStyle.fill,
          );
        }
      }
    } else {
      // Çizgili desen (diagonal)
      final spacing = 12.0;
      for (double i = -size.height; i < size.width; i += spacing) {
        canvas.drawLine(
          Offset(i, 0),
          Offset(i + size.height, size.height),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_CoverPatternPainter oldDelegate) =>
      oldDelegate.backgroundColor != backgroundColor ||
      oldDelegate.patternType != patternType;
}
