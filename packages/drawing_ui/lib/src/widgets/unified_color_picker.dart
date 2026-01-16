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

class _ColorPaletteSheetState extends State<ColorPaletteSheet>
    with SingleTickerProviderStateMixin {
  late Color _selectedColor;
  late TabController _tabController;
  double _opacity = 1.0;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.selectedColor;
    _opacity = widget.selectedColor.opacity;
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _colorToHex(Color color) {
    final r = (color.r * 255).round().toRadixString(16).padLeft(2, '0');
    final g = (color.g * 255).round().toRadixString(16).padLeft(2, '0');
    final b = (color.b * 255).round().toRadixString(16).padLeft(2, '0');
    return '$r$g$b'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        return Container(
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(30),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with tabs
              _buildHeaderWithTabs(),

              // Content
              SizedBox(
                height: 420,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildColorWheel(ref),
                    _buildColorSets(ref),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderWithTabs() {
    return Column(
      children: [
        // Close button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2C2E),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 16, color: Color(0xFF8E8E93)),
                ),
              ),
            ],
          ),
        ),
        // TabBar
        TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF0A84FF),
          unselectedLabelColor: const Color(0xFF8E8E93),
          indicatorColor: const Color(0xFF0A84FF),
          indicatorWeight: 2,
          labelStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
          tabs: const [
            Tab(text: 'Renk paleti'),
            Tab(text: 'Renk Seti'),
          ],
        ),
      ],
    );
  }

  Widget _buildColorWheel(WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Color wheel picker
          ColorPicker(
            color: _selectedColor,
            onColorChanged: (Color color) {
              setState(() {
                _selectedColor = color.withValues(alpha: _opacity);
              });
            },
            width: 40,
            height: 40,
            spacing: 12,
            runSpacing: 12,
            borderRadius: 20,
            wheelDiameter: 220,
            wheelWidth: 24,
            wheelHasBorder: false,
            enableShadesSelection: true,
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
            showColorCode: false,
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
          const SizedBox(height: 20),
          
          // Hex and Opacity
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2C2E),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'Altıgen',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF8E8E93),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _colorToHex(_selectedColor),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'monospace',
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2E),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${(_opacity * 100).round()}%',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Apply button with recent colors
          Row(
            children: [
              // Recent colors
              ...ref.watch(recentColorsProvider).take(7).map((color) {
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedColor = color);
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _colorsMatch(color, _selectedColor)
                            ? Colors.white
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                );
              }),
              const Spacer(),
              // Add button
              GestureDetector(
                onTap: () {
                  ref.read(recentColorsProvider.notifier).addColor(_selectedColor);
                  widget.onColorSelected(_selectedColor);
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF30D158),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 24),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildColorSets(WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildColorSetCategory(
            'Classic note (light background)',
            [
              const Color(0xFF000000),
              const Color(0xFFE53935),
              const Color(0xFF1E88E5),
              const Color(0xFF43A047),
              const Color(0xFFFB8C00),
            ],
            ref,
          ),
          const SizedBox(height: 20),
          _buildColorSetCategory(
            'Classic note (black background)',
            [
              const Color(0xFFFFFFFF),
              const Color(0xFFFFAFCC),
              const Color(0xFFFFCF9F),
              const Color(0xFF64B5F6),
              const Color(0xFFFFD54F),
            ],
            ref,
          ),
          const SizedBox(height: 20),
          _buildColorSetCategory(
            'Highlighter',
            [
              const Color(0xFFFFEB3B),
              const Color(0xFFFFAB40),
              const Color(0xFF69F0AE),
              const Color(0xFF40C4FF),
              const Color(0xFFE1BEE7),
            ],
            ref,
          ),
          const SizedBox(height: 20),
          _buildColorSetCategory(
            'Tape (cream)',
            [
              const Color(0xFF80DEEA),
              const Color(0xFFA5D6A7),
              const Color(0xFFEF9A9A),
              const Color(0xFFFFF59D),
              const Color(0xFFFFAB91),
            ],
            ref,
          ),
          const SizedBox(height: 20),
          _buildColorSetCategory(
            'Tape (bright)',
            [
              const Color(0xFF64B5F6),
              const Color(0xFFB39DDB),
              const Color(0xFF81C784),
              const Color(0xFFFFF176),
              const Color(0xFFFFB74D),
            ],
            ref,
          ),
        ],
      ),
    );
  }

  Widget _buildColorSetCategory(String title, List<Color> colors, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: Color(0xFF8E8E93),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: colors.map((color) {
            return GestureDetector(
              onTap: () {
                setState(() => _selectedColor = color);
                ref.read(recentColorsProvider.notifier).addColor(color);
                widget.onColorSelected(color);
              },
              child: Container(
                width: 44,
                height: 44,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _colorsMatch(color, _selectedColor)
                        ? Colors.white
                        : Colors.transparent,
                    width: 2.5,
                  ),
                ),
              ),
            );
          }).toList(),
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
    return (a.r * 255).round() == (b.r * 255).round() &&
        (a.g * 255).round() == (b.g * 255).round() &&
        (a.b * 255).round() == (b.b * 255).round();
  }
}
