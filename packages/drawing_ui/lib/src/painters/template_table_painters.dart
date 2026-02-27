import 'package:flutter/material.dart';

/// Mixin providing table-based structural template painters.
///
/// Contains: readingLog, vocabularyList.
/// All measurements proportional. All colors derive from lineColor.
mixin TemplateTablePainters {
  Color get lineColor;
  double get lineWidth;
  Map<String, dynamic>? get extraData;
  double get spacingPx;
  Paint get linePaint;

  void _drawTableDivider(
    Canvas canvas, double y, double startX, double endX, Paint paint,
  ) {
    canvas.drawLine(
      Offset(startX, y),
      Offset(endX, y),
      paint..strokeWidth = lineWidth * 2,
    );
  }

  void drawReadingLog(Canvas canvas, Size size) {
    final paint = linePaint;
    final margin = size.width * 0.03;
    final headerH = size.height * 0.07;
    final colHeaderH = size.height * 0.05;
    const colRatios = [0.25, 0.25, 0.15, 0.15, 0.20];

    _drawTableDivider(canvas, headerH, margin, size.width - margin, paint);
    _drawTableDivider(
        canvas, headerH + colHeaderH, margin, size.width - margin, paint);

    // Sütun ayırıcıları
    final usableW = size.width - margin * 2;
    var x = margin;
    for (var i = 0; i < colRatios.length - 1; i++) {
      x += usableW * colRatios[i];
      canvas.drawLine(
        Offset(x, headerH),
        Offset(x, size.height - margin),
        paint..strokeWidth = lineWidth,
      );
    }

    // Satır çizgileri
    paint
      ..color = lineColor.withValues(alpha: 0.3)
      ..strokeWidth = lineWidth * 0.5;
    final rowH = spacingPx * 1.5;
    for (var y = headerH + colHeaderH + rowH;
        y < size.height - margin;
        y += rowH) {
      canvas.drawLine(
          Offset(margin, y), Offset(size.width - margin, y), paint);
    }
  }

  void drawVocabularyList(Canvas canvas, Size size) {
    final paint = linePaint;
    final margin = size.width * 0.03;
    final headerH = size.height * 0.07;
    final colHeaderH = size.height * 0.05;
    const defaultRatios = [0.25, 0.35, 0.40];
    final colRatios = (extraData?['columnRatios'] as List?)
            ?.map((e) => (e as num).toDouble())
            .toList() ??
        defaultRatios;

    _drawTableDivider(canvas, headerH, margin, size.width - margin, paint);
    _drawTableDivider(
        canvas, headerH + colHeaderH, margin, size.width - margin, paint);

    // Sütun ayırıcıları
    final usableW = size.width - margin * 2;
    var x = margin;
    for (var i = 0; i < colRatios.length - 1; i++) {
      x += usableW * colRatios[i];
      canvas.drawLine(
        Offset(x, headerH),
        Offset(x, size.height - margin),
        paint..strokeWidth = lineWidth,
      );
    }

    // Satır çizgileri
    paint
      ..color = lineColor.withValues(alpha: 0.3)
      ..strokeWidth = lineWidth * 0.5;
    for (var y = headerH + colHeaderH + spacingPx;
        y < size.height - margin;
        y += spacingPx) {
      canvas.drawLine(
          Offset(margin, y), Offset(size.width - margin, y), paint);
    }
  }
}
