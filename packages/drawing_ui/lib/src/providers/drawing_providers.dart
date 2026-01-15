import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/models/models.dart';

// =============================================================================
// TOOL SELECTION
// =============================================================================

/// Currently selected tool type.
final currentToolProvider = StateProvider<ToolType>((ref) {
  return ToolType.ballpointPen;
});

/// Whether a panel is currently open (and which one).
final activePanelProvider = StateProvider<ToolType?>((ref) {
  return null;
});

// =============================================================================
// TOOL SETTINGS PROVIDERS
// =============================================================================

/// Settings for pen tools (family provider by tool type).
/// 
/// For pen tools with PenType, default values come from PenType.config.
final penSettingsProvider =
    StateNotifierProvider.family<PenSettingsNotifier, PenSettings, ToolType>(
  (ref, toolType) => PenSettingsNotifier(_defaultPenSettings(toolType)),
);

PenSettings _defaultPenSettings(ToolType toolType) {
  // Use PenType config for pen tools
  final penType = toolType.penType;
  if (penType != null) {
    final config = penType.config;
    return PenSettings(
      color: const Color(0xFF000000), // Default black
      thickness: config.defaultThickness,
      stabilization: 0.3, // Default stabilization
      nibShape: _nibShapeFromCore(config.nibShape),
      pressureSensitive: true, // Default pressure sensitivity
      textured: config.texture != StrokeTexture.none,
    );
  }

  // Fallback for non-pen tools
  return const PenSettings(
    color: Color(0xFF000000),
    thickness: 2.0,
    stabilization: 0.3,
    nibShape: NibShapeType.circle,
    pressureSensitive: true,
  );
}

/// Converts core NibShape to UI NibShapeType.
NibShapeType _nibShapeFromCore(NibShape nibShape) {
  switch (nibShape) {
    case NibShape.circle:
      return NibShapeType.circle;
    case NibShape.ellipse:
      return NibShapeType.ellipse;
    case NibShape.rectangle:
      return NibShapeType.rectangle;
  }
}

/// Notifier for pen settings state.
class PenSettingsNotifier extends StateNotifier<PenSettings> {
  PenSettingsNotifier(super.state);

  void setColor(Color color) {
    state = state.copyWith(color: color);
  }

  void setThickness(double thickness) {
    state = state.copyWith(thickness: thickness);
  }

  void setStabilization(double stabilization) {
    state = state.copyWith(stabilization: stabilization);
  }

  void setNibShape(NibShapeType nibShape) {
    state = state.copyWith(nibShape: nibShape);
  }

  void setPressureSensitive(bool pressureSensitive) {
    state = state.copyWith(pressureSensitive: pressureSensitive);
  }

  void setNibAngle(double nibAngle) {
    state = state.copyWith(nibAngle: nibAngle);
  }
}

/// Pen settings data model for UI state.
class PenSettings {
  const PenSettings({
    required this.color,
    required this.thickness,
    required this.stabilization,
    required this.nibShape,
    required this.pressureSensitive,
    this.nibAngle = 0.0,
    this.textured = false,
  });

  final Color color;
  final double thickness;
  final double stabilization;
  final NibShapeType nibShape;
  final bool pressureSensitive;
  final double nibAngle;
  final bool textured;

  PenSettings copyWith({
    Color? color,
    double? thickness,
    double? stabilization,
    NibShapeType? nibShape,
    bool? pressureSensitive,
    double? nibAngle,
    bool? textured,
  }) {
    return PenSettings(
      color: color ?? this.color,
      thickness: thickness ?? this.thickness,
      stabilization: stabilization ?? this.stabilization,
      nibShape: nibShape ?? this.nibShape,
      pressureSensitive: pressureSensitive ?? this.pressureSensitive,
      nibAngle: nibAngle ?? this.nibAngle,
      textured: textured ?? this.textured,
    );
  }
}

/// Nib shape type for UI representation.
enum NibShapeType { circle, ellipse, rectangle }

/// Highlighter settings provider.
final highlighterSettingsProvider =
    StateNotifierProvider<HighlighterSettingsNotifier, HighlighterSettings>(
  (ref) => HighlighterSettingsNotifier(const HighlighterSettings(
    color: Color(0x80FFEB3B),
    thickness: 20.0,
    straightLineMode: false,
    glowIntensity: 0.6,
  )),
);

/// Highlighter settings data model.
class HighlighterSettings {
  const HighlighterSettings({
    required this.color,
    required this.thickness,
    required this.straightLineMode,
    this.glowIntensity = 0.6,
  });

