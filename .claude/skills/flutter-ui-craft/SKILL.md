---
name: flutter-ui-craft
description: Visual quality bar for Elyanotes Flutter UI - typography, spacing rhythm, color, depth, motion, tablet layouts, and how to avoid the stock Material look. Use when designing, building, or reviewing any widget or screen.
---
# Flutter UI craft

The app should feel like a calm, premium paper tool: content (the page) is the
hero, chrome is quiet and gets out of the way.

## Typography
- One display/serif family for titles and notebook names, one neutral sans for
  UI; at most two families plus the handwriting fonts for content.
- Use the type scale from `AppTypography` roles (display, title, body, label,
  caption). Never set `fontSize` inline.
- Tighten letter-spacing on large titles (−0.5% to −1.5%), loosen small caps labels.
- Numbers in lists/toolbars use tabular figures (`FontFeature.tabularFigures()`).

## Spacing and layout
- 4dp grid via `AppSpacing`. Group related items with smaller gaps than
  unrelated ones; rhythm beats uniform padding.
- Tablet is the primary canvas: use the width (side panels, two-pane library,
  floating toolbars) instead of stretched phone layouts. Max readable line
  length ~70 characters.
- Touch targets ≥ 48dp even when the visual is smaller (pad the hit area).

## Color and depth
- Neutral, slightly warm surfaces; one accent used sparingly for selection
  and primary actions. Ink colors are content, not chrome.
- Depth through subtle elevation tokens and 1px hairline borders, not heavy
  shadows. Dark mode is designed, not inverted: lower contrast surfaces, no
  pure black behind the page.

## Components
- Floating, rounded toolbars and panels over the canvas; panels dismiss on
  outside tap; never cover the area being written on.
- Icons: Phosphor, one weight per context (regular in chrome, fill for selected).
- Avoid stock Material tells: default ripple color on everything, AppBar with
  shadow, FAB on the canvas screen, `Card` default elevation, blue default accent.

## Motion
- 150–250 ms for UI feedback, ease-out for entering, ease-in for exiting;
  durations from `AppDurations`. Tool switches and panel open/close animate;
  drawing itself never waits for an animation.

## Notebook covers
- Covers are original artwork in a consistent family (shape language, palette,
  texture). Thumbnails must read at 120dp wide; titles never on top of busy art.

## Done means
Goldens exist for light/dark × phone/tablet and the `ui-designer` agent has
reviewed the rendered images (see `design-loop`).
