import 'package:drawing_core/src/models/page_size.dart';

/// Standart kağıt boyutu presetleri
enum PaperSizePreset {
  a4,
  a5,
  a6,
  letter,
  legal,
  square,
  widescreen,
  custom,
}

/// Kağıt boyutu modeli (mm cinsinden)
/// 
/// Template seçimi için kullanılır, daha sonra PageSize'a dönüştürülür.
class PaperSize {
  final double widthMm;
  final double heightMm;
  final PaperSizePreset preset;
  final bool isLandscape;

  const PaperSize({
    required this.widthMm,
    required this.heightMm,
    required this.preset,
    this.isLandscape = false,
  });

  /// Pixel cinsinden genişlik (72 DPI)
  double get widthPx => widthMm * 72 / 25.4;
  
  /// Pixel cinsinden yükseklik (72 DPI)
  double get heightPx => heightMm * 72 / 25.4;
  
  /// En-boy oranı
  double get aspectRatio => widthMm / heightMm;

  /// Landscape versiyonu
  PaperSize get landscape => isLandscape 
      ? this 
      : PaperSize(
          widthMm: heightMm,
          heightMm: widthMm,
          preset: preset,
          isLandscape: true,
        );

  /// Portrait versiyonu
  PaperSize get portrait => !isLandscape 
      ? this 
      : PaperSize(
          widthMm: heightMm,
          heightMm: widthMm,
          preset: preset,
          isLandscape: false,
        );

  // === STANDART BOYUTLAR ===
  
  static const a4 = PaperSize(widthMm: 210, heightMm: 297, preset: PaperSizePreset.a4);
  static const a5 = PaperSize(widthMm: 148, heightMm: 210, preset: PaperSizePreset.a5);
  static const a6 = PaperSize(widthMm: 105, heightMm: 148, preset: PaperSizePreset.a6);
  static const letter = PaperSize(widthMm: 215.9, heightMm: 279.4, preset: PaperSizePreset.letter);
  static const legal = PaperSize(widthMm: 215.9, heightMm: 355.6, preset: PaperSizePreset.legal);
  static const square = PaperSize(widthMm: 210, heightMm: 210, preset: PaperSizePreset.square);
  static const widescreen = PaperSize(widthMm: 297, heightMm: 167, preset: PaperSizePreset.widescreen);

  /// Preset'ten PaperSize oluştur
  static PaperSize fromPreset(PaperSizePreset preset) {
    switch (preset) {
      case PaperSizePreset.a4: return a4;
      case PaperSizePreset.a5: return a5;
      case PaperSizePreset.a6: return a6;
      case PaperSizePreset.letter: return letter;
      case PaperSizePreset.legal: return legal;
      case PaperSizePreset.square: return square;
      case PaperSizePreset.widescreen: return widescreen;
      case PaperSizePreset.custom: return a4; // Default
    }
  }

  factory PaperSize.fromJson(Map<String, dynamic> json) {
    return PaperSize(
      widthMm: (json['widthMm'] as num).toDouble(),
      heightMm: (json['heightMm'] as num).toDouble(),
      preset: PaperSizePreset.values.firstWhere(
        (p) => p.name == json['preset'],
        orElse: () => PaperSizePreset.custom,
      ),
      isLandscape: json['isLandscape'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'widthMm': widthMm,
    'heightMm': heightMm,
    'preset': preset.name,
    'isLandscape': isLandscape,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaperSize &&
          widthMm == other.widthMm &&
          heightMm == other.heightMm &&
          isLandscape == other.isLandscape;

  @override
  int get hashCode => Object.hash(widthMm, heightMm, isLandscape);
}

/// PaperSize → PageSize dönüşümü
extension PaperSizeToPageSize on PaperSize {
  /// PageSize'a dönüştür (pixel cinsinden)
  PageSize toPageSize() => PageSize(
    width: widthPx, 
    height: heightPx,
  );
}
