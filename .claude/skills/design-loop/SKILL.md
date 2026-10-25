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
   - **No working SDK** (cloud session whose proxy blocks the engine download):
     push the branch, then dispatch the `Update goldens` workflow:
     `gh api -X POST repos/aktasilyas/pdf-drawing-tool/actions/workflows/update-goldens.yml/dispatches -f ref=main -f "inputs[branch]=claude/<n>-<slug>" -f "inputs[package]=packages/drawing_ui"`
     (`package` is `packages/drawing_ui` or `example_app`; only `claude/*` branches
     are accepted). Find the run with
     `gh api "repos/aktasilyas/pdf-drawing-tool/actions/workflows/update-goldens.yml/runs?branch=main&per_page=1"`,
     wait until it completes, then `git fetch origin <branch> && git merge origin/<branch>`
     and Read the committed CI goldens. It commits
     `test(golden): regenerate goldens [workflow]` and dispatches CI on the branch
     itself (a `GITHUB_TOKEN` push does not trigger CI). Platform goldens (real
     fonts) are only in the run's `goldens-<run_id>` artifact.
4. **Look**: Read the generated platform-golden PNGs. Then ask the
   `ui-designer` agent to review the same files against the spec.
5. **Fix** the ranked findings, re-render, re-review. Stop when the reviewer
   says "approved" or after 3 rounds (then list what is left for the user).
6. **Report** to the user with the final PNG paths so they can see them; in a
   PR, mention which goldens changed.

Never update goldens just to make a failing test pass without looking at the
diff image; an unexpected golden change is a bug until proven otherwise.
