import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawing_ui/src/canvas/eraser_cursor_painter.dart';

void main() {
  group('EraserCursorPainter', () {
    test('shouldRepaint returns true when position changes', () {
      final painter1 = EraserCursorPainter(
        position: const Offset(0, 0),
        size: 20,
        mode: EraserCursorMode.pixel,
      );
      
      final painter2 = EraserCursorPainter(
        position: const Offset(10, 10),
        size: 20,
        mode: EraserCursorMode.pixel,
      );
      
      expect(painter1.shouldRepaint(painter2), isTrue);
    });
    
    test('shouldRepaint returns false when same', () {
      final painter1 = EraserCursorPainter(
        position: const Offset(0, 0),
        size: 20,
        mode: EraserCursorMode.pixel,
      );
      
      final painter2 = EraserCursorPainter(
        position: const Offset(0, 0),
        size: 20,
        mode: EraserCursorMode.pixel,
      );
      
      expect(painter1.shouldRepaint(painter2), isFalse);
    });
    
    test('shouldRepaint returns true when mode changes', () {
      final painter1 = EraserCursorPainter(
        position: const Offset(0, 0),
        size: 20,
        mode: EraserCursorMode.pixel,
      );
      
      final painter2 = EraserCursorPainter(
        position: const Offset(0, 0),
        size: 20,
        mode: EraserCursorMode.lasso,
      );
      
      expect(painter1.shouldRepaint(painter2), isTrue);
    });
    
    test('shouldRepaint returns true when size changes', () {
      final painter1 = EraserCursorPainter(
        position: const Offset(0, 0),
        size: 20,
        mode: EraserCursorMode.pixel,
      );
      
      final painter2 = EraserCursorPainter(
        position: const Offset(0, 0),
        size: 30,
        mode: EraserCursorMode.pixel,
      );
      
      expect(painter1.shouldRepaint(painter2), isTrue);
    });
    
    test('shouldRepaint returns true when isActive changes', () {
      final painter1 = EraserCursorPainter(
        position: const Offset(0, 0),
        size: 20,
        mode: EraserCursorMode.lasso,
        isActive: false,
      );
      
      final painter2 = EraserCursorPainter(
        position: const Offset(0, 0),
        size: 20,
        mode: EraserCursorMode.lasso,
        isActive: true,
      );
      
      expect(painter1.shouldRepaint(painter2), isTrue);
    });
    
    test('shouldRepaint returns true when lassoPoints length changes', () {
      final painter1 = EraserCursorPainter(
        position: const Offset(0, 0),
        size: 20,
        mode: EraserCursorMode.lasso,
        lassoPoints: const [Offset(0, 0), Offset(10, 10)],
      );
      
      final painter2 = EraserCursorPainter(
        position: const Offset(0, 0),
        size: 20,
        mode: EraserCursorMode.lasso,
        lassoPoints: const [Offset(0, 0), Offset(10, 10), Offset(20, 20)],
      );
      
      expect(painter1.shouldRepaint(painter2), isTrue);
    });
  });
}
