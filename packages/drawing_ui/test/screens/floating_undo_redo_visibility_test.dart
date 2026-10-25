import 'package:drawing_ui/drawing_ui.dart';
import 'package:drawing_ui/src/screens/drawing_screen_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  bool visible(double width, {bool readOnly = false, bool compact = false}) {
    return shouldShowFloatingUndoRedo(
      width: width,
      isReadOnly: readOnly,
      isCompactMode: compact,
    );
  }

  group('shouldShowFloatingUndoRedo', () {
    test('is hidden when the expanded toolbar is shown (1180)', () {
      expect(visible(1180), isFalse);
      expect(visible(ToolbarLayoutMode.expandedBreakpoint), isFalse);
    });

    test('is shown at medium widths', () {
      expect(visible(820), isTrue);
      expect(visible(ToolbarLayoutMode.compactBreakpoint), isTrue);
    });

    test('is hidden in compact mode and when read-only', () {
      expect(visible(390, compact: true), isFalse);
      expect(visible(820, readOnly: true), isFalse);
    });
  });
}
