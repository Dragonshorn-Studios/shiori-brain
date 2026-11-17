#!/usr/bin/env sh
set -eu

repository="${SHIORI_REPOSITORY:-Dragonshorn-Studios/shiori-brain}"
marketplace="${SHIORI_MARKETPLACE:-dragonshorn-brain}"
default_archive_url='https://dragonshorn-studios.github.io/shiori-brain/'
guide_url="https://github.com/$repository/blob/main/AGENT-SETUP.md"
checkout="${SHIORI_CHECKOUT:-$HOME/.local/share/shiori/shiori-brain}"
state_root="${SHIORI_STATE_HOME:-$HOME/.local/state/shiori}"
skills_root="${SHIORI_SKILLS_HOME:-$HOME/.agents/skills}"
installed_hosts_file="$state_root/installed-hosts"
managed_skills_file="$state_root/managed-skills"
mcp_helper_tmp=''
mcp_helper_dir=''
if [ -d '.agents/skills' ] && [ -d 'plugins/shiori' ]; then
  context='checkout'
  project_hint='project adapters are ready in this checkout'
else
  context='remote'
  project_hint='no Shiori checkout detected; use a marketplace installation below'
fi

has_command() { command -v "$1" >/dev/null 2>&1; }
has_home() { [ -e "$HOME/$1" ]; }
cleanup_mcp_helper() {
  [ -z "$mcp_helper_tmp" ] || rm -f "$mcp_helper_tmp"
  [ -z "$mcp_helper_dir" ] || rm -rf "$mcp_helper_dir"
}
trap cleanup_mcp_helper EXIT
resolve_mcp_helper() {
  if [ -n "${SHIORI_MCP_HELPER:-}" ] && [ -f "$SHIORI_MCP_HELPER" ]; then
    printf '%s\n' "$SHIORI_MCP_HELPER"
    return 0
  fi
  if [ -f 'scripts/shiori-mcp.mjs' ]; then
    printf '%s\n' 'scripts/shiori-mcp.mjs'
    return 0
  fi
  has_command curl || { printf '%s\n' 'Cannot load the Shiori MCP helper: curl is not available.' >&2; return 1; }
  mcp_helper_dir=$(mktemp -d) || return 1
  mcp_helper_tmp="$mcp_helper_dir/shiori-mcp.mjs"
  curl -fsSL "https://raw.githubusercontent.com/$repository/main/scripts/shiori-mcp.mjs" > "$mcp_helper_tmp" || return 1
  printf '%s\n' "$mcp_helper_tmp"
}
archive_url() {
  if [ -n "${SHIORI_BRAIN_BASE_URL:-}" ]; then
    printf '%s\n' "$SHIORI_BRAIN_BASE_URL"
    return 0
  fi
  if [ -n "$default_archive_url" ]; then
    printf '%s\n' "$default_archive_url"
    return 0
  fi
  owner=${repository%%/*}
  repo=${repository#*/}
  [ -n "$owner" ] && [ -n "$repo" ] && [ "$repository" != "$owner" ] || return 1
  owner_lc=$(printf '%s' "$owner" | tr '[:upper:]' '[:lower:]')
  repo_lc=$(printf '%s' "$repo" | tr '[:upper:]' '[:lower:]')
  if [ "$repo_lc" = "$owner_lc.github.io" ]; then
    printf 'https://%s.github.io/\n' "$owner_lc"
    return 0
  fi
  printf 'https://%s.github.io/%s/\n' "$owner_lc" "$repo"
}
is_allowed_archive_url() {
  lowered=$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')
  case $lowered in
    https://*) return 0 ;;
  esac
  rest=${lowered#http://}
  [ "$rest" != "$lowered" ] || return 1
  hostport=${rest%%/*}
  case $hostport in
    localhost|localhost:*|127.0.0.1|127.0.0.1:*) return 0 ;;
    \[::1\]|\[::1\]:*) return 0 ;;
  esac
  return 1
}
run_mcp_cli() {
  has_command node || { printf '%s\n' 'Skipping MCP config: node is not available.'; return 0; }
  helper=$(resolve_mcp_helper) || return 1
  pages_origin=$(archive_url) || pages_origin=''
  [ -n "$pages_origin" ] || { printf '%s\n' 'Set SHIORI_BRAIN_BASE_URL to the published Pages origin before installing MCP servers. The installer will not fall back to another project archive.' >&2; return 1; }
  is_allowed_archive_url "$pages_origin" || { printf '%s\n' 'SHIORI_BRAIN_BASE_URL must be an https URL (http is allowed only for localhost).' >&2; return 1; }
  node "$helper" "$@" --home "$HOME" --checkout "$checkout" --base-url "$pages_origin"
}
contains_text() {
  case $1 in
    *"$2"*) return 0 ;;
    *) return 1 ;;
  esac
}
host_detected() {
  case $1 in
    opencode) has_command opencode || has_home '.config/opencode' ;;
    mcode) has_command mcode || has_home '.minimax' ;;
    vibe) has_command vibe || has_home '.vibe' ;;
    codex) has_command codex || has_home '.codex' ;;
    claude|claude-code) has_command claude || has_home '.claude' ;;
    cursor) has_command cursor || has_home '.cursor' ;;
    devin) has_command devin || has_home '.config/devin' || has_home '.devin' ;;
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
host_is_recorded() {
  [ -f "$installed_hosts_file" ] || return 1
  while IFS= read -r recorded_host; do [ "$recorded_host" = "$1" ] && return 0; done < "$installed_hosts_file"
  return 1
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
  printf '%s\n' 'Pass at least one installer: opencode, mcode, vibe, codex, claude, cursor, or devin.' >&2
  exit 2
fi
if [ "$operation" = 'update' ] && [ -z "$selected_targets" ]; then
  [ -f "$installed_hosts_file" ] || { printf '%s\n' 'No recorded Shiori installations to update.' >&2; exit 2; }
  while IFS= read -r recorded_host; do selected_targets="$selected_targets $recorded_host"; done < "$installed_hosts_file"
  detected_hints=''
  for candidate in opencode mcode vibe codex claude cursor devin; do
    case " $selected_targets " in *" $candidate "*) continue ;; esac
    host_is_recorded "$candidate" && continue
    host_detected "$candidate" && detected_hints="$detected_hints $candidate"
  done
  [ -z "$detected_hints" ] || printf 'Detected locally but not recorded:%s - pass them to --install or --update to enable their features.\n' "$detected_hints"
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
    cursor)
      has_command node || { printf '%s\n' 'Cannot install Cursor MCP: node is not available.' >&2; return 1; }
      ;;
    devin)
      has_command node || { printf '%s\n' 'Cannot install Devin MCP: node is not available.' >&2; return 1; }
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

mcp_configured() {
  case $1 in
    cursor) mcp_files='.cursor/mcp.json' ;;
    devin) mcp_files='.config/devin/mcp_config.json' ;;
    opencode) mcp_files='.config/opencode/opencode.json .config/opencode/opencode.jsonc' ;;
    claude|claude-code) mcp_files='.claude.json' ;;
    codex) mcp_files='.codex/config.toml' ;;
    *) return 1 ;;
  esac
  for mcp_file in $mcp_files; do
    [ -f "$HOME/$mcp_file" ] || continue
    contains_text "$(cat "$HOME/$mcp_file" 2>/dev/null)" 'shiori-brain' && return 0
  done
  return 1
}

shiori_status() {
  parts=''
  case $1 in
    opencode|mcode|vibe)
      shared_skills_installed && parts='managed Agent Skills'
      ;;
    codex)
      host_is_recorded codex && parts='recorded native plugin'
      ;;
    claude)
      host_is_recorded claude && parts='recorded native plugin'
      ;;
  esac
  case $1 in
    opencode|cursor|devin|claude|codex)
      mcp_configured "$1" && parts="${parts:+$parts + }MCP configured"
      ;;
  esac
  if [ -n "$parts" ]; then
    printf 'installed (%s)' "$parts"
    return
  fi
  case $1 in
    opencode|mcode|vibe|cursor|devin) printf '%s' 'not installed' ;;
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
row 'Devin' devin '.config/devin' cloud devin

printf '%s\n' '' 'MCP servers' '  Installed under --install / --update for cursor, devin, opencode, claude, and codex. A read-only run does not launch host CLIs.'

printf '%s\n' \
  '' \
  'How --install and --update work' \
  '  --install <hosts>  set up the named hosts now. Valid names: opencode, mcode, vibe, codex, claude, cursor, devin.' \
  '  --update [hosts]   re-run the installer for every host recorded by an earlier --install, or only the named' \
  '                     hosts. Capabilities added by a newer doctor (for example MCP config) are applied on update.' \
  '  Host names may be space- or comma-separated; SHIORI_INSTALL / SHIORI_UPDATE are the pipe equivalents.' \
  '' \
  'Recommended native setup' \
  '  OpenCode: --install opencode links skills through ~/.agents/skills and writes MCP config.' \
  "  Codex:    codex plugin marketplace add $repository ; then open /plugins and install Shiori. --install codex also writes MCP config." \
  "  Claude:   /plugin marketplace add $repository ; then /plugin install shiori@$marketplace. --install claude also writes MCP config." \
  "  ZCode:    Settings -> Plugins -> Create -> Add marketplace -> $repository; install Shiori." \
  "  Cursor:   Settings -> Plugins; add https://github.com/$repository; install Shiori. --install cursor writes MCP config." \
  '  MCode:    select --install mcode to use the same managed checkout and global Agent Skills links.' \
  '  Vibe:     select --install vibe to use the same managed checkout and global Agent Skills links.' \
  '  Devin:    --install devin writes user-scope MCP config; the cloud workspace needs no local CLI.' \
  '' \
  "Full instructions: $guide_url"

if [ -n "$operation" ]; then
  printf '%s\n' '' "Selected operation: $operation"
  previous_ifs=$IFS
  IFS=', '
  shared_skills_selected='false'
  mcp_selected='false'
  for selected_target in $selected_targets; do
    assert_installer "$selected_target"
    case $selected_target in opencode|mcode|vibe) shared_skills_selected='true' ;; esac
    case $selected_target in cursor|claude|claude-code|codex|opencode|devin) mcp_selected='true' ;; esac
  done
  if [ "$shared_skills_selected" = true ]; then
    [ "$operation" != update ] || [ -d "$checkout/.git" ] || { printf 'No managed checkout exists to update: %s\n' "$checkout" >&2; exit 2; }
    ensure_checkout
    sync_shared_skills
  fi
  if [ "$mcp_selected" = true ]; then
    mcp_script="$checkout/packages/shiori-brain-mcp/src/index.js"
    if [ ! -f "$mcp_script" ]; then ensure_checkout; fi
    if [ "$operation" = update ] && [ -d "$checkout/.git" ]; then ensure_checkout; fi
    [ -f "$mcp_script" ] || { printf 'Shiori checkout is missing the MCP server: %s\n' "$mcp_script" >&2; exit 1; }
  fi
  for selected_target in $selected_targets; do
    case "$operation:$selected_target" in
      install:opencode|update:opencode) record_host opencode; run_mcp_cli install --host opencode ;;
      install:mcode|install:vibe|update:mcode|update:vibe) record_host "$selected_target" ;;
      install:codex) install_codex; run_mcp_cli install --host codex ;;
      install:claude|install:claude-code) install_claude; run_mcp_cli install --host claude ;;
      install:cursor|update:cursor) run_mcp_cli install --host cursor; record_host cursor ;;
      install:devin|update:devin) run_mcp_cli install --host devin; record_host devin ;;
      update:codex) update_codex; run_mcp_cli install --host codex ;;
      update:claude|update:claude-code) update_claude; run_mcp_cli install --host claude ;;
    esac
  done
  IFS=$previous_ifs
fi
