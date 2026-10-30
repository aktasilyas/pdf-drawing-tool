/// User-facing copy of the lasso panel, selection actions, screenshot
/// messages and context menus.
///
/// Every getter must also be listed in [toMap]; the drift tests rely on it.
abstract class SelectionStrings {
  const SelectionStrings();

  /// Lasso mode.
  String get lassoFreeform;

  /// Lasso mode.
  String get lassoRectangle;

  /// Lasso selectable-types section.
  String get lassoSelectable;

  /// Selectable type.
  String get typeHandwriting;

  /// Selectable type.
  String get typeShape;

  /// Selectable type.
  String get typeImage;

  /// Selectable type.
  String get typeHighlighter;

  /// Selectable type.
  String get typeText;

  /// Selectable type.
  String get typeTape;

  /// Selectable type.
  String get typeLink;

  /// Selectable type.
  String get typeLabel;

  /// Selection action.
  String get ai;

  /// Selection action.
  String get color;

  /// Selection action.
  String get screenshot;

  /// Selection action.
  String get cut;

  /// Selection action.
  String get duplicate;

  /// Selection action.
  String get delete;

  /// Selection action.
  String get bringToFront;

  /// Selection action.
  String get sendToBack;

  /// Selection action.
  String get copy;

  /// Selection action.
  String get paste;

  /// Selection action.
  String get askAi;

  /// Selection action.
  String get takeScreenshot;

  /// Selection overflow menu.
  String get more;

  /// Screenshot preview save button.
  String get save;

  /// Screenshot failure message.
  String get screenshotCaptureFailed;

  /// Screenshot success message.
  String get screenshotSavedAndCopied;

  /// Screenshot success message.
  String get screenshotSaved;

  /// Screenshot success message.
  String get screenshotCopied;

  /// Screenshot failure message.
  String get screenshotSaveFailed;

  /// Every getter by name, for drift tests.
  Map<String, String> toMap() => {
        'lassoFreeform': lassoFreeform,
        'lassoRectangle': lassoRectangle,
        'lassoSelectable': lassoSelectable,
        'typeHandwriting': typeHandwriting,
        'typeShape': typeShape,
        'typeImage': typeImage,
        'typeHighlighter': typeHighlighter,
        'typeText': typeText,
        'typeTape': typeTape,
        'typeLink': typeLink,
        'typeLabel': typeLabel,
        'ai': ai,
        'color': color,
        'screenshot': screenshot,
        'cut': cut,
        'duplicate': duplicate,
        'delete': delete,
        'bringToFront': bringToFront,
        'sendToBack': sendToBack,
        'copy': copy,
        'paste': paste,
        'askAi': askAi,
        'takeScreenshot': takeScreenshot,
        'more': more,
        'save': save,
        'screenshotCaptureFailed': screenshotCaptureFailed,
        'screenshotSavedAndCopied': screenshotSavedAndCopied,
        'screenshotSaved': screenshotSaved,
        'screenshotCopied': screenshotCopied,
        'screenshotSaveFailed': screenshotSaveFailed,
      };
}

/// Turkish copy: the default when no scope is installed.
class SelectionStringsTr extends SelectionStrings {
  const SelectionStringsTr();

  @override
  String get lassoFreeform => 'Serbest Seçim';

  @override
  String get lassoRectangle => 'Dikdörtgen Seçim';

  @override
  String get lassoSelectable => 'Seçilebilir';

  @override
  String get typeHandwriting => 'El yazısı';

  @override
  String get typeShape => 'Şekil';

  @override
  String get typeImage => 'Resim';

  @override
  String get typeHighlighter => 'Vurgulayıcı';

  @override
  String get typeText => 'Metin';

  @override
  String get typeTape => 'Bant';

  @override
  String get typeLink => 'Link';

  @override
  String get typeLabel => 'Etiket';

  @override
  String get ai => 'AI Asistan';

  @override
  String get color => 'Renk';

  @override
  String get screenshot => 'Ekran Resmi';

  @override
  String get cut => 'Kes';

  @override
  String get duplicate => 'Çoğalt';

  @override
  String get delete => 'Sil';

  @override
  String get bringToFront => 'Öne Getir';

  @override
  String get sendToBack => 'Arkaya Gönder';

  @override
  String get copy => 'Kopyala';

  @override
  String get paste => 'Yapıştır';

  @override
  String get askAi => 'Yapay zekaya sor';

  @override
  String get takeScreenshot => 'Ekran Resmi Çek';

  @override
  String get more => 'Daha fazla';

  @override
  String get save => 'Kaydet';

  @override
  String get screenshotCaptureFailed => 'Ekran resmi oluşturulamadı';

  @override
  String get screenshotSavedAndCopied =>
      'Ekran resmi galeriye kaydedildi ve panoya kopyalandı';

  @override
  String get screenshotSaved => 'Ekran resmi galeriye kaydedildi';

  @override
  String get screenshotCopied => 'Ekran resmi panoya kopyalandı';

  @override
  String get screenshotSaveFailed => 'Ekran resmi kaydedilemedi';
}
