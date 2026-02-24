import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:drawing_ui/src/models/tool_type.dart';

/// Configuration for a single tool in the toolbar.
@immutable
class ToolConfig {
  const ToolConfig({
    required this.toolType,
    this.isVisible = true,
    this.order = 0,
  });

  final ToolType toolType;
  final bool isVisible;
  final int order;

  ToolConfig copyWith({
    ToolType? toolType,
    bool? isVisible,
    int? order,
  }) {
    return ToolConfig(
      toolType: toolType ?? this.toolType,
      isVisible: isVisible ?? this.isVisible,
      order: order ?? this.order,
    );
  }

  Map<String, dynamic> toJson() => {
    'toolType': toolType.name,
    'isVisible': isVisible,
    'order': order,
  };

  factory ToolConfig.fromJson(Map<String, dynamic> json) {
    return ToolConfig(
      toolType: ToolType.values.firstWhere(
        (t) => t.name == json['toolType'],
        orElse: () => ToolType.ballpointPen,
      ),
      isVisible: json['isVisible'] ?? true,
      order: json['order'] ?? 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ToolConfig &&
          runtimeType == other.runtimeType &&
          toolType == other.toolType &&
          isVisible == other.isVisible &&
          order == other.order;

  @override
  int get hashCode => Object.hash(toolType, isVisible, order);
}

/// Configuration for an extra tool (ruler, audio, etc.).
@immutable
class ExtraToolConfig {
  const ExtraToolConfig({
    required this.key,
    this.isVisible = true,
    this.order = 0,
  });

  final String key;
  final bool isVisible;
  final int order;

  ExtraToolConfig copyWith({String? key, bool? isVisible, int? order}) {
    return ExtraToolConfig(
      key: key ?? this.key,
      isVisible: isVisible ?? this.isVisible,
      order: order ?? this.order,
    );
  }

  Map<String, dynamic> toJson() => {
    'key': key,
    'isVisible': isVisible,
    'order': order,
  };

  factory ExtraToolConfig.fromJson(Map<String, dynamic> json) {
    return ExtraToolConfig(
      key: json['key'] as String? ?? '',
      isVisible: json['isVisible'] as bool? ?? true,
      order: json['order'] as int? ?? 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExtraToolConfig &&
          runtimeType == other.runtimeType &&
          key == other.key &&
          isVisible == other.isVisible &&
          order == other.order;

  @override
  int get hashCode => Object.hash(key, isVisible, order);
}

/// Complete toolbar configuration.
@immutable
class ToolbarConfig {
  const ToolbarConfig({
    required this.tools,
    this.showQuickAccess = true,
    this.quickAccessColors = const [],
    this.quickAccessThicknesses = const [],
    this.extraTools = const [],
  });

  final List<ToolConfig> tools;
  final bool showQuickAccess;
  final List<int> quickAccessColors;
  final List<double> quickAccessThicknesses;
  final List<ExtraToolConfig> extraTools;

  /// Whether an extra tool is visible (defaults to true).
  bool extraToolVisible(String key) {
    final tool = extraTools.cast<ExtraToolConfig?>().firstWhere(
      (t) => t!.key == key,
      orElse: () => null,
    );
    return tool?.isVisible ?? true;
  }

  /// Get extra tools sorted by order.
  List<ExtraToolConfig> get sortedExtraTools {
    return List<ExtraToolConfig>.from(extraTools)
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  /// Default extra tools.
  static List<ExtraToolConfig> defaultExtraTools() => const [
    ExtraToolConfig(key: 'ruler', isVisible: true, order: 0),
    ExtraToolConfig(key: 'audio', isVisible: true, order: 1),
  ];

  /// Default toolbar configuration
  factory ToolbarConfig.defaultConfig() {
    final defaultTools = [
      ToolType.ballpointPen,
      ToolType.highlighter,
      ToolType.pixelEraser,
      ToolType.selection,
      ToolType.shapes,
      ToolType.text,
      ToolType.sticker,
      ToolType.image,
      ToolType.laserPointer,
    ];

    return ToolbarConfig(
      tools: defaultTools.asMap().entries.map((e) => ToolConfig(
        toolType: e.value,
        isVisible: true,
        order: e.key,
      )).toList(),
      showQuickAccess: true,
      quickAccessColors: const [
        0xFF000000, 0xFF2196F3, 0xFFF44336, 0xFF4CAF50, 0xFFFF9800,
      ],
      quickAccessThicknesses: const [1.0, 2.0, 4.0],
      extraTools: defaultExtraTools(),
    );
  }

  /// Get visible tools sorted by order
  List<ToolConfig> get visibleTools {
    return tools.where((t) => t.isVisible).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  /// Get all tools sorted by order
  List<ToolConfig> get sortedTools {
    return List<ToolConfig>.from(tools)
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  ToolbarConfig copyWith({
    List<ToolConfig>? tools,
    bool? showQuickAccess,
    List<int>? quickAccessColors,
    List<double>? quickAccessThicknesses,
    List<ExtraToolConfig>? extraTools,
  }) {
    return ToolbarConfig(
      tools: tools ?? this.tools,
      showQuickAccess: showQuickAccess ?? this.showQuickAccess,
      quickAccessColors: quickAccessColors ?? this.quickAccessColors,
      quickAccessThicknesses: quickAccessThicknesses ?? this.quickAccessThicknesses,
      extraTools: extraTools ?? this.extraTools,
    );
  }

  /// Update a specific tool's config
  ToolbarConfig updateTool(ToolType toolType, ToolConfig Function(ToolConfig) update) {
    final newTools = tools.map((t) {
      if (t.toolType == toolType) return update(t);
      return t;
    }).toList();
    return copyWith(tools: newTools);
  }

  /// Toggle tool visibility
  ToolbarConfig toggleToolVisibility(ToolType toolType) {
    return updateTool(toolType, (t) => t.copyWith(isVisible: !t.isVisible));
  }

  /// Reorder tools
  ToolbarConfig reorderTools(int oldIndex, int newIndex) {
    final sorted = sortedTools;
    final tool = sorted.removeAt(oldIndex);
    sorted.insert(newIndex, tool);
    final newTools = sorted.asMap().entries.map((e) {
      return e.value.copyWith(order: e.key);
    }).toList();
    return copyWith(tools: newTools);
  }

  /// Toggle extra tool visibility
  ToolbarConfig toggleExtraToolVisibility(String key) {
    final newExtras = extraTools.map((t) {
      if (t.key == key) return t.copyWith(isVisible: !t.isVisible);
      return t;
    }).toList();
    return copyWith(extraTools: newExtras);
  }

  /// Reorder extra tools
  ToolbarConfig reorderExtraTools(int oldIndex, int newIndex) {
    final sorted = sortedExtraTools;
    final tool = sorted.removeAt(oldIndex);
    sorted.insert(newIndex, tool);
    final newExtras = sorted.asMap().entries.map((e) {
      return e.value.copyWith(order: e.key);
    }).toList();
    return copyWith(extraTools: newExtras);
  }

  /// Reset to default
  ToolbarConfig reset() => ToolbarConfig.defaultConfig();

  Map<String, dynamic> toJson() => {
    'tools': tools.map((t) => t.toJson()).toList(),
    'showQuickAccess': showQuickAccess,
    'quickAccessColors': quickAccessColors,
    'quickAccessThicknesses': quickAccessThicknesses,
    'extraTools': extraTools.map((t) => t.toJson()).toList(),
  };

  factory ToolbarConfig.fromJson(Map<String, dynamic> json) {
    return ToolbarConfig(
      tools: (json['tools'] as List<dynamic>?)
          ?.map((t) => ToolConfig.fromJson(t as Map<String, dynamic>))
          .toList() ?? ToolbarConfig.defaultConfig().tools,
      showQuickAccess: json['showQuickAccess'] ?? true,
      quickAccessColors: (json['quickAccessColors'] as List<dynamic>?)
          ?.map((c) => c as int).toList() ?? const [],
      quickAccessThicknesses: (json['quickAccessThicknesses'] as List<dynamic>?)
          ?.map((t) => (t as num).toDouble()).toList() ?? const [],
      extraTools: (json['extraTools'] as List<dynamic>?)
          ?.map((t) => ExtraToolConfig.fromJson(t as Map<String, dynamic>))
          .toList() ?? ToolbarConfig.defaultExtraTools(),
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory ToolbarConfig.fromJsonString(String jsonString) {
    return ToolbarConfig.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }
}
