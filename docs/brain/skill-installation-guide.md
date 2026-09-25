---
layout: default
title: "Skill Installation Guide"
shiori_source_id: "pULFwF62YI"
---

# Installing Dragonshorn Skills

The canonical source is [Dragonshorn-Studios/shiori-brain](https://github.com/Dragonshorn-Studios/shiori-brain). AFFiNE owns the content; Shiori publishes the generated skills and marketplaces. Do not install from or link to the retired personal coding-agent repositories.

## Choose the scope
- **Project scope (recommended):** copy the generated directory for your agent into the target repository and commit it. Cloud agents and teammates then receive the same version.
- **Personal scope:** copy the generated skills into the matching user-level skills directory. Use this only for private workstation defaults.
- **Marketplace/plugin scope:** use the generated marketplace or plugin package where the agent supports it.

Review generated instructions before enabling them. Repository-local rules and the current user request still take precedence.

## Clone the brain

``` bash
git clone https://github.com/Dragonshorn-Studios/shiori-brain.git
```

Pull the repository again whenever AFFiNE content is synchronized.

## Project-scoped installation

Copy the directory matching the target agent into the root of the application repository:

| **Agent** | **Source in shiori-brain** | **Destination in the application** |
| --- | --- | --- |
| Codex and Agent Skills-compatible tools | `.agents/skills/` | `.agents/skills/` |
| Claude Code | `.claude/skills/` | `.claude/skills/` |
| Cursor | `.cursor/skills/` | `.cursor/skills/` |
| Windsurf | `.windsurf/skills/` | `.windsurf/skills/` |
| Vibe | `.vibe/skills/` | `.vibe/skills/` |
| Devin | `.devin/skills/` | `.devin/skills/` |

Commit the copied directories so local and cloud agents use the same skills.

## Codex

For a project, copy `.agents/skills/` into the project root. Codex discovers each folder containing a `SKILL.md`. Invoke a skill explicitly with `$skill-name`, or let Codex select it when the request matches its description.

For personal use, copy individual skill folders to `~/.agents/skills/`. Project-scoped installation is preferred for team rules because it stays versioned with the application.

## Claude Code and ZCode marketplace

The repository root is a marketplace named `dragonshorn-brain`.

``` text
/plugin marketplace add Dragonshorn-Studios/shiori-brain
/plugin install shiori-agent-engineering-contract@dragonshorn-brain
```

Replace `shiori-agent-engineering-contract` with another plugin name from the marketplace. Repeat the install command for every package you want enabled.

## Cursor

Use the generated Cursor marketplace in `.cursor-plugin/marketplace.json`, or copy `.cursor/skills/` into the target project. The copy-based project installation is the portable fallback when marketplace import is unavailable.

## Devin

Install the complete generated collection from the repository root:

``` bash
devin plugins install Dragonshorn-Studios/shiori-brain
```

The root `.devin-plugin/plugin.json` installs each generated package from its `plugins/shiori-*` subdirectory. If Devin already shows a failed partial installation, uninstall that entry before retrying the root collection.

For repository-managed cloud sessions, committing `.devin/skills/` to the application remains the simplest deterministic fallback.

## Windsurf and Vibe

Copy the generated `.windsurf/skills/` or `.vibe/skills/` directory into the application repository. Commit the result for cloud sessions and team-wide consistency.

## Updating
1. Edit the canonical document in AFFiNE.
1. Run **Sync AFFiNE knowledge** in `shiori-brain`.
1. Review and merge the generated pull request.
1. Pull the new `main` branch or refresh the marketplace/plugin installation.
1. Re-copy project-scoped skills when the application does not consume the marketplace directly.

The published human-readable archive is available at [dragonshorn-studios.github.io/shiori-brain](https://dragonshorn-studios.github.io/shiori-brain/).
