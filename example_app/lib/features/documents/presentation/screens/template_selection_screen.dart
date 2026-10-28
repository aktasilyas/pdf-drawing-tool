/// ElyaNotes Template Selection Screen - Design system template picker
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drawing_core/drawing_core.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/core/widgets/index.dart';
import 'package:example_app/core/routing/route_names.dart';
import 'package:example_app/features/documents/domain/entities/paper_color.dart';
import 'package:example_app/features/documents/presentation/providers/documents_provider.dart';
import 'package:example_app/features/documents/presentation/widgets/paper_color_palette.dart';
import 'package:example_app/features/documents/presentation/widgets/template_category_tabs.dart';
import 'package:example_app/features/documents/presentation/widgets/template_grid.dart';
import 'package:example_app/features/documents/presentation/widgets/cover_grid.dart';
import 'package:example_app/features/documents/presentation/widgets/template_preview_section.dart';
import 'package:example_app/l10n/l10n.dart';

class TemplateSelectionScreen extends ConsumerStatefulWidget {
  const TemplateSelectionScreen({super.key});

  @override
  ConsumerState<TemplateSelectionScreen> createState() =>
      _TemplateSelectionScreenState();
}

class _TemplateSelectionScreenState
    extends ConsumerState<TemplateSelectionScreen> {
  String _title = '';
  bool _hasCover = true;
  PaperSize _paperSize = PaperSize.a4;
  int _paperColor = 0xFFFFFFFF;
  TemplateCategory? _category;
  Template? _template;
  bool _isSelectingCover = false;
  Cover _cover = CoverRegistry.defaultCover;

  @override
  void initState() {
    super.initState();
    _template = TemplateRegistry.all.firstOrNull;
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = context.palette.background;
    final surfaceColor = context.palette.surface;
    final textPrimary = context.palette.textPrimary;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 0,
        leading: AppButton(
          label: l10n.commonCancel,
          variant: AppButtonVariant.text,
          onPressed: () => context.pop(),
        ),
        leadingWidth: 104,
        title: Text(l10n.libraryCreateNoteTitle,
            style: AppTypography.titleMedium.copyWith(
              color: textPrimary,
              fontWeight: FontWeight.w600,
            )),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: AppButton(
              label: l10n.commonCreate,
              size: AppButtonSize.small,
              onPressed: _template != null ? _createDocument : null,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          TemplatePreviewSection(
            hasCover: _hasCover,
            isSelectingCover: _isSelectingCover,
            paperSize: _paperSize,
            paperColor: _paperColor,
            title: _title,
            cover: _cover,
            template: _template,
            onCoverToggle: (v) => setState(() {
              _hasCover = v;
              if (!v) _isSelectingCover = false;
            }),
            onSelectingCoverChanged: (v) =>
                setState(() => _isSelectingCover = v),
            onTitleChanged: (v) => setState(() => _title = v),
            onPaperSizeChanged: (v) => setState(() => _paperSize = v),
          ),
          const AppDivider(),
          _buildSectionHeader(),
          if (!_isSelectingCover)
            TemplateCategoryTabs(
              selectedCategory: _category,
              onCategorySelected: (c) => setState(() {
                _category = c;
              }),
            ),
          const SizedBox(height: AppSpacing.xs),
          Expanded(
            child: _isSelectingCover && _hasCover
                ? CoverGridView(
                    selectedCover: _cover,
                    title: _title,
                    onCoverSelected: (c) => setState(() => _cover = c),
                  )
                : TemplateGridView(
                    category: _category,
                    selectedTemplate: _template,
                    paperColor: _paperColor,
                    onTemplateSelected: (t) => setState(() => _template = t),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Text(
            _isSelectingCover
                ? context.l10n.libraryCover
                : context.l10n.libraryTemplate,
            style:
                AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          if (!_isSelectingCover)
            PaperColorPalette(
              selectedColor: _paperColor,
              onColorSelected: (c) => setState(() => _paperColor = c),
            ),
        ],
      ),
    );
  }

  Future<void> _createDocument() async {
    if (_template == null) return;

    final untitled = context.l10n.libraryUntitledNote;
    final controller = ref.read(documentsControllerProvider.notifier);
    final folderId = ref.read(currentFolderIdProvider);
    final docTitle = _title.trim().isEmpty ? untitled : _title.trim();

    final documentId = await controller.createDocument(
      title: docTitle,
      templateId: _template!.id,
      folderId: folderId,
      paperColor: PaperColor.fromArgb(_paperColor).storageKey,
      isPortrait: !_paperSize.isLandscape,
      documentType: DocumentType.notebook,
      coverId: _hasCover ? _cover.id : null,
      hasCover: _hasCover,
      paperWidthMm: _paperSize.widthMm,
      paperHeightMm: _paperSize.heightMm,
    );

    if (mounted && documentId != null) {
      context.go(RouteNames.editorPath(documentId));
    }
  }
}
