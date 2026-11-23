#!/usr/bin/env sh
set -eu

repository="${SHIORI_REPOSITORY:-Dragonshorn-Studios/shiori-brain}"
marketplace="${SHIORI_MARKETPLACE:-dragonshorn-brain}"
default_archive_url='https://dragonshorn-studios.github.io/shiori-brain/'
guide_url="https://github.com/$repository/blob/main/AGENT-SETUP.md"
checkout="${SHIORI_CHECKOUT:-$HOME/.local/share/shiori/shiori-brain}"
state_root="${SHIORI_STATE_HOME:-$HOME/.local/state/shiori}"
skills_root="${SHIORI_SKILLS_HOME:-$HOME/.agents/skills}"
claude_skills_root="${SHIORI_CLAUDE_SKILLS_HOME:-$HOME/.claude/skills}"
installed_hosts_file="$state_root/installed-hosts"
managed_skills_file="$state_root/managed-skills"
managed_claude_skills_file="$state_root/managed-claude-skills"
skill_link_temp_prefix='.shiori-link-'
checkout_changed='false'
skills_changed='false'
mcp_changed='false'
mcp_ran='false'
mcp_output=''
checkout_line=''
verbose='false'
help='false'
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
  if [ "$context" = checkout ] && [ -f 'scripts/shiori-mcp.mjs' ]; then
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
print_mcp_detect_lines() {
  printf '%s\n' "$1" | while IFS= read -r mcp_line; do
    [ -n "$mcp_line" ] || continue
    case $mcp_line in
      'MCP done') continue ;;
      'MCP detect not found:'*) printf 'craft:%s\n' "${mcp_line#MCP detect}" ;;
      'MCP detect '*)
        rest=${mcp_line#MCP detect }
        name=${rest%% *}
        rest=${rest#* }
        case $rest in
          found\ *) printf 'craft: %s %s\n' "$name" "$rest" ;;
        esac
        ;;
    esac
  done
}
print_quiet_mcp_reports() {
  [ "$mcp_ran" = true ] || return 0
  printf '%s\n' "$mcp_output" | while IFS= read -r mcp_line; do
    [ -n "$mcp_line" ] || continue
    case $mcp_line in
      'MCP done'|'MCP detect '*) continue ;;
      MCP\ *) ;;
      *) continue ;;
    esac
    rest=${mcp_line#MCP }
    host=${rest%% *}
    rest=${rest#* }
    name=${rest%% *}
    rest=${rest#* }
    status=${rest%% *}
    detail=${rest#"$status"}
    detail=${detail# }
    case $status in
      added|updated|unchanged|conflict|error)
        if [ -n "$detail" ]; then
          printf '%s: MCP %s %s %s\n' "$host" "$name" "$status" "$detail"
        else
          printf '%s: MCP %s %s\n' "$host" "$name" "$status"
        fi
        ;;
    esac
  done
}
run_mcp_cli() {
  has_command node || { printf '%s\n' 'Skipping MCP config: node is not available.'; return 0; }
  mcp_cmd=$1
  detect_or_list=false
  if [ "$mcp_cmd" = detect ] || [ "$mcp_cmd" = list ]; then
    detect_or_list=true
  fi
  helper=$(resolve_mcp_helper) || {
    if [ "$detect_or_list" = true ]; then
      printf '%s\n' 'Skipping Craft CLI detect: cannot load the Shiori MCP helper.'
      return 0
    fi
    return 1
  }
  pages_origin=$(archive_url) || pages_origin=''
  if [ -n "$pages_origin" ]; then
    if ! is_allowed_archive_url "$pages_origin"; then
      if [ "$detect_or_list" = true ]; then
        pages_origin=''
      else
        printf '%s\n' 'SHIORI_BRAIN_BASE_URL must be an https URL (http is allowed only for localhost).' >&2
        return 1
      fi
    fi
  elif [ "$detect_or_list" != true ]; then
    printf '%s\n' 'Set SHIORI_BRAIN_BASE_URL to the published Pages origin before installing MCP servers. The installer will not fall back to another project archive.' >&2
    return 1
  fi
  set -- "$@" --home "$HOME" --checkout "$checkout"
  if [ -n "$pages_origin" ]; then
    set -- "$@" --base-url "$pages_origin"
  fi
  output=$(node "$helper" "$@") || {
    if [ "$detect_or_list" = true ]; then
      printf '%s\n' 'Skipping Craft CLI detect: helper failed.'
      return 0
    fi
    return 1
  }
  last_line=$(printf '%s\n' "$output" | tail -n 1)
  if [ "$last_line" != 'MCP done' ]; then
    if [ "$detect_or_list" = true ]; then
      printf '%s\n' 'Skipping Craft CLI detect: helper produced no status line.'
      return 0
    fi
    printf '%s\n' 'Shiori MCP helper produced no status line.' >&2
    return 1
  fi
  mcp_ran='true'
  mcp_output="$mcp_output
$output"
  if printf '%s\n' "$output" | grep -qE '^MCP [^[:space:]]+ [^[:space:]]+ (added|updated)([[:space:]]|\(|$)'; then
    mcp_changed='true'
  fi
  if [ "$mcp_cmd" = detect ] || [ "$mcp_cmd" = list ]; then
    print_mcp_detect_lines "$output"
  elif [ "$verbose" = true ]; then
    printf '%s\n' "$output" | sed '/^MCP done$/d'
  fi
}
contains_text() {
  case $1 in
    *"$2"*) return 0 ;;
    *) return 1 ;;
  esac
}
normalize_host() {
  case $1 in
    claude-code) printf '%s\n' 'claude' ;;
    glm-acp) printf '%s\n' 'glm' ;;
    *) printf '%s\n' "$1" ;;
  esac
}
host_detected() {
  case $1 in
    opencode) has_command opencode || has_home '.config/opencode' ;;
    codex) has_command codex || has_home '.codex' ;;
    claude|claude-code) has_command claude || has_home '.claude' ;;
    glm|glm-acp) has_command glm-acp-agent || has_home '.local/share/zed/external_agents/registry/npx/glm-acp-agent/node_modules/.bin/glm-acp-agent' || [ -f "$HOME/.local/share/zed/external_agents/registry/npx/glm-acp-agent/node_modules/.bin/glm-acp-agent" ] ;;
    zcode) has_command zcode || has_home '.zcode' ;;
    cursor) has_command cursor || has_home '.cursor' ;;
    mcode) has_command mcode || has_home '.minimax' ;;
    windsurf) has_command windsurf || has_home '.windsurf' ;;
    vibe) has_command vibe || has_home '.vibe' ;;
    devin) has_command devin || has_home '.config/devin' || has_home '.devin' ;;
    zed) has_command zed || has_home '.config/zed' || has_home '.local/share/zed' ;;
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
assert_home() {
  [ -n "${HOME:-}" ] || { printf '%s\n' 'HOME is empty or missing.' >&2; return 1; }
}
phys_home() {
  CDPATH= cd -P "$HOME" 2>/dev/null && pwd
}
is_our_skill_link() {
  [ -L "$1" ] && [ "$(readlink "$1")" = "$2" ]
}
assert_skills_dest() {
  dest=$1
  assert_home || return 1
  home_phys=$(phys_home) || { printf '%s\n' 'HOME is empty or missing.' >&2; return 1; }
  case $dest in
    "$HOME"|"$HOME"/*|"$home_phys"|"$home_phys"/*) ;;
    *) printf 'Refusing to write skills outside HOME: %s\n' "$dest" >&2; return 1 ;;
  esac
  existing=$dest
  while [ ! -e "$existing" ] && [ ! -L "$existing" ]; do
    parent=$(dirname "$existing")
    [ "$parent" = "$existing" ] && break
    existing=$parent
  done
  if [ -L "$existing" ] || [ -d "$existing" ]; then
    dest_phys=$(CDPATH= cd -P "$existing" 2>/dev/null && pwd) || {
      printf 'Refusing skills directory symlink that leaves HOME: %s\n' "$dest" >&2
      return 1
    }
    case $dest_phys in
      "$home_phys"|"$home_phys"/*) ;;
      *) printf 'Refusing skills directory symlink that leaves HOME: %s\n' "$dest" >&2; return 1 ;;
    esac
  fi
}
cleanup_skill_temps() {
  dest=$1
  [ -d "$dest" ] || return 0
  for leftover in "$dest"/$skill_link_temp_prefix*; do
    if [ -L "$leftover" ] || [ -e "$leftover" ]; then
      rm -f "$leftover"
    fi
  done
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
    before=$(git -C "$checkout" rev-parse HEAD)
    if [ "$verbose" = true ]; then
      git -C "$checkout" pull --ff-only origin main
    else
      git -C "$checkout" pull -q --ff-only origin main
    fi
    after=$(git -C "$checkout" rev-parse HEAD)
    if [ "$before" = "$after" ]; then
      checkout_line="checkout: already up to date $after"
    else
      checkout_changed='true'
      checkout_line="checkout: fast-forwarded $after"
    fi
  elif [ -e "$checkout" ] || [ -L "$checkout" ]; then
    printf 'Refusing to replace non-checkout path: %s\n' "$checkout" >&2
    return 1
  else
    mkdir -p "${checkout%/*}"
    if [ "$verbose" = true ]; then
      git clone --filter=blob:none --branch main "https://github.com/$repository.git" "$checkout"
    else
      git clone -q --filter=blob:none --branch main "https://github.com/$repository.git" "$checkout"
    fi
    checkout_changed='true'
    after=$(git -C "$checkout" rev-parse HEAD)
    checkout_line="checkout: cloned $after"
  fi
}
sync_skills_dest() {
  dest_root=$1
  managed_file=$2
  [ -d "$checkout/skills" ] || { printf 'Checkout has no skills directory: %s\n' "$checkout" >&2; return 1; }
  has_command ln && has_command readlink && has_command rm && has_command mkdir && has_command mv || { printf '%s\n' 'Cannot link skills: ln, readlink, rm, mkdir, and mv are required. On Windows use the PowerShell installer.' >&2; return 1; }
  assert_skills_dest "$dest_root" || return 1
  mkdir -p "$state_root"
  if [ ! -e "$dest_root" ] && [ ! -L "$dest_root" ]; then
    mkdir -p "$dest_root"
  fi
  assert_skills_dest "$dest_root" || return 1
  cleanup_skill_temps "$dest_root"
  if [ -f "$managed_file" ]; then
    while IFS= read -r old_skill; do
      [ -n "$old_skill" ] || continue
      old_target="$dest_root/$old_skill"
      old_source="$checkout/skills/$old_skill"
      if [ ! -d "$old_source" ] && is_our_skill_link "$old_target" "$old_source"; then
        rm "$old_target"
        skills_changed='true'
      fi
    done < "$managed_file"
  fi
  next_managed="$managed_file.next"
  : > "$next_managed"
  for source_skill in "$checkout/skills"/*; do
    [ -d "$source_skill" ] || continue
    skill_name=${source_skill##*/}
    target_skill="$dest_root/$skill_name"
    if [ -L "$target_skill" ] || [ -e "$target_skill" ]; then
      if is_our_skill_link "$target_skill" "$source_skill"; then
        printf '%s\n' "$skill_name" >> "$next_managed"
        continue
      fi
      printf 'Warning: skipping skill %s; %s already belongs to something else.\n' "$skill_name" "$target_skill" >&2
      continue
    fi
    tmp_skill="$dest_root/$skill_link_temp_prefix$skill_name.$$"
    ln -s "$source_skill" "$tmp_skill"
    mv "$tmp_skill" "$target_skill"
    printf '%s\n' "$skill_name" >> "$next_managed"
    skills_changed='true'
  done
  if [ -f "$managed_file" ] && [ "$(cat "$next_managed")" = "$(cat "$managed_file")" ]; then
    rm -f "$next_managed"
  else
    mv "$next_managed" "$managed_file"
    skills_changed='true'
  fi
  if [ "$verbose" = true ]; then
    printf 'Shared Shiori skills linked from %s into %s.\n' "$checkout" "$dest_root"
  fi
}
sync_shared_skills() {
  sync_skills_dest "$skills_root" "$managed_skills_file"
}
sync_claude_skills() {
  sync_skills_dest "$claude_skills_root" "$managed_claude_skills_file"
}
warn_legacy_codex_plugin() {
  config_file="$HOME/.codex/config.toml"
  [ -f "$config_file" ] || return 0
  if contains_text "$(cat "$config_file" 2>/dev/null)" "plugins.\"shiori@$marketplace\""; then
    printf 'Warning: Codex plugin shiori@%s duplicates skills now synced to ~/.agents/skills. Remove it with: codex plugin remove shiori@%s\n' "$marketplace" "$marketplace" >&2
  fi
}
warn_legacy_claude_plugin() {
  config_file="$HOME/.claude/plugins/installed_plugins.json"
  [ -f "$config_file" ] || return 0
  if contains_text "$(cat "$config_file" 2>/dev/null)" "shiori@$marketplace"; then
    printf 'Warning: Claude plugin shiori@%s duplicates skills now synced to ~/.claude/skills. Remove it with: claude plugin uninstall shiori@%s --scope user\n' "$marketplace" "$marketplace" >&2
  fi
}
comma_hosts() {
  first=true
  for item; do
    if [ "$first" = true ]; then
      printf '%s' "$item"
      first=false
    else
      printf ', %s' "$item"
    fi
  done
}
print_host_list() {
  prefix=$1
  shift
  if [ "$#" -eq 0 ]; then
    printf '%s: none\n' "$prefix"
  else
    printf '%s: %s\n' "$prefix" "$(comma_hosts "$@")"
  fi
}
list_detected_hosts() {
  detected_list=''
  not_detected=''
  if host_detected opencode; then detected_list="$detected_list opencode"; else not_detected="$not_detected opencode"; fi
  if host_detected mcode; then detected_list="$detected_list mcode"; else not_detected="$not_detected mcode"; fi
  if host_detected vibe; then detected_list="$detected_list vibe"; else not_detected="$not_detected vibe"; fi
  if host_detected codex; then detected_list="$detected_list codex"; else not_detected="$not_detected codex"; fi
  if host_detected claude; then detected_list="$detected_list claude"; else not_detected="$not_detected claude"; fi
  if host_detected cursor; then detected_list="$detected_list cursor"; else not_detected="$not_detected cursor"; fi
  if host_detected devin; then detected_list="$detected_list devin"; else not_detected="$not_detected devin"; fi
  if host_detected zed; then detected_list="$detected_list zed"; else not_detected="$not_detected zed"; fi
  if host_detected glm; then detected_list="$detected_list glm"; else not_detected="$not_detected glm"; fi
  if host_detected zcode; then detected_list="$detected_list zcode"; else not_detected="$not_detected zcode"; fi
  if host_detected windsurf; then detected_list="$detected_list windsurf"; else not_detected="$not_detected windsurf"; fi
  detected_list=${detected_list# }
  not_detected=${not_detected# }
}
print_quiet_destinations() {
  agents_hosts=''
  claude_hosts=''
  for selected_target in $selected_targets; do
    case $selected_target in
      opencode|codex|cursor|mcode|vibe|devin|zed) agents_hosts="$agents_hosts $selected_target" ;;
      claude|claude-code|glm|glm-acp) claude_hosts="$claude_hosts $selected_target" ;;
    esac
  done
  agents_hosts=${agents_hosts# }
  claude_hosts=${claude_hosts# }
  [ -z "$agents_hosts" ] || printf '%s: skills -> ~/.agents/skills\n' "$(comma_hosts $agents_hosts)"
  [ -z "$claude_hosts" ] || printf '%s: skills -> ~/.claude/skills\n' "$(comma_hosts $claude_hosts)"
  if [ "$mcp_ran" = true ]; then
    for selected_target in $selected_targets; do
      case $selected_target in
      opencode) printf 'opencode: MCP -> ~/.config/opencode/opencode.jsonc\n' ;;
      codex) printf 'codex: MCP -> ~/.codex/config.toml\n' ;;
      claude|claude-code) printf 'claude: MCP -> ~/.claude.json\n' ;;
      cursor) printf 'cursor: MCP -> ~/.cursor/mcp.json\n' ;;
      devin) printf 'devin: MCP -> ~/.config/devin/mcp_config.json\n' ;;
      esac
    done
    print_quiet_mcp_reports
  fi
}
print_quiet_report() {
  if [ -z "$checkout_line" ] && [ -d "$checkout/.git" ]; then
    checkout_line="checkout: already up to date $(git -C "$checkout" rev-parse HEAD)"
  fi
  [ -z "$checkout_line" ] || printf '%s\n' "$checkout_line"
  list_detected_hosts
  print_host_list detected $detected_list
  print_quiet_destinations
  if [ "$install_failed" = true ] && [ "$checkout_changed" = false ] && [ "$skills_changed" = false ] && [ "$mcp_changed" = false ]; then
    printf 'skipped\n'
  elif [ "$checkout_changed" = false ] && [ "$skills_changed" = false ] && [ "$mcp_changed" = false ]; then
    printf 'already current\n'
  else
    printf 'updated\n'
  fi
}
print_usage() {
  printf '%s\n' \
    '' \
    'How --install and --update work' \
    '  --install [hosts]  set up the named hosts, or every locally detected host if none are named. Valid names: opencode, mcode, vibe, codex, claude, cursor, devin, zed, glm.' \
    '  --update [hosts]   re-run the installer for the named hosts, or every currently detected host if none are named.' \
    '                     Recorded-but-missing hosts are not required. Capabilities added by a newer doctor are applied on update.' \
    '  --verbose          print the status table, recipes, git, and MCP lines.' \
    '  --help             print this usage text.' \
    '  Host names may be space- or comma-separated; SHIORI_INSTALL / SHIORI_UPDATE / SHIORI_VERBOSE are the pipe equivalents.' \
    '  MCP: Craft CLIs are found on PATH or in bounded Program Files / LocalAppData *Craft* installs, including one nested *Craft* directory (WSL: /mnt/c Program Files; LocalAppData only if SHIORI_CRAFT_LOCALAPPDATA is set). Windows and WSL use <name>-cli mcp --attach 7979. A bare run reports which Craft CLIs were found without writing MCP config.' \
    '  Pipe (every detected host first; a bare curl | sh stays read-only):' \
    '    curl -fsSL https://raw.githubusercontent.com/Dragonshorn-Studios/shiori-brain/main/scripts/shiori-doctor.sh | SHIORI_INSTALL=all sh' \
    '    $env:SHIORI_INSTALL='\''all'\''; irm https://raw.githubusercontent.com/Dragonshorn-Studios/shiori-brain/main/scripts/shiori-doctor.ps1 | iex' \
    '    curl -fsSL https://raw.githubusercontent.com/Dragonshorn-Studios/shiori-brain/main/scripts/shiori-doctor.sh | SHIORI_UPDATE=all sh' \
    '    $env:SHIORI_UPDATE='\''all'\''; irm https://raw.githubusercontent.com/Dragonshorn-Studios/shiori-brain/main/scripts/shiori-doctor.ps1 | iex' \
    '  Named hosts: SHIORI_INSTALL='\''codex,claude,cursor'\'' (or SHIORI_UPDATE).' \
    '' \
    'Recommended native setup' \
    '  OpenCode: --install opencode links skills through ~/.agents/skills and writes MCP config.' \
    '  Codex:    --install codex links skills through ~/.agents/skills and writes MCP config. Plugin marketplace is a separate ChatGPT web channel.' \
    '  Claude:   --install claude links skills through ~/.claude/skills and writes MCP config. Plugin marketplace is a separate channel.' \
    '  glm:      --install glm links skills through ~/.claude/skills when glm-acp-agent is present as a file.' \
    '  Cursor:   --install cursor writes MCP config and links skills through ~/.agents/skills. It does not write ~/.cursor/skills.' \
    '  MCode:    select --install mcode to use the same managed checkout and global Agent Skills links.' \
    '  Vibe:     select --install vibe to use the same managed checkout and global Agent Skills links.' \
    '  Devin:    --install devin writes user-scope MCP config and links skills through ~/.agents/skills.' \
    '  Zed:      --install zed links skills through ~/.agents/skills.' \
    '  ZCode:    Settings -> Plugins -> Create -> Add marketplace -> Dragonshorn-Studios/shiori-brain; install Shiori.' \
    '' \
    "Full instructions: $guide_url"
}
print_banner() {
  printf 'Shiori agent doctor\nRepository: %s\nMode: %s (%s)\n\n' "$repository" "$context" "$project_hint"
row 'OpenCode' opencode '.config/opencode' local opencode
row 'Codex' codex '.codex' local codex
row 'Claude Code' claude '.claude' local claude
row 'glm-acp-agent' glm-acp-agent '.local/share/zed/external_agents/registry/npx/glm-acp-agent/node_modules/.bin/glm-acp-agent' local glm
row 'ZCode' zcode '.zcode' local zcode
row 'Cursor' cursor '.cursor' local cursor
row 'MCode / MiniMax' mcode '.minimax' local mcode
row 'Windsurf' windsurf '.windsurf' local windsurf
row 'Vibe' vibe '.vibe' local vibe
row 'Devin' devin '.config/devin' cloud devin
row 'Zed' zed '.config/zed' local zed
  printf '%s\n' '' 'MCP servers' '  Installed under --install / --update for cursor, devin, opencode, claude, and codex. Craft CLIs are found on PATH or in bounded Program Files / LocalAppData *Craft* installs, including one nested *Craft* directory (WSL: /mnt/c Program Files; LocalAppData only if SHIORI_CRAFT_LOCALAPPDATA is set). Windows and WSL use <name>-cli mcp --attach 7979. A bare run reports which Craft CLIs were found without writing MCP config. A read-only run does not launch host CLIs.'
  print_usage
}
operation=''
selected_targets="${SHIORI_INSTALL:-}"
case ${SHIORI_VERBOSE:-} in 1|true|all|yes) verbose='true' ;; esac
while [ "$#" -gt 0 ]; do
  case $1 in
    --verbose) verbose='true'; shift ;;
    --help) help='true'; shift ;;
    *) break ;;
  esac
