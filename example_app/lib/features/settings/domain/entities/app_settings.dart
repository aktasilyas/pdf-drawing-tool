import 'package:equatable/equatable.dart';

enum AppThemeMode { light, dark, system }
enum AppLanguage { tr, en }
enum PaperSize { a4, a5, letter }

class AppSettings extends Equatable {
  final AppThemeMode themeMode;
  final AppLanguage language;
  final PaperSize defaultPaperSize;
  final bool autoSaveEnabled;

  const AppSettings({
    this.themeMode = AppThemeMode.system,
    this.language = AppLanguage.tr,
    this.defaultPaperSize = PaperSize.a4,
    this.autoSaveEnabled = true,
  });

  AppSettings copyWith({
    AppThemeMode? themeMode,
    AppLanguage? language,
    PaperSize? defaultPaperSize,
    bool? autoSaveEnabled,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      defaultPaperSize: defaultPaperSize ?? this.defaultPaperSize,
      autoSaveEnabled: autoSaveEnabled ?? this.autoSaveEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
    'themeMode': themeMode.name,
    'language': language.name,
    'defaultPaperSize': defaultPaperSize.name,
    'autoSaveEnabled': autoSaveEnabled,
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      themeMode: AppThemeMode.values.firstWhere(
        (e) => e.name == json['themeMode'],
        orElse: () => AppThemeMode.system,
      ),
      language: AppLanguage.values.firstWhere(
        (e) => e.name == json['language'],
        orElse: () => AppLanguage.tr,
      ),
      defaultPaperSize: PaperSize.values.firstWhere(
        (e) => e.name == json['defaultPaperSize'],
        orElse: () => PaperSize.a4,
      ),
      autoSaveEnabled: json['autoSaveEnabled'] ?? true,
    );
  }

  @override
  List<Object?> get props => [themeMode, language, defaultPaperSize, autoSaveEnabled];
}
