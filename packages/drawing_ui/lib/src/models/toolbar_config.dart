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

/// Complete toolbar configuration.
@immutable
class ToolbarConfig {
  const ToolbarConfig({
    required this.tools,
    this.showQuickAccess = true,
    this.quickAccessColors = const [],
    this.quickAccessThicknesses = const [],
  });

  final List<ToolConfig> tools;
  final bool showQuickAccess;
  final List<int> quickAccessColors; // Color values
  final List<double> quickAccessThicknesses;

  /// Default toolbar configuration
  factory ToolbarConfig.defaultConfig() {
    final defaultTools = [
      ToolType.ballpointPen,
      ToolType.pencil,
      ToolType.highlighter,
      ToolType.pixelEraser,
      ToolType.selection,
      ToolType.shapes,
      ToolType.text,
      ToolType.image,
    ];

    return ToolbarConfig(
      tools: defaultTools.asMap().entries.map((e) => ToolConfig(
        toolType: e.value,
        isVisible: true,
        order: e.key,
      )).toList(),
      showQuickAccess: true,
      quickAccessColors: const [
        0xFF000000, // Black
        0xFF2196F3, // Blue
        0xFFF44336, // Red
        0xFF4CAF50, // Green
        0xFFFF9800, // Orange
      ],
      quickAccessThicknesses: const [1.0, 2.0, 4.0],
    );
  }

  /// Get visible tools sorted by order
  List<ToolConfig> get visibleTools {
    return tools
        .where((t) => t.isVisible)
        .toList()
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
  }) {
    return ToolbarConfig(
      tools: tools ?? this.tools,
      showQuickAccess: showQuickAccess ?? this.showQuickAccess,
      quickAccessColors: quickAccessColors ?? this.quickAccessColors,
      quickAccessThicknesses: quickAccessThicknesses ?? this.quickAccessThicknesses,
    );
  }

  /// Update a specific tool's config
  ToolbarConfig updateTool(ToolType toolType, ToolConfig Function(ToolConfig) update) {
    final newTools = tools.map((t) {
      if (t.toolType == toolType) {
        return update(t);
      }
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
    
    // Update order values
    final newTools = sorted.asMap().entries.map((e) {
      return e.value.copyWith(order: e.key);
    }).toList();
    
    return copyWith(tools: newTools);
  }

  /// Reset to default
  ToolbarConfig reset() => ToolbarConfig.defaultConfig();

  Map<String, dynamic> toJson() => {
    'tools': tools.map((t) => t.toJson()).toList(),
    'showQuickAccess': showQuickAccess,
    'quickAccessColors': quickAccessColors,
    'quickAccessThicknesses': quickAccessThicknesses,
  };

  factory ToolbarConfig.fromJson(Map<String, dynamic> json) {
    return ToolbarConfig(
      tools: (json['tools'] as List<dynamic>?)
          ?.map((t) => ToolConfig.fromJson(t as Map<String, dynamic>))
          .toList() ?? ToolbarConfig.defaultConfig().tools,
      showQuickAccess: json['showQuickAccess'] ?? true,
      quickAccessColors: (json['quickAccessColors'] as List<dynamic>?)
          ?.map((c) => c as int)
          .toList() ?? const [],
      quickAccessThicknesses: (json['quickAccessThicknesses'] as List<dynamic>?)
          ?.map((t) => (t as num).toDouble())
          .toList() ?? const [],
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory ToolbarConfig.fromJsonString(String jsonString) {
    return ToolbarConfig.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }
}
