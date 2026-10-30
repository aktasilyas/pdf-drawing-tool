import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_ui/src/providers/pdf_provider.dart';
import 'package:drawing_ui/src/services/pdf_import_service.dart';

void main() {
  group('PDFProvider', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    group('Import Service Integration', () {
      test('should provide import service instance', () {
        final service = container.read(pdfImportServiceProvider);

        expect(service, isNotNull);
        expect(service.state, PDFImportState.idle);
      });

      test('should dispose import service', () {
        final service = container.read(pdfImportServiceProvider);

        container.dispose();

        expect(service.isDisposed, true);
      });
    });
  });
}
