---
layout: default
title: "Shared Architecture — Start Here"
shiori_source_id: "j4IXQ9l6wz"
---

# Shared Architecture

This is the publication root for Dragonshorn Studios' shared coding-agent brain.

AFFiNE is the source of truth. Shiori exports only this document and same-workspace documents linked from it. Repository-local `AGENTS.md`, project rules and the current user request take precedence over these shared defaults.

## Shared baseline
- [Agent Engineering Contract](agent-engineering-contract.md))
- [Security, Trust Boundaries & Human Approval](security-trust-boundaries-human-approval.md))
- [Testing, Review & Delivery](testing-review-delivery.md))

## Stack guidelines
- [Laravel & PHP Applications](laravel-php-applications.md))
- [Go Services & CLIs](go-services-clis.md))
- [TypeScript Services & Automation](typescript-services-automation.md))
- [Python Services & MCP Apps](python-services-mcp-apps.md))

## Migrated workflow skills
- [Skill — Stacked PR Workflow](skill-stacked-pr-workflow.md))
- [Skill — Comprehensive PR Review](skill-comprehensive-pr-review.md))

## Installation
- [Skill Installation Guide](skill-installation-guide.md))

## Publishing contract

Documents tagged `skill` are emitted as installable skills for Codex-compatible agents, Claude Code, Cursor, Windsurf, Vibe, Devin and ZCode. Keep private or unfinished notes outside this linked graph.

To publish another document:
1. Place it in the Shared Architecture folder for human organization.
1. Add a same-workspace link to it from this root or from another linked document.
1. Add the `skill` tag only when it should become an installable agent skill.
1. Optionally set the `shiori-icon` text property to an approved absolute PNG, JPEG or WebP URL.
