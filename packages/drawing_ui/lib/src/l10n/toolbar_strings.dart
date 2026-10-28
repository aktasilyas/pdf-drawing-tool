/// User-facing copy of the editor toolbar and its settings panel.
///
/// Every getter and method must also be listed in [toMap]; the drift tests
/// rely on it. Parameterized strings are called with a fixed sample there.
abstract class ToolbarStrings {
  const ToolbarStrings();

  String get home;
  String get pages;
  String get ruler;
  String get audio;
  String get readerMode;
  String get editMode;
  String get more;
  String get layers;
  String get addPage;
  String get export;
  String get ai;
  String get untitled;
  String get moreColors;
  String get colorSetHighlighter;
  String get colorSetPastel;
  String selectedColor(String hex);
  String color(String hex);
  String thickness(String value);
  String get moreTools;
  String get readOnlyActive;
  String get readOnly;
  String get undo;
  String get redo;
  String get recordingInProgress;
  String get record;
  String get micPermissionRequired;
  String get showRecordings;
  String get settingsTabTools;
  String get settingsTabExtraTools;
  String get settingsToolsHint;
  String get settingsExtraToolsHint;
  String get settingsReset;

  /// Every getter by name, for drift tests.
  Map<String, String> toMap() => {
        'home': home,
        'pages': pages,
        'ruler': ruler,
        'audio': audio,
        'readerMode': readerMode,
        'editMode': editMode,
        'more': more,
        'layers': layers,
        'addPage': addPage,
        'export': export,
        'ai': ai,
        'untitled': untitled,
        'moreColors': moreColors,
        'colorSetHighlighter': colorSetHighlighter,
        'colorSetPastel': colorSetPastel,
        'selectedColor': selectedColor('#000000'),
        'color': color('#000000'),
        'thickness': thickness('2.0'),
        'moreTools': moreTools,
        'readOnlyActive': readOnlyActive,
        'readOnly': readOnly,
        'undo': undo,
        'redo': redo,
        'recordingInProgress': recordingInProgress,
        'record': record,
        'micPermissionRequired': micPermissionRequired,
        'showRecordings': showRecordings,
        'settingsTabTools': settingsTabTools,
        'settingsTabExtraTools': settingsTabExtraTools,
        'settingsToolsHint': settingsToolsHint,
        'settingsExtraToolsHint': settingsExtraToolsHint,
        'settingsReset': settingsReset,
      };
}

/// Turkish toolbar copy: the default when no scope is installed.
class ToolbarStringsTr extends ToolbarStrings {
  const ToolbarStringsTr();

  @override
  String get home => 'Ana Sayfa';
  @override
  String get pages => 'Sayfa Paneli';
  @override
  String get ruler => 'Cetvel';
  @override
  String get audio => 'Ses Kaydı';
  @override
  String get readerMode => 'Okuyucu Modu';
  @override
  String get editMode => 'Düzenleme Modu';
  @override
  String get more => 'Daha Fazla';
  @override
  String get layers => 'Katmanlar';
  @override
  String get addPage => 'Sayfa Ekle';
  @override
  String get export => 'Dışa Aktar';
  @override
  String get ai => 'Yapay Zeka';
  @override
  String get untitled => 'İsimsiz Not';
  @override
  String get moreColors => 'Daha Fazla Renk';
  @override
  String get colorSetHighlighter => 'Vurgulayıcı';
  @override
  String get colorSetPastel => 'Pastel';
  @override
  String selectedColor(String hex) => 'Seçili renk $hex';
  @override
  String color(String hex) => 'Renk $hex';
  @override
  String thickness(String value) => 'Kalınlık $value';
  @override
  String get moreTools => 'Daha fazla araç';
  @override
  String get readOnlyActive => 'Salt okunur mod aktif';
  @override
  String get readOnly => 'Salt okunur';
  @override
  String get undo => 'Geri al';
  @override
  String get redo => 'İleri al';
  @override
  String get recordingInProgress => 'Kayıt devam ediyor…';
  @override
  String get record => 'Kaydet';
  @override
  String get micPermissionRequired =>
      'Mikrofon izni gerekli. Lütfen ayarlardan izin verin.';
  @override
  String get showRecordings => 'Kayıtları göster';
  @override
  String get settingsTabTools => 'Araçlar';
  @override
  String get settingsTabExtraTools => 'Ek Araçlar';
  @override
  String get settingsToolsHint => 'Araçları sıralayın ve gizleyin';
  @override
  String get settingsExtraToolsHint => 'Ek araçları sıralayın ve gizleyin';
  @override
  String get settingsReset => 'Varsayılana Sıfırla';
}
