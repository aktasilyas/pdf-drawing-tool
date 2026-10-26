import 'package:example_app/features/documents/documents.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PaperColor', () {
    test('every colour round-trips through its storage key', () {
      for (final color in PaperColor.values) {
        expect(PaperColor.tryParse(color.storageKey), color);
      }
    });

    test('every colour round-trips through its ARGB value', () {
      for (final color in PaperColor.values) {
        expect(PaperColor.fromArgb(color.argb), color);
      }
    });

    test('legacy ASCII spellings resolve to the same colour', () {
      expect(PaperColor.tryParse('Beyaz kagit'), PaperColor.white);
      expect(PaperColor.tryParse('Siyah kagit'), PaperColor.black);
      expect(PaperColor.tryParse('Krem kagit'), PaperColor.cream);
      expect(PaperColor.tryParse('Gri kagit'), PaperColor.gray);
      expect(PaperColor.tryParse('Yesil kagit'), PaperColor.green);
      expect(PaperColor.tryParse('Mavi kagit'), PaperColor.blue);
      expect(PaperColor.tryParse('Sari kagit'), PaperColor.yellow);
    });

    test('Turkish spellings and the old light-grey label resolve', () {
      expect(PaperColor.tryParse('Yeşil kağıt'), PaperColor.green);
      expect(PaperColor.tryParse('Sarı kağıt'), PaperColor.yellow);
      expect(PaperColor.tryParse('Açık Gri'), PaperColor.gray);
      expect(PaperColor.tryParse('  KREM KAĞIT '), PaperColor.cream);
    });

    test('unknown or empty values give null', () {
      expect(PaperColor.tryParse(null), isNull);
      expect(PaperColor.tryParse(''), isNull);
      expect(PaperColor.tryParse('Mor kağıt'), isNull);
    });

    test('unknown ARGB falls back to white', () {
      expect(PaperColor.fromArgb(0xFF123456), PaperColor.white);
    });

    test('the creation palette offers every colour except legacy yellow', () {
      expect(PaperColor.palette, isNot(contains(PaperColor.yellow)));
      expect(PaperColor.palette.length, PaperColor.values.length - 1);
    });
  });
}
