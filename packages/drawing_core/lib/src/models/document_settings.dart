import 'package:drawing_core/src/models/page_background.dart';
import 'package:drawing_core/src/models/page_size.dart';

/// Document-wide settings
class DocumentSettings {
  /// Default page size for new pages
  final PageSize defaultPageSize;

  /// Default background for new pages
  final PageBackground defaultBackground;

  const DocumentSettings({
    required this.defaultPageSize,
    required this.defaultBackground,
  });

  /// Create settings with default values
  factory DocumentSettings.defaults() {
    return const DocumentSettings(
      defaultPageSize: PageSize.a4Portrait,
      defaultBackground: PageBackground.blank,
    );
  }

  /// Copy with new values
  DocumentSettings copyWith({
    PageSize? defaultPageSize,
    PageBackground? defaultBackground,
  }) {
    return DocumentSettings(
      defaultPageSize: defaultPageSize ?? this.defaultPageSize,
      defaultBackground: defaultBackground ?? this.defaultBackground,
    );
  }

  /// JSON serialization
  Map<String, dynamic> toJson() => {
    'defaultPageSize': defaultPageSize.toJson(),
    'defaultBackground': defaultBackground.toJson(),
  };

  factory DocumentSettings.fromJson(Map<String, dynamic> json) {
    return DocumentSettings(
      defaultPageSize: PageSize.fromJson(json['defaultPageSize'] as Map<String, dynamic>),
      defaultBackground: PageBackground.fromJson(json['defaultBackground'] as Map<String, dynamic>),
    );
  }
}
