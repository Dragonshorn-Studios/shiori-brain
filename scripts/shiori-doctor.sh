#!/usr/bin/env sh
set -eu

repository="${SHIORI_REPOSITORY:-Dragonshorn-Studios/shiori-brain}"
marketplace="${SHIORI_MARKETPLACE:-dragonshorn-brain}"
guide_url="https://github.com/$repository/blob/main/AGENT-SETUP.md"
checkout="${SHIORI_CHECKOUT:-$HOME/.local/share/shiori/shiori-brain}"
state_root="${SHIORI_STATE_HOME:-$HOME/.local/state/shiori}"
skills_root="${SHIORI_SKILLS_HOME:-$HOME/.agents/skills}"
installed_hosts_file="$state_root/installed-hosts"
managed_skills_file="$state_root/managed-skills"
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
record_host() {
  mkdir -p "$state_root"
  if [ -f "$installed_hosts_file" ]; then
    while IFS= read -r recorded_host; do [ "$recorded_host" = "$1" ] && return 0; done < "$installed_hosts_file"
  fi
  printf '%s\n' "$1" >> "$installed_hosts_file"
}
ensure_checkout() {
  has_command git || { printf '%s\n' 'Cannot install shared skills: git is not available.' >&2; return 1; }
  if [ -d "$checkout/.git" ]; then
    checkout_origin=$(git -C "$checkout" remote get-url origin)
    case $checkout_origin in
      "https://github.com/$repository"|"https://github.com/$repository.git"|"git@github.com:$repository.git") ;;
      *) printf 'Refusing to update checkout with unexpected origin: %s\n' "$checkout_origin" >&2; return 1 ;;
    esac
    [ -z "$(git -C "$checkout" status --porcelain)" ] || { printf 'Refusing to update dirty checkout: %s\n' "$checkout" >&2; return 1; }
    git -C "$checkout" pull --ff-only origin main
  elif [ -e "$checkout" ] || [ -L "$checkout" ]; then
    printf 'Refusing to replace non-checkout path: %s\n' "$checkout" >&2
    return 1
  else
    mkdir -p "${checkout%/*}"
    git clone --filter=blob:none --branch main "https://github.com/$repository.git" "$checkout"
  fi
}
sync_shared_skills() {
  [ -d "$checkout/skills" ] || { printf 'Checkout has no skills directory: %s\n' "$checkout" >&2; return 1; }
  has_command ln && has_command readlink && has_command rm && has_command mkdir && has_command mv || { printf '%s\n' 'Cannot link skills: ln, readlink, rm, mkdir, and mv are required. On Windows use the PowerShell installer.' >&2; return 1; }
  mkdir -p "$skills_root" "$state_root"
  for source_skill in "$checkout/skills"/*; do
    [ -d "$source_skill" ] || continue
    skill_name=${source_skill##*/}
    target_skill="$skills_root/$skill_name"
    if [ -e "$target_skill" ] || [ -L "$target_skill" ]; then
      [ -L "$target_skill" ] && [ "$(readlink "$target_skill")" = "$source_skill" ] || { printf 'Skill destination already belongs to something else: %s\n' "$target_skill" >&2; return 1; }
    fi
  done
  if [ -f "$managed_skills_file" ]; then
    while IFS= read -r old_skill; do
      [ -n "$old_skill" ] || continue
      old_target="$skills_root/$old_skill"
      if [ ! -d "$checkout/skills/$old_skill" ] && [ -L "$old_target" ] && [ "$(readlink "$old_target")" = "$checkout/skills/$old_skill" ]; then
        rm "$old_target"
      fi
    done < "$managed_skills_file"
  fi
  next_managed="$managed_skills_file.next"
  : > "$next_managed"
  for source_skill in "$checkout/skills"/*; do
    [ -d "$source_skill" ] || continue
    skill_name=${source_skill##*/}
    target_skill="$skills_root/$skill_name"
    if [ ! -L "$target_skill" ]; then ln -s "$source_skill" "$target_skill"; fi
    printf '%s\n' "$skill_name" >> "$next_managed"
  done
  mv "$next_managed" "$managed_skills_file"
  printf 'Shared Shiori skills linked from %s into %s.\n' "$checkout" "$skills_root"
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
  record_host codex
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
  record_host claude
}
update_codex() {
  codex plugin marketplace upgrade "$marketplace"
  record_host codex
}
update_claude() {
  claude plugin marketplace update "$marketplace"
  claude plugin update "shiori@$marketplace"
  record_host claude
}
operation=''
selected_targets="${SHIORI_INSTALL:-}"
[ -z "${SHIORI_UPDATE:-}" ] || { [ -z "$selected_targets" ] || { printf '%s\n' 'Choose either SHIORI_INSTALL or SHIORI_UPDATE.' >&2; exit 2; }; operation='update'; selected_targets="$SHIORI_UPDATE"; }
[ -z "$selected_targets" ] || operation="${operation:-install}"
if [ "$#" -gt 0 ]; then
  [ -z "$operation" ] || { printf '%s\n' 'Do not combine environment and command-line operations.' >&2; exit 2; }
  case $1 in
    --install) operation='install' ;;
    --update) operation='update' ;;
    *) printf 'Unknown option: %s\n' "$1" >&2; exit 2 ;;
  esac
  shift
  selected_targets="$*"
