import 'package:drawing_core/drawing_core.dart' as core;
import 'package:drawing_ui/drawing_ui.dart' show copiedPageProvider;
import 'package:example_app/core/bootstrap/clipboard_file_refs_binding.dart';
import 'package:example_app/core/core.dart' show ClipboardFileRefs;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('binds the editor clipboard refs while mounted', (tester) async {
    final refs = ClipboardFileRefs();
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: ClipboardFileRefsBinding(
          refs: refs,
          child: const SizedBox(),
        ),
      ),
    );
    expect(refs.contains('pdfs/a.pdf'), isFalse);

    container.read(copiedPageProvider.notifier).state = core.Page(
      id: 'p',
      index: 0,
      size: core.PageSize.a4Portrait,
      background: const core.PageBackground(
        type: core.BackgroundType.pdf,
        pdfFilePath: 'pdfs/a.pdf',
      ),
      layers: [core.Layer.empty('L')],
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
    expect(refs.contains('pdfs/a.pdf'), isTrue);

    await tester.pumpWidget(const SizedBox());
    expect(refs.contains('pdfs/a.pdf'), isFalse);
  });
}
