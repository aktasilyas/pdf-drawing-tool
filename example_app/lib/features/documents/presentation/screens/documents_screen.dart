import 'package:drawing_ui/drawing_ui.dart' show FloatingExportProgress;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:example_app/core/theme/index.dart';
import 'package:example_app/core/utils/responsive.dart';
import 'package:example_app/features/documents/domain/entities/document_info.dart';
import 'package:example_app/features/documents/domain/entities/folder.dart';
import 'package:example_app/features/documents/presentation/providers/documents_provider.dart';
import 'package:example_app/features/documents/presentation/widgets/documents_content_view.dart';
import 'package:example_app/features/documents/presentation/widgets/documents_header.dart';
import 'package:example_app/features/documents/presentation/widgets/documents_menus.dart';
import 'package:example_app/features/documents/presentation/widgets/documents_sidebar.dart';
import 'package:example_app/features/documents/presentation/widgets/folder_menus.dart';
import 'package:example_app/features/documents/presentation/widgets/new_document_dialog.dart';
import 'package:example_app/core/routing/route_names.dart';
import 'package:example_app/features/premium/premium.dart';
import 'package:example_app/l10n/l10n.dart';
import 'documents_screen_helpers.dart';

class DocumentsScreen extends ConsumerStatefulWidget {
  const DocumentsScreen({super.key});

  @override
  ConsumerState<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends ConsumerState<DocumentsScreen>
    with DocumentsScreenHelpers {
  final GlobalKey _addButtonKey = GlobalKey();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  SidebarSection _selectedSection = SidebarSection.documents;
  String? _selectedFolderId;
  bool _isSidebarCollapsed = false;
  bool _sidebarInitialised = false;
  bool _nearLimitBannerDismissed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_sidebarInitialised) {
      _sidebarInitialised = true;
      _isSidebarCollapsed =
          MediaQuery.sizeOf(context).width < AppBreakpoints.expanded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = Responsive.isPhone(context);

    return _buildScaffold(isPhone);
  }

  Widget _buildScaffold(bool isPhone) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: context.palette.background,
      drawer: isPhone
          ? Drawer(
              backgroundColor: context.palette.surface,
              child: SafeArea(
                child: _buildSidebarContent(isDrawer: true),
              ),
            )
          : null,
      body: Stack(
        fit: StackFit.expand,
        children: [
          SafeArea(
            child: isPhone ? _buildMobileLayout() : _buildDesktopLayout(),
          ),
          // Progress / result card of "Export as PDF" from the document menu.
          const FloatingExportProgress(),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: _buildPane(isPhone: true),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        AnimatedContainer(
          duration: AppDurations.fast,
          curve: _isSidebarCollapsed ? AppCurves.exit : AppCurves.enter,
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
              color: context.palette.background,
              child: _buildPane(isPhone: false),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPane({required bool isPhone}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(isPhone: isPhone),
        _buildNearLimitBanner(),
        Expanded(child: _buildContentView()),
      ],
    );
  }

  Widget _buildHeader({required bool isPhone}) {
    final isInFolder =
        _selectedSection == SidebarSection.folder && _selectedFolderId != null;

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
      onEmptyTrash: _selectedSection == SidebarSection.trash &&
              (ref.watch(trashItemsProvider).valueOrNull ?? const []).isNotEmpty
          ? confirmAndEmptyTrash
          : null,
      title: getSectionTitle(
        ref,
        context.l10n,
        _selectedSection,
        _selectedFolderId,
      ),
      breadcrumb: isInFolder
          ? buildBreadcrumb(
              _selectedFolderId,
              _navigateToRoot,
              _navigateToFolder,
              compact: true,
            )
          : null,
      onSettingsTap: () => context.push('/settings'),
      onMenuTap: isPhone ? () => _scaffoldKey.currentState?.openDrawer() : null,
      onSidebarToggle: !isPhone && _isSidebarCollapsed
          ? () => setState(() => _isSidebarCollapsed = false)
          : null,
    );
  }

  Widget _buildNearLimitBanner() {
    if (_nearLimitBannerDismissed) return const SizedBox.shrink();

    final countAsync = ref.watch(totalDocumentCountProvider);
    final count = countAsync.valueOrNull ?? 0;
    final access = ref.watch(featureAccessProvider(
      FeatureAccessParams(
        feature: GatedFeature.createDocument,
        currentUsage: count,
      ),
    ));

    // At limit: show trash hint if there are trashed documents
    if (!access.isAllowed) {
      final trashDocs = ref.watch(trashDocumentsProvider).valueOrNull ?? [];
      if (trashDocs.isNotEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          child: NearLimitBanner(
            message: context.l10n.libraryTrashCountsTowardsLimit,
            onUpgrade: () => context.push(RouteNames.paywall),
          ),
        );
      }
      return const SizedBox.shrink();
    }

    // Near limit: show remaining count
    if (!access.isNearLimit) return const SizedBox.shrink();

    final remaining = (access.maxUsage ?? 0) - (access.currentUsage ?? 0);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: NearLimitBanner(
        message: context.l10n.libraryRemainingDocuments(remaining),
        onUpgrade: () => context.push(RouteNames.paywall),
        onDismiss: () => setState(() => _nearLimitBannerDismissed = true),
      ),
    );
  }

  Widget _buildContentView() {
    return DocumentsContentView(
      section: _selectedSection,
      folderId: _selectedFolderId,
      onCreateNew: () => showNewDocumentDropdown(context, _addButtonKey),
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
    setState(() {
      _selectedSection = SidebarSection.documents;
      _selectedFolderId = null;
    });
    ref.read(currentFolderIdProvider.notifier).state = null;
  }

  void _navigateToFolder(String folderId) {
    setState(() {
      _selectedSection = SidebarSection.folder;
      _selectedFolderId = folderId;
    });
    ref.read(currentFolderIdProvider.notifier).state = folderId;
  }

  void _handleFolderTap(Folder folder) =>
      handleFolderTap(folder, _navigateToFolder);
  void _handleDocumentTap(DocumentInfo doc) => handleDocumentTap(doc);
}
