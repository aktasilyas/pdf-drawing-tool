import 'package:flutter/material.dart';

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
  late String _selectedSet;

  @override
  void initState() {
    super.initState();
    _selectedSet = widget.colorSets.keys.first;
  }

  @override
  Widget build(BuildContext context) {
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
          // Başlık
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
            child: Row(
              children: [
                const Text(
                  'Renk Paleti',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, size: 20, color: Color(0xFF666666)),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Renk seti seçici
          if (widget.colorSets.length > 1) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: widget.colorSets.keys.map((setName) {
                  final isSelected = setName == _selectedSet;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedSet = setName),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF4A9DFF).withAlpha(25)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF4A9DFF) : Colors.transparent,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          setName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            color: isSelected ? const Color(0xFF4A9DFF) : const Color(0xFF666666),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],

          // Renk grid'i
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: _buildColorGrid(widget.colorSets[_selectedSet] ?? []),
          ),
        ],
      ),
    );
  }

  Widget _buildColorGrid(List<Color> colors) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: colors.map((color) {
        final isSelected = _colorsMatch(color, widget.selectedColor);
        return GestureDetector(
          onTap: () => widget.onColorSelected(color),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF4A9DFF)
                    : (color.computeLuminance() > 0.8 ? Colors.grey.shade400 : Colors.transparent),
                width: isSelected ? 2.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(20),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: isSelected
                ? Icon(
                    Icons.check,
                    size: 18,
                    color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                  )
                : null,
          ),
        );
      }).toList(),
    );
  }

  bool _colorsMatch(Color a, Color b) {
    return a.red == b.red && a.green == b.green && a.blue == b.blue;
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