  final Color color;
  final double thickness;
  final bool straightLineMode;
  final double glowIntensity;

  HighlighterSettings copyWith({
    Color? color,
    double? thickness,
    bool? straightLineMode,
    double? glowIntensity,
  }) {
    return HighlighterSettings(
      color: color ?? this.color,
      thickness: thickness ?? this.thickness,
      straightLineMode: straightLineMode ?? this.straightLineMode,
      glowIntensity: glowIntensity ?? this.glowIntensity,
    );
  }
}

/// Notifier for highlighter settings.
class HighlighterSettingsNotifier extends StateNotifier<HighlighterSettings> {
  HighlighterSettingsNotifier(super.state);

  void setColor(Color color) {
    state = state.copyWith(color: color);
  }

  void setThickness(double thickness) {
    state = state.copyWith(thickness: thickness);
  }

  void setStraightLineMode(bool straightLineMode) {
    state = state.copyWith(straightLineMode: straightLineMode);
  }

  void setGlowIntensity(double glowIntensity) {
    state = state.copyWith(glowIntensity: glowIntensity);
  }
}

/// Eraser settings provider.
final eraserSettingsProvider =
    StateNotifierProvider<EraserSettingsNotifier, EraserSettings>(
  (ref) => EraserSettingsNotifier(const EraserSettings(
    mode: EraserMode.pixel,
    size: 20.0,
    pressureSensitive: true,
    eraseOnlyHighlighter: false,
    eraseBandOnly: false,
    autoLift: false,
  )),
);

/// Eraser mode enum.
enum EraserMode { pixel, stroke, lasso }

/// Eraser settings data model.
class EraserSettings {
  const EraserSettings({
    required this.mode,
    required this.size,
    required this.pressureSensitive,
    required this.eraseOnlyHighlighter,
    required this.eraseBandOnly,
    required this.autoLift,
  });

  final EraserMode mode;
  final double size;
  final bool pressureSensitive;
  final bool eraseOnlyHighlighter;
  final bool eraseBandOnly;
  final bool autoLift;

  EraserSettings copyWith({
    EraserMode? mode,
    double? size,
    bool? pressureSensitive,
    bool? eraseOnlyHighlighter,
    bool? eraseBandOnly,
    bool? autoLift,
  }) {
    return EraserSettings(
      mode: mode ?? this.mode,
      size: size ?? this.size,
      pressureSensitive: pressureSensitive ?? this.pressureSensitive,
      eraseOnlyHighlighter: eraseOnlyHighlighter ?? this.eraseOnlyHighlighter,
      eraseBandOnly: eraseBandOnly ?? this.eraseBandOnly,
      autoLift: autoLift ?? this.autoLift,
    );
  }
}

/// Notifier for eraser settings.
class EraserSettingsNotifier extends StateNotifier<EraserSettings> {
  EraserSettingsNotifier(super.state);

  void setMode(EraserMode mode) {
    state = state.copyWith(mode: mode);
  }

  void setSize(double size) {
    state = state.copyWith(size: size);
  }

  void setPressureSensitive(bool pressureSensitive) {
    state = state.copyWith(pressureSensitive: pressureSensitive);
  }

  void setEraseOnlyHighlighter(bool eraseOnlyHighlighter) {
    state = state.copyWith(eraseOnlyHighlighter: eraseOnlyHighlighter);
  }

  void setEraseBandOnly(bool eraseBandOnly) {
    state = state.copyWith(eraseBandOnly: eraseBandOnly);
  }

  void setAutoLift(bool autoLift) {
    state = state.copyWith(autoLift: autoLift);
  }
}

/// Shapes settings provider.
final shapesSettingsProvider =
    StateNotifierProvider<ShapesSettingsNotifier, ShapesSettingsState>(
  (ref) => ShapesSettingsNotifier(const ShapesSettingsState(
    selectedShape: ShapeType.rectangle,
    strokeThickness: 2.0,
    strokeColor: Color(0xFF000000),
    fillEnabled: false,
    fillColor: Color(0x40000000),
  )),
);

/// Shape type enum - En çok kullanılan 10 şekil.
/// Core ShapeType ile birebir eşleşir.
enum ShapeType {
  /// Düz çizgi
  line,

  /// Ok işareti
  arrow,

  /// Dikdörtgen
  rectangle,

  /// Elips/Daire
  ellipse,

  /// Üçgen
  triangle,

  /// Eşkenar dörtgen
  diamond,

  /// Yıldız
  star,

