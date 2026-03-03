import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:example_app/core/theme/index.dart';
import 'package:example_app/core/utils/responsive.dart';
import 'package:example_app/core/widgets/index.dart';
import 'package:example_app/features/documents/domain/entities/document_info.dart';
import 'package:example_app/features/documents/domain/entities/folder.dart';
import 'package:example_app/features/documents/presentation/providers/documents_provider.dart';
import 'package:example_app/features/documents/presentation/widgets/documents_content_view.dart';
import 'package:example_app/features/documents/presentation/widgets/documents_header.dart';
import 'package:example_app/features/documents/presentation/widgets/documents_menus.dart';
import 'package:example_app/features/documents/presentation/widgets/documents_sidebar.dart';
import 'package:example_app/features/documents/presentation/widgets/folder_menus.dart';
import 'package:example_app/features/documents/presentation/widgets/new_document_dialog.dart';
import 'documents_screen_helpers.dart';

class DocumentsScreen extends ConsumerStatefulWidget {
  const DocumentsScreen({super.key});

  @override
  ConsumerState<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends ConsumerState<DocumentsScreen>
    with DocumentsScreenHelpers {
  final GlobalKey _addButtonKey = GlobalKey();
  SidebarSection _selectedSection = SidebarSection.documents;
  String? _selectedFolderId;
  bool _isSidebarCollapsed = false;

  @override
  Widget build(BuildContext context) {
    final isPhone = Responsive.isPhone(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      drawer: isPhone
          ? Drawer(
              backgroundColor:
                  isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              child: SafeArea(
                child: _buildSidebarContent(isDrawer: true),
              ),
            )
          : null,
      body: SafeArea(
        child: isPhone ? _buildMobileLayout() : _buildDesktopLayout(),
      ),
    );
  }

  Widget _buildMobileLayout() {
    final isInFolder = _selectedSection == SidebarSection.folder &&
        _selectedFolderId != null;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MobileTopBar(
            center: isInFolder
                ? buildBreadcrumb(
                    _selectedFolderId,
                    _navigateToRoot,
                    _navigateToFolder,
                    compact: true,
                  )
                : _buildMobileTitle(),
            onSettingsTap: () => context.push('/settings'),
          ),
          _buildHeader(),
          _buildSoftDivider(),
          Expanded(child: _buildContentView()),
        ],
      ),
    );
  }

  Widget _buildMobileTitle() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return Text(
      getSectionTitle(ref, _selectedSection, _selectedFolderId),
      style: AppTypography.headlineMedium.copyWith(color: textPrimary),
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildDesktopLayout() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isInFolder = _selectedSection == SidebarSection.folder &&
        _selectedFolderId != null;

    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          width: _isSidebarCollapsed ? 0 : AppSpacing.sidebarWidth,
          clipBehavior: Clip.hardEdge,
          decoration: const BoxDecoration(),
          child: OverflowBox(
            maxWidth: AppSpacing.sidebarWidth,
            minWidth: AppSpacing.sidebarWidth,
            alignment: Alignment.centerLeft,
            child: _buildSidebarContent(isDrawer: false),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Container(
              color: isDark
                  ? AppColors.backgroundDark
                  : AppColors.surfaceLight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DesktopTopBar(
                    center: isInFolder
                        ? buildBreadcrumb(
                            _selectedFolderId,
                            _navigateToRoot,
                            _navigateToFolder,
                            compact: true,
                          )
                        : _buildDesktopTitle(),
                    onSidebarToggle: () => setState(
                        () => _isSidebarCollapsed = !_isSidebarCollapsed),
                    isSidebarCollapsed: _isSidebarCollapsed,
                    onSettingsTap: () => context.push('/settings'),
                  ),
                  _buildHeader(),
                  _buildSoftDivider(),
                  Expanded(child: _buildContentView()),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopTitle() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return Text(
      getSectionTitle(ref, _selectedSection, _selectedFolderId),
      style: AppTypography.headlineLarge.copyWith(color: textPrimary),
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildHeader() {
    return DocumentsHeader(
      newButtonKey: _addButtonKey,
      onNewPressed: () => showNewDocumentDropdown(context, _addButtonKey),
      sortOption: ref.watch(sortOptionProvider),
      onSortChanged: (option) {
        ref.read(sortOptionProvider.notifier).set(option);
      },
      allDocumentIds:
          getCurrentDocumentIds(ref, _selectedSection, _selectedFolderId),
      allFolderIds:
          getCurrentFolderIds(ref, _selectedSection, _selectedFolderId),
      isTrashSection: _selectedSection == SidebarSection.trash,
    );
  }

  Widget _buildSoftDivider() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Divider(
        height: 1,
        thickness: 0.5,
        color: isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight,
      ),
    );
  }

  Widget _buildContentView() {
    return DocumentsContentView(
      section: _selectedSection,
      folderId: _selectedFolderId,
      onFolderTap: _handleFolderTap,
      onDocumentTap: _handleDocumentTap,
      onFolderMore: (folder) => showFolderMenu(
        context,
        ref,
        folder,
        onDeleted: () {
          if (_selectedFolderId == folder.id) {
            _navigateToRoot();
          }
        },
      ),
      onDocumentMore: (doc) => showDocumentMenu(
        context,
        ref,
        doc,
        isTrash: _selectedSection == SidebarSection.trash,
      ),
      onTrashedPageTap: (trashedPage) => showTrashedPageMenu(
        context,
        ref,
        trashedPage,
      ),
    );
  }

  Widget _buildSidebarContent({required bool isDrawer}) {
    return DocumentsSidebar(
      selectedSection: _selectedSection,
      selectedFolderId: _selectedFolderId,
      isDrawer: isDrawer,
      onCollapse: isDrawer
          ? () => Navigator.pop(context)
          : () => setState(() => _isSidebarCollapsed = true),
      onSectionChanged: (section) {
        setState(() {
          _selectedSection = section;
          _selectedFolderId = null;
        });
        ref.read(currentFolderIdProvider.notifier).state = null;
        if (isDrawer) Navigator.pop(context);
      },
      onFolderSelected: (folderId) {
        _navigateToFolder(folderId);
        if (isDrawer) Navigator.pop(context);
      },
      onCreateFolder: () {
        if (isDrawer) Navigator.pop(context);
        showCreateFolderDialog();
      },
    );
  }

  void _navigateToRoot() {
    setState(() { _selectedSection = SidebarSection.documents; _selectedFolderId = null; });
    ref.read(currentFolderIdProvider.notifier).state = null;
  }

  void _navigateToFolder(String folderId) {
    setState(() { _selectedSection = SidebarSection.folder; _selectedFolderId = folderId; });
    ref.read(currentFolderIdProvider.notifier).state = folderId;
  }

  void _handleFolderTap(Folder folder) => handleFolderTap(folder, _navigateToFolder);
  void _handleDocumentTap(DocumentInfo doc) => handleDocumentTap(doc);
}

/// Mobile top bar: [Sidebar icon] [Title or Path] [Settings icon]
class _MobileTopBar extends StatelessWidget {
  const _MobileTopBar({
    required this.center,
    required this.onSettingsTap,
  });
  final Widget center;
  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Builder(
            builder: (ctx) => AppIconButton(
              icon: Icons.view_sidebar_outlined,
              variant: AppIconButtonVariant.ghost,
              tooltip: 'Menü',
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(child: center),
          const SizedBox(width: AppSpacing.xs),
          AppIconButton(
            icon: Icons.settings_outlined,
            variant: AppIconButtonVariant.ghost,
            tooltip: 'Ayarlar',
            onPressed: onSettingsTap,
          ),
        ],
      ),
    );
  }
}

/// Desktop top bar: [Sidebar toggle] [Title or Path] [Settings icon]
class _DesktopTopBar extends StatelessWidget {
  const _DesktopTopBar({
    required this.center,
    required this.onSidebarToggle,
    required this.isSidebarCollapsed,
    required this.onSettingsTap,
  });
  final Widget center;
  final VoidCallback onSidebarToggle;
  final bool isSidebarCollapsed;
  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          AppIconButton(
            icon: isSidebarCollapsed
                ? Icons.view_sidebar_outlined
                : Icons.view_sidebar,
            variant: AppIconButtonVariant.ghost,
            tooltip: isSidebarCollapsed
                ? 'Kenar çubuğunu aç'
                : 'Kenar çubuğunu kapat',
            onPressed: onSidebarToggle,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: center),
          const SizedBox(width: AppSpacing.sm),
          AppIconButton(
            icon: Icons.settings_outlined,
            variant: AppIconButtonVariant.ghost,
            tooltip: 'Ayarlar',
            onPressed: onSettingsTap,
          ),
        ],
      ),
    );
  }
}
