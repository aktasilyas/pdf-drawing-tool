import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:drawing_ui/src/services/pdf_export_models.dart';

/// Paper size of the open notebook, used by PDF export so notebook pages come
/// out at their real size (A4 → 210 x 297 mm) (#454).
///
/// The host app sets it when a notebook opens (clearing the previous
/// notebook's size first). When null, page units are exported as PDF points.
final exportPageFormatProvider = StateProvider<PDFPageFormat?>((_) => null);
