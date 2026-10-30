import 'dart:async';

import 'package:example_app/features/documents/documents.dart';

/// Test double for [IncomingPdfSource]. Events emitted before the first
/// listener are buffered, like PDFs that arrive before Dart is ready.
class FakeIncomingPdfSource implements IncomingPdfSource {
  final _controller = StreamController<IncomingPdfEvent>();

  bool get hasListener => _controller.hasListener;

  void emit(IncomingPdfEvent event) => _controller.add(event);

  @override
  Stream<IncomingPdfEvent> watch() => _controller.stream;
}
