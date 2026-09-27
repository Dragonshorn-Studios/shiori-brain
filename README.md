# Shiori Brain 🌸

Shared, versioned knowledge for Dragonshorn Studios coding agents.

AFFiNE is the source of truth. The `Sync AFFiNE knowledge` workflow exports the
linked document graph rooted at **Shared Architecture — Start Here**, opens an
update pull request, and generates installable skills and marketplaces for the
supported coding agents.

Do not edit generated files by hand. Change the source documents in AFFiNE and
run the sync workflow instead.

## Install for an agent

Run the read-only setup doctor without cloning the repository. It detects local
agent CLIs and configuration, handles cloud-only agents such as Devin, and
prints the native installation step for each host:

```powershell
irm https://raw.githubusercontent.com/Dragonshorn-Studios/shiori-brain/main/scripts/shiori-doctor.ps1 | iex
```

```bash
curl -fsSL https://raw.githubusercontent.com/Dragonshorn-Studios/shiori-brain/main/scripts/shiori-doctor.sh | sh
```

The same scripts can be run directly from `scripts/` in a checkout; they then
also verify that the generated project adapters are present.

Install selected hosts. OpenCode, MCode, and Vibe share one managed checkout;
Codex and Claude use plugin management when their client/account exposes it:

```powershell
$env:SHIORI_INSTALL='opencode,mcode,vibe,codex,claude'; irm https://raw.githubusercontent.com/Dragonshorn-Studios/shiori-brain/main/scripts/shiori-doctor.ps1 | iex
```

```bash
curl -fsSL https://raw.githubusercontent.com/Dragonshorn-Studios/shiori-brain/main/scripts/shiori-doctor.sh | sh -s -- --install opencode mcode vibe codex claude
```

The installer preflights every selection before changing anything. Unsupported
or gated clients stop with an explanation; the default invocation remains
read-only.

Later, update every previously selected host without remembering the list:

```powershell
$env:SHIORI_UPDATE='all'; irm https://raw.githubusercontent.com/Dragonshorn-Studios/shiori-brain/main/scripts/shiori-doctor.ps1 | iex
```

```bash
curl -fsSL https://raw.githubusercontent.com/Dragonshorn-Studios/shiori-brain/main/scripts/shiori-doctor.sh | sh -s -- --update
```

See [AGENT-SETUP.md](AGENT-SETUP.md) for the complete OpenCode, Codex, Claude
Code, ZCode, Cursor, MCode/MiniMax, Windsurf, Vibe, and Devin matrix.

## Repository settings

Configure these GitHub Actions values:

- Variable `AFFINE_BASE_URL`
- Variable `AFFINE_WORKSPACE_ID`
- Variable `AFFINE_ROOT_DOCUMENT_ID`
- Secret `AFFINE_EMAIL` — dedicated AFFiNE service-account email
- Secret `AFFINE_PASSWORD` — dedicated AFFiNE service-account password

This repository exports workspace `82dbcbba-c52a-4539-be3f-133ea6ebcb9d`
from root document `j4IXQ9l6wz` (`Shared Architecture — Start Here`).

The sync can then be started from **Actions → Sync AFFiNE knowledge → Run
workflow**. After the generated pull request is merged, the Pages workflow
publishes the browsable archive.
