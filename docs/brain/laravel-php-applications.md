---
layout: default
title: "Laravel & PHP Applications"
shiori_source_id: "D0XZ3Q7LJQ"
---

# Laravel & PHP Applications

Shared guidance derived from Rika, Yomiko and related Dragonshorn Laravel applications.

## Discover the project first
- Read `AGENTS.md` and, when present, `.ai/rules/index.md` plus the rule files matching the task.
- Confirm framework and package versions with Composer and `package.json`; do not assume the newest Laravel API.
- Follow neighboring controllers, actions, jobs, resources, tests and frontend components before introducing a pattern.

## PHP and Laravel style
- Use explicit parameter and return types.
- Prefer constructor property promotion for dependencies.
- Always use braces for control flow.
- Use descriptive names and TitleCase enum cases unless local code says otherwise.
- Prefer Laravel facilities over custom infrastructure: validation requests, policies, events, queues, resources and named routes.
- Use Eloquent relationships and query scopes; avoid raw queries unless the existing code or measured performance requires them.
- Prevent N+1 queries with deliberate eager loading.
- For APIs, preserve existing versioning and resource conventions.

## Generating and changing code
- Use the repository's Laravel environment and Artisan generators with `--no-interaction`.
- Do not hand-edit generated service wiring or environment files when the local toolchain owns them.
- Do not add packages or new architectural layers without approval.
- Keep controllers thin when the repository already uses actions or services.
- Reuse existing Blade, Livewire, Inertia or Vue components rather than duplicating UI.

## Verification
- Behavior changes need focused Pest/PHPUnit feature tests using factories and states.
- Cover success, validation, authorization and meaningful failure paths.
- Project-local rules decide whether copy-only or layout-only changes require new tests.
- Run the narrowest relevant test first, then the broader suite required by the repository.
- Format changed PHP with the repository's Pint command, commonly `vendor/bin/pint --dirty --format agent`.
- Check browser-visible changes in the project's supported runtime when feasible.

## Durable knowledge

If a fix reveals a reusable project rule, add it to the repository's canonical instruction system instead of leaving the knowledge only in a PR discussion.