done
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
normalized_targets=''
for selected_target in $selected_targets; do
  [ -n "$selected_target" ] || continue
  selected_target=$(normalize_host "$selected_target")
  normalized_targets="$normalized_targets $selected_target"
done
selected_targets=${normalized_targets# }
case $selected_targets in
  all|1|true) selected_targets='' ;;
esac
select_detected_hosts() {
  selected_targets=''
    host_detected opencode && selected_targets="$selected_targets opencode"
    host_detected mcode && selected_targets="$selected_targets mcode"
    host_detected vibe && selected_targets="$selected_targets vibe"
    host_detected codex && selected_targets="$selected_targets codex"
    host_detected claude && selected_targets="$selected_targets claude"
    host_detected cursor && selected_targets="$selected_targets cursor"
    host_detected devin && selected_targets="$selected_targets devin"
    host_detected zed && selected_targets="$selected_targets zed"
    host_detected glm && selected_targets="$selected_targets glm"
  selected_targets=${selected_targets# }
}
if [ -n "$operation" ] && [ -z "$selected_targets" ]; then
  select_detected_hosts
  if [ -z "$selected_targets" ]; then
    printf '%s\n' 'No installable hosts detected. Pass a host name to --install / --update: opencode, mcode, vibe, codex, claude, cursor, devin, zed, or glm.' >&2
    exit 2
  fi
fi
assert_installer() {
  case $1 in
    opencode)
      has_command git && has_command ln && has_command readlink && has_command rm && has_command mkdir && has_command mv || { printf '%s\n' 'Cannot install shared skills: git, ln, readlink, rm, mkdir, and mv are required. On Windows use the PowerShell installer.' >&2; return 1; }
      has_command node || { printf '%s\n' 'Cannot install OpenCode MCP: node is not available.' >&2; return 1; }
      ;;
    codex)
      has_command git && has_command ln && has_command readlink && has_command rm && has_command mkdir && has_command mv || { printf '%s\n' 'Cannot install shared skills: git, ln, readlink, rm, mkdir, and mv are required. On Windows use the PowerShell installer.' >&2; return 1; }
      has_command node || { printf '%s\n' 'Cannot install Codex MCP: node is not available.' >&2; return 1; }
      ;;
    claude|claude-code)
      has_command git && has_command ln && has_command readlink && has_command rm && has_command mkdir && has_command mv || { printf '%s\n' 'Cannot install shared skills: git, ln, readlink, rm, mkdir, and mv are required. On Windows use the PowerShell installer.' >&2; return 1; }
      has_command node || { printf '%s\n' 'Cannot install Claude Code MCP: node is not available.' >&2; return 1; }
      ;;
    glm|glm-acp)
      has_command git && has_command ln && has_command readlink && has_command rm && has_command mkdir && has_command mv || { printf '%s\n' 'Cannot install shared skills: git, ln, readlink, rm, mkdir, and mv are required. On Windows use the PowerShell installer.' >&2; return 1; }
      ;;
    cursor)
      has_command git && has_command ln && has_command readlink && has_command rm && has_command mkdir && has_command mv || { printf '%s\n' 'Cannot install shared skills: git, ln, readlink, rm, mkdir, and mv are required. On Windows use the PowerShell installer.' >&2; return 1; }
      has_command node || { printf '%s\n' 'Cannot install Cursor MCP: node is not available.' >&2; return 1; }
      ;;
    mcode)
      has_command git && has_command ln && has_command readlink && has_command rm && has_command mkdir && has_command mv || { printf '%s\n' 'Cannot install shared skills: git, ln, readlink, rm, mkdir, and mv are required. On Windows use the PowerShell installer.' >&2; return 1; }
      ;;
    vibe)
      has_command git && has_command ln && has_command readlink && has_command rm && has_command mkdir && has_command mv || { printf '%s\n' 'Cannot install shared skills: git, ln, readlink, rm, mkdir, and mv are required. On Windows use the PowerShell installer.' >&2; return 1; }
      ;;
    devin)
      has_command git && has_command ln && has_command readlink && has_command rm && has_command mkdir && has_command mv || { printf '%s\n' 'Cannot install shared skills: git, ln, readlink, rm, mkdir, and mv are required. On Windows use the PowerShell installer.' >&2; return 1; }
      has_command node || { printf '%s\n' 'Cannot install Devin MCP: node is not available.' >&2; return 1; }
      ;;
    zed)
      has_command git && has_command ln && has_command readlink && has_command rm && has_command mkdir && has_command mv || { printf '%s\n' 'Cannot install shared skills: git, ln, readlink, rm, mkdir, and mv are required. On Windows use the PowerShell installer.' >&2; return 1; }
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

