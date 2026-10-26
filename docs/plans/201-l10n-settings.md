# Plan: #201 slice 1 — l10n infrastructure + settings

Owner decision (2026-10-26, via architect): TR + EN for v1.0, one PR per screen
group, gen-l10n + ARB, a "no hardcoded strings" guard.

## Acceptance (this slice)
- `example_app/l10n.yaml`, `lib/l10n/app_en.arb` (template) + `app_tr.arb`, same keys
  and placeholders (test). Generated `lib/l10n/app_localizations*.dart` committed; CI
  fails on drift.
- `MaterialApp.router` registers `AppLocalizations.localizationsDelegates` /
  `supportedLocales`, no `locale:` → device decides; other locales fall back to en.
- No user-facing literal left in `lib/features/settings/presentation/**` (guard test;
  later slices add dirs to `migratedDirs`).
- Settings screen, privacy screen and settings dialogs: no overflow at text scale 1.3
  on a phone-size view, tr and en.
- Existing settings tests/goldens pass with locale pinned to tr.

## Design
- No Flutter SDK in agent sessions: `update-goldens.yml` also runs `flutter gen-l10n`
  and commits changed `pubspec.lock` files + `example_app/lib/l10n/*.dart` (even when
  golden tests fail). Dispatch with `ref=<branch>` while the branch changes the workflow.
- `l10n.yaml`: arb-dir lib/l10n, template app_en.arb, output app_localizations.dart,
  class AppLocalizations, `nullable-getter: false`, `generate: true` in pubspec.
- `intl: any` (flutter_localizations pins it), `flutter_localizations` sdk dep.
- Barrel `lib/l10n/l10n.dart`: exports generated file + `context.l10n` extension.
- Keys `settings*` / `common*`; Turkish uppercase headers stored uppercased in the ARB
  (`toUpperCase()` is not locale-aware: "Gizlilik" → "GIZLILIK").
- Test helper `test/helpers/l10n.dart` (`testLocale = Locale('tr')`, `localizedApp`).
- Guard: `test/helpers/hardcoded_strings.dart` scanner (Turkish chars in literals;
  literals after `Text(`, `title:`, `label:`, `tooltip:` …; `// l10n-ignore` opt-out).

## Left for later slices
Library (+ `DocumentDateFormatter` → `DateFormat`), editor (+ drawing_ui toolbar strings),
remaining dialogs. `timeago` 'tr' stays (AI chat frozen). English privacy policy text is
legal copy → owner. Android 13 per-app language: later.

## Reference check
GoodNotes, StarNote, Flexcil: UI language follows the system (or per-app system
setting); no in-app picker → we follow the device locale.
