import 'package:drawing_ui/src/widgets/sticky_note_context_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Phone canvas (logical px).
const _screen = Size(390, 844);
const _screenRect = Rect.fromLTWH(0, 0, 390, 844);

void main() {
  int? tappedColor;
  var deleted = 0;

  setUp(() {
    tappedColor = null;
    deleted = 0;
  });

  Future<void> pumpMenu(
    WidgetTester tester, {
    required Rect noteRect,
    int selectedColor = 0xFFFFF3CD,
  }) async {
    tester.view.physicalSize = _screen;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    // find.bySemanticsLabel needs the semantics tree.
    final handle = tester.ensureSemantics();
    addTearDown(handle.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              StickyNoteContextMenu(
                noteRect: noteRect,
                selectedColor: selectedColor,
                onColorChange: (c) => tappedColor = c,
                onDelete: () => deleted++,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Rect menuRect(WidgetTester tester) =>
      tester.getRect(find.byType(StickyNoteMenuCard));

  bool inside(Rect outer, Rect inner) =>
      inner.left >= outer.left &&
      inner.top >= outer.top &&
      inner.right <= outer.right &&
      inner.bottom <= outer.bottom;

  group('placement', () {
    testWidgets('note at the page top-left at zoom 0.5 stays on screen',
        (tester) async {
      // A 200x200 note at (0,0) at zoom 0.5 with no pan offset.
      const note = Rect.fromLTWH(0, 0, 100, 100);
      await pumpMenu(tester, noteRect: note);
      final menu = menuRect(tester);
      expect(inside(_screenRect, menu), isTrue, reason: '$menu');
      // No room above the note: the menu flips below it.
      expect(menu.top, greaterThanOrEqualTo(note.bottom));
    });

    testWidgets('note near the bottom-right edge stays on screen',
        (tester) async {
      const note = Rect.fromLTWH(340, 790, 100, 100);
      await pumpMenu(tester, noteRect: note);
      final menu = menuRect(tester);
      expect(inside(_screenRect, menu), isTrue, reason: '$menu');
    });

    testWidgets('note in the middle gets the menu centred above it',
        (tester) async {
      const note = Rect.fromLTWH(95, 400, 200, 120);
      await pumpMenu(tester, noteRect: note);
      final menu = menuRect(tester);
      expect(menu.bottom, lessThanOrEqualTo(note.top));
      expect(menu.center.dx, closeTo(note.center.dx, 0.5));
    });

    test('origin clamps both axes and flips below at the top edge', () {
      const menu = Size(296, 105);
      const bounds = Size(390, 844);
      final topLeft = stickyNoteMenuOrigin(
        noteRect: const Rect.fromLTWH(-40, -20, 100, 100),
        menuSize: menu,
        bounds: bounds,
      );
      expect(topLeft, const Offset(8, 88));
      final bottomRight = stickyNoteMenuOrigin(
        noteRect: const Rect.fromLTWH(380, 900, 100, 100),
        menuSize: menu,
        bounds: bounds,
      );
      expect(bottomRight, const Offset(390 - 296 - 8, 844 - 105 - 8));
    });
  });

  group('targets and semantics', () {
    testWidgets('every target is at least 48dp', (tester) async {
      await pumpMenu(tester, noteRect: const Rect.fromLTWH(95, 400, 200, 120));
      for (final c in StickyNoteColor.values) {
        final size = tester.getSize(find.bySemanticsLabel(_trLabel(c)));
        expect(size.width, greaterThanOrEqualTo(48), reason: c.name);
        expect(size.height, greaterThanOrEqualTo(48), reason: c.name);
      }
      final delete = tester.getSize(find.bySemanticsLabel('Sil'));
      expect(delete.height, greaterThanOrEqualTo(48));
      expect(delete.width, greaterThanOrEqualTo(48));
    });

    testWidgets('meets the Android tap target and label guidelines',
        (tester) async {
      await pumpMenu(tester, noteRect: const Rect.fromLTWH(95, 400, 200, 120));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    });

    testWidgets('each colour is a labelled button with a selected state',
        (tester) async {
      await pumpMenu(
        tester,
        noteRect: const Rect.fromLTWH(95, 400, 200, 120),
        selectedColor: StickyNoteColor.blue.argb,
      );
      for (final c in StickyNoteColor.values) {
        expect(
          tester.getSemantics(find.bySemanticsLabel(_trLabel(c))),
          containsSemantics(
            label: _trLabel(c),
            isButton: true,
            hasSelectedState: true,
            isSelected: c == StickyNoteColor.blue,
            hasTapAction: true,
          ),
          reason: c.name,
        );
      }
      expect(
        tester.getSemantics(find.bySemanticsLabel('Sil')),
        containsSemantics(isButton: true, hasTapAction: true),
      );
    });
  });

  group('actions', () {
    testWidgets('tapping a colour reports its ARGB value', (tester) async {
      await pumpMenu(tester, noteRect: const Rect.fromLTWH(95, 400, 200, 120));
      await tester.tap(find.bySemanticsLabel('Mor'));
      expect(tappedColor, StickyNoteColor.purple.argb);
    });

    testWidgets('tapping delete calls onDelete', (tester) async {
      await pumpMenu(tester, noteRect: const Rect.fromLTWH(95, 400, 200, 120));
      await tester.tap(find.text('Sil'));
      expect(deleted, 1);
    });

    testWidgets('taps outside the card reach widgets below the menu',
        (tester) async {
      var below = 0;
      tester.view.physicalSize = _screen;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => below++,
                ),
              ),
              StickyNoteContextMenu(
                noteRect: const Rect.fromLTWH(95, 400, 200, 120),
                selectedColor: 0,
                onColorChange: (_) {},
                onDelete: () {},
              ),
            ],
          ),
        ),
      );
      await tester.tapAt(const Offset(20, 800));
      expect(below, 1);
    });
  });
}

String _trLabel(StickyNoteColor c) => switch (c) {
      StickyNoteColor.yellow => 'Sarı',
      StickyNoteColor.pink => 'Pembe',
      StickyNoteColor.blue => 'Mavi',
      StickyNoteColor.green => 'Yeşil',
      StickyNoteColor.orange => 'Turuncu',
      StickyNoteColor.purple => 'Mor',
    };