skills_dest_installed() {
  dest_root=$1
  managed_file=$2
  [ -d "$checkout/.git" ] && [ -s "$managed_file" ] || return 1
  found_skill=false
  while IFS= read -r skill_name; do
    [ -n "$skill_name" ] || continue
    found_skill=true
    target_skill="$dest_root/$skill_name"
    source_skill="$checkout/skills/$skill_name"
    is_our_skill_link "$target_skill" "$source_skill" || return 1
  done < "$managed_file"
  [ "$found_skill" = true ]
}

shared_skills_installed() {
  skills_dest_installed "$skills_root" "$managed_skills_file"
}

claude_skills_installed() {
  skills_dest_installed "$claude_skills_root" "$managed_claude_skills_file"
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
    opencode|codex|cursor|mcode|vibe|devin|zed)
      shared_skills_installed && parts='managed Agent Skills'
      ;;
    claude|claude-code|glm|glm-acp)
      claude_skills_installed && parts='managed Agent Skills'
      ;;
  esac
  case $1 in
    opencode|codex|claude|claude-code|cursor|devin)
      mcp_configured "$1" && parts="${parts:+$parts + }MCP configured"
      ;;
  esac
  if [ -n "$parts" ]; then
    printf 'installed (%s)' "$parts"
    return
  fi
  case $1 in
    opencode|codex|claude|claude-code|glm|glm-acp|cursor|mcode|vibe|devin|zed) printf '%s' 'not installed' ;;
    *) printf '%s' 'unknown (no local status API)' ;;
  esac
}

