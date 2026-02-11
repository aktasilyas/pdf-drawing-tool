/// StarNote Design System - Widget Library Exports
///
/// Tüm widget kategorilerini tek noktadan export eder.
///
/// Kullanım:
/// ```dart
/// import 'package:example_app/core/widgets/index.dart';
///
/// // Buttons
/// AppButton(label: 'Kaydet', onPressed: save)
/// AppIconButton(icon: Icons.add, onPressed: add, tooltip: 'Ekle')
///
/// // Inputs
/// AppTextField(label: 'E-posta', onChanged: handleEmail)
/// AppSearchField(onChanged: handleSearch)
/// AppPasswordField(label: 'Şifre', onChanged: handlePassword)
///
/// // Feedback
/// AppModal.show(context, title: 'Başlık', content: MyWidget())
/// AppToast.success(context, 'Başarılı!')
/// AppLoadingOverlay(isLoading: true, child: MyWidget())
/// AppEmptyState(icon: Icons.inbox, title: 'Boş')
///
/// // Layout
/// AppCard(child: MyContent())
/// AppListTile(title: 'Item', subtitle: 'Description')
/// AppAvatar(initials: 'IA')
/// AppBadge(label: '5', child: Icon(Icons.notifications))
/// AppChip(label: 'Tag', isSelected: true)
///
/// // Navigation
/// ResponsiveBuilder(compact: PhoneUI(), expanded: TabletUI())
/// AdaptiveNavigation(items: items, body: content)
/// MasterDetailLayout(master: list, detail: detail)
/// ```
library;

export 'buttons/index.dart';
export 'feedback/index.dart';
export 'inputs/index.dart';
export 'layout/index.dart';
export 'navigation/index.dart';
