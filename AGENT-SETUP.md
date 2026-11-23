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

The doctor is read-only. It does not edit home-directory configuration or install plugins. When piped from GitHub it runs in remote mode and does not assume that this repository's project skill directories exist locally. Default `--install` / `--update` output is a checkout line, the detected hosts, one line per destination, MCP added/updated/unchanged/conflict lines, and a short summary that counts MCP writes. A bare run also lists each Craft CLI the helper found. `--verbose` (or `SHIORI_VERBOSE=1`) restores the status table, recipes, git, and MCP lines. `--help` prints usage.

## Install from the command line

`--install` or `--update` with no host names sets up every locally detected installable host. An explicit host list still takes precedence over detection. Hosts that already read `~/.agents/skills` with full skill functionality share one managed checkout at `~/.local/share/shiori/shiori-brain` and receive individual links in `~/.agents/skills/<name>`. Claude Code uses the same checkout linked into `~/.claude/skills/<name>`. Two hosts that share a destination never get two copies. The doctor does not install Codex or Claude plugins; those remain published in the repository marketplace as a separate channel (ChatGPT web and manual installs). Cursor, Devin, OpenCode, Claude Code, and Codex also receive MCP config under `--install` / `--update`. Devin is detected only when the `devin` CLI is on `PATH` or `~/.config/devin` / `~/.devin` exists; cloud-capable status alone is not enough. A bare `curl | sh` / `irm | iex` with no environment variable stays read-only.

```bash
curl -fsSL https://raw.githubusercontent.com/Dragonshorn-Studios/shiori-brain/main/scripts/shiori-doctor.sh | SHIORI_INSTALL=all sh
```

```powershell
$env:SHIORI_INSTALL='all'; irm https://raw.githubusercontent.com/Dragonshorn-Studios/shiori-brain/main/scripts/shiori-doctor.ps1 | iex
```

Named hosts:

```bash
curl -fsSL https://raw.githubusercontent.com/Dragonshorn-Studios/shiori-brain/main/scripts/shiori-doctor.sh | SHIORI_INSTALL='codex,claude,cursor' sh
```

```powershell
$env:SHIORI_INSTALL='codex,claude,cursor'; irm https://raw.githubusercontent.com/Dragonshorn-Studios/shiori-brain/main/scripts/shiori-doctor.ps1 | iex
```

For a checked-out script, use `sh scripts/shiori-doctor.sh --install` to set up every detected host, or `sh scripts/shiori-doctor.sh --install opencode mcode vibe` / `.\scripts\shiori-doctor.ps1 -Install opencode,mcode,vibe` to name hosts. Re-running install fast-forwards the managed checkout and reconciles skill links. Existing non-Shiori skill destinations are skipped with a warning and never overwritten. A host that is not detected is not created.

Valid host names: `opencode`, `mcode`, `vibe`, `codex`, `claude`, `cursor`, `devin`, `zed`, and `glm` (`claude-code` is accepted as `claude`). What each one does:

| Host | `--install` effect |
| --- | --- |
| opencode | Managed checkout + Agent Skills links in `~/.agents/skills` + MCP config in `~/.config/opencode/opencode.jsonc` |
| codex | Managed checkout + Agent Skills links in `~/.agents/skills` + MCP via `codex mcp add`. Does not install the Codex plugin. |
| claude | Managed checkout + Agent Skills links in `~/.claude/skills` + MCP via `claude mcp add -s user`. Does not install the Claude plugin. |
| glm | Managed checkout + Agent Skills links in `~/.claude/skills` (shared with Claude Code). A Zed directory alone does not count as detection. |
| cursor | Managed checkout + Agent Skills links in `~/.agents/skills` + MCP config in `~/.cursor/mcp.json`. Does not write `~/.cursor/skills`. Cursor Cloud gets no user-level skills. |
| mcode | Managed checkout + Agent Skills links in `~/.agents/skills` |
| vibe | Managed checkout + Agent Skills links in `~/.agents/skills` only — does not copy into `~/.vibe/skills` |
| devin | Managed checkout + Agent Skills links in `~/.agents/skills` + MCP config in `~/.config/devin/mcp_config.json`. Does not write `~/.config/devin/skills`. |
| zed | Managed checkout + Agent Skills links in `~/.agents/skills` only. Does not write a Zed-specific skill tree. |

## Update installed hosts

