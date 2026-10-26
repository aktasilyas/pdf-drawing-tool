import 'dart:async';

import 'package:flutter/services.dart';

import 'package:example_app/core/utils/logger.dart';
import 'package:example_app/features/documents/domain/entities/incoming_pdf.dart';
import 'package:example_app/features/documents/domain/repositories/incoming_pdf_source.dart';

/// Receives PDFs from the Android side over the `elyanotes/incoming_pdf`
/// channel.
///
/// Dart calls `ready` once it listens; native answers with the PDFs queued so
/// far and afterwards pushes each new one with `onPdf`.
class MethodChannelIncomingPdfSource implements IncomingPdfSource {
  MethodChannelIncomingPdfSource({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel(channelName);

  static const channelName = 'elyanotes/incoming_pdf';

  final MethodChannel _channel;

  @override
  Stream<IncomingPdf> watch() {
    final controller = StreamController<IncomingPdf>();

    Future<void> start() async {
      _channel.setMethodCallHandler((call) async {
        if (call.method != 'onPdf') return null;
        final pdf = _parse(call.arguments);
        if (pdf != null && !controller.isClosed) controller.add(pdf);
        return null;
      });
      try {
        final pending = await _channel.invokeMethod<List<Object?>>('ready');
        for (final item in pending ?? const <Object?>[]) {
          final pdf = _parse(item);
          if (pdf != null && !controller.isClosed) controller.add(pdf);
        }
      } on MissingPluginException {
        // No native side (tests, other platforms): nothing will ever arrive.
        _channel.setMethodCallHandler(null);
        await controller.close();
      } catch (e, st) {
        // Native failed to answer; PDFs pushed later are still delivered.
        logger.w('Incoming PDF channel not ready', error: e, stackTrace: st);
      }
    }

    controller.onListen = start;
    controller.onCancel = () => _channel.setMethodCallHandler(null);
    return controller.stream;
  }

  static IncomingPdf? _parse(Object? raw) {
    if (raw is! Map) return null;
    final path = raw['path'];
    final name = raw['name'];
    final size = raw['size'];
    if (path is! String || path.isEmpty) return null;
    if (name is! String || size is! int) return null;
    return IncomingPdf(path: path, name: name, size: size);
  }
}
