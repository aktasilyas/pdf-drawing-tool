/// PDF text helpers for exporter tests: decoded streams, media boxes and
/// path points after `cm` transforms.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The raw PDF text plus every stream that inflates to plain ASCII text
/// (content streams, object streams), so dictionaries and drawing operators
/// can be searched whether or not they are compressed.
List<String> pdfTexts(List<int> pdf) {
  bool isText(List<int> data) =>
      data.every((b) => b == 9 || b == 10 || b == 13 || (b >= 32 && b < 127));
  final raw = latin1.decode(pdf);
  final texts = [raw];
  for (final m in RegExp(r'stream\r?\n').allMatches(raw)) {
    final end = raw.indexOf('endstream', m.end);
    if (end < 0) continue;
    final slice = pdf.sublist(m.end, end);
    List<int> data;
    try {
      data = zlib.decode(slice);
    } catch (_) {
      // Not a flate stream: keep it if it is an uncompressed text stream.
      data = slice;
    }
    if (isText(data)) texts.add(latin1.decode(data));
  }
  return texts;
}

({double width, double height}) pdfMediaBox(List<String> texts) {
  final re =
      RegExp(r'/MediaBox\s*\[\s*(\S+)\s+(\S+)\s+(\S+)\s+([^\s\]]+)\s*\]');
  for (final t in texts) {
    final m = re.firstMatch(t);
    if (m == null) continue;
    final v = [for (var i = 1; i <= 4; i++) double.parse(m.group(i)!)];
    return (width: v[2] - v[0], height: v[3] - v[1]);
  }
  fail('no /MediaBox in the PDF');
}

/// A point in PDF user space.
typedef PdfPt = ({double x, double y});

/// Path points of all drawing operators in [content], in page space after
/// the `cm` transforms in effect, paired with their untransformed points.
List<({PdfPt user, PdfPt page})> pdfPathPoints(String content) {
  // Affine [a b c d e f]: x' = a x + c y + e, y' = b x + d y + f.
  var ctm = <double>[1, 0, 0, 1, 0, 0];
  final saved = <List<double>>[];
  final nums = <double>[];
  final out = <({PdfPt user, PdfPt page})>[];

  PdfPt apply(List<double> m, double x, double y) =>
      (x: m[0] * x + m[2] * y + m[4], y: m[1] * x + m[3] * y + m[5]);
  void add(double x, double y) =>
      out.add((user: (x: x, y: y), page: apply(ctm, x, y)));
  List<double> last(int n) => nums.sublist(nums.length - n);

  for (final tok in content.split(RegExp(r'\s+'))) {
    if (tok.isEmpty) continue;
    final n = double.tryParse(tok);
    if (n != null) {
      nums.add(n);
      continue;
    }
    switch (tok) {
      case 'q':
        saved.add(List.of(ctm));
      case 'Q' when saved.isNotEmpty:
        ctm = saved.removeLast();
      case 'cm' when nums.length >= 6:
        final m = last(6);
        final o = ctm;
        // New CTM = M x CTM.
        ctm = [
          m[0] * o[0] + m[1] * o[2],
          m[0] * o[1] + m[1] * o[3],
          m[2] * o[0] + m[3] * o[2],
          m[2] * o[1] + m[3] * o[3],
          m[4] * o[0] + m[5] * o[2] + o[4],
          m[4] * o[1] + m[5] * o[3] + o[5],
        ];
      case 'm' || 'l' when nums.length >= 2:
        final p = last(2);
        add(p[0], p[1]);
      case 'c' when nums.length >= 6:
        final p = last(6);
        for (var i = 0; i < 6; i += 2) {
          add(p[i], p[i + 1]);
        }
      case 'v' || 'y' when nums.length >= 4:
        final p = last(4);
        add(p[0], p[1]);
        add(p[2], p[3]);
      case 're' when nums.length >= 4:
        final p = last(4);
        add(p[0], p[1]);
        add(p[0] + p[2], p[1] + p[3]);
    }
    nums.clear();
  }
  return out;
}

/// Every `/MediaBox` size in [texts], in page order (taken from the first
/// text that holds any, so a stream is never counted twice).
List<({double width, double height})> pdfMediaBoxes(List<String> texts) {
  final re =
      RegExp(r'/MediaBox\s*\[\s*(\S+)\s+(\S+)\s+(\S+)\s+([^\s\]]+)\s*\]');
  for (final t in texts) {
    final boxes = [
      for (final m in re.allMatches(t))
        [for (var i = 1; i <= 4; i++) double.parse(m.group(i)!)],
    ];
    if (boxes.isEmpty) continue;
    return [for (final v in boxes) (width: v[2] - v[0], height: v[3] - v[1])];
  }
  fail('no /MediaBox in the PDF');
}
