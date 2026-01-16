import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:drawing_ui/src/providers/recent_colors_provider.dart';

/// Premium renk paleti - 24 renk, 4 satır
class PremiumColors {
  PremiumColors._();

  /// Gri tonları (6)
  static const List<Color> grayscale = [
    Color(0xFF000000), // Pure Black
    Color(0xFF3D3D3D), // Charcoal
    Color(0xFF6B6B6B), // Dark Gray
    Color(0xFFA0A0A0), // Medium Gray
    Color(0xFFD4D4D4), // Light Gray
    Color(0xFFFFFFFF), // Pure White
  ];

  /// Canlı renkler (6)
  static const List<Color> vivid = [
    Color(0xFFE53935), // Red
    Color(0xFFFB8C00), // Orange
    Color(0xFFFFD600), // Yellow
    Color(0xFF43A047), // Green
    Color(0xFF1E88E5), // Blue
    Color(0xFF8E24AA), // Purple
  ];

  /// Soft renkler (6)
  static const List<Color> soft = [
    Color(0xFFFFCDD2), // Soft Pink
    Color(0xFFFFE0B2), // Soft Peach
    Color(0xFFFFF9C4), // Soft Yellow
    Color(0xFFC8E6C9), // Soft Green
    Color(0xFFBBDEFB), // Soft Blue
    Color(0xFFE1BEE7), // Soft Purple
  ];

  /// Aksan renkler (6)
  static const List<Color> accent = [
    Color(0xFF6D4C41), // Brown
    Color(0xFF546E7A), // Blue Gray
    Color(0xFF37474F), // Dark Slate
    Color(0xFFD32F2F), // Deep Red
    Color(0xFF1565C0), // Deep Blue
    Color(0xFFAD1457), // Deep Pink
  ];

  /// Tüm renkler (24)
  static List<Color> get all => [
        ...grayscale,
        ...vivid,
        ...soft,
        ...accent,
      ];

  /// Hızlı erişim (6)
  static const List<Color> quickAccess = [
    Color(0xFF000000), // Black
    Color(0xFFE53935), // Red
    Color(0xFF1E88E5), // Blue
    Color(0xFF43A047), // Green
    Color(0xFFFB8C00), // Orange
    Color(0xFF8E24AA), // Purple
  ];

  /// Vurgulayıcı (5) - yarı saydam
  static const List<Color> highlighter = [
    Color(0x80FFD600), // Yellow
    Color(0x8043A047), // Green
    Color(0x801E88E5), // Blue
    Color(0x80E91E63), // Pink
    Color(0x80FB8C00), // Orange
  ];
}

/// Renk setleri (eski API uyumluluğu için)
class ColorSets {
  ColorSets._();

  static List<Color> get basic => PremiumColors.all;
  static const List<Color> pastel = PremiumColors.soft;
  static const List<Color> neon = PremiumColors.vivid;
  static const List<Color> highlighter = PremiumColors.highlighter;
  static const List<Color> quickAccess = PremiumColors.quickAccess;

  static const List<Color> laser = [
    Color(0xFFFF0000),
    Color(0xFF00FF00),
    Color(0xFF0000FF),
    Color(0xFFFFFF00),
    Color(0xFFFF00FF),
  ];

  static Map<String, List<Color>> get all => {
        'Temel': PremiumColors.all,
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
  late Color _selectedColor;
  bool _showCustomPicker = false;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.selectedColor;
  }

  String _colorToHex(Color color) {
    return '#${(color.value & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

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
                color: Colors.black.withAlpha(20),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              _buildHeader(),

              // Content
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: _showCustomPicker
                    ? _buildCustomPicker(ref)
                    : _buildPremiumPalette(ref, recentColors),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 10, 10),
      child: Row(
        children: [
          const Text(
            'Renk Seçici',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 15, color: Color(0xFF666666)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumPalette(WidgetRef ref, List<Color> recentColors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Recent colors (varsa)
        if (recentColors.isNotEmpty) ...[
          Text(
            'Son Kullanılan',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 6),
          _buildColorGrid(recentColors.take(6).toList(), ref),
          const SizedBox(height: 12),
          Divider(height: 1, color: Colors.grey.shade200),
          const SizedBox(height: 12),
        ],

        // 4x6 Premium Grid
        _buildColorGrid(PremiumColors.grayscale, ref),
        const SizedBox(height: 8),
        _buildColorGrid(PremiumColors.vivid, ref),
        const SizedBox(height: 8),
        _buildColorGrid(PremiumColors.soft, ref),
        const SizedBox(height: 8),
        _buildColorGrid(PremiumColors.accent, ref),

        const SizedBox(height: 12),
        Divider(height: 1, color: Colors.grey.shade200),
        const SizedBox(height: 12),

        // Bottom: Hex + Custom button
        _buildBottomRow(ref),
      ],
    );
  }

  Widget _buildColorGrid(List<Color> colors, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: colors.map((color) {
        final isSelected = _colorsMatch(color, _selectedColor);
        return GestureDetector(
          onTap: () {
            setState(() => _selectedColor = color);
            ref.read(recentColorsProvider.notifier).addColor(color);
            widget.onColorSelected(color);
          },
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF4A9DFF)
                    : (color.computeLuminance() > 0.85
                        ? Colors.grey.shade300
                        : Colors.transparent),
                width: isSelected ? 2 : 0.8,
              ),
              boxShadow: [
                if (isSelected)
                  BoxShadow(
                    color: const Color(0xFF4A9DFF).withAlpha(30),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
              ],
            ),
            child: isSelected
                ? Icon(
                    Icons.check,
                    size: 16,
                    color: color.computeLuminance() > 0.5
                        ? Colors.black87
                        : Colors.white,
                  )
                : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomRow(WidgetRef ref) {
    return Row(
      children: [
        // Hex preview
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: _selectedColor,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: _selectedColor.computeLuminance() > 0.85
                        ? Colors.grey.shade300
                        : Colors.transparent,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                _colorToHex(_selectedColor),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'monospace',
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        // Custom color button
        GestureDetector(
          onTap: () => setState(() => _showCustomPicker = true),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFF4A9DFF).withAlpha(12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.colorize,
                  size: 14,
                  color: Color(0xFF4A9DFF),
                ),
                SizedBox(width: 4),
                Text(
                  'Özel',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF4A9DFF),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomPicker(WidgetRef ref) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Back button
        Row(
          children: [
            GestureDetector(
              onTap: () => setState(() => _showCustomPicker = false),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_back_ios, size: 12, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      'Paletler',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Wheel picker
        ColorPicker(
          color: _selectedColor,
          onColorChanged: (Color color) {
            setState(() => _selectedColor = color);
          },
          width: 32,
          height: 32,
          spacing: 8,
          runSpacing: 8,
          borderRadius: 16,
          wheelDiameter: 180,
          wheelWidth: 20,
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
        ),
        const SizedBox(height: 16),
        // Apply button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              ref.read(recentColorsProvider.notifier).addColor(_selectedColor);
              widget.onColorSelected(_selectedColor);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A9DFF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Uygula',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
          ),
        ),
      ],
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
