---
name: ship-issue
description: End-to-end delivery of one GitHub issue - plan, implement test-first, verify, review, open PR. Invoke as /ship-issue <issue-number>.
disable-model-invocation: true
---
Deliver GitHub issue #$ARGUMENTS for Elyanotes.

1. `gh issue view $ARGUMENTS` — read the issue and its acceptance criteria.
   If there are no clear criteria, write them as a comment on the issue
   (`gh issue comment`) and continue with those.
2. Branch from fresh main: `git fetch origin main && git switch -c <type>/<issue>-<slug> origin/main`.
3. Size the work:
   - Small (one sentence diff, ≤3 files): implement directly.
   - Otherwise: ask the `architect` subagent for a plan, save it to
     `docs/plans/<issue>-<slug>.md`, then hand each step to the `implementer`
     subagent in order (see `subagent-driven-development`).
4. Verify: `melos analyze` and tests for every touched package must pass.
   Paste the command output summary — no claims without evidence.
5. Ask the `reviewer` subagent to review `origin/main...HEAD` against the issue.
   Fix blocking findings, re-verify.
6. Commit (`type(scope): message`, reference `#<issue>`), push, and open the PR
   with `gh pr create` — body: summary, acceptance-criteria checklist, test evidence,
   `Closes #<issue>`.
7. Reply to the user in Turkish with the PR link and anything left open.
