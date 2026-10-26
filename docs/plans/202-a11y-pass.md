# #202 — Accessibility pass: semantics labels, 48dp targets, 1.3x text scale

Milestone M4 (Android release). Scope: library, settings and the shared
component layer in `example_app`. The editor chrome already satisfies the
criteria (`ChromeIconButton` labels every control and
`packages/drawing_ui/test/screens/editor_chrome_layout_test.dart` runs
`androidTapTargetGuideline` on tablet and phone), so it is verified, not
rewritten.

## Reference check (owner rule)

| | Screen-reader labelling | Large text |
|---|---|---|
| GoodNotes | Toolbar and library chrome labelled for VoiceOver; the canvas itself is not screen-reader navigable (AppleVis reports, open feature requests for reading handwriting aloud) | Follows system text size on list/settings surfaces |
| Flexcil | No published accessibility statement; no documented screen-reader support | Follows system text size |
| StarNote | No published accessibility statement | Follows system text size |
| **Elyanotes** | Label all chrome, library and settings controls; the ink canvas stays unlabelled (a stroke surface has no useful node) | Library and settings must lay out at 1.3x |

Converging on the pattern the three share, with one deviation: we enforce it
with automated guideline tests, because Android is our first release target
and the Play pre-launch report flags small tap targets.

## What was missing

- `AppIconButton` wrapped its content in a `Tooltip` only: the label node and
  the inner `InkWell` button node were two separate nodes, so a screen reader
  focused an unlabelled button.
- Two call sites passed no tooltip at all (`move_to_folder_dialog`,
  `manage_folders_screen`), and `AppModal` built raw `IconButton` closes.
- Icon-only `GestureDetector`s in the library (tile covers, favourite badges,
  the trashed-page thumbnail) exposed a tap action with no label.
- `example_app` had no tap-target guideline test and no screen-level
  large-text test.

## Steps

1. `AppIconButton`: one `Semantics(button, label, excludeSemantics)` node
   around the whole button, a `semanticLabel` override, and an assert that
   a label exists. Variant widgets moved to `app_icon_button_variants.dart`
   (`part`) to stay under the 300-line limit.
2. Missing labels: `'Kapat'` in `move_to_folder_dialog`, `'Geri'` in
   `manage_folders_screen`, and a shared `_ModalCloseButton` in `AppModal`.
3. Library: labelled button nodes for tile covers (`LibraryTileFrame`
   `semanticLabel`, fed with the document title / folder name), favourite
   badges (`'Favorilerden çıkar'`) and the trashed-page thumbnail.
4. Settings: the account name row becomes a labelled button with a 48dp
   minimum height (it only renders with cloud sync on).
5. Tests: `test/helpers/a11y.dart` (guideline reporter ported from
   `drawing_ui`, text-scale and overflow helpers), component semantics tests,
   library and settings guideline + 1.3x tests, tile semantics tests.
6. Back navigation: documented below and guarded by
   `test/core/routing/back_navigation_test.dart`.

## Back navigation matrix

Every route in `core/routing/app_router.dart` is top level (no nested
`ShellRoute`), so GoRouter's back stack is the push order.

| Route | System back / app back |
|---|---|
| `/` (splash) | Replaced by `/documents`; never on the stack |
| `/documents` | Nothing to pop → exits the app (Android default). The sidebar and folder breadcrumbs are in-screen state, not routes |
| `/folder/:id` | Pops to `/documents` |
| `/manage-folders` | Pops to `/documents`; the header back button calls `context.pop()` |
| `/settings` | Pops to the previous screen; the header close button calls `maybePop()` |
| `/settings/privacy` | Pops to `/settings` |
| `/editor/:id`, `/new-document` | `PopScope` in `editor_leave_guard.dart` intercepts back, flushes the session and then pops. On a load error the view falls back to `go('/documents')` when there is nothing to pop |
| `/template-selection` | Pops to the caller |
| auth / paywall routes | Only exist behind frozen flags; out of v1.0 scope |

`PopScope` is intentionally used in exactly one place: unsaved ink is the only
state that cannot survive an unguarded pop. Everything else is persisted
before navigation, so the platform default is the correct behaviour.

## Deliberately out of scope

- Localisation: labels are Turkish, matching the rest of the UI (the issue
  says "Turkish for now").
- `features/ai`, `features/premium`, `features/sync` and `features/auth`
  screens: frozen behind flags until after v1.0.
- Canvas / stroke semantics (see the reference check).
- `textContrastGuideline` on the library: decorative covers would fail it;
  contrast is a `ui-designer` review matter.