`--install` records each host it successfully sets up in `~/.local/state/shiori/installed-hosts`. A named `--update` still re-runs the current doctor against those recorded hosts. A bare `--update` (or `SHIORI_UPDATE=all`) sets up every host the doctor currently detects, including tools that were never recorded. Recorded-but-no-longer-detected hosts are not required. If a detected host cannot be installed, the doctor warns, continues with the rest, and exits non-zero:

```bash
curl -fsSL https://raw.githubusercontent.com/Dragonshorn-Studios/shiori-brain/main/scripts/shiori-doctor.sh | SHIORI_UPDATE=all sh
```

```powershell
$env:SHIORI_UPDATE='all'; irm https://raw.githubusercontent.com/Dragonshorn-Studios/shiori-brain/main/scripts/shiori-doctor.ps1 | iex
```

Pass names after `--install` / `--update`, or use PowerShell `-Install opencode` / `-Update -UpdateTargets opencode,mcode`, to change only selected hosts. A bare run with no `--install` / `--update` stays read-only. Checkout updates are always `git pull --ff-only`; an unexpected origin, dirty checkout, non-repository path, or skills directory symlink leaving `$HOME` stops the operation rather than deleting user data. A second consecutive `--update` with no checkout or MCP change reports `already current` and writes nothing. If nothing installable is detected, the doctor prints an error on stderr and writes nothing.

## Native setup matrix

| Host | Project use | Native reusable installation |
| --- | --- | --- |
| OpenCode | Automatic through `.agents/skills` | `--install opencode` uses the managed checkout and global `~/.agents/skills` links, and writes MCP config to `~/.config/opencode/opencode.jsonc`. |
| Codex / ChatGPT desktop | Repository skills work through `.agents/skills` | `--install codex` links skills through `~/.agents/skills` and writes MCP via `codex mcp add`. The plugin marketplace remains a separate channel for ChatGPT web (`codex plugin marketplace add Dragonshorn-Studios/shiori-brain`), not owned by the doctor. |
| Claude Code | Automatic through `.claude/skills` and `.claude/agents` | `--install claude` links skills through `~/.claude/skills` and writes MCP via `claude mcp add -s user`. The plugin marketplace remains a separate channel (`/plugin marketplace add Dragonshorn-Studios/shiori-brain`), not owned by the doctor. |
| glm-acp-agent | Zed glm-acp-agent reads `~/.claude/skills` | `--install glm` (alias `glm-acp`) links skills through `~/.claude/skills`. Detection is file existence only (`glm-acp-agent` on `PATH` or the npx registry binary under `~/.local/share/zed`); the doctor never runs the binary. Windows support is out of scope. |
| ZCode | Install the generated plugin | Open **Settings -> Plugins -> Create -> Add marketplace**, enter `Dragonshorn-Studios/shiori-brain`, then install **Shiori**. Do not add `--install zcode`. |
| Cursor | Automatic through `.cursor/skills` in the repository; local agent also reads `~/.agents/skills` | `--install cursor` writes MCP config and joins the shared `~/.agents/skills` sync. The doctor does not copy files into `~/.cursor/skills`. Cursor Cloud support is out of scope. |
| MCode / MiniMax Code | Automatic through `.agents/skills` in this checkout | `--install mcode` uses the same managed checkout and global `~/.agents/skills` links. |
| Windsurf | Automatic through `.windsurf/skills` | Keep the generated project adapter; no marketplace step is required. |
| Vibe | Automatic through `.vibe/skills` in the repository; local Vibe also reads `~/.agents/skills` | `--install vibe` uses the same managed checkout and global `~/.agents/skills` links. It does not write `~/.vibe/skills`. |
| Devin | Automatic through committed `.devin/skills` in repository sessions; local Devin also reads `~/.agents/skills` | `--install devin` writes user-scope MCP config to `~/.config/devin/mcp_config.json` and joins the shared `~/.agents/skills` sync when selected. Devin may be cloud-only, so absence of a local executable is not an error. The doctor does not write `~/.config/devin/skills`. |
| Zed Agent | Automatic through `~/.agents/skills` | `--install zed` links skills through `~/.agents/skills`. Detected if `zed` is on `PATH`, or `~/.config/zed` / `~/.local/share/zed` exists. Windows support is out of scope. |

## MCP servers

