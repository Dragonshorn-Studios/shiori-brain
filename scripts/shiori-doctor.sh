#!/usr/bin/env sh
set -eu

repository="${SHIORI_REPOSITORY:-Dragonshorn-Studios/shiori-brain}"

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

printf 'Shiori agent doctor\nRepository: %s\n\n' "$repository"
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
  "  OpenCode: project skills are ready in .agents/skills. For global use, add this checkout's skills directory to opencode.json or link it under ~/.config/opencode/skills." \
  "  Codex:    codex plugin marketplace add $repository ; then open /plugins and install Shiori." \
  "  Claude:   /plugin marketplace add $repository ; then /plugin install shiori@dragonshorn-brain." \
  "  ZCode:    Settings -> Plugins -> Create -> Add marketplace -> $repository; install Shiori." \
  "  Cursor:   Settings -> Plugins; add https://github.com/$repository; install Shiori." \
  '  MCode:    project skills are ready in .agents/skills. For plugin install, inspect mcode plugin marketplace list --json and copy plugins/shiori into its local marketplace.' \
  '  Devin:    connect this repository to the cloud workspace; no local executable is required.' \
  '' \
  'Full instructions: AGENT-SETUP.md'
