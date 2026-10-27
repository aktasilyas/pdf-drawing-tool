import 'package:drawing_core/drawing_core.dart' show Page;

/// Which pages an export covers.
enum ExportPageScope { all, current, range }

/// User choices made in the export options step.
class ExportOptions {
  const ExportOptions({
    this.scope = ExportPageScope.all,
    this.from = 1,
    this.to = 1,
    this.includeTemplate = true,
  });

  final ExportPageScope scope;

  /// 1-based inclusive range, only used when [scope] is [ExportPageScope.range].
  final int from;
  final int to;

  /// When false the page template/cover/pattern paper is dropped. PDF-imported
  /// page content is always kept.
  final bool includeTemplate;

  ExportOptions copyWith({
    ExportPageScope? scope,
    int? from,
    int? to,
    bool? includeTemplate,
  }) =>
      ExportOptions(
        scope: scope ?? this.scope,
        from: from ?? this.from,
        to: to ?? this.to,
        includeTemplate: includeTemplate ?? this.includeTemplate,
      );

  /// Whether the choice is exportable for a document with [pageCount] pages.
  bool isValid(int pageCount) =>
      scope != ExportPageScope.range ||
      (from >= 1 && to <= pageCount && from <= to);

  /// The pages to export, in document order.
  List<Page> select(List<Page> pages, int currentIndex) {
    switch (scope) {
      case ExportPageScope.all:
        return pages;
      case ExportPageScope.current:
        if (pages.isEmpty) return const [];
        return [pages[currentIndex.clamp(0, pages.length - 1)]];
      case ExportPageScope.range:
        return pages.sublist(from - 1, to);
    }
  }
}
