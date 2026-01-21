import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawing_ui/src/utils/size_utils.dart';

void main() {
  group('SizeUtils', () {
    testWidgets('isLandscape returns true for landscape', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      late bool isLandscape;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              isLandscape = context.isLandscape;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(isLandscape, true);
    });

    testWidgets('isPortrait returns true for portrait', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      late bool isPortrait;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              isPortrait = context.isPortrait;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(isPortrait, true);
    });

    testWidgets('screenWidth and screenHeight return correct values', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      late double width;
      late double height;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              width = context.screenWidth;
              height = context.screenHeight;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(width, 800.0);
      expect(height, 600.0);
    });

    testWidgets('screenSize returns correct size', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      late Size size;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              size = context.screenSize;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(size.width, 800.0);
      expect(size.height, 600.0);
    });
  });
}
