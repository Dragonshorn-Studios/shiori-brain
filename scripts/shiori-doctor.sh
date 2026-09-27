#!/usr/bin/env sh
set -eu

repository="${SHIORI_REPOSITORY:-Dragonshorn-Studios/shiori-brain}"
marketplace="${SHIORI_MARKETPLACE:-dragonshorn-brain}"
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
contains_text() {
  case $1 in
    *"$2"*) return 0 ;;
    *) return 1 ;;
  esac
}
install_codex() {
  has_command codex || { printf '%s\n' 'Cannot install Codex plugin: codex CLI is not available.' >&2; return 1; }
  codex plugin marketplace add --help >/dev/null 2>&1 && codex plugin add --help >/dev/null 2>&1 || { printf '%s\n' 'Cannot install Codex plugin: this CLI build or account does not expose plugin installation.' >&2; return 1; }
  codex_marketplaces=$(codex plugin marketplace list --json)
  if contains_text "$codex_marketplaces" "$marketplace"; then
    printf 'Codex marketplace %s is already configured.\n' "$marketplace"
  else
    codex plugin marketplace add "$repository" --ref main --json
  fi
  codex_plugins=$(codex plugin list --json)
  if contains_text "$codex_plugins" "shiori@$marketplace"; then
    printf 'Codex plugin shiori@%s is already installed.\n' "$marketplace"
  else
    codex plugin add "shiori@$marketplace" --json
  fi
}
install_claude() {
  has_command claude || { printf '%s\n' 'Cannot install Claude plugin: claude CLI is not available.' >&2; return 1; }
  claude plugin marketplace add --help >/dev/null 2>&1 && claude plugin install --help >/dev/null 2>&1 || { printf '%s\n' 'Cannot install Claude plugin: this CLI build or account does not expose plugin installation.' >&2; return 1; }
  claude_marketplaces=$(claude plugin marketplace list --json)
  if contains_text "$claude_marketplaces" "$marketplace"; then
    printf 'Claude marketplace %s is already configured.\n' "$marketplace"
  else
    claude plugin marketplace add "$repository"
  fi
  claude_plugins=$(claude plugin list --json)
  if contains_text "$claude_plugins" "shiori@$marketplace"; then
    printf 'Claude plugin shiori@%s is already installed.\n' "$marketplace"
  else
    claude plugin install --scope user --yes "shiori@$marketplace"
  fi
}
install_targets="${SHIORI_INSTALL:-}"
if [ "$#" -gt 0 ]; then
  [ "$1" = '--install' ] || { printf 'Unknown option: %s\n' "$1" >&2; exit 2; }
  shift
  [ "$#" -gt 0 ] || { printf '%s\n' 'Pass at least one installer: codex or claude.' >&2; exit 2; }
  install_targets="$*"
fi
assert_installer() {
  case $1 in
    codex)
      has_command codex && codex plugin marketplace add --help >/dev/null 2>&1 && codex plugin add --help >/dev/null 2>&1 || { printf '%s\n' 'Cannot install Codex plugin: this CLI build or account does not expose plugin installation.' >&2; return 1; }
      ;;
    claude|claude-code)
      has_command claude && claude plugin marketplace add --help >/dev/null 2>&1 && claude plugin install --help >/dev/null 2>&1 || { printf '%s\n' 'Cannot install Claude plugin: this CLI build or account does not expose plugin installation.' >&2; return 1; }
      ;;
    *) printf 'No command-line installer is available for: %s\n' "$1" >&2; return 1 ;;
  esac
}
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
  "  Claude:   /plugin marketplace add $repository ; then /plugin install shiori@$marketplace." \
  "  ZCode:    Settings -> Plugins -> Create -> Add marketplace -> $repository; install Shiori." \
  "  Cursor:   Settings -> Plugins; add https://github.com/$repository; install Shiori." \
  '  MCode:    in a checkout it reads .agents/skills automatically. For plugin install, inspect mcode plugin marketplace list --json and place plugins/shiori in its local marketplace.' \
  '  Devin:    connect this repository to the cloud workspace; no local executable is required.' \
  '' \
  "Full instructions: $guide_url"

if [ -n "$install_targets" ]; then
  printf '%s\n' '' 'Selected installations'
  previous_ifs=$IFS
  IFS=', '
  for install_target in $install_targets; do assert_installer "$install_target"; done
  for install_target in $install_targets; do
    case $install_target in
      codex) install_codex ;;
      claude|claude-code) install_claude ;;
      *) printf 'No command-line installer is available for: %s\n' "$install_target" >&2; exit 2 ;;
    esac
  done
  IFS=$previous_ifs
fi