  /// Beşgen
  pentagon,

  /// Altıgen
  hexagon,

  /// Artı işareti
  plus,
}

/// Shapes settings data model.
class ShapesSettingsState {
  const ShapesSettingsState({
    required this.selectedShape,
    required this.strokeThickness,
    required this.strokeColor,
    required this.fillEnabled,
    required this.fillColor,
  });

  final ShapeType selectedShape;
  final double strokeThickness;
  final Color strokeColor;
  final bool fillEnabled;
  final Color fillColor;

  ShapesSettingsState copyWith({
    ShapeType? selectedShape,
    double? strokeThickness,
    Color? strokeColor,
    bool? fillEnabled,
    Color? fillColor,
  }) {
    return ShapesSettingsState(
      selectedShape: selectedShape ?? this.selectedShape,
      strokeThickness: strokeThickness ?? this.strokeThickness,
      strokeColor: strokeColor ?? this.strokeColor,
      fillEnabled: fillEnabled ?? this.fillEnabled,
      fillColor: fillColor ?? this.fillColor,
    );
  }
}

/// Notifier for shapes settings.
class ShapesSettingsNotifier extends StateNotifier<ShapesSettingsState> {
  ShapesSettingsNotifier(super.state);

  void setSelectedShape(ShapeType shape) {
    state = state.copyWith(selectedShape: shape);
  }

  void setStrokeThickness(double thickness) {
    state = state.copyWith(strokeThickness: thickness);
  }

  void setStrokeColor(Color color) {
    state = state.copyWith(strokeColor: color);
  }

  void setFillEnabled(bool enabled) {
    state = state.copyWith(fillEnabled: enabled);
  }

  void setFillColor(Color color) {
    state = state.copyWith(fillColor: color);
  }
}

// =============================================================================
// LASSO (KEMENT) SETTINGS
// =============================================================================

/// Lasso selection mode.
enum LassoMode {
  /// Free-form lasso selection (Serbest kement).
  freeform,

  /// Rectangle selection (Dikdörtgen kement).
  rectangle,
}

/// Types of elements that can be selected with lasso tool.
enum SelectableType {
  /// Shapes (Şekil).
  shape,

  /// Images and stickers (Resim/Çıkartma).
  imageSticker,

  /// Tape/washi elements (Bant).
  tape,

  /// Text boxes (Metin kutusu).
  textBox,

  /// Handwriting strokes (El yazısı).
  handwriting,

  /// Highlighter strokes (Vurgulayıcı).
  highlighter,

  /// Links (Bağlantı).
  link,

  /// Labels (Etiket).
  label,
}

/// Lasso tool settings data model.
class LassoSettings {
  const LassoSettings({
    required this.mode,
    required this.selectableTypes,
  });

  /// The current lasso selection mode.
  final LassoMode mode;

  /// Map of selectable types and whether they are enabled.
  final Map<SelectableType, bool> selectableTypes;

  /// Default lasso settings matching PHASE1_UI_REFERENCE.md.
  factory LassoSettings.defaultSettings() {
    return LassoSettings(
      mode: LassoMode.freeform,
      selectableTypes: {
        SelectableType.shape: true,
        SelectableType.imageSticker: true,
        SelectableType.tape: true,
        SelectableType.textBox: true,
        SelectableType.handwriting: true,
        SelectableType.highlighter: false, // Default OFF per spec
        SelectableType.link: true,
        SelectableType.label: true,
      },
    );
  }

  LassoSettings copyWith({
    LassoMode? mode,
    Map<SelectableType, bool>? selectableTypes,
  }) {
    return LassoSettings(
      mode: mode ?? this.mode,
      selectableTypes: selectableTypes ?? Map.from(this.selectableTypes),
    );
  }

  /// Creates a copy with a single selectable type toggled.
  LassoSettings withSelectableType(SelectableType type, bool enabled) {
    final newTypes = Map<SelectableType, bool>.from(selectableTypes);
    newTypes[type] = enabled;
    return copyWith(selectableTypes: newTypes);
  }
}

// =============================================================================
// LASER POINTER SETTINGS
// =============================================================================

/// Laser pointer mode.
enum LaserMode {
  /// Line mode - draws a temporary line (Çizgi).
  line,

  /// Dot mode - shows a temporary dot (Nokta).
  dot,
}

/// Laser pointer settings data model.
class LaserSettings {
  const LaserSettings({
    required this.mode,
    required this.thickness,
    required this.duration,
    required this.color,
  });

  /// The current laser mode (line or dot).
  final LaserMode mode;

