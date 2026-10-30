import 'package:drawing_ui/drawing_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../golden/helpers/sidebar_fixture.dart';

Future<void> _pump(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    const ProviderScope(child: MaterialApp(home: DrawingScreen())),
  );
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  testWidgets('tablet: sidebar closed by default and takes no width',
      (tester) async {
    await _pump(tester, const Size(1180, 820));
    expect(find.byType(PageSidebar), findsOneWidget);
    final host = find
        .ancestor(
          of: find.byType(PageSidebar),
          matching: find.byType(AnimatedContainer),
        )
        .first;
    expect(tester.getSize(host).width, 0);
    expect(
      tester.widget<AnimatedContainer>(host).duration,
      ChromeDurations.normal,
    );
  });

  testWidgets('phone: sidebar is an off-screen drawer when closed',
      (tester) async {
    await _pump(tester, const Size(390, 844));
    final drawer = find.byType(PageSidebar);
    expect(drawer, findsOneWidget);
    expect(tester.getTopLeft(drawer).dx, lessThan(0));
    final positioned = find
        .ancestor(
          of: drawer,
          matching: find.byType(AnimatedPositioned),
        )
        .first;
    expect(
      tester.widget<AnimatedPositioned>(positioned).duration,
      ChromeDurations.normal,
    );
  });

  testWidgets('phone: system Back closes the open page drawer (#482)',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    addTearDown(DismissibleOverlays.instance.reset);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container
        .read(pageManagerProvider.notifier)
        .initializeFromDocument(sidebarPages(3));
    container.read(sidebarOpenProvider.notifier).state = true;
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: DrawingScreen()),
    ));
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.getTopLeft(find.byType(PageSidebar)).dx,
        greaterThanOrEqualTo(0));

    expect(DismissibleOverlays.instance.dismissTopmost(), isTrue);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(container.read(sidebarOpenProvider), isFalse);
    expect(tester.getTopLeft(find.byType(PageSidebar)).dx, lessThan(0));
    expect(DismissibleOverlays.instance.isEmpty, isTrue);
  });
}
