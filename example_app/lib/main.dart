import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:example_app/core/core.dart';
import 'package:example_app/features/settings/settings.dart';
import 'package:example_app/features/premium/premium.dart';
import 'package:example_app/features/sync/presentation/providers/sync_provider.dart';
import 'package:drawing_ui/drawing_ui.dart' as drawing_ui;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hide status bar globally for entire app
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersiveSticky,
    overlays: [],
  );

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Supabase and SharedPreferences in parallel
  final (_, prefs) = await (
    Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
      debug: true,
    ),
    SharedPreferences.getInstance(),
  ).wait;

  logger.i('Supabase initialized: ${dotenv.env['SUPABASE_URL']}');

  // Initialize RevenueCat for in-app purchases
  try {
    final rcApiKey = RevenueCatConstants.apiKey;
    if (rcApiKey.isNotEmpty) {
      await Purchases.configure(PurchasesConfiguration(rcApiKey));
      if (kDebugMode) {
        await Purchases.setLogLevel(LogLevel.debug);
      }
      logger.i('RevenueCat initialized');
    } else {
      logger.w('RevenueCat API key not configured — skipping init');
    }
  } catch (e) {
    logger.e('RevenueCat init failed: $e');
    // App continues to work without RevenueCat (graceful degradation)
  }

  // Initialize GetIt dependencies
  await configureDependencies();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        drawing_ui.sharedPreferencesProvider.overrideWithValue(prefs),
        drawing_ui.recordingMaxDurationProvider.overrideWith((ref) {
          final tier = ref.watch(currentTierProvider);
          if (tier != SubscriptionTier.free) return null; // unlimited
          // Free users: remaining time = 5 min - total used
          const limit = Duration(minutes: 5);
          final recordings = ref.watch(drawing_ui.audioRecordingsProvider);
          final totalUsed = recordings.fold<Duration>(
            Duration.zero,
            (sum, r) => sum + r.duration,
          );
          final remaining = limit - totalUsed;
          if (remaining <= Duration.zero) return Duration.zero;
          return remaining;
        }),
        drawing_ui.canStartRecordingProvider.overrideWith((ref) {
          final tier = ref.watch(currentTierProvider);
          if (tier != SubscriptionTier.free) return true;
          final recordings = ref.watch(drawing_ui.audioRecordingsProvider);
          final totalUsed = recordings.fold<Duration>(
            Duration.zero,
            (sum, r) => sum + r.duration,
          );
          return totalUsed < const Duration(minutes: 5);
        }),
        drawing_ui.onRecordingBlockedProvider.overrideWith((ref) {
          return (BuildContext ctx) {
            final recordings = ref.read(drawing_ui.audioRecordingsProvider);
            final totalSeconds = recordings.fold<int>(
              0,
              (sum, r) => sum + r.duration.inSeconds,
            );
            final usedMinutes = (totalSeconds / 60).ceil();
            showModalBottomSheet(
              context: ctx,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (sheetCtx) => UpgradePromptSheet(
                access: FeatureAccess.blocked(
                  currentUsage: usedMinutes,
                  maxUsage: 5,
                  message:
                      'Ücretsiz planda toplam 5 dakika ses kaydı yapabilirsiniz. '
                      "Premium'a geçerek sınırsız kayıt yapın.",
                ),
                featureIcon: Icons.mic_outlined,
                featureTitle: 'Ses Kaydı Limitine Ulaştınız',
                onUpgrade: () {
                  Navigator.pop(sheetCtx);
                  GoRouter.of(sheetCtx).push(RouteNames.paywall);
                },
                onDismiss: () => Navigator.pop(sheetCtx),
              ),
            );
          };
        }),
        drawing_ui.exportWatermarkProvider.overrideWith((ref) {
          final tier = ref.watch(currentTierProvider);
          return tier == SubscriptionTier.free;
        }),
      ],
      child: const ElyaNotesApp(),
    ),
  );
}

/// Global Supabase client getter
final supabase = Supabase.instance.client;

/// Main application widget for ElyaNotes.
class ElyaNotesApp extends ConsumerWidget {
  const ElyaNotesApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    final themeMode = switch (settings.themeMode) {
      AppThemeMode.light => ThemeMode.light,
      AppThemeMode.dark => ThemeMode.dark,
      AppThemeMode.system => ThemeMode.system,
    };

    return MaterialApp.router(
      title: 'ElyaNotes',
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        // In landscape, remove all system padding so content fills
        // the entire screen including the notch/cutout area.
        if (MediaQuery.of(context).orientation == Orientation.landscape) {
          return MediaQuery.removePadding(
            context: context,
            removeLeft: true,
            removeRight: true,
            removeTop: true,
            removeBottom: true,
            child: child!,
          );
        }
        return child!;
      },
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}
