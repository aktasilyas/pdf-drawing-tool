import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_ui/src/providers/pdf_provider.dart';
import 'package:drawing_ui/src/services/pdf_import_service.dart';
import 'package:drawing_ui/src/services/pdf_export_service.dart';

void main() {
  group('PDFProvider', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    group('Import State', () {
      test('should initialize with idle import state', () {
        final state = container.read(pdfImportStateProvider);

        expect(state.state, PDFImportState.idle);
        expect(state.isLoading, false);
        expect(state.hasError, false);
      });

      test('should track import progress', () {
        final state = container.read(pdfImportStateProvider);

        expect(state.progress, 0.0);
        expect(state.progressPercentage, 0);
      });

      test('should update import state', () {
        final notifier = container.read(pdfImportStateProvider.notifier);

        notifier.updateState(PDFImportState.loadingPDF);

        final state = container.read(pdfImportStateProvider);
        expect(state.state, PDFImportState.loadingPDF);
        expect(state.isLoading, true);
      });

      test('should update import progress', () {
        final notifier = container.read(pdfImportStateProvider.notifier);

        notifier.updateProgress(0.5);

        final state = container.read(pdfImportStateProvider);
        expect(state.progress, 0.5);
        expect(state.progressPercentage, 50);
      });

      test('should set import error', () {
        final notifier = container.read(pdfImportStateProvider.notifier);

        notifier.setError('Import failed');

        final state = container.read(pdfImportStateProvider);
        expect(state.hasError, true);
        expect(state.errorMessage, 'Import failed');
      });

      test('should reset import state', () {
        final notifier = container.read(pdfImportStateProvider.notifier);

        notifier.updateState(PDFImportState.loadingPDF);
        notifier.updateProgress(0.5);
        notifier.reset();

        final state = container.read(pdfImportStateProvider);
        expect(state.state, PDFImportState.idle);
        expect(state.progress, 0.0);
      });
    });

    group('Export State', () {
      test('should initialize with idle export state', () {
        final state = container.read(pdfExportStateProvider);

        expect(state.state, PDFExportState.idle);
        expect(state.isExporting, false);
        expect(state.hasError, false);
      });

      test('should track export progress', () {
        final state = container.read(pdfExportStateProvider);

        expect(state.progress, 0.0);
        expect(state.progressPercentage, 0);
      });

      test('should update export state', () {
        final notifier = container.read(pdfExportStateProvider.notifier);

        notifier.updateState(PDFExportState.preparing);

        final state = container.read(pdfExportStateProvider);
        expect(state.state, PDFExportState.preparing);
        expect(state.isExporting, true);
      });

      test('should update export progress', () {
        final notifier = container.read(pdfExportStateProvider.notifier);

        notifier.updateProgress(0.75);

        final state = container.read(pdfExportStateProvider);
        expect(state.progress, 0.75);
        expect(state.progressPercentage, 75);
      });

      test('should set export error', () {
        final notifier = container.read(pdfExportStateProvider.notifier);

        notifier.setError('Export failed');

        final state = container.read(pdfExportStateProvider);
        expect(state.hasError, true);
        expect(state.errorMessage, 'Export failed');
      });

      test('should reset export state', () {
        final notifier = container.read(pdfExportStateProvider.notifier);

        notifier.updateState(PDFExportState.exporting);
        notifier.updateProgress(0.8);
        notifier.reset();

        final state = container.read(pdfExportStateProvider);
        expect(state.state, PDFExportState.idle);
        expect(state.progress, 0.0);
      });
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

    group('Export Service Integration', () {
      test('should provide export service instance', () {
        final service = container.read(pdfExportServiceProvider);

        expect(service, isNotNull);
        expect(service.state, PDFExportState.idle);
      });

      test('should dispose export service', () {
        final service = container.read(pdfExportServiceProvider);

        container.dispose();

        expect(service.isDisposed, true);
      });
    });

    group('Helper Providers', () {
      test('should check if import is loading', () {
        final isLoading = container.read(isImportingProvider);

        expect(isLoading, false);
      });

      test('should check if export is loading', () {
        final isExporting = container.read(isExportingProvider);

        expect(isExporting, false);
      });

      test('should get import progress message', () {
        final notifier = container.read(pdfImportStateProvider.notifier);

        notifier.updateState(PDFImportState.loadingPDF);

        final message = container.read(importProgressMessageProvider);

        expect(message, contains('Loading'));
      });

      test('should get export progress message', () {
        final notifier = container.read(pdfExportStateProvider.notifier);

        notifier.updateState(PDFExportState.exporting);

        final message = container.read(exportProgressMessageProvider);

        expect(message, contains('Exporting'));
      });
    });

    group('State Notifications', () {
      test('should notify on import state change', () {
        var notificationCount = 0;

        container.listen(
          pdfImportStateProvider,
          (previous, next) {
            notificationCount++;
          },
        );

        final notifier = container.read(pdfImportStateProvider.notifier);
        notifier.updateState(PDFImportState.loadingPDF);

        expect(notificationCount, 1);
      });

      test('should notify on export state change', () {
        var notificationCount = 0;

        container.listen(
          pdfExportStateProvider,
          (previous, next) {
            notificationCount++;
          },
        );

        final notifier = container.read(pdfExportStateProvider.notifier);
        notifier.updateState(PDFExportState.preparing);

        expect(notificationCount, 1);
      });
    });
  });
}
