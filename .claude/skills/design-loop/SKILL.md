---
name: design-loop
description: Visual iteration loop without a device - render widgets to golden PNGs, look at them, critique with the ui-designer agent, fix, repeat. Use for any UI build or restyle task.
---
# Design loop (golden-driven)

Claude can read PNG files as images, so golden tests double as screenshots.

1. **Spec**: get a spec from the `ui-designer` agent (or the issue) before coding.
2. **Golden test first**: write a golden test for the widget/screen covering
   light/dark × phone (390×844) / tablet (1180×820) × key states.
   - Use the `alchemist` package (add as dev_dependency when first needed).
     CI goldens (font-agnostic) are committed; platform goldens with real fonts
     are for local review and are git-ignored.
   - Wrap the widget in the real `AppTheme` so tokens apply.
3. **Render**: `flutter test --update-goldens <test file>` in the package.
4. **Look**: Read the generated platform-golden PNGs. Then ask the
   `ui-designer` agent to review the same files against the spec.
5. **Fix** the ranked findings, re-render, re-review. Stop when the reviewer
   says "approved" or after 3 rounds (then list what is left for the user).
6. **Report** to the user with the final PNG paths so they can see them; in a
   PR, mention which goldens changed.

Never update goldens just to make a failing test pass without looking at the
diff image; an unexpected golden change is a bug until proven otherwise.
