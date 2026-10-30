/// User-facing copy of the export panel and options, file dialogs and progress.
///
/// Every getter and method must also be listed in [toMap]; the drift tests
/// rely on it. Parameterized strings are called with a fixed sample there.
abstract class ExportStrings {
  const ExportStrings();

  String get scopeAll;
  String get scopeCurrent;
  String get scopeRange;
  String get from;
  String get to;
  String get includeTemplate;
  String get exportPng;
  String get exportPdf;
  String get sharePdf;
  String invalidRange(int count);
  String get savePdfDialog;
  String get savePngDialog;
  String get fallbackFileName;
  String pageFileName(String title, int page);
  String get exporting;
  String percent(int percent);
  String remainingSeconds(int seconds);
  String remainingMinutes(int minutes);
  String get saved;
  String savedWithSize(String size);
  String get cancelled;

  /// Shown when an export is started while another one is still running.
  String get inProgress;
  String pagesWithoutPdfBackground(int count);
  String pagesWithoutImages(int count);

  /// Every getter by name, for drift tests.
  Map<String, String> toMap() => {
        'scopeAll': scopeAll,
        'scopeCurrent': scopeCurrent,
        'scopeRange': scopeRange,
        'from': from,
        'to': to,
        'includeTemplate': includeTemplate,
        'exportPng': exportPng,
        'exportPdf': exportPdf,
        'sharePdf': sharePdf,
        'invalidRange': invalidRange(1),
        'savePdfDialog': savePdfDialog,
        'savePngDialog': savePngDialog,
        'fallbackFileName': fallbackFileName,
        'pageFileName': pageFileName('Notes', 2),
        'exporting': exporting,
        'percent': percent(1),
        'remainingSeconds': remainingSeconds(1),
        'remainingMinutes': remainingMinutes(1),
        'saved': saved,
        'savedWithSize': savedWithSize('Notes'),
        'cancelled': cancelled,
        'inProgress': inProgress,
        'pagesWithoutPdfBackground': pagesWithoutPdfBackground(2),
        'pagesWithoutImages': pagesWithoutImages(2),
      };
}

/// Turkish copy: the default when no scope is installed.
class ExportStringsTr extends ExportStrings {
  const ExportStringsTr();

  @override
  String get scopeAll => 'Tümü';

  @override
  String get scopeCurrent => 'Bu sayfa';

  @override
  String get scopeRange => 'Aralık';

  @override
  String get from => 'Başlangıç';

  @override
  String get to => 'Bitiş';

  @override
  String get includeTemplate => 'Sayfa şablonunu dahil et';

  @override
  String get exportPng => 'PNG Olarak Dışa Aktar';

  @override
  String get exportPdf => 'PDF Olarak Dışa Aktar';

  @override
  String get sharePdf => 'PDF Paylaş';

  @override
  String invalidRange(int count) =>
      'Sayfa aralığı 1 ile $count arasında olmalı.';

  @override
  String get savePdfDialog => 'PDF Kaydet';

  @override
  String get savePngDialog => 'PNG Kaydet';

  @override
  String get fallbackFileName => 'doküman';

  @override
  String pageFileName(String title, int page) => '${title}_sayfa$page';

  @override
  String get exporting => 'PDF Dışa Aktarılıyor...';

  @override
  String percent(int percent) => '%$percent';

  @override
  String remainingSeconds(int seconds) => '~$seconds sn';

  @override
  String remainingMinutes(int minutes) => '~$minutes dk';

  @override
  String get saved => 'PDF Kaydedildi';

  @override
  String savedWithSize(String size) => 'PDF Kaydedildi ($size)';

  @override
  String get cancelled => 'İptal edildi';

  @override
  String get inProgress => 'Bir dışa aktarma zaten sürüyor';

  @override
  String pagesWithoutPdfBackground(int count) =>
      '$count sayfa PDF arka planı olmadan dışa aktarıldı';

  @override
  String pagesWithoutImages(int count) =>
      '$count sayfadaki bazı görseller okunamadı ve dışa aktarılmadı';
}