if [ "$help" = true ]; then
  print_usage
  exit 0
fi
if [ "$verbose" = true ]; then
  print_banner
fi
if [ -z "$operation" ]; then
  if [ "$verbose" != true ]; then
    list_detected_hosts
    print_host_list detected $detected_list
    print_host_list 'not detected' $not_detected
  fi
  run_mcp_cli detect
fi

if [ -n "$operation" ]; then
  assert_home || exit 2
  if [ "$verbose" = true ]; then
    printf '%s\n' '' "Selected operation: $operation"
  fi
  previous_ifs=$IFS
  IFS=', '
  agents_skills_selected='false'
  claude_skills_selected='false'
  mcp_selected='false'
  warn_codex_plugin='false'
  warn_claude_plugin='false'
  install_failed='false'
  usable_targets=''
  for selected_target in $selected_targets; do
    if assert_installer "$selected_target"; then
      usable_targets="$usable_targets $selected_target"
    else
      printf 'Warning: cannot install %s; continuing with remaining hosts.\n' "$selected_target" >&2
      install_failed='true'
    fi
  done
  selected_targets=${usable_targets# }
  if [ -z "$selected_targets" ]; then
    printf '%s\n' 'No remaining hosts could be installed.' >&2
    exit 1
  fi
  for selected_target in $selected_targets; do
    case $selected_target in
    opencode|codex|cursor|mcode|vibe|devin|zed) agents_skills_selected='true' ;;
    claude|claude-code|glm|glm-acp) claude_skills_selected='true' ;;
    esac
    case $selected_target in
    opencode|codex|claude|claude-code|cursor|devin) mcp_selected='true' ;;
    esac
    case $selected_target in
      codex) warn_codex_plugin='true' ;;
      claude|claude-code) warn_claude_plugin='true' ;;
    esac
  done
  if [ "$agents_skills_selected" = true ] || [ "$claude_skills_selected" = true ] || [ "$mcp_selected" = true ]; then
    [ "$operation" != update ] || [ -d "$checkout/.git" ] || [ "$mcp_selected" = true ] || { printf 'No managed checkout exists to update: %s\n' "$checkout" >&2; exit 2; }
    if [ "$agents_skills_selected" = true ] || [ "$claude_skills_selected" = true ]; then
      [ "$operation" != update ] || [ -d "$checkout/.git" ] || { printf 'No managed checkout exists to update: %s\n' "$checkout" >&2; exit 2; }
      ensure_checkout
    fi
  fi
  if [ "$agents_skills_selected" = true ]; then
    sync_shared_skills
    [ "$warn_codex_plugin" = true ] && warn_legacy_codex_plugin
  fi
  if [ "$claude_skills_selected" = true ]; then
    sync_claude_skills
    [ "$warn_claude_plugin" = true ] && warn_legacy_claude_plugin
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
      install:codex|update:codex) record_host codex; run_mcp_cli install --host codex ;;
      install:claude|update:claude|install:claude-code|update:claude-code) record_host claude; run_mcp_cli install --host claude ;;
      install:glm|update:glm|install:glm-acp|update:glm-acp) record_host glm ;;
      install:cursor|update:cursor) record_host cursor; run_mcp_cli install --host cursor ;;
      install:mcode|update:mcode) record_host mcode ;;
      install:vibe|update:vibe) record_host vibe ;;
      install:devin|update:devin) record_host devin; run_mcp_cli install --host devin ;;
      install:zed|update:zed) record_host zed ;;
    esac
  done
  IFS=$previous_ifs
  if [ "$verbose" = true ]; then
    if [ "$checkout_changed" = false ] && [ "$skills_changed" = false ] && [ "$mcp_changed" = false ]; then
      printf 'already current\n'
    fi
  else
    print_quiet_report
  fi
  if [ "$install_failed" = true ]; then
    exit 1
  fi
fi
