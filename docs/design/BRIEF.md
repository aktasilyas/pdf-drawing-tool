# Design brief

Decided by the product owner on 2026-10-22. Change only with their approval.

## Direction: warm paper
A calm stationery feel. The page is the hero; chrome is quiet, rounded and
floating. Baseline apps (owner rule, 2026-10-23): GoodNotes, StarNote and Flexcil;
follow their conventions unless there is a stated reason (see CLAUDE.md).
Originality: never copy their icons, cover art or exact layouts.

## Decisions
| Area | Decision |
|---|---|
| Overall feel | Warm paper: slightly cream surfaces, soft hairline borders, low shadows |
| Accent | Ink blue, used only for selection, focus and primary actions |
| Typography | Serif for titles and notebook names (Source Serif 4), neutral sans for UI (Inter). Fonts bundled as assets, not fetched at runtime |
| Notebook covers | Solid colors with material textures (linen, leather, kraft, felt) in one consistent family |
| Iconography | Phosphor; regular weight in chrome, fill for selected state |

## Starting palette (to be validated with goldens in M2)
| Role | Light | Dark |
|---|---|---|
| background (behind pages) | #F4F1EA | #1B1A18 |
| surface (panels, toolbars) | #FBF9F4 | #242320 |
| surfaceElevated | #FFFFFF | #2D2B28 |
| border (hairline) | #E4DED2 | #3A3834 |
| textPrimary | #22201C | #ECE8E0 |
| textMuted | #6E685E | #A39D92 |
| accent (ink blue) | #2B4C7E | #8FAEDB |
| accentContainer | #DCE5F2 | #263548 |
| danger | #B3261E | #F2B8B5 |
| paper (default page) | #FFFDF8 | #F3EFE6 (pages stay light in dark mode) |

## Cover family (initial set)
Linen: sage, sand, slate. Leather: oxblood, cognac, navy. Kraft: natural, charcoal.
Felt: mustard, dusty rose. Title area: label plate in surface color, serif title.

## Open questions (ask before deciding)
- App name/wordmark treatment.
- Default pen set and colors shown on first launch.
