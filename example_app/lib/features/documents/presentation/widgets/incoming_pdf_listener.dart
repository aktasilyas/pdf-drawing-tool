import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:example_app/core/utils/logger.dart';
import 'package:example_app/features/documents/domain/entities/incoming_pdf.dart';
import 'package:example_app/features/documents/presentation/providers/incoming_pdf_provider.dart';
import 'package:example_app/features/documents/presentation/widgets/document_quota.dart';
import 'package:example_app/features/documents/presentation/widgets/pdf_file_importer.dart';

/// Imports one PDF file as a new document (see [importPdfFile]).
typedef IncomingPdfImporter = Future<void> Function(
  BuildContext context, {
  required String path,
  required String name,
  required int size,
});

/// Returns true when another document may be created.
typedef DocumentQuotaCheck = Future<bool> Function(BuildContext context);

/// Imports PDFs opened from other apps (Open with / Share), one at a time.
///
/// Mount it below the Navigator (inside a screen): dialogs and routing need a
/// context that has one.
class IncomingPdfListener extends ConsumerStatefulWidget {
  const IncomingPdfListener({
    super.key,
    required this.child,
    this.importFile = importPdfFile,
    this.ensureQuota = ensureDocumentQuota,
  });

  final Widget child;
  final IncomingPdfImporter importFile;
  final DocumentQuotaCheck ensureQuota;

  @override
  ConsumerState<IncomingPdfListener> createState() =>
      _IncomingPdfListenerState();
}

class _IncomingPdfListenerState extends ConsumerState<IncomingPdfListener> {
  bool _draining = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _drain());
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<List<IncomingPdf>>(
      incomingPdfQueueProvider,
      (_, __) => _drain(),
    );
    return widget.child;
  }

  Future<void> _drain() async {
    if (_draining) return;
    _draining = true;
    try {
      while (mounted) {
        final queue = ref.read(incomingPdfQueueProvider);
        if (queue.isEmpty) break;
        final pdf = queue.first;
        ref.read(incomingPdfQueueProvider.notifier).remove(pdf);
        await _process(pdf);
      }
    } finally {
      _draining = false;
    }
  }

  Future<void> _process(IncomingPdf pdf) async {
    try {
      _showLibrary();
      if (!await widget.ensureQuota(context)) return;
      if (!mounted) return;
      await widget.importFile(
        context,
        path: pdf.path,
        name: pdf.name,
        size: pdf.size,
      );
    } catch (e, st) {
      logger.e('Incoming PDF import failed', error: e, stackTrace: st);
    } finally {
      _deleteCopy(pdf.path);
    }
  }

  /// The library stays mounted below the editor. Close routes above it so the
  /// new document does not open on top of another editor (they share the
  /// global PDF state providers).
  void _showLibrary() {
    final route = ModalRoute.of(context);
    if (route == null || route.isCurrent) return;
    Navigator.of(context).popUntil((r) => r == route);
  }

  void _deleteCopy(String path) {
    try {
      final file = File(path);
      if (file.existsSync()) file.deleteSync();
    } on FileSystemException catch (e) {
      logger.w('Could not delete incoming PDF copy: $e');
    }
  }
}
