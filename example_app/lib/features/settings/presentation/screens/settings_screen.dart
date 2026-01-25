import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:example_app/features/auth/presentation/providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/settings_section.dart';
import '../widgets/settings_tile.dart';
import '../widgets/profile_header.dart';
import '../../domain/entities/app_settings.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final user = Supabase.instance.client.auth.currentUser;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
        centerTitle: !isTablet,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isTablet ? 600 : double.infinity),
          child: ListView(
            children: [
              // Profil
              ProfileHeader(
                name: user?.userMetadata?['name'] as String? ?? 
                      user?.email?.split('@').first ?? 'Kullanıcı',
                email: user?.email ?? '',
                isPremium: false, // TODO: Premium provider
                onTap: () => _showEditNameDialog(context, ref),
              ),
              const Divider(height: 1),

              // Uygulama Ayarları
              SettingsSection(
                title: 'UYGULAMA',
                children: [
                  SettingsTile(
                    icon: Icons.palette_outlined,
                    title: 'Tema',
                    subtitle: _getThemeText(settings.themeMode),
                    onTap: () => _showThemeDialog(context, ref, settings),
                  ),
                  SettingsTile(
                    icon: Icons.language,
                    title: 'Dil',
                    subtitle: settings.language == AppLanguage.tr ? 'Türkçe' : 'English',
                    onTap: () => _showLanguageDialog(context, ref, settings),
                  ),
                  SettingsTile(
                    icon: Icons.description_outlined,
                    title: 'Varsayılan Kağıt Boyutu',
                    subtitle: settings.defaultPaperSize.name.toUpperCase(),
                    onTap: () => _showPaperSizeDialog(context, ref, settings),
                  ),
                  SettingsTile(
                    icon: Icons.save_outlined,
                    title: 'Otomatik Kaydetme',
                    showArrow: false,
                    trailing: Switch(
                      value: settings.autoSaveEnabled,
                      onChanged: (v) => ref.read(settingsProvider.notifier).setAutoSave(v),
                    ),
                  ),
                ],
              ),

              // Yasal
              SettingsSection(
                title: 'YASAL',
                children: [
                  SettingsTile(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Gizlilik Politikası',
                    onTap: () => _openLegalPage(context, 'privacy'),
                  ),
                  SettingsTile(
                    icon: Icons.description_outlined,
                    title: 'Kullanım Koşulları',
                    onTap: () => _openLegalPage(context, 'terms'),
                  ),
                  SettingsTile(
                    icon: Icons.cookie_outlined,
                    title: 'Çerez Politikası',
                    onTap: () => _openLegalPage(context, 'cookies'),
                  ),
                ],
              ),

              // Destek
              SettingsSection(
                title: 'DESTEK',
                children: [
                  SettingsTile(
                    icon: Icons.help_outline,
                    title: 'Yardım & SSS',
                    onTap: () => _openLegalPage(context, 'help'),
                  ),
                  SettingsTile(
                    icon: Icons.feedback_outlined,
                    title: 'Geri Bildirim Gönder',
                    onTap: () => _showFeedbackDialog(context),
                  ),
                  SettingsTile(
                    icon: Icons.star_outline,
                    title: 'Bizi Değerlendir',
                    onTap: () {}, // TODO: Store link
                  ),
                ],
              ),

              // Hakkında
              SettingsSection(
                title: 'HAKKINDA',
                children: [
                  SettingsTile(
                    icon: Icons.info_outline,
                    title: 'Versiyon',
                    subtitle: '1.0.0 (1)',
                    showArrow: false,
                  ),
                  SettingsTile(
                    icon: Icons.code,
                    title: 'Açık Kaynak Lisansları',
                    onTap: () => showLicensePage(
                      context: context,
                      applicationName: 'StarNote',
                      applicationVersion: '1.0.0',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Çıkış Yap
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: OutlinedButton.icon(
                  onPressed: () => _handleLogout(context, ref),
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text('Çıkış Yap', style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  String _getThemeText(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light: return 'Açık';
      case AppThemeMode.dark: return 'Koyu';
      case AppThemeMode.system: return 'Sistem';
    }
  }

  void _showThemeDialog(BuildContext context, WidgetRef ref, AppSettings settings) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Tema Seçin'),
        children: AppThemeMode.values.map((mode) => RadioListTile<AppThemeMode>(
          title: Text(_getThemeText(mode)),
          value: mode,
          groupValue: settings.themeMode,
          onChanged: (v) {
            ref.read(settingsProvider.notifier).setTheme(v!);
            Navigator.pop(ctx);
          },
        )).toList(),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, WidgetRef ref, AppSettings settings) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Dil Seçin'),
        children: [
          RadioListTile<AppLanguage>(
            title: const Text('Türkçe'),
            value: AppLanguage.tr,
            groupValue: settings.language,
            onChanged: (v) {
              ref.read(settingsProvider.notifier).setLanguage(v!);
              Navigator.pop(ctx);
            },
          ),
          RadioListTile<AppLanguage>(
            title: const Text('English'),
            value: AppLanguage.en,
            groupValue: settings.language,
            onChanged: (v) {
              ref.read(settingsProvider.notifier).setLanguage(v!);
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  void _showPaperSizeDialog(BuildContext context, WidgetRef ref, AppSettings settings) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Kağıt Boyutu'),
        children: PaperSize.values.map((size) => RadioListTile<PaperSize>(
          title: Text(size.name.toUpperCase()),
          value: size,
          groupValue: settings.defaultPaperSize,
          onChanged: (v) {
            ref.read(settingsProvider.notifier).setPaperSize(v!);
            Navigator.pop(ctx);
          },
        )).toList(),
      ),
    );
  }

  void _showEditNameDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('İsim Düzenle'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Adınız',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () async {
              // TODO: Supabase user metadata güncelle
              Navigator.pop(ctx);
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  void _openLegalPage(BuildContext context, String type) {
    // TODO: Legal sayfalarına route eklenince güncellenecek
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$type sayfası yakında eklenecek')),
    );
  }

  void _showFeedbackDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Geri Bildirim'),
        content: const TextField(
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Görüşlerinizi yazın...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Teşekkürler! Geri bildiriminiz alındı.')),
              );
            },
            child: const Text('Gönder'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text('Hesabınızdan çıkış yapmak istediğinize emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      await ref.read(authControllerProvider.notifier).signOut();
      if (context.mounted) context.go('/login');
    }
  }
}
