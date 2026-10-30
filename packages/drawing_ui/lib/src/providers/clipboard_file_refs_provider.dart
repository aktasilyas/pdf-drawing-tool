import 'dart:io';

import 'package:drawing_core/drawing_core.dart';
import 'package:flutter/material.dart'
    show BuildContext, ScaffoldMessenger, SnackBar, Text;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:drawing_ui/src/l10n/drawing_strings_scope.dart';
import 'package:drawing_ui/src/providers/copied_page_provider.dart';
import 'package:drawing_ui/src/providers/pdf_path_provider.dart';
import 'package:drawing_ui/src/providers/selection_clipboard_provider.dart';

/// Stored paths of the files (PDF or image background, image elements) that
/// [page] and [selection] point to.
Set<String> fileRefsOfClipboard(Page? page, SelectionClipboardData? selection) {
  final refs = <String>{};
  if (page != null) {
    final bg = page.background;
    final pdf = bg.pdfFilePath;
    final image = bg.imageFilePath;
    if (pdf != null && pdf.isNotEmpty) refs.add(pdf);
    if (image != null && image.isNotEmpty) refs.add(image);
    for (final layer in page.layers) {
      for (final element in layer.images) {
        if (element.filePath.isNotEmpty) refs.add(element.filePath);
      }
    }
  }
  if (selection != null) {
    for (final element in selection.images) {
      if (element.filePath.isNotEmpty) refs.add(element.filePath);
    }
  }
  return refs;
}

/// Stored file paths the page clipboard and the selection clipboard still
/// reference. The host app must not delete these files while they are here.
final clipboardFileRefsProvider = Provider<Set<String>>((ref) {
  return fileRefsOfClipboard(
    ref.watch(copiedPageProvider),
    ref.watch(selectionClipboardProvider),
  );
});

/// Whether every file in [refs] exists on disk (resolved through [resolver]).
bool allFilesExist(Iterable<String> refs, PdfPathResolver resolver) {
  for (final ref in refs) {
    if (!File(resolver.resolve(ref)).existsSync()) return false;
  }
  return true;
}

/// Whether every file of [refs] still exists. When one is gone, shows a
/// SnackBar through [context] (if given) and returns false so the caller
/// pastes nothing.
bool checkPasteFiles(
  WidgetRef ref,
  Iterable<String> refs,
  BuildContext? context,
) {
  if (allFilesExist(refs, ref.read(pdfPathResolverProvider))) return true;
  if (context != null && context.mounted) {
    final message = context.drawingStrings.pages.pasteFilesMissing;
    ScaffoldMessenger.maybeOf(context)
        ?.showSnackBar(SnackBar(content: Text(message)));
  }
  return false;
}
