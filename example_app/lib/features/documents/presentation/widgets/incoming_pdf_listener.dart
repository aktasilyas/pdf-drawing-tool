import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:example_app/core/utils/logger.dart';
import 'package:example_app/features/documents/domain/entities/incoming_pdf.dart';
import 'package:example_app/core/session/active_editor_leave_provider.dart';
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
/// Mount it above the routes (`MaterialApp.router` builder) so it is alive on
/// every screen. Dialogs and routing use the context of [navigatorKey]. When an
/// editor is open it is left first through [activeEditorLeaveProvider], so its
/// save-and-reset path runs before the new document opens.
class IncomingPdfListener extends ConsumerStatefulWidget {
  const IncomingPdfListener({
    super.key,
    required this.child,
    required this.navigatorKey,
    this.importFile = importPdfFile,
    this.ensureQuota = ensureDocumentQuota,
  });

  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;
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
        if (!await _leaveEditor()) {
          // Save failed: the editor stays open and the PDF stays queued
          // (its copy is kept) until the next incoming PDF or app start.
          break;
        }
        // Another drain may have taken it while the editor was closing.
        if (!ref.read(incomingPdfQueueProvider).contains(pdf)) continue;
        ref.read(incomingPdfQueueProvider.notifier).remove(pdf);
        await _process(pdf);
      }
    } finally {
      _draining = false;
    }
  }

  Future<void> _process(IncomingPdf pdf) async {
    try {
      final context = widget.navigatorKey.currentContext;
      if (context == null || !context.mounted) return;
      if (!await widget.ensureQuota(context)) return;
      if (!mounted || !context.mounted) return;
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

  /// Closes the open editor, if any. False when it could not be left.
  Future<bool> _leaveEditor() async {
    final leave = ref.read(activeEditorLeaveProvider);
    if (leave == null) return true;
    return leave();
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
