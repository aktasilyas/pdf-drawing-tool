import 'dart:async';

import 'package:flutter/services.dart';

import 'package:example_app/core/utils/logger.dart';
import 'package:example_app/features/documents/domain/entities/incoming_pdf.dart';
import 'package:example_app/features/documents/domain/repositories/incoming_pdf_source.dart';

/// Receives PDFs from the Android side over the `elyanotes/incoming_pdf`
/// channel.
///
/// Dart calls `ready` once it listens; native answers with the events queued
/// so far and afterwards pushes each new PDF with `onPdf` ({path, name, size})
/// and each PDF it could not copy with `onPdfError` ({name, reason}). In the
/// `ready` list a failure is told apart by its `reason` key.
class MethodChannelIncomingPdfSource implements IncomingPdfSource {
  MethodChannelIncomingPdfSource({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel(channelName);

  static const channelName = 'elyanotes/incoming_pdf';

  final MethodChannel _channel;

  @override
  Stream<IncomingPdfEvent> watch() {
    final controller = StreamController<IncomingPdfEvent>();

    void add(IncomingPdfEvent? event) {
      if (event != null && !controller.isClosed) controller.add(event);
    }

    Future<void> start() async {
      _channel.setMethodCallHandler((call) async {
        switch (call.method) {
          case 'onPdf':
            add(_parsePdf(call.arguments));
          case 'onPdfError':
            add(_parseFailure(call.arguments));
        }
        return null;
      });
      try {
        final pending = await _channel.invokeMethod<List<Object?>>('ready');
        for (final item in pending ?? const <Object?>[]) {
          add(_parsePending(item));
        }
      } on MissingPluginException {
        // No native side (tests, other platforms): nothing will ever arrive.
        _channel.setMethodCallHandler(null);
        await controller.close();
      } catch (e, st) {
        // Native failed to answer; events pushed later are still delivered.
        logger.w('Incoming PDF channel not ready', error: e, stackTrace: st);
      }
    }

    controller.onListen = start;
    controller.onCancel = () => _channel.setMethodCallHandler(null);
    return controller.stream;
  }

  static IncomingPdfEvent? _parsePending(Object? raw) {
    if (raw is Map && raw.containsKey('reason')) return _parseFailure(raw);
    return _parsePdf(raw);
  }

  static IncomingPdf? _parsePdf(Object? raw) {
    if (raw is! Map) return null;
    final path = raw['path'];
    final name = raw['name'];
    final size = raw['size'];
    if (path is! String || path.isEmpty) return null;
    if (name is! String || size is! int) return null;
    return IncomingPdf(path: path, name: name, size: size);
  }

  static IncomingPdfFailure? _parseFailure(Object? raw) {
    if (raw is! Map) return null;
    final name = raw['name'];
    final reason = raw['reason'];
    if (name is! String || reason is! String) return null;
    return IncomingPdfFailure(
      name: name,
      // An unknown reason still tells the user the file was not imported.
      reason: reason == 'storageFull'
          ? IncomingPdfFailureReason.storageFull
          : IncomingPdfFailureReason.unreadable,
    );
  }
}
