import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/core/widgets/buttons/index.dart';
import 'package:example_app/core/widgets/feedback/index.dart';

import '../../../helpers/l10n.dart';

const _phone = Size(400, 800);
const _tablet = Size(900, 1000);

Future<void> _open(
  WidgetTester tester, {
  required Size size,
  List<Widget>? actions,
  bool isDismissible = true,
  bool showCloseButton = true,
  void Function(Object? result)? onResult,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(localizedApp(
    theme: AppTheme.light,
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () async {
              final r = await AppModal.show<String>(
                context: context,
                title: 'Title',
                content: const Text('Body'),
                actions: actions,
                isDismissible: isDismissible,
                showCloseButton: showCloseButton,
              );
              onResult?.call(r);
            },
            child: const Text('open'),
          ),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  group('layout', () {
    testWidgets('phone shows a bottom sheet', (tester) async {
      await _open(tester, size: _phone);

      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.byType(Dialog), findsNothing);
      expect(find.text('Title'), findsOneWidget);
      expect(find.text('Body'), findsOneWidget);
    });

    testWidgets('tablet shows a center dialog capped at 560dp', (tester) async {
      await _open(tester, size: _tablet);

      expect(find.byType(Dialog), findsOneWidget);
      expect(find.byType(BottomSheet), findsNothing);
      expect(
        tester
            .getSize(find
                .descendant(
                  of: find.byType(Dialog),
                  matching: find.byType(ConstrainedBox),
                )
                .first)
            .width,
        lessThanOrEqualTo(560),
      );
    });
  });

  for (final entry in {'phone': _phone, 'tablet': _tablet}.entries) {
    group(entry.key, () {
      testWidgets('close button dismisses with null and is >= 48dp',
          (tester) async {
        Object? result = 'unset';
        await _open(tester, size: entry.value, onResult: (r) => result = r);

        final close = find.byType(AppIconButton);
        expect(close, findsOneWidget);
        final size = tester.getSize(close);
        expect(size.width, greaterThanOrEqualTo(48));
        expect(size.height, greaterThanOrEqualTo(48));

        await tester.tap(close);
        await tester.pumpAndSettle();

        expect(find.text('Title'), findsNothing);
        expect(result, isNull);
      });

      testWidgets('action returns its result and actions are >= 48dp',
          (tester) async {
        Object? result;
        await _open(
          tester,
          size: entry.value,
          onResult: (r) => result = r,
          actions: [
            Builder(builder: (context) {
              return AppButton(
                label: 'Save',
                size: AppButtonSize.large,
                onPressed: () => Navigator.of(context).pop('saved'),
              );
            }),
          ],
        );

        expect(tester.getSize(find.byType(AppButton)).height,
            greaterThanOrEqualTo(48));
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(find.text('Title'), findsNothing);
        expect(result, 'saved');
      });

      testWidgets('showCloseButton false hides the close button',
          (tester) async {
        await _open(tester, size: entry.value, showCloseButton: false);

        expect(find.byType(AppIconButton), findsNothing);
      });

      testWidgets('non-dismissible ignores barrier tap', (tester) async {
        await _open(tester, size: entry.value, isDismissible: false);

        await tester.tapAt(const Offset(5, 5));
        await tester.pumpAndSettle();

        expect(find.text('Title'), findsOneWidget);
      });

      testWidgets('barrier tap dismisses when dismissible', (tester) async {
        await _open(tester, size: entry.value);

        await tester.tapAt(const Offset(5, 5));
        await tester.pumpAndSettle();

        expect(find.text('Title'), findsNothing);
      });
    });
  }
}
