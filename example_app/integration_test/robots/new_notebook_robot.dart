import 'dart:async';

import 'package:drawing_core/drawing_core.dart' show Cover, Template;
import 'package:drawing_ui/drawing_ui.dart' show CoverPreviewWidget;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:example_app/core/routing/route_names.dart';
import 'package:example_app/core/widgets/index.dart';
import 'package:example_app/features/documents/presentation/providers/documents_provider.dart';
import 'package:example_app/features/documents/presentation/screens/documents_screen.dart';
import 'package:example_app/features/documents/presentation/screens/template_selection_screen.dart';
import 'package:example_app/features/documents/presentation/widgets/cover_grid.dart';
import 'package:example_app/features/documents/presentation/widgets/library_header_parts.dart';
import 'package:example_app/features/documents/presentation/widgets/template_grid.dart';
import 'package:example_app/features/documents/presentation/widgets/template_preview_card.dart';

import '../helpers/l10n.dart';
import '../helpers/pump_helpers.dart';

/// Creates notebooks with a chosen cover and paper template.
///
/// [createThroughUi] drives the template screen like a user. [createAndOpen]
/// writes the notebook through the app's own documents controller and
/// opens it on the library's editor route, so a test can go through every
/// cover and template without paying for the picker each time.
class NewNotebookRobot {
  NewNotebookRobot(this.tester);

  final WidgetTester tester;

  Finder get _library => find.byType(DocumentsScreen);

  /// New (+) > "Notebook" > pick [cover] on the cover tab and [template]
  /// on the paper tab > set [title] > "Create". Opens the editor.
  Future<void> createThroughUi(
    String title, {
    required Cover cover,
    required Template template,
  }) async {
    await tester.tapAndWait(find.byType(LibraryNewButton));
    final l10n = tester.l10n;
    await tester.tapAndWait(find.text(l10n.libraryNewNotebook));
    await tester.pumpUntilFound(find.byType(TemplateSelectionScreen));

    // Preview cards: cover first (the cover switch is on by default), paper
    // last. Tapping one switches the grid below it.
    final cards = find.byType(TemplatePreviewCard);
    await tester.pumpUntilFound(cards);
    await tester.tapAndWait(cards.first);
    // By cover id, not label: cover names follow the device locale.
    await tester.tapAndWait(find.descendant(
      of: find.byType(CoverGridView),
      matching: find.byWidgetPredicate(
        (w) => w is CoverPreviewWidget && w.cover.id == cover.id,
      ),
    ));
    await tester.tapAndWait(cards.last);
    final templateItem = find.byWidgetPredicate(
      (w) => w is TemplateGridItem && w.template.id == template.id,
    );
    await tester.pumpUntilFound(templateItem);
    await tester.ensureVisible(templateItem);
    await tester.pumpFor(const Duration(milliseconds: 300));
    await tester.tapAndWait(templateItem);

    final field = find.descendant(
      of: find.byType(AppTextField),
      matching: find.byType(TextFormField),
    );
    await tester.enterText(field.first, title);
    await tester.pumpFor(const Duration(milliseconds: 300));
    await tester.tapAndWait(
      find.widgetWithText(AppButton, l10n.commonCreate),
    );
  }

  /// Creates a notebook from the library screen without the picker and
  /// pushes the editor route, as tapping its tile does. Returns the id.
  Future<String> createAndOpen(
    String title, {
    required Template template,
    Cover? cover,
  }) async {
    await tester.pumpUntilFound(_library);
    final controller =
        ProviderScope.containerOf(tester.element(_library), listen: false)
            .read(documentsControllerProvider.notifier);
    final id = await controller.createDocument(
      title: title,
      templateId: template.id,
      coverId: cover?.id,
      hasCover: cover != null,
    );
    expect(id, isNotNull, reason: 'notebook "$title" was not created');
    final router = GoRouter.of(tester.element(_library));
    unawaited(router.push<void>(RouteNames.editorPath(id!)));
    await tester.pump();
    return id;
  }
}
