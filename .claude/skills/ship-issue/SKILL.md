---
name: ship-issue
description: End-to-end delivery of one GitHub issue - plan, implement test-first, verify, review, open PR. Invoke as /ship-issue <issue-number>.
---
Deliver GitHub issue #$ARGUMENTS for Elyanotes.

GitHub access: use `gh api` (REST) only. GraphQL (`gh issue view`, `gh pr create`)
is not available in cloud sessions. `R=repos/aktasilyas/pdf-drawing-tool`.

1. Read the issue: `gh api $R/issues/<n>` and its comments `gh api $R/issues/<n>/comments`.
   If acceptance criteria are missing, write them as a comment and continue with them.
2. Branch from fresh main: `git fetch origin main && git switch -c claude/<n>-<slug> origin/main`.
3. Size the work:
   - Small (one-sentence diff, ≤3 files): implement directly.
   - Otherwise: ask the `architect` subagent for a plan, save it to
     `docs/plans/<n>-<slug>.md`, then hand each step to the `implementer`
     subagent in order (see `subagent-driven-development`).
   - UI work: follow `design-loop` (spec from `ui-designer`, goldens, review).
4. Verify: `./scripts/check.sh analyze <pkg>` and `./scripts/check.sh test <pkg>`
   for every touched package must pass. Keep the output summary for the PR.
5. Ask the `reviewer` subagent to review `origin/main...HEAD` against the issue.
   Fix blocking findings, re-verify.
6. Commit (`type(scope): message`, reference `#<n>`), push, and open the PR:
   write the body to a file, then
   `gh api $R/pulls -f title="<title>" -f head=claude/<n>-<slug> -f base=main -F body=@/tmp/pr.md`.
   Body: summary, acceptance-criteria checklist, test evidence, `Closes #<n>`.
7. Report in Turkish: PR link and anything left open.
