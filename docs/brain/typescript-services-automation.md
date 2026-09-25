---
layout: default
title: "TypeScript Services & Automation"
shiori_source_id: "GjUoG9ePZ5"
---

# TypeScript Services & Automation

Shared guidance derived from Maomao, Shiori, Eru, Lain and related TypeScript/Node projects.

## Runtime and contracts
- Read the pinned Node/package-manager versions and CI commands before editing.
- Preserve strict type checking; avoid `any` and unchecked type assertions at trust boundaries.
- Validate webhook payloads, configuration, subprocess output and persisted data with explicit schemas.
- Model important workflows as explicit states and make illegal transitions impossible or rejected.

## Reproducible automation
- Resolve work against an exact commit SHA or immutable checkpoint.
- Make jobs idempotent: retries must not duplicate comments, reviews, artifacts or database records.
- Bound concurrency and resource usage.
- Persist enough state to resume safely after interruption.
- Separate orchestration, domain logic, adapters and presentation according to the repository's existing structure.

## Trust boundaries
- Treat checked-out repositories, model output and subprocess output as untrusted.
- Give workers only the permissions they need.
- Keep publication and external writes in the trusted orchestrator.
- Use least-privilege GitHub App permissions.
- Never expose secrets in environment dumps, command lines, logs, images or generated review text.
- Sanitize paths and reject attempts to escape the intended workspace.

## Quality
- Reuse existing utilities and UI components.
- Prefer small modules with clear ownership over broad helpers.
- Test state transitions, retries, duplicate delivery, malformed input and authorization failures.
- Run the repository's formatter, linter, type checker, unit tests and relevant integration tests.
- For browser behavior, test the user-visible outcome rather than implementation details.