fi
if [ "$operation" = 'install' ] && [ -z "$selected_targets" ]; then
  printf '%s\n' 'Pass at least one installer: opencode, mcode, vibe, codex, or claude.' >&2
  exit 2
fi
if [ "$operation" = 'update' ] && [ -z "$selected_targets" ]; then
  [ -f "$installed_hosts_file" ] || { printf '%s\n' 'No recorded Shiori installations to update.' >&2; exit 2; }
  while IFS= read -r recorded_host; do selected_targets="$selected_targets $recorded_host"; done < "$installed_hosts_file"
fi
assert_installer() {
  case $1 in
    opencode|mcode|vibe)
      has_command git && has_command ln && has_command readlink && has_command rm && has_command mkdir && has_command mv || { printf '%s\n' 'Cannot install shared skills: git, ln, readlink, rm, mkdir, and mv are required. On Windows use the PowerShell installer.' >&2; return 1; }
      ;;
    codex)
      if [ "$operation" = update ]; then
        has_command codex && codex plugin marketplace upgrade --help >/dev/null 2>&1 || { printf '%s\n' 'Cannot update Codex plugin: this CLI build does not expose marketplace upgrades.' >&2; return 1; }
      else
        has_command codex && codex plugin marketplace add --help >/dev/null 2>&1 && codex plugin add --help >/dev/null 2>&1 || { printf '%s\n' 'Cannot install Codex plugin: this CLI build or account does not expose plugin installation.' >&2; return 1; }
      fi
      ;;
    claude|claude-code)
      if [ "$operation" = update ]; then
        has_command claude && claude plugin marketplace update --help >/dev/null 2>&1 && claude plugin update --help >/dev/null 2>&1 || { printf '%s\n' 'Cannot update Claude plugin: this CLI build does not expose plugin updates.' >&2; return 1; }
      else
        has_command claude && claude plugin marketplace add --help >/dev/null 2>&1 && claude plugin install --help >/dev/null 2>&1 || { printf '%s\n' 'Cannot install Claude plugin: this CLI build or account does not expose plugin installation.' >&2; return 1; }
      fi
      ;;
    *) printf 'No command-line installer is available for: %s\n' "$1" >&2; return 1 ;;
  esac
}
row() {
  tool=$1
  command_name=$2
  home_path=$3
  mode=$4
  provider=$5
  if has_command "$command_name"; then
    printf '%-18s detected (CLI: %s) | Shiori: %s\n' "$tool" "$(command -v "$command_name")" "$(shiori_status "$provider")"
  elif [ -n "$home_path" ] && has_home "$home_path"; then
    printf '%-18s detected (configuration: ~/%s) | Shiori: %s\n' "$tool" "$home_path" "$(shiori_status "$provider")"
  elif [ "$mode" = cloud ]; then
    printf '%-18s cloud-capable (local CLI not required) | Shiori: %s\n' "$tool" "$(shiori_status "$provider")"
  else
    printf '%-18s not detected locally\n' "$tool"
  fi
}

