---
name: autopilot
description: Unattended backlog runner for scheduled routines - tends open agent PRs, then picks the next ready GitHub issue and ships it, and logs the run. Invoke as /autopilot.
---
# Autopilot

You run unattended. Nobody will answer questions during the run. Per run:
first tend every open agent PR that needs work (step 1), then ship up to TWO
issues (steps 3-4, one after the other), then log once and stop. Stop early
if you hit a usage limit or a decision you cannot make.

Runs can overlap. Lock what you work on: add label `in-progress` to an issue
or PR before touching it, remove it when done, and skip anything that already
has it unless that label is older than 3 hours (a crashed run).

GitHub: REST only via `gh api` (no GraphQL). `R=repos/aktasilyas/pdf-drawing-tool`.

## Allowed operations (the session's permission policy blocks the rest)
- Git: commit, `git merge origin/main`, plain `git push` of `claude/*` branches.
- GitHub API: read anything; create PRs, issue/PR comments, labels.
- Never: rebase or amend pushed commits, force-push, push to `main`, merge or
  close PRs, delete branches, change repository settings.
- If any action is denied: do not retry it or try another route. Note it in the
  log and continue with the next step of this skill.
- The VM is discarded after the run. Never clean, reset, checkout or stash files
  to tidy up; leftover uncommitted files are harmless. Only commit what the task needs.

## Decide before asking
Ask the owner (`needs-decision`) only for product or business choices
(scope, naming, visuals, money, accounts). Technical choices are yours: weigh
the options against CLAUDE.md and the `architect` subagent, pick the one that
keeps the codebase on current stable tooling with the least churn, explain it
in the PR, and proceed. Before proposing options, search for a maintained
replacement or upstream fix.
Find the status issue: `gh api "$R/issues?labels=autopilot-status&state=open"`.

## 1. Tend open agent PRs first
List open PRs whose head branch starts with `claude/`:
`gh api "$R/pulls?state=open&per_page=50"`.
For each, newest first (skip PRs already labeled `ready-to-merge` unless they
got new commits, conflicts or review comments since; review comments from the
architect desk count the same as the owner's):
- **Behind main**: not a problem; do nothing. GitHub merges it as is.
- **Conflicts with main** (`gh api $R/pulls/<n>` → `mergeable` is false):
  `git merge origin/main` into the branch, resolve, re-verify, normal `git push`, then continue.
- **Failing checks** (`gh api $R/commits/<head_sha>/check-runs`): compare with the
  same check names on main's HEAD. A check that also fails on main is pre-existing;
  ignore it. Otherwise fix the failure (use `systematic-debugging`), push, continue.
- **Review comments** (`gh api $R/pulls/<n>/comments` and
  `$R/issues/<n>/comments` newer than the last commit) → address them, push,
  reply on each thread, then continue with the next PR.
- **Ready**: if every check is green or pre-existing-failing and the `reviewer`
  subagent (already run when the PR was opened; re-run only after new commits)
  found nothing blocking, add label `ready-to-merge` to the PR and list
  it in the log. Never merge, and never try another way to merge: merging is
  the owner's step (the session's permission policy blocks it).

## 2. Throttle
If 4 or more `claude/` PRs are open and labeled `ready-to-merge`, start no new
work: log "waiting for owner review" with the PR list and stop.

## 3. Pick the next issue
Open issues with label `agent-ready` and without `in-progress`/`in-review`:
`gh api "$R/issues?state=open&labels=agent-ready&per_page=100"` (skip PRs).
Skip any whose body has `Depends on: #a, #b` with an open dependency.
Order: milestone title (M0b < M1 < M2 < M3 < M4 < M5), then lowest number.
If none is eligible, log "queue empty or blocked" with the reason and stop.

## 4. Ship it
- Add label `in-progress` (`gh api -X POST $R/issues/<n>/labels -f "labels[]=in-progress"`).
- Follow the `ship-issue` skill for issue <n>.
- If you hit a decision you cannot make (see "Decide before asking"): label
  `needs-architect` as described there, log it, stop.
- If the work is too big for one run, open a draft-quality PR with what is done
  and verified, list the remaining steps in the PR body, keep the issue open.
- Always run the `reviewer` subagent before labeling a PR `ready-to-merge`.
- On success: remove `in-progress`, add `in-review`. Then, if this run has
  shipped only one issue so far, go back to step 3 for one more.

## 5. Log the run
Comment on the status issue, in Turkish, at most 8 lines:
what you did (issue/PR links), PRs waiting for the owner, questions asked,
anything that failed. If nothing happened, say why in one line.
