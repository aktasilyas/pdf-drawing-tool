import 'package:flutter_test/flutter_test.dart';

import 'package:example_app/features/documents/domain/entities/document_info.dart';
import 'package:example_app/features/documents/domain/entities/document_sort.dart';
import 'package:example_app/features/documents/domain/entities/sort_option.dart';

DocumentInfo _doc(String title, int day, int pages, {bool fav = false}) {
  return DocumentInfo(
    id: title,
    title: title,
    templateId: 'blank',
    createdAt: DateTime(2026, 1, day),
    updatedAt: DateTime(2026, 1, day),
    pageCount: pages,
    isFavorite: fav,
  );
}

final _alfa = _doc('Alfa', 1, 3);
final _beta = _doc('Beta', 3, 1, fav: true);
final _gama = _doc('Gama', 2, 2);
final _delta = _doc('Delta', 4, 1, fav: true);

List<String> _sorted(
  List<DocumentInfo> docs,
  SortOption option,
  SortDirection direction, {
  bool pin = false,
}) {
  final result = sortDocuments(
    docs,
    option: option,
    direction: direction,
    pinFavorites: pin,
  );
  return [for (final d in result) d.title];
}

void main() {
  const asc = SortDirection.ascending;
  const desc = SortDirection.descending;
  final docs = [_alfa, _beta, _gama];

  group('sortDocuments', () {
    test('sorts by date, name and size in both directions', () {
      expect(_sorted(docs, SortOption.date, desc), ['Beta', 'Gama', 'Alfa']);
      expect(_sorted(docs, SortOption.date, asc), ['Alfa', 'Gama', 'Beta']);
      expect(_sorted(docs, SortOption.name, asc), ['Alfa', 'Beta', 'Gama']);
      expect(_sorted(docs, SortOption.name, desc), ['Gama', 'Beta', 'Alfa']);
      expect(_sorted(docs, SortOption.size, asc), ['Beta', 'Gama', 'Alfa']);
    });

    test('without pinning, favourites keep their sorted position', () {
      expect(_sorted(docs, SortOption.name, asc), ['Alfa', 'Beta', 'Gama']);
    });

    test('pinFavorites puts favourites first, each group still sorted', () {
      final more = [...docs, _delta];
      expect(
        _sorted(more, SortOption.name, asc, pin: true),
        ['Beta', 'Delta', 'Alfa', 'Gama'],
      );
      expect(
        _sorted(more, SortOption.date, desc, pin: true),
        ['Delta', 'Beta', 'Gama', 'Alfa'],
      );
    });

    test('does not modify the input list', () {
      final input = [_gama, _alfa, _beta];
      _sorted(input, SortOption.name, asc, pin: true);
      expect([for (final d in input) d.title], ['Gama', 'Alfa', 'Beta']);
    });
  });
}
