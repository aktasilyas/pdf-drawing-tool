import 'dart:io';

import 'package:drawing_core/drawing_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Resolves stored (container-relative or legacy absolute) PDF and
/// inserted-image paths to the
/// file to open. The host app overrides this with the app documents root;
/// the default leaves paths unchanged.
final pdfPathResolverProvider =
    Provider<PdfPathResolver>((ref) => PdfPathResolver.passthrough);

/// Whether the source PDF for the stored path no longer exists on disk.
///
/// Only read after a render returned nothing, so it costs no I/O for pages
/// that display normally.
final pdfSourceMissingProvider =
    FutureProvider.autoDispose.family<bool, String>((ref, stored) async {
  final resolver = ref.watch(pdfPathResolverProvider);
  return !await File(resolver.resolve(stored)).exists();
});
