import 'dart:typed_data';

import 'package:drawing_ui/drawing_ui.dart' show pdfLibraryPreviewCacheProvider;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:example_app/features/documents/presentation/widgets/library_memory_pressure_scope.dart';

void main() {
  testWidgets('memory pressure empties the library preview cache',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(pdfLibraryPreviewCacheProvider.notifier).state = {
      '480|a.pdf|1': Uint8List(4),
    };

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const LibraryMemoryPressureScope(child: SizedBox()),
      ),
    );
    tester.binding.handleMemoryPressure();

    expect(container.read(pdfLibraryPreviewCacheProvider), isEmpty);
  });

  testWidgets('no longer listens once the library is gone', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const LibraryMemoryPressureScope(child: SizedBox()),
      ),
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const SizedBox(),
      ),
    );
    container.read(pdfLibraryPreviewCacheProvider.notifier).state = {
      '480|a.pdf|1': Uint8List(4),
    };
    tester.binding.handleMemoryPressure();

    expect(container.read(pdfLibraryPreviewCacheProvider), hasLength(1));
  });
}
