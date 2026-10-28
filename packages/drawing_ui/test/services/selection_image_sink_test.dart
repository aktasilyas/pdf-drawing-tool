import 'dart:typed_data';

import 'package:drawing_ui/src/providers/selection_capture_actions.dart';
import 'package:drawing_ui/src/services/selection_image_sink.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSink extends Mock implements SelectionImageSink {}

void main() {
  final bytes = Uint8List.fromList([1, 2, 3]);
  late _MockSink sink;

  setUpAll(() => registerFallbackValue(Uint8List(0)));
  setUp(() => sink = _MockSink());

  void stub({required bool gallery, required bool clipboard}) {
    when(() => sink.saveToGallery(any())).thenAnswer((_) async => gallery);
    when(() => sink.copyToClipboard(any())).thenAnswer((_) async => clipboard);
  }

  test('saves to the gallery and copies to the clipboard', () async {
    stub(gallery: true, clipboard: true);
    expect(await saveSelectionImage(sink, bytes),
        SelectionImageSaveResult.savedAndCopied);
    verify(() => sink.saveToGallery(bytes)).called(1);
    verify(() => sink.copyToClipboard(bytes)).called(1);
  });

  test('a failed gallery save falls back to the clipboard', () async {
    stub(gallery: false, clipboard: true);
    final result = await saveSelectionImage(sink, bytes);
    expect(result, SelectionImageSaveResult.copied);
    verify(() => sink.copyToClipboard(bytes)).called(1);
    expect(screenshotOutcomeFor(result), SelectionScreenshotOutcome.copied);
  });

  test('gallery only', () async {
    stub(gallery: true, clipboard: false);
    expect(
        await saveSelectionImage(sink, bytes), SelectionImageSaveResult.saved);
  });

  test('both fail', () async {
    stub(gallery: false, clipboard: false);
    final result = await saveSelectionImage(sink, bytes);
    expect(result, SelectionImageSaveResult.failed);
    expect(screenshotOutcomeFor(result), SelectionScreenshotOutcome.saveFailed);
  });

  test('the default sink is the platform one', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(selectionImageSinkProvider),
        isA<PlatformSelectionImageSink>());
  });
}
