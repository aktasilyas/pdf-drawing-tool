import 'package:flutter_test/flutter_test.dart';

import 'package:example_app/features/documents/domain/entities/library_text.dart';

void main() {
  group('foldForSearch', () {
    test('lower-cases I and İ the Turkish way and trims', () {
      expect(foldForSearch('  IŞIK '), 'ışık');
      expect(foldForSearch('İş Notları'), 'iş notları');
      expect(foldForSearch('NOT'), 'not');
    });

    test('keeps diacritics', () {
      expect(foldForSearch('Çay'), 'çay');
      expect(foldForSearch('Ünite'), 'ünite');
    });
  });

  group('matchesSearch', () {
    test('Turkish-aware case-insensitive matches (#406)', () {
      expect(matchesSearch('İş Notları', 'iş'), isTrue);
      expect(matchesSearch('IŞIK', 'ışık'), isTrue);
      expect(matchesSearch('notlar', 'NOT'), isTrue);
      expect(matchesSearch('İstanbul', 'İST'), isTrue);
    });

    test('does not match across i/ı or missing diacritics', () {
      expect(matchesSearch('Işık', 'is'), isFalse);
      expect(matchesSearch('Kitap', 'KİTAP'), isTrue);
      expect(matchesSearch('Kitap', 'KITAP'), isFalse);
    });

    test('blank query matches everything', () {
      expect(matchesSearch('anything', ''), isTrue);
      expect(matchesSearch('anything', '  '), isTrue);
    });
  });

  group('compareNames', () {
    List<String> sorted(List<String> names) =>
        List.of(names)..sort(compareNames);

    test('case-insensitive with Turkish letter order (#406)', () {
      expect(
        sorted(['beta', 'Alfa', 'Çay', 'Zeytin', 'Şehir']),
        ['Alfa', 'beta', 'Çay', 'Şehir', 'Zeytin'],
      );
    });

    test('orders ı before i, ö after o, ğ after g, ü after u', () {
      expect(sorted(['iz', 'ız']), ['ız', 'iz']);
      expect(sorted(['Öykü', 'Pera', 'Oda']), ['Oda', 'Öykü', 'Pera']);
      expect(sorted(['Ha', 'Ğa', 'Ga']), ['Ga', 'Ğa', 'Ha']);
      expect(sorted(['Va', 'Üç', 'Uç']), ['Uç', 'Üç', 'Va']);
    });

    test('digits sort before letters and prefixes first', () {
      expect(sorted(['Not', '2026 Plan', 'Notlar']),
          ['2026 Plan', 'Not', 'Notlar']);
    });

    test('names differing only in case get a stable raw-text tie-break', () {
      expect(compareNames('alfa', 'Alfa'), isNot(0));
      expect(sorted(['alfa', 'Alfa']), ['Alfa', 'alfa']);
      expect(sorted(['Alfa', 'alfa']), ['Alfa', 'alfa']);
      expect(compareNames('Same', 'Same'), 0);
    });
  });
}
