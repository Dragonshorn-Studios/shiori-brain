# Install Shiori for coding agents

This repository is already project-ready: supported agents can read the committed adapters without a global installation. Run the doctor from the repository root to see which local tools are present and the native setup action for each one.

```bash
sh scripts/shiori-doctor.sh
```

```powershell
.\scripts\shiori-doctor.ps1
```

The doctor is read-only. It does not edit home-directory configuration or install plugins.

## Native setup matrix

| Host | Project use | Native reusable installation |
| --- | --- | --- |
| OpenCode | Automatic through `.agents/skills` | Add this checkout's `skills` directory to `skills` in `opencode.json`, or copy/link each skill to `~/.config/opencode/skills`. |
| Codex / ChatGPT desktop | Repository skills work through `.agents/skills` | Run `codex plugin marketplace add Dragonshorn-Studios/shiori-brain`, then open `/plugins` and install **Shiori**. |
| Claude Code | Automatic through `.claude/skills` and `.claude/agents` | Run `/plugin marketplace add Dragonshorn-Studios/shiori-brain`, then `/plugin install shiori@dragonshorn-brain`. |
| ZCode | Install the generated plugin | Open **Settings -> Plugins -> Create -> Add marketplace**, enter `Dragonshorn-Studios/shiori-brain`, then install **Shiori**. |
| Cursor | Automatic through `.cursor/skills` | Open **Settings -> Plugins**, add `https://github.com/Dragonshorn-Studios/shiori-brain`, then install **Shiori**. |
| MCode / MiniMax Code | Automatic through `.agents/skills` in this checkout | For a reusable local plugin, find the local marketplace with `mcode plugin marketplace list --json`, copy `plugins/shiori` there, then run `mcode plugin enable shiori@local`. |
| Windsurf | Automatic through `.windsurf/skills` | Keep the generated project adapter; no marketplace step is required. |
| Vibe | Automatic through `.vibe/skills` | Keep the generated project adapter; no marketplace step is required. |
| Devin | Automatic through committed `.devin/skills` in repository sessions | Devin may be cloud-only, so absence of a local executable is not an error. Connect this repository to the Devin workspace. |

## What gets generated

- `plugins/shiori/plugin.json`: portable [Agent Plugins](https://agent-plugins.org/) manifest.
- `plugins/shiori/.codex-plugin/plugin.json`: Codex compatibility manifest.
- `.agents/plugins/marketplace.json`: native repository marketplace for Codex and ChatGPT desktop.
- Host-specific project skill directories, all generated from the same AFFiNE documents.

AFFiNE remains canonical. Do not edit generated skills, manifests, this guide, or the doctor scripts by hand; change Shiori and regenerate them.
