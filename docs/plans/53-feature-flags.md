# Plan: compile-time feature flags (#53)

Flags (`--dart-define`): FF_AI_CHAT, FF_CLOUD_SYNC, FF_PREMIUM, FF_AUDIO_RECORDING. Default all off (release).

## Design
- `example_app/lib/core/config/feature_flags.dart`: immutable `FeatureFlags` (allOff/allOn, `fromEnvironment`, `needsSupabase = aiChat || cloudSync`) + `featureFlagsProvider` (tests override it).
- `core/config/app_env.dart`: `String.fromEnvironment` for Supabase/RevenueCat keys, `validateFor(flags)` fails fast.
- Drop `flutter_dotenv` and the `.env` asset (a missing declared asset breaks the build); CI placeholder `.env` step removed. Dev: `flutter run --dart-define-from-file=.env`. CLAUDE.md "Commands" line needs an owner update (agents must not edit it).
- `core/bootstrap/app_bootstrap.dart`: Supabase init only if needsSupabase, RevenueCat only if premium; injectable initializers for tests.
- Premium off => `FeatureGateService.unrestricted()`, no RevenueCat access.
- drawing_ui gets `aiAssistantEnabledProvider` / `audioRecordingEnabledProvider` (default true), set from flags in app overrides.

## Steps
1. Flags, env, bootstrap, premium, pubspec/CI, tests.
2. Router (auth/paywall routes conditional), splash, settings, editor AI gating, tests.
3. drawing_ui toggles (AI button, selection 'ai' action, mic buttons, recording bar, recordings chip), tests.

Every entry point is tested in both flag states.
