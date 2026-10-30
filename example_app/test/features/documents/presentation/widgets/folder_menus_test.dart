import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/features/documents/domain/entities/folder.dart';
import 'package:example_app/features/documents/presentation/widgets/folder_menus.dart';
import '../../../../helpers/l10n.dart';

void main() {
  Future<void> openMenu(WidgetTester tester, {required bool favorite}) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final folder = Folder(
      id: 'f1',
      name: 'Ders',
      colorValue: 0xFF2196F3,
      createdAt: DateTime(2025, 1, 1),
      isFavorite: favorite,
    );
    await tester.pumpWidget(
      ProviderScope(
        child: localizedApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) => TextButton(
                onPressed: () =>
                    showFolderMenu(context, ref, folder, onDeleted: null),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('offers Favorilere Ekle for a non-favorite folder',
      (tester) async {
    await openMenu(tester, favorite: false);
    expect(find.text('Favorilere Ekle'), findsOneWidget);
    expect(find.text('Favorilerden Kaldır'), findsNothing);
  });

  testWidgets('offers Favorilerden Kaldır for a favorite folder',
      (tester) async {
    await openMenu(tester, favorite: true);
    expect(find.text('Favorilerden Kaldır'), findsOneWidget);
    expect(find.text('Favorilere Ekle'), findsNothing);
  });

  testWidgets('does not offer PDF export', (tester) async {
    await openMenu(tester, favorite: false);
    expect(find.text('PDF olarak dışa aktar'), findsNothing);
  });
}
