# Install Shiori for coding agents

Run the read-only doctor without cloning the repository:

```bash
curl -fsSL https://raw.githubusercontent.com/Dragonshorn-Studios/shiori-brain/main/scripts/shiori-doctor.sh | sh
```

```powershell
irm https://raw.githubusercontent.com/Dragonshorn-Studios/shiori-brain/main/scripts/shiori-doctor.ps1 | iex
```

If this repository is already checked out, the doctor also recognizes the project adapters:

```bash
sh scripts/shiori-doctor.sh
```

```powershell
.\scripts\shiori-doctor.ps1
```

The doctor is read-only. It does not edit home-directory configuration or install plugins. When piped from GitHub it runs in remote mode and does not assume that this repository's project skill directories exist locally.

## Install from the command line

Only explicitly selected hosts are changed. OpenCode, MCode, and Vibe share one managed checkout at `~/.local/share/shiori/shiori-brain`; its skills are linked individually into the standard global `~/.agents/skills` directory. Codex and Claude Code use their plugin CLIs when the installed client version and account rollout expose them:

```bash
curl -fsSL https://raw.githubusercontent.com/Dragonshorn-Studios/shiori-brain/main/scripts/shiori-doctor.sh | sh -s -- --install opencode mcode vibe codex claude
```

```powershell
$env:SHIORI_INSTALL='opencode,mcode,vibe,codex,claude'; irm https://raw.githubusercontent.com/Dragonshorn-Studios/shiori-brain/main/scripts/shiori-doctor.ps1 | iex
```

For a checked-out script, use `sh scripts/shiori-doctor.sh --install opencode mcode vibe` or `.\scripts\shiori-doctor.ps1 -Install opencode,mcode,vibe`. Re-running install fast-forwards the managed checkout and reconciles skill links. Existing non-Shiori skill destinations are never overwritten.

## Update installed hosts

The installer records successful host selections. Update all recorded hosts without remembering the list:

```bash
curl -fsSL https://raw.githubusercontent.com/Dragonshorn-Studios/shiori-brain/main/scripts/shiori-doctor.sh | sh -s -- --update
```

```powershell
$env:SHIORI_UPDATE='all'; irm https://raw.githubusercontent.com/Dragonshorn-Studios/shiori-brain/main/scripts/shiori-doctor.ps1 | iex
```

Pass names after `--update`, or use PowerShell `-Update -UpdateTargets opencode,mcode`, to update only selected hosts. Checkout updates are always `git pull --ff-only`; an unexpected origin, dirty checkout, non-repository path, or conflicting skill destination stops the operation rather than deleting user data.

## Native setup matrix

| Host | Project use | Native reusable installation |
| --- | --- | --- |
| OpenCode | Automatic through `.agents/skills` | `--install opencode` uses the managed checkout and global Agent Skills links. |
| Codex / ChatGPT desktop | Repository skills work through `.agents/skills` | Run `codex plugin marketplace add Dragonshorn-Studios/shiori-brain`, then open `/plugins` and install **Shiori**. |
| Claude Code | Automatic through `.claude/skills` and `.claude/agents` | Run `/plugin marketplace add Dragonshorn-Studios/shiori-brain`, then `/plugin install shiori@dragonshorn-brain`. |
| ZCode | Install the generated plugin | Open **Settings -> Plugins -> Create -> Add marketplace**, enter `Dragonshorn-Studios/shiori-brain`, then install **Shiori**. |
| Cursor | Automatic through `.cursor/skills` | Open **Settings -> Plugins**, add `https://github.com/Dragonshorn-Studios/shiori-brain`, then install **Shiori**. |
| MCode / MiniMax Code | Automatic through `.agents/skills` in this checkout | `--install mcode` uses the same managed checkout and global Agent Skills links. |
| Windsurf | Automatic through `.windsurf/skills` | Keep the generated project adapter; no marketplace step is required. |
| Vibe | Automatic through `.vibe/skills` | `--install vibe` uses the same managed checkout and global Agent Skills links. |
| Devin | Automatic through committed `.devin/skills` in repository sessions | Devin may be cloud-only, so absence of a local executable is not an error. Connect this repository to the Devin workspace. |

## What gets generated

- `plugins/shiori/plugin.json`: portable [Agent Plugins](https://agent-plugins.org/) manifest.
- `plugins/shiori/.codex-plugin/plugin.json`: Codex compatibility manifest.
- `.agents/plugins/marketplace.json`: native repository marketplace for Codex and ChatGPT desktop.
- Host-specific project skill directories, all generated from the same AFFiNE documents.

AFFiNE remains canonical. Do not edit generated skills, manifests, this guide, or the doctor scripts by hand; change Shiori and regenerate them.
