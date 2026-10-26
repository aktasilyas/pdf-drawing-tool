/// Opens the OS share sheet for an exported PDF.
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Result of presenting the share sheet.
enum PdfShareOutcome { shared, dismissed }

/// Writes PDF bytes to a temp file and hands it to the system share sheet.
///
/// Replaced in tests so no platform channel is touched.
class PdfShareService {
  const PdfShareService();

  Future<PdfShareOutcome> sharePdf(
    Uint8List bytes, {
    required String fileName,
  }) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    final result = await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/pdf')],
        subject: fileName,
      ),
    );
    // Cancelling the sheet is a normal outcome, not an error.
    return result.status == ShareResultStatus.dismissed
        ? PdfShareOutcome.dismissed
        : PdfShareOutcome.shared;
  }
}

/// The [PdfShareService] used by the export panel.
final pdfShareServiceProvider =
    Provider<PdfShareService>((ref) => const PdfShareService());
