/// Kapak stilleri
enum CoverStyle {
  solid, // Düz renk
  gradient, // Gradient
  pattern, // Desenli (çizgili, noktalı vs)
  minimal, // Minimalist çerçeve
  image, // Görsel kapak (asset)
  material, // Procedural material (linen, leather, kraft, felt)
}

/// Material of a procedural [CoverStyle.material] cover.
enum CoverMaterial { linen, leather, kraft, felt }

/// Kapak modeli
class Cover {
  final String id;
  final String name;
  final CoverStyle style;
  final int primaryColor;
  final int? secondaryColor; // Gradient için
  final String?
      imagePath; // Asset path (örn: 'assets/covers/cover_01_kraft.webp')
  final bool isPremium;
  final bool showTitle; // Başlık gösterilsin mi
  final CoverMaterial? material; // Only for CoverStyle.material

  const Cover({
    required this.id,
    required this.name,
    required this.style,
    required this.primaryColor,
    this.secondaryColor,
    this.imagePath,
    this.isPremium = false,
    this.showTitle = false,
    this.material,
  });

  factory Cover.fromJson(Map<String, dynamic> json) {
    return Cover(
      id: json['id'] as String,
      name: json['name'] as String,
      style: CoverStyle.values.firstWhere(
        (s) => s.name == json['style'],
        orElse: () => CoverStyle.solid,
      ),
      primaryColor: json['primaryColor'] as int,
      secondaryColor: json['secondaryColor'] as int?,
      imagePath: json['imagePath'] as String?,
      isPremium: json['isPremium'] as bool? ?? false,
      showTitle: json['showTitle'] as bool? ?? false,
      material: _materialFromName(json['material'] as String?),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'style': style.name,
        'primaryColor': primaryColor,
        if (secondaryColor != null) 'secondaryColor': secondaryColor,
        if (imagePath != null) 'imagePath': imagePath,
        'isPremium': isPremium,
        'showTitle': showTitle,
        if (material != null) 'material': material!.name,
      };

  static CoverMaterial? _materialFromName(String? name) {
    if (name == null) return null;
    for (final m in CoverMaterial.values) {
      if (m.name == name) return m;
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Cover && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