  /// Thickness of the laser line/dot in mm.
  final double thickness;

  /// Duration the laser mark stays visible in seconds.
  final double duration;

  /// Color of the laser.
  final Color color;

  /// Default laser settings matching PHASE1_UI_REFERENCE.md.
  factory LaserSettings.defaultSettings() {
    return const LaserSettings(
      mode: LaserMode.line,
      thickness: 0.5,
      duration: 2.0,
      color: Color(0xFF29B6F6), // Light blue
    );
  }

  LaserSettings copyWith({
    LaserMode? mode,
    double? thickness,
    double? duration,
    Color? color,
  }) {
    return LaserSettings(
      mode: mode ?? this.mode,
      thickness: thickness ?? this.thickness,
      duration: duration ?? this.duration,
      color: color ?? this.color,
    );
  }
}

/// Lasso settings provider.
final lassoSettingsProvider =
    StateNotifierProvider<LassoSettingsNotifier, LassoSettings>(
  (ref) => LassoSettingsNotifier(LassoSettings.defaultSettings()),
);

/// Notifier for lasso settings.
class LassoSettingsNotifier extends StateNotifier<LassoSettings> {
  LassoSettingsNotifier(super.state);

  void setMode(LassoMode mode) {
    state = state.copyWith(mode: mode);
  }

  void setSelectableType(SelectableType type, bool enabled) {
    state = state.withSelectableType(type, enabled);
  }

  void setAllSelectableTypes(bool enabled) {
    final newTypes = <SelectableType, bool>{};
    for (final type in SelectableType.values) {
      newTypes[type] = enabled;
    }
    state = state.copyWith(selectableTypes: newTypes);
  }
}

/// Laser settings provider.
final laserSettingsProvider =
    StateNotifierProvider<LaserSettingsNotifier, LaserSettings>(
  (ref) => LaserSettingsNotifier(LaserSettings.defaultSettings()),
);

/// Notifier for laser settings.
class LaserSettingsNotifier extends StateNotifier<LaserSettings> {
  LaserSettingsNotifier(super.state);

  void setMode(LaserMode mode) {
    state = state.copyWith(mode: mode);
  }

  void setThickness(double thickness) {
    state = state.copyWith(thickness: thickness);
  }

  void setDuration(double duration) {
    state = state.copyWith(duration: duration);
  }

  void setColor(Color color) {
    state = state.copyWith(color: color);
  }
}

// =============================================================================
// QUICK ACCESS SETTINGS
// =============================================================================

/// Grid visibility provider.
final gridVisibilityProvider = StateProvider<bool>((ref) => true);

/// Quick colors provider - 5 colors for quick access in toolbar.
/// Default colors based on common drawing tool colors.
final quickColorsProvider = StateProvider<List<Color>>((ref) {
  return const [
    Color(0xFF000000), // Black
    Color(0xFF1976D2), // Blue
    Color(0xFFD32F2F), // Red
    Color(0xFF388E3C), // Green
    Color(0xFFF57C00), // Orange
  ];
});

/// Quick thickness provider - 3 thickness values for quick access.
/// Small, Medium, Large options.
final quickThicknessProvider = StateProvider<List<double>>((ref) {
  return const [1.0, 2.5, 5.0];
});

// =============================================================================
// PEN BOX PRESETS
// =============================================================================

/// Pen box presets provider.
final penBoxPresetsProvider =
    StateNotifierProvider<PenBoxPresetsNotifier, List<PenPreset>>(
  (ref) => PenBoxPresetsNotifier(_defaultPenPresets()),
);

List<PenPreset> _defaultPenPresets() {
  // Başlangıçta boş - kullanıcı kendi kalemlerini ekleyecek
  return [];
}

/// Pen preset data model.
class PenPreset {
  const PenPreset({
    required this.id,
    this.toolType = ToolType.ballpointPen,
    this.color = const Color(0xFF000000),
    this.thickness = 2.0,
    this.nibShape = NibShapeType.circle,
    this.isEmpty = false,
  });

  final String id;
  final ToolType toolType;
  final Color color;
  final double thickness;
  final NibShapeType nibShape;
  final bool isEmpty;

  PenPreset copyWith({
    String? id,
    ToolType? toolType,
    Color? color,
    double? thickness,
    NibShapeType? nibShape,
    bool? isEmpty,
  }) {
    return PenPreset(
      id: id ?? this.id,
      toolType: toolType ?? this.toolType,
      color: color ?? this.color,
      thickness: thickness ?? this.thickness,
      nibShape: nibShape ?? this.nibShape,
      isEmpty: isEmpty ?? this.isEmpty,
    );
  }
}

