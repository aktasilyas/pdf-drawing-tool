import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:example_app/features/documents/data/datasources/method_channel_incoming_pdf_source.dart';
import 'package:example_app/features/documents/domain/entities/incoming_pdf.dart';
import 'package:example_app/features/documents/domain/repositories/incoming_pdf_source.dart';

/// Where incoming PDFs come from. Override in tests.
final incomingPdfSourceProvider = Provider<IncomingPdfSource>(
  (ref) => MethodChannelIncomingPdfSource(),
);

/// FIFO queue of incoming PDFs (and copy failures) waiting to be handled.
final incomingPdfQueueProvider =
    NotifierProvider<IncomingPdfQueue, List<IncomingPdfEvent>>(
  IncomingPdfQueue.new,
);

class IncomingPdfQueue extends Notifier<List<IncomingPdfEvent>> {
  @override
  List<IncomingPdfEvent> build() {
    final subscription =
        ref.watch(incomingPdfSourceProvider).watch().listen(_enqueue);
    ref.onDispose(subscription.cancel);
    return const [];
  }

  void _enqueue(IncomingPdfEvent event) => state = [...state, event];

  /// Removes [event] (the first identical instance) from the queue.
  void remove(IncomingPdfEvent event) {
    final index = state.indexWhere((item) => identical(item, event));
    if (index < 0) return;
    state = [...state]..removeAt(index);
  }
}
