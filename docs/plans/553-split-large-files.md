# #553 Split four v1.0 files under 300 lines

Pure refactor; each split follows an existing seam. No behaviour, API or golden change.

| File (lines before → after) | Seam | New file |
|---|---|---|
| `drawing_ui/.../screens/drawing_screen.dart` (321 → 296) | Tablet side panels and phone drawers become list builders spread into the same `Row`/`Stack` slots (same widget types and order, so the element tree is unchanged) | `screens/drawing_screen_sidebars.dart` |
| `drawing_ui/.../canvas/secondary_canvas_view.dart` (308 → 278) | Private last-page placeholder widget moved out as `LastPagePlaceholder` (not exported from the barrel) | `canvas/last_page_placeholder.dart` |
| `example_app/.../providers/documents_controller.dart` (310 → 230) | PDF import (`createDocumentWithPages` + ghost cleanup) becomes a mixin, like the existing bulk / page-trash / empty-trash mixins | `providers/documents_controller_import.dart` |
| `example_app/.../widgets/documents_content_view.dart` (319 → 253) | Grid/list switcher and the preference-driven sort shared by the folder and favourites views | `widgets/documents_view_mode_switcher.dart` (exported from `documents.dart`) |

Verification: `./scripts/check.sh analyze`, drawing_ui + example_app tests, goldens unchanged (CI; no Flutter SDK in the cloud session).
