#!/usr/bin/env sh
set -eu

repository="${SHIORI_REPOSITORY:-Dragonshorn-Studios/shiori-brain}"
guide_url="https://github.com/$repository/blob/main/AGENT-SETUP.md"
if [ -d '.agents/skills' ] && [ -d 'plugins/shiori' ]; then
  context='checkout'
  project_hint='project adapters are ready in this checkout'
else
  context='remote'
  project_hint='no Shiori checkout detected; use a marketplace installation below'
fi

has_command() { command -v "$1" >/dev/null 2>&1; }
has_home() { [ -e "$HOME/$1" ]; }
row() {
  tool=$1
  command_name=$2
  home_path=$3
  mode=$4
  if has_command "$command_name"; then
    printf '%-18s detected (CLI: %s)\n' "$tool" "$(command -v "$command_name")"
  elif [ -n "$home_path" ] && has_home "$home_path"; then
    printf '%-18s detected (configuration: ~/%s)\n' "$tool" "$home_path"
  elif [ "$mode" = cloud ]; then
    printf '%-18s cloud-capable (local CLI not required)\n' "$tool"
  else
    printf '%-18s not detected locally\n' "$tool"
  fi
}

printf 'Shiori agent doctor\nRepository: %s\nMode: %s (%s)\n\n' "$repository" "$context" "$project_hint"
row 'OpenCode' opencode '.config/opencode' local
row 'Codex' codex '.codex' local
row 'Claude Code' claude '.claude' local
row 'ZCode' zcode '.zcode' local
row 'Cursor' cursor '.cursor' local
row 'MCode / MiniMax' mcode '.minimax' local
row 'Windsurf' windsurf '.windsurf' local
row 'Vibe' vibe '.vibe' local
row 'Devin' devin '.devin' cloud

printf '%s\n' \
  '' \
  'Recommended native setup' \
  "  OpenCode: in a checkout it reads .agents/skills automatically. For global use, point opencode.json at a Shiori skills checkout or link it under ~/.config/opencode/skills." \
  "  Codex:    codex plugin marketplace add $repository ; then open /plugins and install Shiori." \
  "  Claude:   /plugin marketplace add $repository ; then /plugin install shiori@dragonshorn-brain." \
  "  ZCode:    Settings -> Plugins -> Create -> Add marketplace -> $repository; install Shiori." \
  "  Cursor:   Settings -> Plugins; add https://github.com/$repository; install Shiori." \
  '  MCode:    in a checkout it reads .agents/skills automatically. For plugin install, inspect mcode plugin marketplace list --json and place plugins/shiori in its local marketplace.' \
  '  Devin:    connect this repository to the cloud workspace; no local executable is required.' \
  '' \
  "Full instructions: $guide_url"