shared_skills_installed() {
  [ -d "$checkout/.git" ] && [ -s "$managed_skills_file" ] || return 1
  found_skill=false
  while IFS= read -r skill_name; do
    [ -n "$skill_name" ] || continue
    found_skill=true
    target_skill="$skills_root/$skill_name"
    source_skill="$checkout/skills/$skill_name"
    [ -L "$target_skill" ] && [ "$(readlink "$target_skill")" = "$source_skill" ] || return 1
  done < "$managed_skills_file"
  [ "$found_skill" = true ]
}

shiori_status() {
  case $1 in
    opencode|mcode|vibe)
      if shared_skills_installed; then printf '%s' 'installed (managed Agent Skills)'; else printf '%s' 'not installed'; fi
      ;;
    codex)
      if has_command codex && codex_plugins=$(codex plugin list --json 2>/dev/null); then
        if contains_text "$codex_plugins" "shiori@$marketplace"; then printf '%s' 'installed (native plugin)'; else printf '%s' 'not installed'; fi
      else
        printf '%s' 'unknown (plugin status unavailable)'
      fi
      ;;
    claude)
      if has_command claude && claude_plugins=$(claude plugin list --json 2>/dev/null); then
        if contains_text "$claude_plugins" "shiori@$marketplace"; then printf '%s' 'installed (native plugin)'; else printf '%s' 'not installed'; fi
      else
        printf '%s' 'unknown (plugin status unavailable)'
      fi
      ;;
    *) printf '%s' 'unknown (no local status API)' ;;
  esac
}

printf 'Shiori agent doctor\nRepository: %s\nMode: %s (%s)\n\n' "$repository" "$context" "$project_hint"
row 'OpenCode' opencode '.config/opencode' local opencode
row 'Codex' codex '.codex' local codex
row 'Claude Code' claude '.claude' local claude
row 'ZCode' zcode '.zcode' local zcode
row 'Cursor' cursor '.cursor' local cursor
row 'MCode / MiniMax' mcode '.minimax' local mcode
row 'Windsurf' windsurf '.windsurf' local windsurf
row 'Vibe' vibe '.vibe' local vibe
row 'Devin' devin '.devin' cloud devin

printf '%s\n' \
  '' \
  'Recommended native setup' \
  '  OpenCode: select --install opencode to clone/update Shiori and link its skills through ~/.agents/skills.' \
  "  Codex:    codex plugin marketplace add $repository ; then open /plugins and install Shiori." \
  "  Claude:   /plugin marketplace add $repository ; then /plugin install shiori@$marketplace." \
  "  ZCode:    Settings -> Plugins -> Create -> Add marketplace -> $repository; install Shiori." \
  "  Cursor:   Settings -> Plugins; add https://github.com/$repository; install Shiori." \
  '  MCode:    select --install mcode to use the same managed checkout and global Agent Skills links.' \
  '  Vibe:     select --install vibe to use the same managed checkout and global Agent Skills links.' \
  '  Devin:    connect this repository to the cloud workspace; no local executable is required.' \
  '' \
  "Full instructions: $guide_url"

if [ -n "$operation" ]; then
  printf '%s\n' '' "Selected operation: $operation"
  previous_ifs=$IFS
  IFS=', '
  shared_skills_selected='false'
  for selected_target in $selected_targets; do
    assert_installer "$selected_target"
    case $selected_target in opencode|mcode|vibe) shared_skills_selected='true' ;; esac
  done
  if [ "$shared_skills_selected" = true ]; then
    [ "$operation" != update ] || [ -d "$checkout/.git" ] || { printf 'No managed checkout exists to update: %s\n' "$checkout" >&2; exit 2; }
    ensure_checkout
    sync_shared_skills
  fi
  for selected_target in $selected_targets; do
    case "$operation:$selected_target" in
      install:opencode|install:mcode|install:vibe|update:opencode|update:mcode|update:vibe) record_host "$selected_target" ;;
      install:codex) install_codex ;;
      install:claude|install:claude-code) install_claude ;;
      update:codex) update_codex ;;
      update:claude|update:claude-code) update_claude ;;
    esac
  done
  IFS=$previous_ifs
fi
