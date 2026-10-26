import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:example_app/features/documents/data/datasources/method_channel_incoming_pdf_source.dart';
import 'package:example_app/features/documents/domain/entities/incoming_pdf.dart';
import 'package:example_app/features/documents/domain/repositories/incoming_pdf_source.dart';

/// Where incoming PDFs come from. Override in tests.
final incomingPdfSourceProvider = Provider<IncomingPdfSource>(
  (ref) => MethodChannelIncomingPdfSource(),
);

/// FIFO queue of PDFs waiting to be imported.
final incomingPdfQueueProvider =
    NotifierProvider<IncomingPdfQueue, List<IncomingPdf>>(IncomingPdfQueue.new);

class IncomingPdfQueue extends Notifier<List<IncomingPdf>> {
  @override
  List<IncomingPdf> build() {
    final subscription =
        ref.watch(incomingPdfSourceProvider).watch().listen(_enqueue);
    ref.onDispose(subscription.cancel);
    return const [];
  }

  void _enqueue(IncomingPdf pdf) => state = [...state, pdf];

  /// Removes [pdf] (the first identical instance) from the queue.
  void remove(IncomingPdf pdf) {
    final index = state.indexWhere((item) => identical(item, pdf));
    if (index < 0) return;
    state = [...state]..removeAt(index);
  }
}
