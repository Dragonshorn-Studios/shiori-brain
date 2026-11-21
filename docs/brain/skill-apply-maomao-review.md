---
layout: default
title: "Skill — Apply Maomao Review"
shiori_source_id: "K_U9u5tVOS"
---

> After a maomao pull-request review, apply the comments, reply to every unresolved maomao thread, push, and wait for the next review round — without further human clicking. Use when asked to handle, apply, or clean up a maomao review. Arguments are a PR number or URL.

# Apply Maomao Review

Work through unresolved review threads from **maomao** (the team's bot reviewer) on one pull request. Follow the loop exactly. Do not treat human review comments as maomao threads.

**Input:** "$ARGUMENTS" — PR number (`#87`) or URL. If empty, use the open PR for the current branch, or ask once.

## Hard rules (never violate)
1. **Never merge**, close, or change the PR's draft/ready state. You apply comments; humans merge.
2. **Never post, push, or comment as Szefowa's personal GitHub account.** Use the project's usual coding-agent GitHub identity.
3. **Never put secrets**, tokens, credentials, or `.env` values in comments, commits, or the follow-up issue.
4. In each working round, **resolve every unresolved maomao thread**, including ones you did not change, each with a short reply.
5. After three rounds, **do not resolve** remaining threads that are medium or higher.
6. If `gh` is missing, unauthenticated, or the PR cannot be fetched — stop and report; do not guess.

## Severity — what to change
- **Low, medium, high, or critical:** apply the fix.
- **Info:** apply only if the change is clearly correct and in scope. Otherwise leave the code and explain why in the reply.

If maomao did not label severity, infer it from the comment. Apply when it is clearly a defect; otherwise treat it as info.

## Round loop (maximum 3 working rounds)

A **working round** is: read the current unresolved maomao threads → apply changes → run local checks if the code changed → commit and push to the PR branch → reply to and resolve every thread from that review → wait for maomao's next review.

Stop early if a new maomao review has no unresolved threads.
1. Identify the PR and check out its head branch. `git status` should be clean on that branch.
2. Collect **unresolved** review threads authored by maomao only.
3. Apply fixes per the severity rules above. Stay in scope; do not drive-by refactor.
4. If you changed code, run the project's existing lint, typecheck, and tests. Fix failures before pushing.
5. Commit (conventional message, no secrets) and `git push` to the PR branch. Never force-push unless the user explicitly asks.
6. Reply to **every** unresolved maomao thread, then resolve it. If fixed: say what changed and include the commit SHA. If not fixed: say why not (disagreed, out of scope, info skipped, already covered) and still resolve it. Keep replies short. No secrets.
7. Wait for maomao's next review. Do not start the next working round until it arrives.

If this was the third working round, go to **After 3 rounds** instead of starting a fourth.

## After 3 rounds

When the review that follows the third push arrives (or you have completed three working rounds and no further review is coming):
- **Any medium, high, or critical findings remain:** stop. Do not apply a fourth round. Do not resolve those remaining threads. Leave a short summary for Szefowa: what is still open, where, and why you stopped. Do not merge.
- **Only low and/or info remain:** open **one** follow-up issue in the same repository listing each leftover item (file, thread, severity, summary). Then resolve each of those remaining comments with a short reply that links the issue. Do not merge.
- **Nothing remains:** report that the loop is clean. Do not merge.

## Report

After stopping, report: PR, rounds completed, what was applied, threads resolved, the follow-up issue if any, and any remaining medium-or-higher findings left open.
