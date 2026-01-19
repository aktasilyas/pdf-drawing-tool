import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_ui/src/providers/recent_colors_provider.dart';

/// Preset renk kategorileri
class ColorPresets {
  ColorPresets._();

  /// Açık arka plan için klasik renkler
  static const classicLight = [
    Color(0xFF000000), // Siyah
    Color(0xFFE53935), // Kırmızı
    Color(0xFF1E88E5), // Mavi
    Color(0xFF43A047), // Yeşil
    Color(0xFFFFC107), // Sarı
  ];

  /// Koyu arka plan için klasik renkler
  static const classicDark = [
    Color(0xFFE0E0E0), // Açık gri
    Color(0xFFFFAB91), // Açık turuncu
    Color(0xFFF48FB1), // Açık pembe
    Color(0xFF81D4FA), // Açık mavi
    Color(0xFFFFE082), // Açık sarı
  ];

  /// Highlighter renkleri
  static const highlighter = [
    Color(0xFFFFEB3B), // Sarı
    Color(0xFFFF9800), // Turuncu
    Color(0xFF69F0AE), // Yeşil
    Color(0xFF80D8FF), // Mavi
    Color(0xFFE1BEE7), // Mor
  ];

  /// Tape cream
  static const tapeCream = [
    Color(0xFF80DEEA), // Cyan
    Color(0xFFA5D6A7), // Yeşil
    Color(0xFFF8BBD0), // Pembe
    Color(0xFFFFCC80), // Turuncu
    Color(0xFFFFAB91), // Şeftali
  ];

  /// Tape bright
  static const tapeBright = [
    Color(0xFF40C4FF), // Mavi
    Color(0xFFE040FB), // Mor
    Color(0xFF69F0AE), // Yeşil
    Color(0xFFFFFF00), // Sarı
    Color(0xFFFF6E40), // Turuncu
  ];

  /// Hızlı erişim renkleri
  static const quickAccess = [
    Color(0xFF000000),
    Color(0xFFE53935),
    Color(0xFF1E88E5),
    Color(0xFF43A047),
    Color(0xFFFFC107),
    Color(0xFF9C27B0),
  ];
}

/// ColorSets - Backward compatibility
class ColorSets {
  ColorSets._();

  static const List<Color> basic = ColorPresets.classicLight;
  static const List<Color> pastel = ColorPresets.tapeCream;
  static const List<Color> neon = ColorPresets.tapeBright;
  static const List<Color> highlighter = ColorPresets.highlighter;
  static const List<Color> quickAccess = ColorPresets.quickAccess;

  static const List<Color> laser = [
    Color(0xFFFF0000),
    Color(0xFF00FF00),
    Color(0xFF0000FF),
    Color(0xFFFFFF00),
    Color(0xFFFF00FF),
  ];

  static Map<String, List<Color>> get all => {
        'Temel': basic,
        'Pastel': pastel,
        'Neon': neon,
      };
}