/// Currently selected preset index.
final selectedPresetIndexProvider = StateProvider<int>((ref) => 0);

/// Notifier for pen box presets.
class PenBoxPresetsNotifier extends StateNotifier<List<PenPreset>> {
  PenBoxPresetsNotifier(super.state);

  void updatePreset(int index, PenPreset preset) {
    if (index < 0 || index >= state.length) return;
    state = [
      ...state.sublist(0, index),
      preset,
      ...state.sublist(index + 1),
    ];
  }

  void addPreset(PenPreset preset) {
    // Find first empty slot
    final emptyIndex = state.indexWhere((p) => p.isEmpty);
    if (emptyIndex != -1) {
      updatePreset(emptyIndex, preset);
    } else {
      // No empty slot, add to the end of the list
      state = [...state, preset];
    }
  }

  void removePreset(int index) {
    if (index < 0 || index >= state.length) return;
    // Listeden tamamen sil
    state = [
      ...state.sublist(0, index),
      ...state.sublist(index + 1),
    ];
  }
}

// =============================================================================
// TOOLBAR CONFIGURATION
// =============================================================================

/// Toolbar configuration provider.
final toolbarConfigProvider =
    StateNotifierProvider<ToolbarConfigNotifier, ToolbarConfig>(
  (ref) => ToolbarConfigNotifier(ToolbarConfig.defaultConfig()),
);

/// Toolbar configuration data model.
class ToolbarConfig {
  const ToolbarConfig({
    required this.toolOrder,
    required this.visibleTools,
  });

  /// Order of tools in the toolbar.
  final List<ToolType> toolOrder;

  /// Which tools are visible in the toolbar.
  final Set<ToolType> visibleTools;

  /// Default toolbar configuration.
  factory ToolbarConfig.defaultConfig() {
    return ToolbarConfig(
      toolOrder: [
        ToolType.pencil,
        ToolType.hardPencil,
        ToolType.ballpointPen,
        ToolType.gelPen,
        ToolType.dashedPen,
        ToolType.highlighter,
        ToolType.brushPen,
        ToolType.marker,
        ToolType.neonHighlighter,
        ToolType.pixelEraser,
        ToolType.strokeEraser,
        ToolType.selection,
        ToolType.shapes,
        ToolType.text,
        ToolType.sticker,
        ToolType.image,
      ],
      visibleTools: {
        ToolType.pencil,
        ToolType.ballpointPen,
        ToolType.gelPen,
        ToolType.highlighter,
        ToolType.brushPen,
        ToolType.marker,
        ToolType.pixelEraser,
        ToolType.selection,
        ToolType.shapes,
        ToolType.text,
        ToolType.sticker,
        ToolType.image,
      },
    );
  }

  ToolbarConfig copyWith({
    List<ToolType>? toolOrder,
    Set<ToolType>? visibleTools,
  }) {
    return ToolbarConfig(
      toolOrder: toolOrder ?? this.toolOrder,
      visibleTools: visibleTools ?? this.visibleTools,
    );
  }
}

/// Notifier for toolbar configuration.
class ToolbarConfigNotifier extends StateNotifier<ToolbarConfig> {
  ToolbarConfigNotifier(super.state);

  void reorderTools(int oldIndex, int newIndex) {
    final tools = List<ToolType>.from(state.toolOrder);
    final tool = tools.removeAt(oldIndex);
    tools.insert(newIndex, tool);
    state = state.copyWith(toolOrder: tools);
  }

  void setToolVisibility(ToolType tool, bool visible) {
    final visibleTools = Set<ToolType>.from(state.visibleTools);
    if (visible) {
      visibleTools.add(tool);
    } else {
      visibleTools.remove(tool);
    }
    state = state.copyWith(visibleTools: visibleTools);
  }

  void resetToDefault() {
    state = ToolbarConfig.defaultConfig();
  }
}

// =============================================================================
// HISTORY (UNDO/REDO)
// =============================================================================
// NOTE: Real HistoryProvider is now in history_provider.dart
// The historyManagerProvider, canUndoProvider, canRedoProvider,
// undoCountProvider, and redoCountProvider are exported from there.

// =============================================================================
// DOCUMENT PROVIDER
// =============================================================================
// NOTE: Real DocumentProvider is now in document_provider.dart
// The documentProvider, activeLayerStrokesProvider, strokeCountProvider,
// and isDocumentEmptyProvider are exported from there.
