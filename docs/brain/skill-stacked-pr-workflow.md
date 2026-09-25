---
layout: default
title: "Skill — Stacked PR Workflow"
shiori_source_id: "zUln8DRF4P"
---

> Source: [Rughalt/coding-agent-plugins](https://github.com/Rughalt/coding-agent-plugins)

> Implements a list of issues as a stack of dependent PRs. Plans the stack, then for each issue implements, reviews sequentially until clean, opens a PR, monitors CI, and moves to the next. Ends with a report and offers to file deferred low-severity findings as follow-up tickets. Arguments are issue numbers/URLs or a gh issue filter.

# Stacked PR Workflow

Work through a list of issues as a stack of dependent PRs, one PR per&#10;issue, in order. This is a strict protocol — follow the phases exactly,&#10;respect every STOP, and never improvise the order.

**Input:** "$ARGUMENTS" — issue numbers (`#12 #13`), URLs, or a filter for&#10;`gh issue list` (e.g. `--label bug`). If empty, run `gh issue list` and ask&#10;the user which issues to include.

**State directory:** `.git/stack-pr/` in the repo. It is never committed&#10;and survives interruptions — if this session restarts mid-stack, read&#10;`plan.md` and `state.md` there and resume from the first incomplete item.

---

## Hard rules (never violate)
1. One issue = one branch = one PR. No scope creep. Anything noticed but&#10;out of scope goes to `.git/stack-pr/deferred.md`, not into the diff.
1. **Sequential only.** Finish each phase fully before starting the next.&#10;Never run reviews in parallel. Never start issue N+1 before PR N is&#10;opened and its CI is green or explicitly waived by the user.
1. **Never force-push.** To update a stack branch after its base changed,&#10;merge the base branch into it (`git merge <base>`), never rebase -i or&#10;`push --force`. Rebase only if the user explicitly asks.
1. **Never merge, close, or mark PRs ready-for-review/draft.** You open&#10;PRs; humans merge them.
1. **Never commit secrets, .env files, or credentials.** Check `git diff --cached` before every commit.
1. **Every STOP below is mandatory.** Ask the user and wait for an answer.
1. If `gh` is missing, unauthenticated, or an issue can't be fetched —&#10;stop immediately and report; do not guess issue contents.
1. Commits must pass the project's own checks (lint/typecheck/tests) run&#10;locally before opening each PR. Find them in [AGENTS.md/README/CI](http://AGENTS.md/README/CI) config;&#10;if you can't determine them, ask once at the start.

## Severity rubric (used by the review loop)
- **CRITICAL** — breaks production, data loss, security hole, silent&#10;failure (swallowed error), broken build/tests.
- **HIGH** — real bug, missing error handling on a failure path, wrong&#10;contract/edge case, missing test for new behavior.
- **MEDIUM** ("yellow") — incomplete error context, unclear naming that&#10;hides intent, missing edge-case test, comment that contradicts code.
- **LOW** — style nits, optional simplifications, nice-to-have docs.
- **INFO** — observations, suggestions for future work.

A PR may only ship when a review round reports **zero CRITICAL, HIGH, and&#10;MEDIUM** findings. Remaining LOW/INFO items are appended to&#10;`.git/stack-pr/deferred.md` under the PR's heading — do not fix them&#10;unless they are one-line trivial (then fix and note it).

---

## Phase 0 — Setup
1. `git status` must be clean and on the default branch; `git pull`.&#10;If dirty or on a branch → STOP and ask whether to stash/continue.
1. Verify `gh auth status`. Fail → stop.
1. Create `.git/stack-pr/` and write `state.md` with a checklist of the&#10;issues and columns: branch, PR #, review rounds, CI, status.

## Phase 1 — Plan the stack
1. Fetch every issue: `gh issue view <n>`. Record title + acceptance&#10;criteria. If any fetch fails → stop.
1. Order issues so each PR builds only on earlier ones. If issues are&#10;independent, keep the user's order. If ordering is ambiguous → present&#10;options and STOP for a decision.
1. Write `.git/stack-pr/plan.md`: numbered table — issue, title, branch&#10;name `stack/<NN>-<slug>`, base branch, one-line approach.
1. Present the plan to the user and **STOP for approval**. Do not write&#10;code before approval.

## Phase 2 — Per-issue loop (repeat in stack order)

For each issue:
1. **Branch:** `git checkout -b stack/<NN>-<slug> <base>` where `<base>`&#10;is the previous stack branch, or the default branch for the first.
1. **Implement** only what the issue requires.
1. **Local checks:** run the project's lint/typecheck/tests. Fix failures&#10;before proceeding.
1. **Review loop** (max 3 rounds, sequential):
- If the `pr-review-toolkit` agents are installed (bare names or&#10;`pr-review-toolkit:*` — whatever the tool exposes), delegate one&#10;review round to `code-reviewer`, then `silent-failure-hunter`, then&#10;`pr-test-analyzer` (and `comment-analyzer`/`type-design-analyzer`&#10;when relevant), each with the diff as scope.
- Otherwise review the diff yourself against the rubric above, in&#10;this order: correctness → error handling/silent failures → tests →&#10;comments → types → simplicity.
- Fix every CRITICAL/HIGH/MEDIUM. Trivial LOWs may be fixed inline;&#10;the rest go to `deferred.md` under `## PR <N> — <title>`.
- Re-run the review until a round reports no CRITICAL/HIGH/MEDIUM.
- After 3 dirty rounds → STOP, summarize remaining findings, ask the&#10;user how to proceed.
1. **Commit & push:** conventional commit message referencing the issue&#10;(`Fixes #<n>` in the PR body, not the commit). `git push -u origin`.
1. **Open PR:** `gh pr create --base <base-branch>` — base is the previous&#10;stack branch (or default branch for the first). Body: summary, `Fixes #<n>`, and a `Stack: <i> of <N>, depends on #<prev-pr>` line.
1. **CI:** `gh pr checks <pr> --watch` (or poll `gh pr checks` every 60s,&#10;up to \~30 min). Failure → inspect logs, fix, push, re-watch — max 2&#10;fix attempts, then STOP and report. Pending too long → ask the user&#10;whether to wait or continue.
1. **Record:** update `state.md` (PR number, status), then continue to the&#10;next issue.

## Phase 3 — Report

When the last PR is open and green:

``` markdown
## Stack complete — <N> PRs

| # | PR | Issue | Status | Deferred lows |
|---|----|-------|--------|---------------|
| 1 | #101 | #12 | CI green | 2 |

### Deferred findings (.git/stack-pr/deferred.md)
- PR #101: <item> [file:line]
...

Recommended merge order: #101 → #102 → #103 (bottom-up).
```

Then ask: **"File the deferred LOW items as follow-up GitHub issues?"**&#10;Only on an explicit yes, `gh issue create` one issue per PR's deferred&#10;group (title: `Follow-up: <pr title> — review leftovers`, body from&#10;[deferred.md](http://deferred.md)), and link them in the report. Anything but clear yes → skip.
