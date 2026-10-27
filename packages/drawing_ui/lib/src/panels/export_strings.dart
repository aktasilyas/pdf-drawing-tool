/// Strings of the export options step, kept together until the l10n slice
/// (#201) moves them into ARB files.
abstract final class ExportStrings {
  static const scopeAll = 'Tümü';
  static const scopeCurrent = 'Bu sayfa';
  static const scopeRange = 'Aralık';
  static const from = 'Başlangıç';
  static const to = 'Bitiş';
  static const includeTemplate = 'Sayfa şablonunu dahil et';
  static String invalidRange(int count) =>
      'Sayfa aralığı 1 ile $count arasında olmalı.';
}
