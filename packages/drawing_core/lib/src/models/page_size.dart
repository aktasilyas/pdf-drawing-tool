/// Sayfa boyutu preset'leri
enum PagePreset {
  a4Portrait,
  a4Landscape,
  letterPortrait,
  letterLandscape,
  custom,
}

/// Sayfa boyutu modeli
class PageSize {
  final double width;
  final double height;
  final PagePreset? preset;

  const PageSize({
    required this.width,
    required this.height,
    this.preset,
  });

  /// A4 Portrait (595 x 842 points @ 72 DPI)
  static const a4Portrait = PageSize(
    width: 595,
    height: 842,
    preset: PagePreset.a4Portrait,
  );

  /// A4 Landscape
  static const a4Landscape = PageSize(
    width: 842,
    height: 595,
    preset: PagePreset.a4Landscape,
  );

  /// US Letter Portrait (612 x 792 points)
  static const letterPortrait = PageSize(
    width: 612,
    height: 792,
    preset: PagePreset.letterPortrait,
  );

  /// US Letter Landscape
  static const letterLandscape = PageSize(
    width: 792,
    height: 612,
    preset: PagePreset.letterLandscape,
  );

  /// Aspect ratio
  double get aspectRatio => width / height;

  /// Is landscape
  bool get isLandscape => width > height;

  /// Copy with
  PageSize copyWith({double? width, double? height}) {
    return PageSize(
      width: width ?? this.width,
      height: height ?? this.height,
      preset: PagePreset.custom,
    );
  }

  /// JSON serialization
  Map<String, dynamic> toJson() => {
    'width': width,
    'height': height,
    'preset': preset?.name,
  };

  factory PageSize.fromJson(Map<String, dynamic> json) {
    final presetName = json['preset'] as String?;
    final preset = presetName != null
        ? PagePreset.values.firstWhere(
            (p) => p.name == presetName,
            orElse: () => PagePreset.custom,
          )
        : null;
    
    // Handle String/int/double parsing safely
    double parseNumber(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.parse(value);
      throw ArgumentError('Invalid number: $value');
    }
    
    return PageSize(
      width: parseNumber(json['width']),
      height: parseNumber(json['height']),
      preset: preset,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PageSize &&
          width == other.width &&
          height == other.height;

  @override
  int get hashCode => Object.hash(width, height);
}
