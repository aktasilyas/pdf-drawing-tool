import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:drawing_ui/src/providers/recent_colors_provider.dart';

/// Renk setleri tanımları
class ColorSets {
  ColorSets._();

  /// Temel renkler
  static const List<Color> basic = [
    Color(0xFF000000), // Siyah
    Color(0xFF666666), // Koyu gri
    Color(0xFF999999), // Gri
    Color(0xFFFFFFFF), // Beyaz
    Color(0xFFFF0000), // Kırmızı
    Color(0xFFFF9800), // Turuncu
    Color(0xFFFFEB3B), // Sarı
    Color(0xFF4CAF50), // Yeşil
    Color(0xFF2196F3), // Mavi
    Color(0xFF9C27B0), // Mor
    Color(0xFFE91E63), // Pembe
    Color(0xFF795548), // Kahverengi
  ];

  /// Pastel renkler
  static const List<Color> pastel = [
    Color(0xFFFFCDD2), // Açık pembe
    Color(0xFFFFE0B2), // Açık turuncu
    Color(0xFFFFF9C4), // Açık sarı
    Color(0xFFC8E6C9), // Açık yeşil
    Color(0xFFB3E5FC), // Açık mavi
    Color(0xFFE1BEE7), // Açık mor
    Color(0xFFD7CCC8), // Açık kahve
    Color(0xFFCFD8DC), // Açık gri-mavi
    Color(0xFFF8BBD0), // Soft pembe
    Color(0xFFDCEDC8), // Soft yeşil
    Color(0xFFB2EBF2), // Soft cyan
    Color(0xFFD1C4E9), // Soft lavanta
  ];

  /// Neon renkler
  static const List<Color> neon = [
    Color(0xFFFF1744), // Neon kırmızı
    Color(0xFFFF9100), // Neon turuncu
    Color(0xFFFFEA00), // Neon sarı
    Color(0xFF00E676), // Neon yeşil
    Color(0xFF00B0FF), // Neon mavi
    Color(0xFFD500F9), // Neon mor
    Color(0xFFFF4081), // Neon pembe
    Color(0xFF1DE9B6), // Neon turkuaz
    Color(0xFF76FF03), // Neon lime
    Color(0xFFE040FB), // Neon fuşya
    Color(0xFF00E5FF), // Neon cyan
    Color(0xFFFFFF00), // Parlak sarı
  ];

  /// Vurgulayıcı renkleri (yarı saydam)
  static const List<Color> highlighter = [
    Color(0x80FFEB3B), // Sarı
    Color(0x804CAF50), // Yeşil
    Color(0x8000BCD4), // Cyan
    Color(0x802196F3), // Mavi
    Color(0x80E91E63), // Pembe
    Color(0x80FF9800), // Turuncu
    Color(0x809C27B0), // Mor
    Color(0x80F44336), // Kırmızı
  ];

  /// Lazer renkleri
  static const List<Color> laser = [
    Color(0xFFFF0000), // Kırmızı
    Color(0xFF00FF00), // Yeşil
    Color(0xFF0000FF), // Mavi
    Color(0xFFFFFF00), // Sarı
    Color(0xFFFF00FF), // Magenta
  ];

  /// Varsayılan hızlı erişim renkleri
  static const List<Color> quickAccess = [
    Color(0xFF000000), // Siyah
    Color(0xFF4A9DFF), // Mavi
    Color(0xFFFF5252), // Kırmızı
    Color(0xFF4CAF50), // Yeşil
    Color(0xFFFF9800), // Turuncu
    Color(0xFF9C27B0), // Mor
  ];

  /// Tüm renk setleri
  static const Map<String, List<Color>> all = {
    'Temel': basic,
    'Pastel': pastel,
    'Neon': neon,
  };
}

/// Ortak renk seçici widget.
/// 
/// Hızlı renk seçimi için birkaç renk gösterir.
/// "Daha fazla" butonuna veya seçili renge çift tıklayınca
/// tam renk paleti açılır.
class UnifiedColorPicker extends StatelessWidget {
  const UnifiedColorPicker({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
    this.quickColors,
    this.allColors,
    this.colorSets,
    this.showMoreButton = true,
    this.chipSize = 22.0,
    this.spacing = 6.0,
    this.isHighlighter = false,
  });

  /// Seçili renk
  final Color selectedColor;

  /// Renk seçildiğinde çağrılır
  final ValueChanged<Color> onColorSelected;