The doctor can add a local stdio MCP client for the published Pages archive, plus Storytold Craft CLIs found on `PATH` or in a bounded Windows install search (`Program Files\*Craft*`, `Program Files (x86)\*Craft*`, `%LOCALAPPDATA%\Programs\*Craft*`, one nested `*Craft*` directory such as `ArtCraft\DesignCraft`, and the WSL `/mnt/c` Program Files trees). Under WSL, set `SHIORI_CRAFT_LOCALAPPDATA` to scan that Windows profile's `Programs\*Craft*` directory; other users' profiles are not scanned. The catalog includes DesignCraft, SolidCraft, and VectorCraft. Default doctor mode is still read-only, does not launch Claude or Codex, and reports each Craft CLI the helper found. MCP writes happen only under `--install` / `--update`: Cursor via `~/.cursor/mcp.json`, Devin via `~/.config/devin/mcp_config.json`, OpenCode via `~/.config/opencode/opencode.jsonc` (`mcp.servers`; an existing `opencode.json` is updated in place instead. Fresh installs choose `.jsonc` so other tools' flat-schema OpenCode imports do not misread the file), Claude Code via `claude mcp add -s user`, and Codex via `codex mcp add`. Quiet install output names each added, updated, unchanged, or conflicting MCP server. The shiori-brain server is `node <checkout>/packages/shiori-brain-mcp/src/index.js` from the managed checkout; it is not loaded from a package registry. Installed entries set `SHIORI_BRAIN_BASE_URL` to this project's Pages origin (`https://dragonshorn-studios.github.io/shiori-brain/`). Override with `SHIORI_BRAIN_BASE_URL` if Pages uses a custom domain. The installer fails instead of using another project's archive when that URL cannot be determined. Existing non-Shiori MCP entries are never overwritten.

On Windows and in WSL, detected Craft CLIs are configured as `<name>-cli mcp --attach 7979` so a host can drive the running desktop app (start it with `figcraft --control 7979`). In WSL the doctor prefers the Windows `.exe` via WSL interop, because the control channel binds `127.0.0.1` on the Windows host and a Linux-side localhost may not reach it. Elsewhere the doctor keeps headless `<name>-cli mcp`.

| Server | Command | Purpose | When the doctor adds it |
| --- | --- | --- | --- |
| `shiori-brain` | `node ~/.local/share/shiori/shiori-brain/packages/shiori-brain-mcp/src/index.js` | Search and read the published Shiori knowledge archive | On `--install` / `--update` for Cursor, Devin, OpenCode, Claude Code, and Codex |
| `figcraft` | `figcraft-cli mcp` | Interface design (FigCraft) | When `figcraft-cli` is on `PATH` or in a bounded Program Files / LocalAppData `*Craft*` install (WSL: `/mnt/c` Program Files; LocalAppData only if `SHIORI_CRAFT_LOCALAPPDATA` is set). Windows and WSL use `figcraft-cli mcp --attach 7979` |
| `cadcraft` | `cadcraft-cli mcp` | CAD and drafting (CadCraft) | When `cadcraft-cli` is on `PATH` or in a bounded Program Files / LocalAppData `*Craft*` install (WSL: `/mnt/c` Program Files; LocalAppData only if `SHIORI_CRAFT_LOCALAPPDATA` is set). Windows and WSL use `cadcraft-cli mcp --attach 7979` |
| `deckcraft` | `deckcraft-cli mcp` | Slide decks (DeckCraft) | When `deckcraft-cli` is on `PATH` or in a bounded Program Files / LocalAppData `*Craft*` install (WSL: `/mnt/c` Program Files; LocalAppData only if `SHIORI_CRAFT_LOCALAPPDATA` is set). Windows and WSL use `deckcraft-cli mcp --attach 7979` |
| `gridcraft` | `gridcraft-cli mcp` | Spreadsheets and tables (GridCraft) | When `gridcraft-cli` is on `PATH` or in a bounded Program Files / LocalAppData `*Craft*` install (WSL: `/mnt/c` Program Files; LocalAppData only if `SHIORI_CRAFT_LOCALAPPDATA` is set). Windows and WSL use `gridcraft-cli mcp --attach 7979` |
| `lightcraft` | `lightcraft-cli mcp` | Photo library and RAW development (LightCraft) | When `lightcraft-cli` is on `PATH` or in a bounded Program Files / LocalAppData `*Craft*` install (WSL: `/mnt/c` Program Files; LocalAppData only if `SHIORI_CRAFT_LOCALAPPDATA` is set). Windows and WSL use `lightcraft-cli mcp --attach 7979` |
| `pdfcraft` | `pdfcraft-cli mcp` | PDF documents (PdfCraft) | When `pdfcraft-cli` is on `PATH` or in a bounded Program Files / LocalAppData `*Craft*` install (WSL: `/mnt/c` Program Files; LocalAppData only if `SHIORI_CRAFT_LOCALAPPDATA` is set). Windows and WSL use `pdfcraft-cli mcp --attach 7979` |
| `photocraft` | `photocraft-cli mcp` | Image editor (PhotoCraft) | When `photocraft-cli` is on `PATH` or in a bounded Program Files / LocalAppData `*Craft*` install (WSL: `/mnt/c` Program Files; LocalAppData only if `SHIORI_CRAFT_LOCALAPPDATA` is set). Windows and WSL use `photocraft-cli mcp --attach 7979` |
| `wordcraft` | `wordcraft-cli mcp` | Word processing (WordCraft) | When `wordcraft-cli` is on `PATH` or in a bounded Program Files / LocalAppData `*Craft*` install (WSL: `/mnt/c` Program Files; LocalAppData only if `SHIORI_CRAFT_LOCALAPPDATA` is set). Windows and WSL use `wordcraft-cli mcp --attach 7979` |
| `effectcraft` | `effectcraft-cli mcp` | Motion graphics and VFX (EffectCraft) | When `effectcraft-cli` is on `PATH` or in a bounded Program Files / LocalAppData `*Craft*` install (WSL: `/mnt/c` Program Files; LocalAppData only if `SHIORI_CRAFT_LOCALAPPDATA` is set). Windows and WSL use `effectcraft-cli mcp --attach 7979` |
| `anicraft` | `anicraft-cli mcp` | 2D vector animation (AniCraft) | When `anicraft-cli` is on `PATH` or in a bounded Program Files / LocalAppData `*Craft*` install (WSL: `/mnt/c` Program Files; LocalAppData only if `SHIORI_CRAFT_LOCALAPPDATA` is set). Windows and WSL use `anicraft-cli mcp --attach 7979` |
| `soundcraft` | `soundcraft-cli mcp` | Digital audio workstation (SoundCraft) | When `soundcraft-cli` is on `PATH` or in a bounded Program Files / LocalAppData `*Craft*` install (WSL: `/mnt/c` Program Files; LocalAppData only if `SHIORI_CRAFT_LOCALAPPDATA` is set). Windows and WSL use `soundcraft-cli mcp --attach 7979` |
| `designcraft` | `designcraft-cli mcp` | Product and UI design (DesignCraft) | When `designcraft-cli` is on `PATH` or in a bounded Program Files / LocalAppData `*Craft*` install (WSL: `/mnt/c` Program Files; LocalAppData only if `SHIORI_CRAFT_LOCALAPPDATA` is set). Windows and WSL use `designcraft-cli mcp --attach 7979` |
| `solidcraft` | `solidcraft-cli mcp` | 3D solid modeling (SolidCraft) | When `solidcraft-cli` is on `PATH` or in a bounded Program Files / LocalAppData `*Craft*` install (WSL: `/mnt/c` Program Files; LocalAppData only if `SHIORI_CRAFT_LOCALAPPDATA` is set). Windows and WSL use `solidcraft-cli mcp --attach 7979` |
| `vectorcraft` | `vectorcraft-cli mcp` | Vector illustration (VectorCraft) | When `vectorcraft-cli` is on `PATH` or in a bounded Program Files / LocalAppData `*Craft*` install (WSL: `/mnt/c` Program Files; LocalAppData only if `SHIORI_CRAFT_LOCALAPPDATA` is set). Windows and WSL use `vectorcraft-cli mcp --attach 7979` |

Consult shiori-brain on demand (`search` / `read_doc`) before architecture or security decisions; do not dump that knowledge into context. Skills are procedures only.

## What gets generated

- `plugins/shiori/plugin.json`: portable [Agent Plugins](https://agent-plugins.org/) manifest.
- `plugins/shiori/.codex-plugin/plugin.json`: Codex compatibility manifest.
- `.agents/plugins/marketplace.json`: native repository marketplace for Codex and ChatGPT desktop.
- `scripts/shiori-mcp.mjs`: helper used by the doctor to add and verify MCP entries.
- `packages/shiori-brain-mcp/`: local stdio MCP server launched from the managed checkout.
- Host-specific project skill directories, all generated from the same AFFiNE documents.

AFFiNE remains canonical. Do not edit generated skills, manifests, this guide, or the doctor scripts by hand; change Shiori and regenerate them.
