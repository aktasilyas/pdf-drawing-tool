import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:example_app/core/theme/index.dart';
import 'package:example_app/features/documents/domain/entities/sort_option.dart';
import 'package:example_app/features/documents/presentation/widgets/documents_header.dart';

void main() {
  Future<void> pump(WidgetTester tester, {VoidCallback? onEmptyTrash}) async {
    tester.view.physicalSize = const Size(1000, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: DocumentsHeader(
              title: 'Çöp Kutusu',
              isTrashSection: true,
              onNewPressed: () {},
              sortOption: SortOption.date,
              onSortChanged: (_) {},
              onEmptyTrash: onEmptyTrash,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('Çöpü Boşalt calls onEmptyTrash', (tester) async {
    var called = 0;
    await pump(tester, onEmptyTrash: () => called++);
    await tester.tap(find.text('Çöpü Boşalt'));
    expect(called, 1);
  });

  testWidgets('Çöpü Boşalt is hidden without a handler', (tester) async {
    await pump(tester);
    expect(find.text('Çöpü Boşalt'), findsNothing);
  });
}