  /// Hızlı erişim renkleri (varsayılan: ColorSets.quickAccess)
  final List<Color>? quickColors;

  /// Tam palette gösterilecek tüm renkler
  final List<Color>? allColors;

  /// Renk setleri (palette'te gösterilecek)
  final Map<String, List<Color>>? colorSets;

  /// "Daha fazla" butonu gösterilsin mi
  final bool showMoreButton;

  /// Renk chip boyutu
  final double chipSize;

  /// Renk chip'leri arası boşluk
  final double spacing;

  /// Vurgulayıcı modu (yarı saydam renkler)
  final bool isHighlighter;

  @override
  Widget build(BuildContext context) {
    // Sadece 5 renk göster (taşmayı önle)
    final colors = (quickColors ?? ColorSets.quickAccess).take(5).toList();

    return Wrap(
      spacing: spacing,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Hızlı renkler
        ...colors.map((color) => _ColorChip(
          color: color,
          isSelected: _colorsMatch(color, selectedColor),
          size: chipSize,
          onTap: () => onColorSelected(isHighlighter ? color.withAlpha(128) : color),
          onDoubleTap: () => _showColorPalette(context),
        )),
        // Daha fazla butonu
        if (showMoreButton)
          _MoreButton(onTap: () => _showColorPalette(context)),
      ],
    );
  }

  void _showColorPalette(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ColorPaletteSheet(
        selectedColor: selectedColor,
        onColorSelected: (color) {
          onColorSelected(isHighlighter ? color.withAlpha(128) : color);
          Navigator.pop(ctx);
        },
        colorSets: colorSets ?? ColorSets.all,
        allColors: allColors,
      ),
    );
  }

  bool _colorsMatch(Color a, Color b) {
    // RGB karşılaştır (alpha'yı yoksay - vurgulayıcı için)
    return a.red == b.red && a.green == b.green && a.blue == b.blue;
  }
}

/// Tek bir renk chip'i
class _ColorChip extends StatelessWidget {
  const _ColorChip({
    required this.color,
    required this.isSelected,
    required this.size,
    required this.onTap,
    this.onDoubleTap,
  });

  final Color color;
  final bool isSelected;
  final double size;
  final VoidCallback onTap;
  final VoidCallback? onDoubleTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? const Color(0xFF4A9DFF)
                : (color.computeLuminance() > 0.8 ? Colors.grey.shade400 : Colors.transparent),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF4A9DFF).withAlpha(60),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: isSelected
            ? Icon(
                Icons.check,
                size: size * 0.5,
                color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
              )
            : null,
      ),
    );
  }
}

