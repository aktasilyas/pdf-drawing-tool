/// Kapak stilleri
enum CoverStyle {
  solid,      // Düz renk
  gradient,   // Gradient
  pattern,    // Desenli (çizgili, noktalı vs)
  minimal,    // Minimalist çerçeve
  image,      // Görsel kapak (asset)
}

/// Kapak modeli
class Cover {
  final String id;
  final String name;
  final CoverStyle style;
  final int primaryColor;
  final int? secondaryColor; // Gradient için
  final String? imagePath; // Asset path (örn: 'assets/covers/cover_01_kraft.webp')
  final bool isPremium;
  final bool showTitle; // Başlık gösterilsin mi

  const Cover({
    required this.id,
    required this.name,
    required this.style,
    required this.primaryColor,
    this.secondaryColor,
    this.imagePath,
    this.isPremium = false,
    this.showTitle = false,
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
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Cover && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
