part of 'document.dart';

/// JSON serialization for [DrawingDocument].
mixin _DocumentJson on _DocumentViews {
  /// Converts this [DrawingDocument] to a JSON map.
  Map<String, dynamic> toJson() {
    if (isMultiPage) {
      // V2: Multi-page format
      return {
        'version': 2,
        'id': id,
        'title': title,
        'pages': pages.map((p) => p.toJson()).toList(),
        'currentPageIndex': currentPageIndex,
        'activeLayerIndex': activeLayerIndex,
        'settings': settings.toJson(),
        'documentType': documentType.name,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        if (audioRecordings.isNotEmpty)
          'audioRecordings': audioRecordings.map((r) => r.toJson()).toList(),
      };
    } else {
      // V1: Legacy format (no version for backward compat)
      return {
        'id': id,
        'title': title,
        'layers': layers.map((l) => l.toJson()).toList(),
        'activeLayerIndex': activeLayerIndex,
        'documentType': documentType.name,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'width': width,
        'height': height,
      };
    }
  }
}

/// Builds a document from V1 (legacy) or V2 (multi-page) JSON.
DrawingDocument _documentFromJson(Map<String, dynamic> json) {
  // Version detection with safe parsing
  final version = _parseVersion(json['version']) ?? 1;

  // Parse documentType (with fallback to notebook for backward compatibility)
  final documentType = json.containsKey('documentType')
      ? DocumentType.values.firstWhere(
          (e) => e.name == json['documentType'],
          orElse: () => DocumentType.notebook,
        )
      : DocumentType.notebook;

  // V2: Has version >= 2 AND pages field
  if (version >= 2 && json.containsKey('pages')) {
    return DrawingDocument.multiPage(
      id: json['id'] as String,
      title: json['title'] as String,
      pages: (json['pages'] as List)
          .map((p) => Page.fromJson(p as Map<String, dynamic>))
          .toList(),
      currentPageIndex: _parseInt(json['currentPageIndex']) ?? 0,
      activeLayerIndex: _parseInt(json['activeLayerIndex']) ?? 0,
      settings: json.containsKey('settings')
          ? DocumentSettings.fromJson(json['settings'] as Map<String, dynamic>)
          : DocumentSettings.defaults(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      documentType: documentType,
      audioRecordings: (json['audioRecordings'] as List?)
          ?.map((r) => AudioRecording.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }

  // V1: Legacy format with layers
  return DrawingDocument(
    id: json['id'] as String,
    title: json['title'] as String,
    layers: (json['layers'] as List)
        .map((l) => Layer.fromJson(l as Map<String, dynamic>))
        .toList(),
    activeLayerIndex: _parseInt(json['activeLayerIndex']) ?? 0,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
    width: _parseDouble(json['width']) ?? 1920.0,
    height: _parseDouble(json['height']) ?? 1080.0,
    documentType: documentType,
  );
}

/// Safe version parsing
int? _parseVersion(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value);
  if (value is num) return value.toInt();
  return null;
}

/// Safe int parsing
int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value);
  if (value is num) return value.toInt();
  return null;
}

/// Safe double parsing
double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value);
  if (value is num) return value.toDouble();
  return null;
}
