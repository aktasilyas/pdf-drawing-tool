import 'dart:ui' as ui;

import 'package:drawing_core/drawing_core.dart';
import 'package:flutter/painting.dart';

/// Builds and lays out the paragraph used to draw (and measure) [text].
///
/// Shared by the scene renderer and the bounds calculation so both agree on
/// the exact text extents.
ui.Paragraph layoutTextParagraph(TextElement text) {
  final textStyle = ui.TextStyle(
    color: Color(text.color),
    fontSize: text.fontSize,
    fontFamily: text.fontFamily,
    fontWeight: text.isBold ? FontWeight.bold : FontWeight.normal,
    fontStyle: text.isItalic ? FontStyle.italic : FontStyle.normal,
    decoration:
        text.isUnderline ? TextDecoration.underline : TextDecoration.none,
  );

  final paragraph = (ui.ParagraphBuilder(
    ui.ParagraphStyle(
      textAlign: _convertAlignment(text.alignment),
      maxLines: null,
    ),
  )
        ..pushStyle(textStyle)
        ..addText(text.text.isEmpty ? ' ' : text.text))
      .build();

  paragraph.layout(ui.ParagraphConstraints(width: text.width ?? 1000.0));
  return paragraph;
}

TextAlign _convertAlignment(TextAlignment alignment) {
  switch (alignment) {
    case TextAlignment.left:
      return TextAlign.left;
    case TextAlignment.center:
      return TextAlign.center;
    case TextAlignment.right:
      return TextAlign.right;
  }
}
