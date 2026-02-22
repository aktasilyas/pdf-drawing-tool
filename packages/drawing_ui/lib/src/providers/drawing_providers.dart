import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_ui/src/models/models.dart';
import 'package:drawing_ui/src/providers/pen_settings_provider.dart';

// Re-export extracted settings providers for backward compatibility.
export 'pen_settings_provider.dart';
export 'highlighter_settings_provider.dart';
export 'eraser_settings_provider.dart';

// =============================================================================
// TOOL SELECTION
// =============================================================================

/// Currently selected tool type.
final currentToolProvider = StateProvider<ToolType>((ref) {
  return ToolType.ballpointPen;
});

/// Tool that was active before switching to eraser (for autoLift).
final previousToolProvider = StateProvider<ToolType?>((ref) => null);

/// Whether a panel is currently open (and which one).
final activePanelProvider = StateProvider<ToolType?>((ref) {
  return null;
});

// =============================================================================
// SHAPES SETTINGS
// =============================================================================

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

/// Shape type enum - En cok kullanilan 10 sekil.
/// Core ShapeType ile birebir eslesir.
enum ShapeType {
  /// Duz cizgi
  line,

  /// Ok isareti
  arrow,

  /// Dikdortgen
  rectangle,

  /// Elips/Daire
  ellipse,

  /// Ucgen
  triangle,

  /// Eskenar dortgen
  diamond,

  /// Yildiz
  star,

  /// Besgen
  pentagon,

  /// Altigen
  hexagon,

  /// Arti isareti
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

  /// Rectangle selection (Dikdortgen kement).
  rectangle,
}

/// Types of elements that can be selected with lasso tool.
enum SelectableType {
  /// Shapes (Sekil).
  shape,

  /// Images and stickers (Resim/Cikartma).
  imageSticker,

  /// Tape/washi elements (Bant).
  tape,

  /// Text boxes (Metin kutusu).
  textBox,

  /// Handwriting strokes (El yazisi).
  handwriting,

  /// Highlighter strokes (Vurgulayici).
  highlighter,

  /// Links (Baglanti).
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
  /// Line mode - draws a temporary line (Cizgi).
  line,

  /// Dot mode - shows a temporary dot (Nokta).
  dot,
}

/// Laser line drawing style (only applies in line mode).
enum LaserLineStyle {
  /// Solid neon glow line with bright core.
  solid,

  /// Hollow neon line - glow only, no bright core.
  hollow,

  /// Rainbow gradient along the path.
  rainbow,
}

/// Laser pointer settings data model.
class LaserSettings {
  const LaserSettings({
    required this.mode,
    required this.lineStyle,
    required this.thickness,
    required this.duration,
    required this.color,
  });

  /// The current laser mode (line or dot).
  final LaserMode mode;

  /// Line drawing style (solid / hollow / rainbow).
  final LaserLineStyle lineStyle;

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
      lineStyle: LaserLineStyle.solid,
      thickness: 0.5,
      duration: 2.0,
      color: Color(0xFF29B6F6), // Light blue
    );
  }

  LaserSettings copyWith({
    LaserMode? mode,
    LaserLineStyle? lineStyle,
    double? thickness,
    double? duration,
    Color? color,
  }) {
    return LaserSettings(
      mode: mode ?? this.mode,
      lineStyle: lineStyle ?? this.lineStyle,
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

  void setLineStyle(LaserLineStyle style) {
    state = state.copyWith(lineStyle: style);
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
    final emptyIndex = state.indexWhere((p) => p.isEmpty);
    if (emptyIndex != -1) {
      updatePreset(emptyIndex, preset);
    } else {
      state = [...state, preset];
    }
  }

  void removePreset(int index) {
    if (index < 0 || index >= state.length) return;
    state = [
      ...state.sublist(0, index),
      ...state.sublist(index + 1),
    ];
  }
}

// =============================================================================
// TOOLBAR CONFIGURATION
// =============================================================================
// NOTE: ToolbarConfig model is now in models/toolbar_config.dart
// NOTE: Toolbar configuration provider is now in toolbar_config_provider.dart
// with SharedPreferences persistence

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
