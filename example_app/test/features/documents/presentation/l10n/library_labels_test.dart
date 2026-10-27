import 'package:drawing_core/drawing_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:example_app/core/core.dart';
import 'package:example_app/features/documents/documents.dart';
import 'package:example_app/features/documents/domain/entities/sort_option.dart';
import 'package:example_app/features/documents/presentation/l10n/library_labels.dart';
import 'package:example_app/l10n/l10n.dart';

void main() {
  const locales = [Locale('en'), Locale('tr')];

  void expectDistinctNonEmpty(
    Iterable<String> labels,
    String locale,
    String what,
  ) {
    final list = labels.toList();
    for (final label in list) {
      expect(label.trim(), isNotEmpty, reason: '$what ($locale)');
    }
    expect(list.toSet(), hasLength(list.length), reason: '$what ($locale)');
  }

  for (final locale in locales) {
    final l10n = lookupAppLocalizations(locale);
    final code = locale.languageCode;

    test('every LibraryAction has a distinct message in $code', () {
      expectDistinctNonEmpty(
        LibraryAction.values.map((a) => a.failureMessage(l10n)),
        code,
        'LibraryAction',
      );
    });

    test('every LibraryRule has a distinct message in $code', () {
      expectDistinctNonEmpty(
        LibraryRule.values.map((r) => r.message(l10n)),
        code,
        'LibraryRule',
      );
    });

    test('sort options and sidebar sections are labelled in $code', () {
      expectDistinctNonEmpty(
        SortOption.values.map((o) => o.label(l10n)),
        code,
        'SortOption',
      );
      expectDistinctNonEmpty(
        SidebarSection.values.map((s) => s.title(l10n)),
        code,
        'SidebarSection',
      );
    });

    test('every PaperSizePreset is labelled in $code', () {
      expectDistinctNonEmpty(
        PaperSizePreset.values.map((p) => p.label(l10n)),
        code,
        'PaperSizePreset',
      );
    });

    test('LibraryError picks rule or action text in $code', () {
      final rule = LibraryError(
        LibraryRuleFailure(LibraryRule.folderDepth),
        LibraryAction.createFolder,
      );
      expect(rule.message(l10n), LibraryRule.folderDepth.message(l10n));

      final storage = LibraryError(
        const CacheFailure('disk full'),
        LibraryAction.createFolder,
      );
      expect(
        storage.message(l10n),
        LibraryAction.createFolder.failureMessage(l10n),
      );
    });
  }

  test('localizedName follows the locale', () {
    final tr = lookupAppLocalizations(const Locale('tr'));
    final en = lookupAppLocalizations(const Locale('en'));
    expect(localizedName(tr, tr: 'Notlar', en: 'Notes'), 'Notlar');
    expect(localizedName(en, tr: 'Notlar', en: 'Notes'), 'Notes');
  });

  test('a rule failure has an English diagnostic message', () {
    final failure = LibraryRuleFailure(LibraryRule.folderLimit);
    expect(failure, isA<ValidationFailure>());
    expect(failure.message, contains('library rule'));
  });
}
