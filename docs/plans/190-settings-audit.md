# #190 Settings audit and fixes

## Reference check
- **GoodNotes**: Settings holds appearance (dark mode), stylus/palm rejection, documents
  defaults, backup/sync, Support (help, contact) and About (version, privacy policy, terms,
  acknowledgements).
- **Flexcil**: appearance (dark mode), pen/touch input (pen-only mode), backup, help/feedback,
  About (version, legal).
- **StarNote**: theme, pen settings, cloud backup, feedback, privacy policy / terms.
- **Converged pattern → what we do for v1.0**: appearance + privacy toggles + About with version,
  privacy policy, open-source licences and a feedback contact. Backup/sync and account entries are
  frozen features (hidden with flags off). Stylus-only / palm rejection is not implemented in the
  ink engine yet, so it has no entry here (gap noted on the issue). No terms-of-use document exists,
  so that entry is removed rather than left as a dead link.

## Audit (flags off, before this change)
| Entry | Should do | Status | File |
|---|---|---|---|
| Header name tap | edit account name | no-op (TODO), shown even without account | `settings_screen.dart` |
| Tema | app theme, persisted | works, but loaded async → light flash after restart | `settings_provider.dart` |
| Canvas teması | canvas light/dark/follow app, persisted | works (sync prefs) | `canvas_theme_setting.dart` |
| Favorileri üste sabitle | pin favourites, persisted | works | `document_view_preferences_providers.dart` |
| Dışa aktar | — | "yakında" toast | `settings_dialogs.dart` |
| Önbelleği temizle | — | no-op with fake success toast | `settings_dialogs.dart` |
| Çökme raporları | opt-out, persisted | works | `crash_reporting_setting.dart` |
| Versiyon | real app version | hardcoded `1.0.0 (1)` | `settings_screen.dart` |
| Gizlilik politikası | show policy | "yakında" toast | `settings_dialogs.dart` |
| Kullanım koşulları | show terms | "yakında" toast, no terms exist | `settings_dialogs.dart` |
| Licences / contact | required by #190 | missing | — |
| Hesap / Çıkış | cloud only | hidden with flags off (works) | `settings_screen.dart` |

## Changes
1. `SettingsNotifier` reads the bootstrapped `SharedPreferences` synchronously (no theme flash);
   corrupt JSON falls back to defaults.
2. Header: title "Ayarlar" + close when there is no account; avatar/name only with cloud on.
3. Remove Dışa aktar, Önbelleği temizle, Kullanım koşulları (and the empty VERİ section).
4. About: version from `appBuildName`/`appBuildNumber` (embedded by `flutter build`, no new
   dependency), in-app privacy policy from a bundled Markdown asset (Turkish section of
   `docs/store/privacy-policy.md`, drift guarded by a test), `showLicensePage`, feedback e-mail
   copied to the clipboard.
5. No new packages: pub.dev is unreachable from agent sessions, so `package_info_plus` /
   `url_launcher` cannot be added with a valid lockfile. Opening the mail app directly can follow
   with `url_launcher` later.
6. Tests: provider unit tests, widget test per entry, goldens (phone/tablet × light/dark, About,
   privacy policy).