/// Ortak renk seçici widget - hızlı renkler + daha fazla butonu
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

  final Color selectedColor;
  final ValueChanged<Color> onColorSelected;
  final List<Color>? quickColors;
  final List<Color>? allColors;
  final Map<String, List<Color>>? colorSets;
  final bool showMoreButton;
  final double chipSize;
  final double spacing;
  final bool isHighlighter;

  @override
  Widget build(BuildContext context) {
    final colors = (quickColors ?? ColorPresets.quickAccess).take(5).toList();

    return Wrap(
      spacing: spacing,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ...colors.map((color) => _ColorChip(
              color: color,
              isSelected: _colorsMatch(color, selectedColor),
              size: chipSize,
              onTap: () => onColorSelected(color),
              onDoubleTap: () => _showColorPalette(context),
            )),
        if (showMoreButton)
          _MoreButton(onTap: () => _showColorPalette(context)),
      ],
    );
  }

  void _showColorPalette(BuildContext context) {
    // Use custom overlay instead of showDialog to prevent interference with anchored panel
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;
    
    overlayEntry = OverlayEntry(
      builder: (overlayContext) {
        return Material(
          color: Colors.black54,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              // Tap on barrier closes the color picker
              overlayEntry.remove();
            },
            child: Center(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {}, // Absorb taps on picker content
                child: Material(
                  type: MaterialType.transparency,
                  child: CompactColorPicker(
                    selectedColor: selectedColor,
                    onColorSelected: (color) {
                      onColorSelected(color);
                      overlayEntry.remove();
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
    
    overlay.insert(overlayEntry);
  }

  bool _colorsMatch(Color a, Color b) {
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
                ? const Color(0xFF4FC3F7)
                : (color.computeLuminance() > 0.8
                    ? Colors.grey.shade400
                    : Colors.transparent),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF4FC3F7).withAlpha(60),
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
                color: color.computeLuminance() > 0.5
                    ? Colors.black
                    : Colors.white,
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
          color: const Color(0xFF2D2D2D),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.palette_outlined, size: 12, color: Color(0xFF4FC3F7)),
            SizedBox(width: 3),
            Text(
              'Daha fazla',
              style: TextStyle(fontSize: 10, color: Color(0xFF4FC3F7)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kompakt renk seçici - Fenci tarzı
class CompactColorPicker extends StatefulWidget {
  const CompactColorPicker({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
    this.showOpacity = true,
  });

  final Color selectedColor;
  final ValueChanged<Color> onColorSelected;
  final bool showOpacity;

  @override
  State<CompactColorPicker> createState() => _CompactColorPickerState();
}

class _CompactColorPickerState extends State<CompactColorPicker>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late HSVColor _hsvColor;
  late double _opacity;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _hsvColor = HSVColor.fromColor(widget.selectedColor);
    _opacity = widget.selectedColor.opacity;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color get _currentColor {
    return _hsvColor.toColor().withValues(alpha: widget.showOpacity ? _opacity : 1.0);
  }

  void _updateColor(HSVColor hsv) {
    setState(() => _hsvColor = hsv);
  }

  void _updateOpacity(double opacity) {
    setState(() => _opacity = opacity);
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    // Responsive height - max 60% of screen or 420px, whichever is smaller
    final maxContentHeight = (screenHeight * 0.55).clamp(280.0, 420.0);

    // Wrap in GestureDetector to absorb all taps and prevent propagation to underlying overlays
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {}, // Absorb taps - do nothing
      child: Container(
        width: 280,
        margin: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxHeight: maxContentHeight + 80, // 80 for header
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(60),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with tabs
            _buildHeader(),
            // Tab content - flexible height
            Flexible(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildColorPaletteTab(),
                  _buildColorSetsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Close button
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 8, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D2D2D),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 16,
                    color: Color(0xFFE0E0E0),
                  ),
                ),
              ),
            ],
          ),
        ),
        // TabBar
        TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF4FC3F7),
          unselectedLabelColor: const Color(0xFFE0E0E0),
          indicatorColor: const Color(0xFF4FC3F7),
          indicatorWeight: 2,
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 14,
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

  Widget _buildColorPaletteTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // HSV Picker Box
          HSVPickerBox(
            hsvColor: _hsvColor,
            onColorChanged: _updateColor,
          ),
          const SizedBox(height: 16),
          // Hue Slider
          HueSlider(
            hue: _hsvColor.hue,
            onChanged: (hue) => _updateColor(_hsvColor.withHue(hue)),
          ),
          const SizedBox(height: 12),
          // Opacity Slider
          if (widget.showOpacity) ...[
            OpacitySlider(
              color: _hsvColor.toColor(),
              opacity: _opacity,
              onChanged: _updateOpacity,
            ),
            const SizedBox(height: 16),
          ],
          // Hex + Opacity Input
          HexOpacityInput(
            color: _currentColor,
            opacity: _opacity,
            showOpacity: widget.showOpacity,
            onColorChanged: (color) {
              setState(() {
                _hsvColor = HSVColor.fromColor(color);
                _opacity = color.opacity;
              });
            },
            onSave: () => widget.onColorSelected(_currentColor),
          ),
          const SizedBox(height: 16),
          // Recent Colors - tap to apply immediately
          Consumer(
            builder: (context, ref, _) {
              final recentColors = ref.watch(recentColorsProvider);
              if (recentColors.isEmpty) return const SizedBox.shrink();
              
              return Column(
                children: [
                  const Divider(color: Color(0xFF424242), height: 1),
                  const SizedBox(height: 12),
                  RecentColorsRow(
                    colors: recentColors,
                    selectedColor: _currentColor,
                    onColorSelected: (color) {
                      // Apply immediately when recent color is tapped
                      widget.onColorSelected(color);
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildColorSetsTab() {
    return Consumer(
      builder: (context, ref, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPresetCategory('Classic note (light)', ColorPresets.classicLight, ref),
              const SizedBox(height: 20),
              _buildPresetCategory('Classic note (dark)', ColorPresets.classicDark, ref),
              const SizedBox(height: 20),
              _buildPresetCategory('Highlighter', ColorPresets.highlighter, ref),
              const SizedBox(height: 20),
              _buildPresetCategory('Tape (cream)', ColorPresets.tapeCream, ref),
              const SizedBox(height: 20),
              _buildPresetCategory('Tape (bright)', ColorPresets.tapeBright, ref),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPresetCategory(String title, List<Color> colors, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF9E9E9E),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: colors.map((color) {
            final isSelected = _colorsMatch(color, _currentColor);
            return GestureDetector(
              onTap: () {
                ref.read(recentColorsProvider.notifier).addColor(color);
                widget.onColorSelected(color);
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF4FC3F7)
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Icon(
                        Icons.check,
                        size: 18,
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

  bool _colorsMatch(Color a, Color b) {
    return (a.r * 255).round() == (b.r * 255).round() &&
        (a.g * 255).round() == (b.g * 255).round() &&
        (a.b * 255).round() == (b.b * 255).round();
  }
}

/// HSV Picker Box - 160x160 gradient
class HSVPickerBox extends StatefulWidget {
  const HSVPickerBox({
    super.key,
    required this.hsvColor,
    required this.onColorChanged,
  });

  final HSVColor hsvColor;
  final ValueChanged<HSVColor> onColorChanged;

  @override
  State<HSVPickerBox> createState() => _HSVPickerBoxState();
}

class _HSVPickerBoxState extends State<HSVPickerBox> {
  void _handlePositionUpdate(Offset globalPosition, BoxConstraints constraints) {
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    
    final localPosition = box.globalToLocal(globalPosition);
    final saturation = (localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0);
    final value = 1.0 - (localPosition.dy / constraints.maxHeight).clamp(0.0, 1.0);
    
    widget.onColorChanged(
      widget.hsvColor.withSaturation(saturation).withValue(value),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) => _handlePositionUpdate(details.globalPosition, constraints),
          onPanStart: (details) => _handlePositionUpdate(details.globalPosition, constraints),
          onPanUpdate: (details) => _handlePositionUpdate(details.globalPosition, constraints),
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF424242)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: CustomPaint(
                painter: _HSVBoxPainter(
                  hue: widget.hsvColor.hue,
                  saturation: widget.hsvColor.saturation,
                  value: widget.hsvColor.value,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HSVBoxPainter extends CustomPainter {
  _HSVBoxPainter({
    required this.hue,
    required this.saturation,
    required this.value,
  });

  final double hue;
  final double saturation;
  final double value;

  @override
  void paint(Canvas canvas, Size size) {
    // Background with hue
    final hueColor = HSVColor.fromAHSV(1.0, hue, 1.0, 1.0).toColor();
    final huePaint = Paint()..color = hueColor;
    canvas.drawRect(Offset.zero & size, huePaint);

    // White gradient (left to right)
    final whiteGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [Colors.white, Colors.white.withAlpha(0)],
    );
    final whiteShader = whiteGradient.createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, Paint()..shader = whiteShader);

    // Black gradient (top to bottom)
    final blackGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Colors.black.withAlpha(0), Colors.black],
    );
    final blackShader = blackGradient.createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, Paint()..shader = blackShader);

    // Selector
    final selectorX = saturation * size.width;
    final selectorY = (1 - value) * size.height;
    final selectorPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(
      Offset(selectorX, selectorY),
      8,
      selectorPaint,
    );
  }

  @override
  bool shouldRepaint(_HSVBoxPainter oldDelegate) =>
      hue != oldDelegate.hue ||
      saturation != oldDelegate.saturation ||
      value != oldDelegate.value;
}

/// Hue Slider - Rainbow gradient
class HueSlider extends StatelessWidget {
  const HueSlider({
    super.key,
    required this.hue,
    required this.onChanged,
  });

  final double hue;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF424242)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: Stack(
          children: [
            // Rainbow gradient background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const HSVColor.fromAHSV(1.0, 0, 1.0, 1.0).toColor(),
                    const HSVColor.fromAHSV(1.0, 60, 1.0, 1.0).toColor(),
                    const HSVColor.fromAHSV(1.0, 120, 1.0, 1.0).toColor(),
                    const HSVColor.fromAHSV(1.0, 180, 1.0, 1.0).toColor(),
                    const HSVColor.fromAHSV(1.0, 240, 1.0, 1.0).toColor(),
                    const HSVColor.fromAHSV(1.0, 300, 1.0, 1.0).toColor(),
                    const HSVColor.fromAHSV(1.0, 360, 1.0, 1.0).toColor(),
                  ],
                ),
              ),
            ),
            // Slider
            SliderTheme(
              data: SliderThemeData(
                trackHeight: 24,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
                trackShape: const RectangularSliderTrackShape(),
              ),
              child: Slider(
                value: hue,
                min: 0,
                max: 360,
                onChanged: onChanged,
                activeColor: Colors.transparent,
                inactiveColor: Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Opacity Slider - Checkerboard + color gradient
class OpacitySlider extends StatelessWidget {
  const OpacitySlider({
    super.key,
    required this.color,
    required this.opacity,
    required this.onChanged,
  });

  final Color color;
  final double opacity;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF424242)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: Stack(
          children: [
            // Checkerboard
            CustomPaint(
              size: const Size(double.infinity, 24),
              painter: _CheckerboardPainter(),
            ),
            // Color gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0),
                    color.withValues(alpha: 1),
                  ],
                ),
              ),
            ),
            // Slider
            SliderTheme(
              data: SliderThemeData(
                trackHeight: 24,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
                trackShape: const RectangularSliderTrackShape(),
              ),
              child: Slider(
                value: opacity,
                onChanged: onChanged,
                activeColor: Colors.transparent,
                inactiveColor: Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckerboardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const squareSize = 8.0;
    final paint = Paint();
    
    for (double y = 0; y < size.height; y += squareSize) {
      for (double x = 0; x < size.width; x += squareSize) {
        final isEven = ((x / squareSize).floor() + (y / squareSize).floor()) % 2 == 0;
        paint.color = isEven ? const Color(0xFFCCCCCC) : const Color(0xFFFFFFFF);
        canvas.drawRect(
          Rect.fromLTWH(x, y, squareSize, squareSize),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Hex + Opacity Input Row
class HexOpacityInput extends StatefulWidget {
  const HexOpacityInput({
    super.key,
    required this.color,
    required this.opacity,
    required this.showOpacity,
    required this.onColorChanged,
    required this.onSave,
  });

  final Color color;
  final double opacity;
  final bool showOpacity;
  final ValueChanged<Color> onColorChanged;
  final VoidCallback onSave;

  @override
  State<HexOpacityInput> createState() => _HexOpacityInputState();
}

class _HexOpacityInputState extends State<HexOpacityInput> {
  late TextEditingController _hexController;
  late TextEditingController _opacityController;

  @override
  void initState() {
    super.initState();
    _hexController = TextEditingController(text: _colorToHex(widget.color));
    _opacityController = TextEditingController(
      text: (widget.opacity * 100).round().toString(),
    );
  }

  @override
  void didUpdateWidget(HexOpacityInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.color != widget.color) {
      _hexController.text = _colorToHex(widget.color);
    }
    if (oldWidget.opacity != widget.opacity) {
      _opacityController.text = (widget.opacity * 100).round().toString();
    }
  }

  @override
  void dispose() {
    _hexController.dispose();
    _opacityController.dispose();
    super.dispose();
  }

  String _colorToHex(Color color) {
    final r = (color.r * 255).round().toRadixString(16).padLeft(2, '0');
    final g = (color.g * 255).round().toRadixString(16).padLeft(2, '0');
    final b = (color.b * 255).round().toRadixString(16).padLeft(2, '0');
    return r + g + b;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Eyedropper icon
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF2D2D2D),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.colorize,
            size: 18,
            color: Color(0xFF4FC3F7),
          ),
        ),
        const SizedBox(width: 8),
        // Hex input
        Expanded(
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF2D2D2D),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Text(
                  '#',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF9E9E9E),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: TextField(
                    controller: _hexController,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFFE0E0E0),
                      fontFamily: 'monospace',
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9A-Fa-f]')),
                      LengthLimitingTextInputFormatter(6),
                    ],
                    onSubmitted: (value) {
                      if (value.length == 6) {
                        final color = Color(int.parse('FF$value', radix: 16));
                        widget.onColorChanged(color);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        if (widget.showOpacity) ...[
          const SizedBox(width: 8),
          // Opacity input
          SizedBox(
            width: 60,
            height: 36,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF2D2D2D),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _opacityController,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFFE0E0E0),
                      ),
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(3),
                      ],
                      onSubmitted: (value) {
                        final opacity = (int.tryParse(value) ?? 100) / 100;
                        widget.onColorChanged(
                          widget.color.withValues(alpha: opacity.clamp(0.0, 1.0)),
                        );
                      },
                    ),
                  ),
                  const Text(
                    '%',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF9E9E9E),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(width: 8),
        // Save button
        GestureDetector(
          onTap: widget.onSave,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF4FC3F7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.add,
              size: 20,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

/// Recent Colors Row
class RecentColorsRow extends StatelessWidget {
  const RecentColorsRow({
    super.key,
    required this.colors,
    required this.selectedColor,
    required this.onColorSelected,
  });

  final List<Color> colors;
  final Color selectedColor;
  final ValueChanged<Color> onColorSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: colors.take(12).map((color) {
        final isSelected = _colorsMatch(color, selectedColor);
        return GestureDetector(
          onTap: () => onColorSelected(color),
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF4FC3F7)
                    : Colors.transparent,
                width: 2,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  bool _colorsMatch(Color a, Color b) {
    return (a.r * 255).round() == (b.r * 255).round() &&
        (a.g * 255).round() == (b.g * 255).round() &&
        (a.b * 255).round() == (b.b * 255).round();
  }
}

/// Full palette sheet (for compatibility)
class ColorPaletteSheet extends StatelessWidget {
  const ColorPaletteSheet({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
    this.colorSets,
    this.allColors,
  });

  final Color selectedColor;
  final ValueChanged<Color> onColorSelected;
  final Map<String, List<Color>>? colorSets;
  final List<Color>? allColors;

  @override
  Widget build(BuildContext context) {
    return CompactColorPicker(
      selectedColor: selectedColor,
      onColorSelected: onColorSelected,
    );
  }
}
