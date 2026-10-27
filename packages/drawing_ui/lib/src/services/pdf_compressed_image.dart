import 'dart:io';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
// PdfNum/PdfIndirect are not part of the public barrel; needed to write the
// image dictionary entries by hand.
// ignore: implementation_imports
import 'package:pdf/src/pdf/format/indirect.dart';
// ignore: implementation_imports
import 'package:pdf/src/pdf/format/num.dart';

import 'pdf_raster_layer_renderer.dart';

/// Adds [raw] to [doc] as an image XObject whose stream is already
/// Flate-compressed, with a separate compressed soft mask for alpha.
///
/// `PdfImage(...)` keeps the full uncompressed RGB + alpha planes in memory
/// until `doc.save()` (about 8.7 MB per A4 layer at 150 dpi). Compressing here
/// keeps only the small deflated streams alive for the rest of the export.
///
/// The `pdf` package skips its own compression when `/Filter` is set, so the
/// bytes are written as given.
PdfImage addCompressedRgbaImage(PdfDocument doc, PdfRawImage raw) {
  final pixels = raw.width * raw.height;
  final rgba = raw.bytes;
  final rgb = Uint8List(pixels * 3);
  final alpha = Uint8List(pixels);
  for (var i = 0, p = 0, a = 0; i < pixels; i++, p += 3, a++) {
    final s = i * 4;
    rgb[p] = rgba[s];
    rgb[p + 1] = rgba[s + 1];
    rgb[p + 2] = rgba[s + 2];
    alpha[a] = rgba[s + 3];
  }

  final mask = _emptyImage(doc, raw, '/DeviceGray')
    ..buf.putBytes(zlib.encode(alpha));
  final img = _emptyImage(doc, raw, '/DeviceRGB')
    ..params['/SMask'] = PdfIndirect(mask.objser, 0)
    ..buf.putBytes(zlib.encode(rgb));
  return img;
}

/// Adds [raw] to [doc] as an opaque, Flate-compressed RGB image XObject
/// (alpha is dropped, no soft mask). For fully opaque rasters such as page
/// backgrounds: one image object instead of two, and a smaller file.
PdfImage addCompressedRgbImage(PdfDocument doc, PdfRawImage raw) {
  final pixels = raw.width * raw.height;
  final rgba = raw.bytes;
  final rgb = Uint8List(pixels * 3);
  for (var i = 0, p = 0; i < pixels; i++, p += 3) {
    final s = i * 4;
    rgb[p] = rgba[s];
    rgb[p + 1] = rgba[s + 1];
    rgb[p + 2] = rgba[s + 2];
  }
  return _emptyImage(doc, raw, '/DeviceRGB')..buf.putBytes(zlib.encode(rgb));
}

/// A data-less image object. A 0×0 raw image writes no stream bytes, so the
/// caller can supply a pre-compressed stream instead.
PdfImage _emptyImage(PdfDocument doc, PdfRawImage raw, String colorSpace) {
  final im =
      PdfImage(doc, image: Uint8List(0), width: 0, height: 0, alpha: false);
  im.params['/Width'] = PdfNum(raw.width);
  im.params['/Height'] = PdfNum(raw.height);
  im.params['/ColorSpace'] = PdfName(colorSpace);
  im.params['/Filter'] = const PdfName('/FlateDecode');
  return im;
}