/// "Daha fazla" butonu
class _MoreButton extends StatelessWidget {
  const _MoreButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.palette_outlined, size: 12, color: Color(0xFF666666)),
            SizedBox(width: 3),
            Text(
              'Daha fazla',
              style: TextStyle(fontSize: 10, color: Color(0xFF666666)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tam renk paleti (bottom sheet)
class ColorPaletteSheet extends StatefulWidget {
  const ColorPaletteSheet({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
    required this.colorSets,
    this.allColors,
  });

  final Color selectedColor;
  final ValueChanged<Color> onColorSelected;
  final Map<String, List<Color>> colorSets;
  final List<Color>? allColors;

  @override
  State<ColorPaletteSheet> createState() => _ColorPaletteSheetState();
}

class _ColorPaletteSheetState extends State<ColorPaletteSheet> {
  bool _showWheel = false;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final recentColors = ref.watch(recentColorsProvider);

        return Container(
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(30),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Kompakt Header
              _buildCompactHeader(ref),
              const Divider(height: 1),

              // Color Grids veya Wheel
              Padding(
                padding: const EdgeInsets.all(12),
                child: _showWheel
                    ? _buildWheelPicker(ref)
                    : _buildCompactPalettes(ref, recentColors),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompactHeader(WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 8, 8),
      child: Row(
        children: [
          // Seçili renk önizleme
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: widget.selectedColor,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: widget.selectedColor.computeLuminance() > 0.8
                    ? Colors.grey.shade300
                    : Colors.transparent,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Renk Seç',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          // Wheel toggle
          GestureDetector(
            onTap: () => setState(() => _showWheel = !_showWheel),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _showWheel
                    ? const Color(0xFF4A9DFF).withAlpha(20)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _showWheel ? Icons.palette : Icons.color_lens,
                    size: 14,
                    color: _showWheel
                        ? const Color(0xFF4A9DFF)
                        : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _showWheel ? 'Paletler' : 'Özel',
                    style: TextStyle(
                      fontSize: 11,
                      color: _showWheel
                          ? const Color(0xFF4A9DFF)
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.close, size: 18, color: Color(0xFF666666)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactPalettes(WidgetRef ref, List<Color> recentColors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Recent colors (varsa)
        if (recentColors.isNotEmpty) ...[
          _buildColorRow('Son Kullanılan', recentColors.take(8).toList(), ref),
          const SizedBox(height: 10),
        ],
        // Temel renkler
        _buildColorRow('Temel', ColorSets.basic, ref),
        const SizedBox(height: 10),
        // Pastel
        _buildColorRow('Pastel', ColorSets.pastel, ref),
        const SizedBox(height: 10),
        // Neon
        _buildColorRow('Neon', ColorSets.neon, ref),
      ],
    );
  }

  Widget _buildColorRow(String label, List<Color> colors, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade500,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: colors.map((color) {
            final isSelected = _colorsMatch(color, widget.selectedColor);
            return GestureDetector(
              onTap: () {
                ref.read(recentColorsProvider.notifier).addColor(color);
                widget.onColorSelected(color);
              },
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF4A9DFF)
                        : (color.computeLuminance() > 0.8
                            ? Colors.grey.shade300
                            : Colors.transparent),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: isSelected
                    ? Icon(
                        Icons.check,
                        size: 14,
                        color: color.computeLuminance() > 0.5
                            ? Colors.black
                            : Colors.white,
                      )
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildWheelPicker(WidgetRef ref) {
    return ColorPicker(
      color: widget.selectedColor,
      onColorChanged: (Color color) {
        ref.read(recentColorsProvider.notifier).addColor(color);
        widget.onColorSelected(color);
      },
      width: 28,
      height: 28,
      spacing: 6,
      runSpacing: 6,
      borderRadius: 14,
      wheelDiameter: 140,
      wheelWidth: 14,
      wheelHasBorder: false,
      enableShadesSelection: false,
      enableTonalPalette: false,
      pickersEnabled: const <ColorPickerType, bool>{
        ColorPickerType.both: false,
        ColorPickerType.primary: false,
        ColorPickerType.accent: false,
        ColorPickerType.bw: false,
        ColorPickerType.custom: false,
        ColorPickerType.customSecondary: false,
        ColorPickerType.wheel: true,
      },
      showRecentColors: false,
      showColorCode: true,
      colorCodeHasColor: true,
      colorCodeReadOnly: false,
      showColorName: false,
      copyPasteBehavior: const ColorPickerCopyPasteBehavior(
        copyButton: false,
        pasteButton: false,
      ),
      actionButtons: const ColorPickerActionButtons(
        okButton: false,
        closeButton: false,
        dialogActionButtons: false,
      ),
    );
  }

  bool _colorsMatch(Color a, Color b) {
    return (a.r * 255).round() == (b.r * 255).round() &&
        (a.g * 255).round() == (b.g * 255).round() &&
        (a.b * 255).round() == (b.b * 255).round();
  }
}

/// Toolbar için kompakt renk seçici (sadece chip'ler)
class ToolbarColorChips extends StatelessWidget {
  const ToolbarColorChips({
    super.key,
    required this.colors,
    required this.selectedColor,
    required this.onColorSelected,
    required this.onMoreTap,
    this.chipSize = 20.0,
  });

  final List<Color> colors;
  final Color selectedColor;
  final ValueChanged<Color> onColorSelected;
  final VoidCallback onMoreTap;
  final double chipSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...colors.map((color) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: GestureDetector(
            onTap: () => onColorSelected(color),
            onDoubleTap: onMoreTap,
            child: Container(
              width: chipSize,
              height: chipSize,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: _colorsMatch(color, selectedColor)
                      ? Colors.white
                      : Colors.grey.shade300,
                  width: _colorsMatch(color, selectedColor) ? 2 : 0.5,
                ),
                boxShadow: _colorsMatch(color, selectedColor)
                    ? [
                        BoxShadow(
                          color: color.withAlpha(80),
                          blurRadius: 3,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: _colorsMatch(color, selectedColor)
                  ? Icon(
                      Icons.check,
                      size: chipSize * 0.5,
                      color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                    )
                  : null,
            ),
          ),
        )),
      ],
    );
  }

  bool _colorsMatch(Color a, Color b) {
    return a.red == b.red && a.green == b.green && a.blue == b.blue;
  }
}
