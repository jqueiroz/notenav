# notenav — TUI faceted browser for markdown notes
# https://github.com/jqueiroz/notenav

NOTENAV_VERSION="0.1.0-dev"

# --- Config loader ---
# Parses TOML config/schema files via yq (TOML→JSON), merges with jq.
# Result stored in NN_CFG_JSON for consumption by nn_cfg().

nn_load_config() {
  local notenav_root="$1"

  # Require yq and jq
  if ! command -v yq >/dev/null 2>&1; then
    echo "notenav: yq is required for config loading (install yq-go)" >&2
    return 1
  fi
  if ! command -v jq >/dev/null 2>&1; then
    echo "notenav: jq is required for config loading" >&2
    return 1
  fi

  # Step 1: Load config files to determine schema name
  local base_cfg="$notenav_root/config/base.toml"
  local user_cfg="${XDG_CONFIG_HOME:-$HOME/.config}/notenav/config.toml"

  # Find closest .nn directory (walk from cwd up to filesystem root)
  local project_nn_dir=""
  local _search_dir="$PWD"
  while true; do
    if [[ -d "$_search_dir/.nn" ]]; then
      project_nn_dir="$_search_dir/.nn"
      break
    fi
    [[ "$_search_dir" == "/" ]] && break
    _search_dir="$(dirname "$_search_dir")"
  done
  local project_cfg="${project_nn_dir:+$project_nn_dir/config.toml}"

  # Parse each config to JSON (empty object if missing)
  local base_json="{}" user_json="{}" project_json="{}"
  if [[ -f "$base_cfg" ]]; then
    base_json=$(yq -p=toml -o=json -I=0 '.' "$base_cfg" 2>/dev/null) || base_json="{}"
  fi
  if [[ -f "$user_cfg" ]]; then
    user_json=$(yq -p=toml -o=json -I=0 '.' "$user_cfg" 2>/dev/null) || user_json="{}"
  fi
  if [[ -n "$project_cfg" && -f "$project_cfg" ]]; then
    project_json=$(yq -p=toml -o=json -I=0 '.' "$project_cfg" 2>/dev/null) || project_json="{}"
  fi

  # Determine schema name: project "schema" > user "default_schema" > default "default_schema" > "compass"
  local schema_name
  schema_name=$(printf '%s' "$project_json" | jq -r '.schema // empty' 2>/dev/null)
  if [[ -z "$schema_name" ]]; then
    schema_name=$(printf '%s' "$user_json" | jq -r '.default_schema // empty' 2>/dev/null)
  fi
  if [[ -z "$schema_name" ]]; then
    schema_name=$(printf '%s' "$base_json" | jq -r '.default_schema // empty' 2>/dev/null)
  fi
  schema_name="${schema_name:-compass}"

  # Step 2: Resolve schema file (most specific wins)
  local schema_file=""
  if [[ -n "$project_nn_dir" && -f "$project_nn_dir/schemas/$schema_name.toml" ]]; then
    schema_file="$project_nn_dir/schemas/$schema_name.toml"
  elif [[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/notenav/schemas/$schema_name.toml" ]]; then
    schema_file="${XDG_CONFIG_HOME:-$HOME/.config}/notenav/schemas/$schema_name.toml"
  elif [[ -f "$notenav_root/config/schemas/$schema_name.toml" ]]; then
    schema_file="$notenav_root/config/schemas/$schema_name.toml"
  fi

  if [[ -z "$schema_file" ]]; then
    echo "notenav: schema '$schema_name' not found, falling back to compass" >&2
    schema_file="$notenav_root/config/schemas/compass.toml"
  fi

  if [[ ! -f "$schema_file" ]]; then
    echo "notenav: no schema file found at $schema_file" >&2
    return 1
  fi

  # Step 3: Parse schema and merge
  # Preferences: schema → base config → user config (project config does NOT contribute preferences)
  # Queries: user queries + project queries (project wins on name collisions)
  local schema_json
  schema_json=$(yq -p=toml -o=json -I=0 '.' "$schema_file" 2>/dev/null)
  if [[ -z "$schema_json" || "$schema_json" == "null" ]]; then
    echo "notenav: failed to parse schema $schema_file" >&2
    return 1
  fi

  # Extract only queries from project config (schema is already handled above)
  local project_queries="{}"
  if [[ -n "$project_json" && "$project_json" != "{}" ]]; then
    project_queries=$(printf '%s' "$project_json" | jq '{queries: (.queries // {})}' 2>/dev/null) || project_queries="{}"
  fi

  # Deep merge: jq * is recursive merge, later values win
  NN_CFG_JSON=$(printf '%s\n%s\n%s\n%s' "$schema_json" "$base_json" "$user_json" "$project_queries" \
    | jq -s '.[0] * .[1] * .[2] * .[3]' 2>/dev/null)

  if [[ -z "$NN_CFG_JSON" || "$NN_CFG_JSON" == "null" ]]; then
    echo "notenav: config merge failed" >&2
    return 1
  fi

  export NN_CFG_JSON
}

# Query the merged config. Usage: nn_cfg '.entity | keys[]'
nn_cfg() {
  printf '%s' "$NN_CFG_JSON" | jq -r "$1"
}

# --- Pre-compute schema values ---
# Extracts all schema/config values into bash variables at startup.
# Called once after nn_load_config(). Helper scripts read from temp files
# written by nn_write_schema_files().

_nn_gen_awk_bodies() {
  # Entity color+icon assignments
  local _ent_awk="" _first=true
  for _v in "${NN_ENTITY_VALUES[@]}"; do
    if $_first; then
      _ent_awk="tc = \"\\033[${NN_ENTITY_COLORS[$_v]}m\"; ic = \"${NN_ENTITY_ICONS[$_v]}\""
      _first=false
    else
      _ent_awk+=$'\n'"  if (\$1 == \"$_v\") { tc = \"\\033[${NN_ENTITY_COLORS[$_v]}m\"; ic = \"${NN_ENTITY_ICONS[$_v]}\" }"
    fi
  done

  # Status color assignments
  local _sta_awk="sc = \"\\033[${NN_STATUS_DEFAULT_COLOR}m\""
  for _v in "${NN_STATUS_VALUES[@]}"; do
    [[ "${NN_STATUS_COLORS[$_v]}" == "$NN_STATUS_DEFAULT_COLOR" ]] && continue
    _sta_awk+=$'\n'"  if (\$2 == \"$_v\") sc = \"\\033[${NN_STATUS_COLORS[$_v]}m\""
  done

  # Priority color + label assignments
  local _pri_awk=""
  if [[ "$NN_PRIORITY_ENABLED" != "false" ]]; then
    _pri_awk="pc = \"\\033[${NN_PRIORITY_DEFAULT_COLOR}m\""
    for _v in "${NN_PRIORITY_VALUES[@]}"; do
      [[ "${NN_PRIORITY_COLORS[$_v]}" == "$NN_PRIORITY_DEFAULT_COLOR" ]] && continue
      if [[ "$_v" =~ ^[0-9]+$ ]]; then
        _pri_awk+=$'\n'"  if (\$3+0 == $_v) pc = \"\\033[${NN_PRIORITY_COLORS[$_v]}m\""
      else
        _pri_awk+=$'\n'"  if (\$3 == \"$_v\") pc = \"\\033[${NN_PRIORITY_COLORS[$_v]}m\""
      fi
    done
    _pri_awk+=$'\n''  pl = "P" $3'
    for _v in "${NN_PRIORITY_VALUES[@]}"; do
      [[ "${NN_PRIORITY_LABELS[$_v]}" == "P$_v" ]] && continue
      _pri_awk+=$'\n'"  if (\$3 == \"$_v\") pl = \"${NN_PRIORITY_LABELS[$_v]}\""
    done
  fi

  # Age computation (constant across schemas)
  local _age_awk='age = ""
  if ($7 != "") {
    split($7, dt, /[-: ]/)
    ts = mktime(dt[1] " " dt[2] " " dt[3] " " dt[4] " " dt[5] " " int(dt[6]))
    if (ts > 0) {
      diff = now - ts
      if (diff < 0) diff = 0
      if (diff < 3600) age = int(diff/60) "m"
      else if (diff < 86400) age = int(diff/3600) "h"
      else if (diff < 604800) age = int(diff/86400) "d"
      else if (diff < 2592000) age = int(diff/604800) "w"
      else if (diff < 31536000) age = int(diff/2592000) "mo"
      else age = int(diff/31536000) "y"
    }
  }
  age_s = (age != "") ? " \033[90m" age r : ""'

  # Ad-hoc mode AWK body (no age)
  local _simple="$_ent_awk"
  [[ -n "$_pri_awk" ]] && _simple+=$'\n'"  $_pri_awk"
  _simple+=$'\n'"  $_sta_awk"
  _simple+=$'\n''  r = "\033[0m"'
  if [[ "$NN_PRIORITY_ENABLED" != "false" ]]; then
    _simple+=$'\n''  printf "%s\t%s%s %s%s %s%s%s %s%s%s %s\n", $6, tc, ic, $1, r, pc, pl, r, sc, $2, r, $5'
  else
    _simple+=$'\n''  printf "%s\t%s%s %s%s %s%s%s %s\n", $6, tc, ic, $1, r, sc, $2, r, $5'
  fi
  NN_AWK_COLOR="{ $_simple }"

  # Filter.sh main display AWK body (with age)
  local _full="$_ent_awk"
  [[ -n "$_pri_awk" ]] && _full+=$'\n'"  $_pri_awk"
  _full+=$'\n'"  $_sta_awk"
  _full+=$'\n''  r = "\033[0m"'
  _full+=$'\n'"  $_age_awk"
  if [[ "$NN_PRIORITY_ENABLED" != "false" ]]; then
    _full+=$'\n''  printf "%s\t%s%s %s%s %s%s%s %s%s%s %s%s\n", $6, tc, ic, $1, r, pc, pl, r, sc, $2, r, $5, age_s'
  else
    _full+=$'\n''  printf "%s\t%s%s %s%s %s%s%s %s%s\n", $6, tc, ic, $1, r, sc, $2, r, $5, age_s'
  fi
  NN_AWK_COLOR_BODY="$_full"

  # Pinned items AWK body (all dim, icon varies by entity)
  local _pinned='tc = "\033[90m"; pc = "\033[90m"; sc = "\033[90m"; r = "\033[0m"'
  _pinned+=$'\n'"  ic = \"${NN_ENTITY_ICONS[${NN_ENTITY_VALUES[0]}]}\""
  for (( _i=1; _i<${#NN_ENTITY_VALUES[@]}; _i++ )); do
    local _v="${NN_ENTITY_VALUES[$_i]}"
    _pinned+=$'\n'"  if (\$1 == \"$_v\") ic = \"${NN_ENTITY_ICONS[$_v]}\""
  done
  _pinned+=$'\n'"  $_age_awk"
  if [[ "$NN_PRIORITY_ENABLED" != "false" ]]; then
    _pinned+=$'\n''  printf "%s\t%s%s %s%s %sP%s%s %s%s%s %s%s \033[90m(temporarily pinned)\033[0m\n", $6, tc, ic, $1, r, pc, $3, r, sc, $2, r, $5, age_s'
  else
    _pinned+=$'\n''  printf "%s\t%s%s %s%s %s%s%s %s%s \033[90m(temporarily pinned)\033[0m\n", $6, tc, ic, $1, r, sc, $2, r, $5, age_s'
  fi
  NN_AWK_COLOR_PINNED="$_pinned"

  # Stats AWK body
  local _entity_order_str="${NN_ENTITY_VALUES[*]}"
  local _status_fc_str="${NN_STATUS_FILTER_CYCLE[*]}"
  local _stats_entity_lookup="" _stats_status_lookup=""
  for _v in "${NN_ENTITY_VALUES[@]}"; do
    _stats_entity_lookup+="icon[\"$_v\"] = \"${NN_ENTITY_ICONS[$_v]}\"; clr[\"$_v\"] = \"\\033[${NN_ENTITY_COLORS[$_v]}m\"; "
  done
  for _v in "${NN_STATUS_FILTER_CYCLE[@]}"; do
    _stats_status_lookup+="sc[\"$_v\"] = \"\\033[${NN_STATUS_COLORS[$_v]}m\"; "
  done
  NN_AWK_COLOR_STATS='{ types[$1]++; combos[$1, $2]++ } END {
  n = split("'"$_entity_order_str"'", order, " ")
  '"$_stats_entity_lookup"'
  '"$_stats_status_lookup"'
  first = 1
  for (o = 1; o <= n; o++) {
    t = order[o]
    if (!(t in types)) continue
    if (!first) printf " \033[90m·\033[0m "
    first = 0
    tc = (t in clr) ? clr[t] : "\033[36m"
    ic = (t in icon) ? icon[t] : "*"
    tl = t; if (types[t] != 1) tl = t "s"
    printf "%s%s %d %s\033[0m", tc, ic, types[t], tl
    printf " ("
    sn = split("'"$_status_fc_str"'", statuses, " ")
    sfirst = 1
    for (si = 1; si <= sn; si++) {
      s = statuses[si]
      key = t SUBSEP s
      if (!(key in combos)) continue
      if (!sfirst) printf ", "
      sfirst = 0
      scolor = (s in sc) ? sc[s] : "\033[90m"
      printf "%s%d %s\033[0m", scolor, combos[key], s
    }
    printf ")"
  }
}'

  # Group ordering strings
  NN_ENTITY_ORDER_STR="$_entity_order_str"
  NN_STATUS_ORDER_STR="${NN_STATUS_VALUES[*]}"

  # Entity icon AWK snippet for grouping
  NN_AWK_ICON_SETUP=""
  for _v in "${NN_ENTITY_VALUES[@]}"; do
    NN_AWK_ICON_SETUP+="icon[\"$_v\"] = \"${NN_ENTITY_ICONS[$_v]}\"; "
  done
}

nn_precompute_schema() {
  # Entity types
  mapfile -t NN_ENTITY_VALUES < <(nn_cfg '.entity.values[]')
  NN_ENTITY_DEFAULT_COLOR=$(nn_cfg '.entity.default_color // "36"')
  declare -gA NN_ENTITY_ICONS NN_ENTITY_COLORS NN_ENTITY_DESCS
  for _v in "${NN_ENTITY_VALUES[@]}"; do
    NN_ENTITY_ICONS[$_v]=$(nn_cfg ".entity.\"$_v\".icon // \"*\"")
    NN_ENTITY_COLORS[$_v]=$(nn_cfg ".entity.\"$_v\".color // \"$NN_ENTITY_DEFAULT_COLOR\"")
    NN_ENTITY_DESCS[$_v]=$(nn_cfg ".entity.\"$_v\".description // \"\"")
  done

  # Statuses
  mapfile -t NN_STATUS_VALUES < <(nn_cfg '.status.values[]')
  mapfile -t NN_STATUS_ARCHIVE < <(nn_cfg '.status.archive // [] | .[]')
  mapfile -t NN_STATUS_FILTER_CYCLE < <(nn_cfg '.status.filter_cycle // [] | .[]')
  NN_STATUS_DEFAULT_COLOR=$(nn_cfg '.status.default_color // "90"')
  declare -gA NN_STATUS_COLORS
  for _v in "${NN_STATUS_VALUES[@]}"; do
    NN_STATUS_COLORS[$_v]=$(nn_cfg ".status.colors.\"$_v\" // \"$NN_STATUS_DEFAULT_COLOR\"")
  done

  # Status lifecycle
  declare -gA NN_STATUS_FWD NN_STATUS_REV
  for _v in "${NN_STATUS_VALUES[@]}"; do
    local _fwd; _fwd=$(nn_cfg ".status.lifecycle.forward.\"$_v\" // empty")
    [[ -n "$_fwd" ]] && NN_STATUS_FWD[$_v]=$_fwd
    local _rev; _rev=$(nn_cfg ".status.lifecycle.reverse.\"$_v\" // empty")
    [[ -n "$_rev" ]] && NN_STATUS_REV[$_v]=$_rev
  done

  # Priority
  NN_PRIORITY_ENABLED=$(nn_cfg '.priority.enabled // true')
  declare -gA NN_PRIORITY_COLORS NN_PRIORITY_LABELS NN_PRIORITY_UP NN_PRIORITY_DOWN
  if [[ "$NN_PRIORITY_ENABLED" != "false" ]]; then
    mapfile -t NN_PRIORITY_VALUES < <(nn_cfg '.priority.values[]')
    mapfile -t NN_PRIORITY_FILTER_CYCLE < <(nn_cfg '.priority.filter_cycle // [] | .[]')
    NN_PRIORITY_DEFAULT_COLOR=$(nn_cfg '.priority.default_color // "33"')
    for _v in "${NN_PRIORITY_VALUES[@]}"; do
      NN_PRIORITY_COLORS[$_v]=$(nn_cfg ".priority.colors.\"$_v\" // \"$NN_PRIORITY_DEFAULT_COLOR\"")
      local _label; _label=$(nn_cfg ".priority.labels.\"$_v\" // empty")
      NN_PRIORITY_LABELS[$_v]="${_label:-P$_v}"
    done
    for _v in "" "${NN_PRIORITY_VALUES[@]}"; do
      local _up; _up=$(nn_cfg ".priority.lifecycle.up.\"$_v\" // empty")
      [[ -n "$_up" ]] && NN_PRIORITY_UP[$_v]=$_up
      local _down; _down=$(nn_cfg ".priority.lifecycle.down.\"$_v\" // empty")
      [[ -n "$_down" ]] && NN_PRIORITY_DOWN[$_v]=$_down
    done
  else
    NN_PRIORITY_VALUES=()
    NN_PRIORITY_FILTER_CYCLE=()
    NN_PRIORITY_DEFAULT_COLOR="33"
  fi

  # Defaults
  NN_DEFAULT_SORT=$(nn_cfg '.defaults.sort_by // "created"')
  NN_DEFAULT_GROUP=$(nn_cfg '.defaults.group_by // "type"')
  NN_DEFAULT_ARCHIVE=$(nn_cfg '.defaults.show_archive // false')

  # ZK format
  NN_ZK_FMT=$(nn_cfg '.zk.format // empty')
  [[ -z "$NN_ZK_FMT" ]] && NN_ZK_FMT='{{metadata.type}}\t{{metadata.status}}\t{{metadata.priority}}\t{{tags}}\t{{title}}\t{{absPath}}\t{{modified}}\t{{created}}'

  # Generate AWK bodies
  _nn_gen_awk_bodies

  # Archive AWK condition (e.g. ' && $2!="done" && $2!="removed"')
  NN_ARCHIVE_COND=""
  for _v in "${NN_STATUS_ARCHIVE[@]}"; do
    NN_ARCHIVE_COND+=" && \$2!=\"$_v\""
  done
}

nn_write_schema_files() {
  local dir="$1"
  printf '%s\n' "${NN_ENTITY_VALUES[@]}" > "$dir/.schema_entity_values"
  printf '%s\n' "${NN_STATUS_VALUES[@]}" > "$dir/.schema_status_values"
  if [[ ${#NN_PRIORITY_VALUES[@]} -gt 0 ]]; then
    printf '%s\n' "${NN_PRIORITY_VALUES[@]}" > "$dir/.schema_priority_values"
  else
    : > "$dir/.schema_priority_values"
  fi
  if [[ ${#NN_STATUS_FILTER_CYCLE[@]} -gt 0 ]]; then
    printf '%s\n' "${NN_STATUS_FILTER_CYCLE[@]}" > "$dir/.schema_status_filter_cycle"
  else
    : > "$dir/.schema_status_filter_cycle"
  fi
  if [[ ${#NN_PRIORITY_FILTER_CYCLE[@]} -gt 0 ]]; then
    printf '%s\n' "${NN_PRIORITY_FILTER_CYCLE[@]}" > "$dir/.schema_priority_filter_cycle"
  else
    : > "$dir/.schema_priority_filter_cycle"
  fi
  if [[ ${#NN_STATUS_ARCHIVE[@]} -gt 0 ]]; then
    printf '%s\n' "${NN_STATUS_ARCHIVE[@]}" > "$dir/.schema_archive"
  else
    : > "$dir/.schema_archive"
  fi
  printf '%s' "$NN_PRIORITY_ENABLED" > "$dir/.schema_priority_enabled"

  # Entity details (TSV: value\ticon\tcolor\tdescription)
  local _v
  for _v in "${NN_ENTITY_VALUES[@]}"; do
    printf '%s\t%s\t%s\t%s\n' "$_v" "${NN_ENTITY_ICONS[$_v]}" "${NN_ENTITY_COLORS[$_v]}" "${NN_ENTITY_DESCS[$_v]}"
  done > "$dir/.schema_entities"

  # Entity icon map (TSV: value\ticon)
  for _v in "${NN_ENTITY_VALUES[@]}"; do
    printf '%s\t%s\n' "$_v" "${NN_ENTITY_ICONS[$_v]}"
  done > "$dir/.schema_entity_icons"

  # Status lifecycle (TSV: from\tto)
  for _v in "${NN_STATUS_VALUES[@]}"; do
    [[ -n "${NN_STATUS_FWD[$_v]+x}" ]] && printf '%s\t%s\n' "$_v" "${NN_STATUS_FWD[$_v]}"
  done > "$dir/.schema_status_fwd"
  for _v in "${NN_STATUS_VALUES[@]}"; do
    [[ -n "${NN_STATUS_REV[$_v]+x}" ]] && printf '%s\t%s\n' "$_v" "${NN_STATUS_REV[$_v]}"
  done > "$dir/.schema_status_rev"

  # Priority lifecycle (TSV: from\tto)
  if [[ "$NN_PRIORITY_ENABLED" != "false" ]]; then
    for _v in "" "${NN_PRIORITY_VALUES[@]}"; do
      [[ -n "${NN_PRIORITY_UP[$_v]+x}" ]] && printf '%s\t%s\n' "$_v" "${NN_PRIORITY_UP[$_v]}"
    done > "$dir/.schema_priority_up"
    for _v in "" "${NN_PRIORITY_VALUES[@]}"; do
      [[ -n "${NN_PRIORITY_DOWN[$_v]+x}" ]] && printf '%s\t%s\n' "$_v" "${NN_PRIORITY_DOWN[$_v]}"
    done > "$dir/.schema_priority_down"
  else
    : > "$dir/.schema_priority_up"
    : > "$dir/.schema_priority_down"
  fi

  # Priority labels (TSV: value\tlabel)
  for _v in "${NN_PRIORITY_VALUES[@]}"; do
    printf '%s\t%s\n' "$_v" "${NN_PRIORITY_LABELS[$_v]}"
  done > "$dir/.schema_priority_labels"

  # Defaults (one per line: sort_by, group_by, show_archive)
  printf '%s\n%s\n%s\n' "$NN_DEFAULT_SORT" "$NN_DEFAULT_GROUP" "$NN_DEFAULT_ARCHIVE" > "$dir/.schema_defaults"

  # AWK bodies
  printf '%s' "$NN_AWK_COLOR_BODY" > "$dir/.awk_color_body"
  printf '%s' "$NN_AWK_COLOR_PINNED" > "$dir/.awk_color_pinned"
  printf '%s' "$NN_AWK_COLOR_STATS" > "$dir/.awk_color_stats"

  # Archive AWK condition
  printf '%s' "$NN_ARCHIVE_COND" > "$dir/.schema_archive_cond"

  # Entity and status order strings (space-separated, for AWK split)
  printf '%s' "$NN_ENTITY_ORDER_STR" > "$dir/.schema_entity_order"
  printf '%s' "$NN_STATUS_ORDER_STR" > "$dir/.schema_status_order"

  # AWK icon setup for grouping
  printf '%s' "$NN_AWK_ICON_SETUP" > "$dir/.schema_icon_setup"

  # Archive label (slash-separated status names for header display)
  local _archive_label=""
  for _v in "${NN_STATUS_ARCHIVE[@]}"; do
    [[ -n "$_archive_label" ]] && _archive_label+="/"
    _archive_label+="$_v"
  done
  printf '%s' "$_archive_label" > "$dir/.schema_archive_label"
}

notenav_main() {
  # --version support
  if [[ "$1" == "--version" || "$1" == "-V" ]]; then
    echo "notenav $NOTENAV_VERSION"
    return 0
  fi

  # Load config (schema + user/project overrides)
  nn_load_config "$NOTENAV_ROOT" || true
  nn_precompute_schema

  shopt -s nullglob

  # Collect .nn/queries/ dirs from git root down to cwd (deeper dirs override)
  declare -A saved_queries
  local git_root
  git_root=$(git rev-parse --show-toplevel 2>/dev/null)
  if [[ -n "$git_root" ]]; then
    local rel="${PWD#$git_root}"
    local search_path="$git_root"
    if [[ -d "$search_path/.nn/queries" ]]; then
      for f in "$search_path/.nn/queries"/*; do
        [[ -f "$f" ]] || continue
        saved_queries[${f##*/}]="$f"
      done
    fi
    IFS='/' read -ra _segments <<< "$rel"
    for segment in "${_segments[@]}"; do
      [[ -z "$segment" ]] && continue
      search_path="$search_path/$segment"
      if [[ -d "$search_path/.nn/queries" ]]; then
        for f in "$search_path/.nn/queries"/*; do
          [[ -f "$f" ]] || continue
          saved_queries[${f##*/}]="$f"
        done
      fi
    done
  elif [[ -d ".nn/queries" ]]; then
    for f in .nn/queries/*; do
      [[ -f "$f" ]] || continue
      saved_queries[${f##*/}]="$f"
    done
  fi

  # Format and color from config
  local _fmt="$NN_ZK_FMT"
  local _awk_color="$NN_AWK_COLOR"

  # Default zk path args based on cwd
  local _zk_path=()
  local _gr
  _gr=$(git rev-parse --show-toplevel 2>/dev/null)
  [[ -n "$_gr" && "$PWD" != "$_gr" ]] && _zk_path=("$(pwd)")

  # ---- FACETED BROWSER (no args) ----
  if [[ $# -eq 0 ]]; then
    local _nn_dir=$(mktemp -d)
    nn_write_schema_files "$_nn_dir"

    # Get all notes
    zk list "${_zk_path[@]}" --format "$_fmt" --quiet 2>/dev/null > "$_nn_dir/.raw"

    # Initialize filter state (empty = all)
    : > "$_nn_dir/.f_type"
    : > "$_nn_dir/.f_status"
    : > "$_nn_dir/.f_priority"
    : > "$_nn_dir/.f_tags"
    : > "$_nn_dir/.f_sq"
    echo "$NN_DEFAULT_SORT" > "$_nn_dir/.f_sort"
    echo type > "$_nn_dir/.f_active"
    echo "$NN_DEFAULT_GROUP" > "$_nn_dir/.f_group"
    : > "$_nn_dir/.f_archive"
    : > "$_nn_dir/.f_match"

    # Write saved query definitions for filter.sh, sorted by priority
    # Files may start with "# N" comment to set sort order (default 50)
    local _sq_names=() _sq_unsorted=() _qfile _qpri _qfirst _qargs _sorted_keys=()
    if [[ ${#saved_queries[@]} -gt 0 ]]; then
    mapfile -t _sorted_keys < <(printf '%s\n' "${!saved_queries[@]}" | sort)
    fi
    for _qname in "${_sorted_keys[@]}"; do
      _qfile="${saved_queries[$_qname]}"
      _qpri=100
      _qfirst=$(head -1 "$_qfile")
      if [[ "$_qfirst" =~ ^#\ *([0-9]+) ]]; then
        _qpri=${BASH_REMATCH[1]}
      fi
      _qargs=$(grep -v '^#' "$_qfile" | tr '\n' ' ' | sed 's/ *$//')
      _sq_unsorted+=("${_qpri}	${_qname}	${_qargs}")
    done
    printf '%s\n' "${_sq_unsorted[@]}" | sort -t'	' -k1,1n -k2,2 | while IFS=$'\t' read -r _ _qname _qargs; do
      _sq_names+=("$_qname")
      echo "$_qname	$_qargs" >> "$_nn_dir/.queries"
    done

    # Tag picker script (opens sub-fzf for multi-select)
    cat > "$_nn_dir/tags.sh" << 'ENDTAGS'
#!/bin/bash
dir="$1"
tags=$(awk -F'\t' 'length($4) > 0 {
  n=split($4, arr, " "); for(i=1;i<=n;i++) t[arr[i]]=1
} END { for(k in t) print k }' "$dir/.raw" | sort)
[ -z "$tags" ] && exit 0
cur_tags=""
[ -s "$dir/.f_tags" ] && cur_tags=$(cat "$dir/.f_tags")
n_cur=$(echo "$cur_tags" | grep -c . 2>/dev/null || echo 0)
if [ "$n_cur" -gt 0 ]; then
  ordered=$(printf '%s\n%s' "$cur_tags" "$tags" | awk '!seen[$0]++')
  start_bind="load:select+down"
  i=1; while [ "$i" -lt "$n_cur" ]; do start_bind="$start_bind+select+down"; i=$((i+1)); done
else
  ordered="$tags"
  start_bind=""
fi
selected=$(echo "$ordered" | fzf --multi --reverse --prompt 'tags: ' \
  --ansi --header $'Select tags for filtering (\033[36mSpace\033[0m/\033[36mTab\033[0m toggle \033[90m·\033[0m \033[36mEnter\033[0m apply \033[90m·\033[0m \033[36mEsc\033[0m cancel)' \
  --bind 'j:down,k:up,space:toggle' ${start_bind:+--bind "$start_bind"})
if [ $? -eq 0 ]; then
  if [ -n "$selected" ]; then echo "$selected" > "$dir/.f_tags"
  else : > "$dir/.f_tags"; fi
fi
ENDTAGS
    chmod +x "$_nn_dir/tags.sh"

    # Body text search: live fzf with zk --match
    cat > "$_nn_dir/match_search.sh" << 'ENDMSEARCH'
#!/bin/bash
dir="$1"; query="$2"
zk_path=()
while IFS= read -r p; do [ -n "$p" ] && zk_path+=("$p"); done < "$dir/.zk_path"
if [ -n "$query" ]; then
  zk list "${zk_path[@]}" --match "$query" --format "{{absPath}}	{{title}}" --quiet 2>/dev/null
else
  zk list "${zk_path[@]}" --format "{{absPath}}	{{title}}" --quiet 2>/dev/null
fi
ENDMSEARCH
    chmod +x "$_nn_dir/match_search.sh"

    cat > "$_nn_dir/match.sh" << 'ENDMATCH'
#!/bin/bash
dir="$1"
cur=""
[ -s "$dir/.f_match" ] && cur=$(cat "$dir/.f_match")
result=$(: | fzf --ansi --disabled --query "$cur" \
  --prompt 'search contents: ' \
  --header $'Body text search · Enter apply · Esc cancel' \
  --bind "start:reload:$dir/match_search.sh $dir {q}" \
  --bind "change:reload:$dir/match_search.sh $dir {q}" \
  --preview "$dir/preview.sh {1}" \
  --delimiter $'\t' --with-nth 2 \
  --print-query \
  --bind 'j:down,k:up' \
  --reverse)
rc=$?
query=$(printf '%s' "$result" | head -1)
if [ $rc -eq 0 ] && [ -n "$query" ]; then
  zk_path=()
  while IFS= read -r p; do [ -n "$p" ] && zk_path+=("$p"); done < "$dir/.zk_path"
  zk list "${zk_path[@]}" --match "$query" --format '{{absPath}}' --quiet 2>/dev/null > "$dir/.f_match_paths"
  echo "$query" > "$dir/.f_match"
elif [ $rc -eq 0 ]; then
  : > "$dir/.f_match"
  : > "$dir/.f_match_paths"
fi
ENDMATCH
    chmod +x "$_nn_dir/match.sh"

    # Store zk list args for reload
    printf '%s\n' "${_zk_path[@]}" > "$_nn_dir/.zk_path"
    echo "$_fmt" > "$_nn_dir/.zk_fmt"

    # Bulk action script: update frontmatter field on selected files, then reload
    cat > "$_nn_dir/action.sh" << 'ENDACTION'
#!/bin/bash
# Usage: action.sh <dir> <field> <value> <file1> [file2 ...]
dir="$1"; field="$2"; value="$3"; shift 3
count=0
for file in "$@"; do
  [ ! -f "$file" ] && continue
  # Update field within YAML frontmatter (between first --- and second ---)
  awk -v field="$field" -v value="$value" '
    NR==1 && /^---/ { in_fm=1; print; next }
    in_fm && /^---/ { in_fm=0; if (!found) print field ": " value; print; next }
    in_fm && $0 ~ "^"field":" { print field ": " value; found=1; next }
    { print }
  ' "$file" > "$file.tmp" && mv "$file.tmp" "$file" && count=$((count + 1))
done
# Pin acted-on files so they stay visible after filter
printf '%s\n' "$@" > "$dir/.pinned"
# Regenerate raw data
fmt=$(cat "$dir/.zk_fmt")
zk_path=()
while IFS= read -r p; do [ -n "$p" ] && zk_path+=("$p"); done < "$dir/.zk_path"
zk list "${zk_path[@]}" --format "$fmt" --quiet 2>/dev/null > "$dir/.raw"
# Re-run current filter to update .current
"$dir/filter.sh" "$dir" refresh > /dev/null
ENDACTION
    chmod +x "$_nn_dir/action.sh"

    # Field picker: opens sub-fzf to choose a value, writes to .f_pick_val
    cat > "$_nn_dir/fieldpick.sh" << 'ENDFP'
#!/bin/bash
dir="$1"; field="$2"; shift 2
# Build context header from file paths
ctx=""
total=$#
shown=0
for f in "$@"; do
  [ ! -f "$f" ] && continue
  if [ $shown -lt 2 ]; then
    t=$(awk -F'\t' -v p="$f" '$6 == p {print $5; exit}' "$dir/.raw")
    [ -z "$t" ] && t=$(basename "$f" .md)
    [ $shown -eq 0 ] && ctx="$t" || ctx="$ctx, $t"
  fi
  shown=$((shown + 1))
done
[ $shown -gt 2 ] && ctx="$ctx (+$((shown - 2)) more)"
case "$field" in
  status)   vals=$(paste -sd'\n' "$dir/.schema_status_values") ;;
  priority)
    [ "$(cat "$dir/.schema_priority_enabled")" = "false" ] && exit 1
    vals=$(paste -sd'\n' "$dir/.schema_priority_values") ;;
  type)
    vals=""
    while IFS=$'\t' read -r v ic clr desc; do
      [ -n "$vals" ] && vals="$vals\n"
      vals="$vals$(printf '\033[%sm%s %s\033[0m' "$clr" "$ic" "$v")"
    done < "$dir/.schema_entities" ;;
  *) exit 1 ;;
esac
hdr="Enter apply · Esc cancel"
[ -n "$ctx" ] && hdr=$(printf '%s\n%s' "$ctx" "$hdr")
selected=$(printf "$vals" | fzf --reverse --prompt "set $field: " \
  --border --border-label " Set $field " \
  --header "$hdr" \
  --bind 'j:down,k:up')
[ -z "$selected" ] && exit 1
# Strip icon prefix (e.g. "◆ task" → "task")
selected=$(echo "$selected" | sed 's/^[^ ]* //')
echo "$field" > "$dir/.fp_field"
echo "$selected" > "$dir/.fp_value"
ENDFP
    chmod +x "$_nn_dir/fieldpick.sh"

    # Combined pick-and-apply: pick value then update files
    cat > "$_nn_dir/bulkset.sh" << 'ENDBS'
#!/bin/bash
dir="$1"; field="$2"; shift 2
# Read file paths from args or .c_sel file
if [ $# -gt 0 ]; then
  files=("$@")
else
  files=()
  while IFS= read -r f; do [ -n "$f" ] && files+=("$f"); done < "$dir/.c_sel"
fi
[ ${#files[@]} -eq 0 ] && exit 0
# Pick value (pass file paths for context display)
"$dir/fieldpick.sh" "$dir" "$field" "${files[@]}" || exit 0
value=$(cat "$dir/.fp_value")
# Apply to selected files
"$dir/action.sh" "$dir" "$field" "$value" "${files[@]}"
ENDBS
    chmod +x "$_nn_dir/bulkset.sh"

    # Bulk edit: multi-field frontmatter updater (single awk pass)
    cat > "$_nn_dir/bulkedit_update.sh" << 'ENDBEU'
#!/bin/bash
# Usage: bulkedit_update.sh <file> field=value [field=value ...]
file="$1"; shift
[ ! -f "$file" ] && exit 1
# Parse field=value pairs into individual vars
set_type=""; set_status=""; set_priority=""; set_tags=""
has_type=0; has_status=0; has_priority=0; has_tags=0
for arg in "$@"; do
  f="${arg%%=*}"; v="${arg#*=}"
  case "$f" in
    type)     set_type="$v"; has_type=1 ;;
    status)   set_status="$v"; has_status=1 ;;
    priority) set_priority="$v"; has_priority=1 ;;
    tags)
      has_tags=1
      if [ -n "$v" ]; then
        # Convert space-separated tags to YAML array: [tag1, tag2]
        set_tags=$(echo "$v" | sed 's/  */ /g; s/^ //; s/ $//' | tr ' ' '\n' | paste -sd, | sed 's/^/[/; s/$/]/')
      fi
      ;;
  esac
done
awk -v set_type="$set_type" -v has_type="$has_type" \
    -v set_status="$set_status" -v has_status="$has_status" \
    -v set_priority="$set_priority" -v has_priority="$has_priority" \
    -v set_tags="$set_tags" -v has_tags="$has_tags" '
  NR==1 && /^---/ { in_fm=1; print; next }
  in_fm && /^---/ {
    in_fm=0
    if (has_type && !found_type && set_type != "") print "type: " set_type
    if (has_status && !found_status && set_status != "") print "status: " set_status
    if (has_priority && !found_priority && set_priority != "") print "priority: " set_priority
    if (has_tags && !found_tags && set_tags != "") print "tags: " set_tags
    print; next
  }
  in_fm && /^type:/ {
    if (has_type) { if (set_type != "") print "type: " set_type; found_type=1; next }
    else { found_type=1 }
  }
  in_fm && /^status:/ {
    if (has_status) { if (set_status != "") print "status: " set_status; found_status=1; next }
    else { found_status=1 }
  }
  in_fm && /^priority:/ {
    if (has_priority) { if (set_priority != "") print "priority: " set_priority; found_priority=1; next }
    else { found_priority=1 }
  }
  in_fm && /^tags:/ {
    if (has_tags) { if (set_tags != "") print "tags: " set_tags; found_tags=1; next }
    else { found_tags=1 }
  }
  { print }
' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
ENDBEU
    chmod +x "$_nn_dir/bulkedit_update.sh"

    # Bulk edit: diff and apply changes from edited TSV
    cat > "$_nn_dir/bulkedit_apply.sh" << 'ENDBA'
#!/bin/bash
dir="$1"; orig="$2"; edited="$3"
errors=""
count=0
while IFS= read -r new_line; do
  # Skip comments and empty lines
  case "$new_line" in '#'*|'') continue ;; esac
  path=$(printf '%s' "$new_line" | awk -F'\t' '{print $6}')
  [ -z "$path" ] && continue
  # Find matching original line by path
  orig_line=$(awk -F'\t' -v p="$path" '$6 == p' "$orig")
  [ -z "$orig_line" ] && continue
  # Compare fields
  new_type=$(printf '%s' "$new_line" | awk -F'\t' '{print $1}')
  new_status=$(printf '%s' "$new_line" | awk -F'\t' '{print $2}')
  new_pri=$(printf '%s' "$new_line" | awk -F'\t' '{print $3}')
  new_tags=$(printf '%s' "$new_line" | awk -F'\t' '{print $4}')
  old_type=$(printf '%s' "$orig_line" | awk -F'\t' '{print $1}')
  old_status=$(printf '%s' "$orig_line" | awk -F'\t' '{print $2}')
  old_pri=$(printf '%s' "$orig_line" | awk -F'\t' '{print $3}')
  old_tags=$(printf '%s' "$orig_line" | awk -F'\t' '{print $4}')
  # Skip if nothing changed
  [ "$new_type" = "$old_type" ] && [ "$new_status" = "$old_status" ] && \
    [ "$new_pri" = "$old_pri" ] && [ "$new_tags" = "$old_tags" ] && continue
  # Validate type
  valid=false
  while IFS= read -r vt; do [ "$new_type" = "$vt" ] && valid=true && break; done < "$dir/.schema_entity_values"
  $valid || { errors="${errors}Invalid type '$new_type' for $(basename "$path")\n"; continue; }
  # Validate status
  if [ -n "$new_status" ]; then
    valid=false
    while IFS= read -r vs; do [ "$new_status" = "$vs" ] && valid=true && break; done < "$dir/.schema_status_values"
    $valid || { errors="${errors}Invalid status '$new_status' for $(basename "$path")\n"; continue; }
  fi
  # Validate priority
  if [ -n "$new_pri" ]; then
    if [ "$(cat "$dir/.schema_priority_enabled")" != "false" ]; then
      valid=false
      while IFS= read -r vp; do [ "$new_pri" = "$vp" ] && valid=true && break; done < "$dir/.schema_priority_values"
      $valid || { errors="${errors}Invalid priority '$new_pri' for $(basename "$path")\n"; continue; }
    fi
  fi
  # Build update args for changed fields only
  update_args=()
  [ "$new_type" != "$old_type" ] && update_args+=("type=$new_type")
  [ "$new_status" != "$old_status" ] && update_args+=("status=$new_status")
  [ "$new_pri" != "$old_pri" ] && update_args+=("priority=$new_pri")
  [ "$new_tags" != "$old_tags" ] && update_args+=("tags=$new_tags")
  "$dir/bulkedit_update.sh" "$path" "${update_args[@]}" && count=$((count + 1))
done < "$edited"
# Regenerate raw data and re-filter
fmt=$(cat "$dir/.zk_fmt")
zk_path=()
while IFS= read -r p; do [ -n "$p" ] && zk_path+=("$p"); done < "$dir/.zk_path"
zk list "${zk_path[@]}" --format "$fmt" --quiet 2>/dev/null > "$dir/.raw"
"$dir/filter.sh" "$dir" refresh > /dev/null
ENDBA
    chmod +x "$_nn_dir/bulkedit_apply.sh"

    # Bulk edit: orchestrator — generates TSV, opens editor, applies changes
    cat > "$_nn_dir/bulkedit.sh" << 'ENDBE'
#!/bin/bash
dir="$1"
tmpfile="$dir/.bulkedit.tsv"
origfile="$dir/.bulkedit_orig.tsv"
# Header with vim modeline
printf '# vim:ft=conf:ts=12:noet:nowrap\n' > "$tmpfile"
printf '# type\tstatus\tpriority\ttags\ttitle\tpath\n' >> "$tmpfile"
# Read each path from .current and look up metadata in .raw
while IFS=$'\t' read -r fpath _rest; do
  [ -z "$fpath" ] && continue
  awk -F'\t' -v p="$fpath" '$6 == p { printf "%s\t%s\t%s\t%s\t%s\t%s\n", $1, $2, $3, $4, $5, $6 }' "$dir/.raw" >> "$tmpfile"
done < <(tac "$dir/.current")
# Footer with valid values from schema
printf '\n# type: %s\n' "$(paste -sd', ' "$dir/.schema_entity_values")" >> "$tmpfile"
printf '# status: %s (or empty)\n' "$(paste -sd', ' "$dir/.schema_status_values")" >> "$tmpfile"
if [ "$(cat "$dir/.schema_priority_enabled")" != "false" ]; then
  printf '# priority: %s (or empty)\n' "$(paste -sd', ' "$dir/.schema_priority_values")" >> "$tmpfile"
fi
printf '# tags: space-separated\n' >> "$tmpfile"
# Save original for diffing
cp "$tmpfile" "$origfile"
# Open editor
${EDITOR:-nvim} "$tmpfile" </dev/tty >/dev/tty
# Apply changes
"$dir/bulkedit_apply.sh" "$dir" "$origfile" "$tmpfile"
ENDBE
    chmod +x "$_nn_dir/bulkedit.sh"

    # Quick note creation: type picker → title prompt → zk new → editor
    cat > "$_nn_dir/newnote.sh" << 'ENDNN'
#!/bin/bash
dir="$1"
# Pick type (default to current type filter)
cur_type=$(cat "$dir/.f_type")
types=""
while IFS=$'\t' read -r v ic clr desc; do
  [ -n "$types" ] && types="$types"$'\n'
  types="$types$(printf '\033[%sm%s %s\033[0m\t\033[90m  %s\033[0m' "$clr" "$ic" "$v" "$desc")"
done < "$dir/.schema_entities"
selected=$(printf '%s' "$types" | fzf --reverse --prompt "type: " \
  --ansi --border --border-label ' New Note ' --delimiter '\t' --with-nth '1,2' \
  --header $'Select note type\n\033[36mEnter\033[0m confirm \033[90m·\033[0m \033[36mEsc\033[0m cancel' \
  --bind "j:down,k:up" \
  --query "${cur_type}" | awk '{print $2}')
[ -z "$selected" ] && exit 0
# Styled title prompt — look up icon and color from schema
tc=""; icon=""
while IFS=$'\t' read -r v ic clr desc; do
  [ "$v" = "$selected" ] && tc=$(printf '\033[%sm' "$clr") && icon="$ic" && break
done < "$dir/.schema_entities"
printf '\n' > /dev/tty
inner=41
pad=$((inner - 7 - ${#selected}))
top_dashes=$(printf '%*s' "$pad" '' | sed 's/ /─/g')
printf '  %s╭─ New %s %s╮\033[0m\n' "$tc" "$selected" "$top_dashes" > /dev/tty
printf '  %s│\033[0m%*s%s│\033[0m\n' "$tc" "$inner" "" "$tc" > /dev/tty
printf '  %s│\033[0m  \033[1mTitle:\033[0m%*s%s│\033[0m\n' "$tc" "$((inner - 8))" "" "$tc" > /dev/tty
printf '  %s│\033[0m%*s%s│\033[0m\n' "$tc" "$inner" "" "$tc" > /dev/tty
bot_dashes=$(printf '%*s' "$inner" '' | sed 's/ /─/g')
printf '  %s╰%s╯\033[0m\n' "$tc" "$bot_dashes" > /dev/tty
# Move cursor up 3 lines, to column 13 (after "Title: ")
printf '\033[3A\033[13G' > /dev/tty
read -r title < /dev/tty
# Move to the bottom border line to overwrite with result
printf '\033[1B' > /dev/tty
if [ -z "$title" ]; then
  printf '\r  %s└─ \033[0m\033[90mCancelled\033[0m\033[K\n\n' "$tc" > /dev/tty
  exit 0
fi
# Create note
new_path=$(zk new . --template "${selected}.md" --title "$title" --no-input --print-path 2>/dev/null)
if [ -z "$new_path" ]; then
  printf '\r  %s└─ \033[31mFailed to create note\033[0m\033[K\n\n' "$tc" > /dev/tty
  exit 0
fi
printf '\r  %s└─ \033[32m%s Created!\033[0m Opening in editor...\033[K\n\n' "$tc" "$icon" > /dev/tty
# Regenerate raw
fmt=$(cat "$dir/.zk_fmt")
zk_path=()
while IFS= read -r p; do [ -n "$p" ] && zk_path+=("$p"); done < "$dir/.zk_path"
zk list "${zk_path[@]}" --format "$fmt" --quiet 2>/dev/null > "$dir/.raw"
"$dir/filter.sh" "$dir" refresh > /dev/null
# Open in editor
${EDITOR:-nvim} "$new_path" < /dev/tty > /dev/tty
ENDNN
    chmod +x "$_nn_dir/newnote.sh"

    # Inline status cycling: advance/reverse status through lifecycle
    cat > "$_nn_dir/cyclestatus.sh" << 'ENDCS'
#!/bin/bash
dir="$1"; file="$2"; direction="${3:-fwd}"
[ ! -f "$file" ] && exit 0
cur=$(awk -F'\t' -v p="$file" '$6 == p {print $2; exit}' "$dir/.raw")
if [ "$direction" = "rev" ]; then
  next=$(awk -F'\t' -v cur="$cur" '$1 == cur {print $2; exit}' "$dir/.schema_status_rev")
else
  next=$(awk -F'\t' -v cur="$cur" '$1 == cur {print $2; exit}' "$dir/.schema_status_fwd")
fi
[ -z "$next" ] && next="$cur"
"$dir/action.sh" "$dir" status "$next" "$file"
ENDCS
    chmod +x "$_nn_dir/cyclestatus.sh"

    # Quick priority bump: increase/decrease urgency
    cat > "$_nn_dir/bumppri.sh" << 'ENDBP'
#!/bin/bash
dir="$1"; file="$2"; direction="$3"
[ ! -f "$file" ] && exit 0
[ "$(cat "$dir/.schema_priority_enabled")" = "false" ] && exit 0
cur=$(awk -F'\t' -v p="$file" '$6 == p {print $3; exit}' "$dir/.raw")
case "$direction" in
  up)   next=$(awk -F'\t' -v cur="$cur" '$1 == cur {print $2; exit}' "$dir/.schema_priority_up") ;;
  down) next=$(awk -F'\t' -v cur="$cur" '$1 == cur {print $2; exit}' "$dir/.schema_priority_down") ;;
esac
[ -z "$next" ] && exit 0
"$dir/action.sh" "$dir" priority "$next" "$file"
ENDBP
    chmod +x "$_nn_dir/bumppri.sh"

    # Reload helper: reloads list and positions cursor on the given path
    cat > "$_nn_dir/reload_at.sh" << 'ENDRA'
#!/bin/bash
dir="$1"; path="$2"
n=$(awk -F'\t' -v p="$path" '$1==p{print NR;exit}' "$dir/.current")
border=$(cat "$dir/.border" 2>/dev/null || echo " nn ")
printf 'reload(cat %s/.current)+pos(%s)+transform-header(cat %s/.header)+change-border-label(%s)' "$dir" "${n:-1}" "$dir" "$border"
ENDRA
    chmod +x "$_nn_dir/reload_at.sh"

    # Query picker script (opens sub-fzf to select a saved query)
    cat > "$_nn_dir/querypick.sh" << 'ENDQP'
#!/bin/bash
dir="$1"
[ ! -f "$dir/.queries" ] && exit 0
n=0
list=""
while IFS='	' read -r qname qargs; do
  n=$((n + 1))
  list="$list$(printf '%d\t%s\t%s\n' "$n" "$qname" "$qargs")"$'\n'
done < "$dir/.queries"
[ -z "$list" ] && exit 0
selected=$(printf '%s' "$list" | fzf --reverse --prompt 'query: ' \
  --delimiter '\t' --with-nth '1,2' \
  --header 'Enter apply · Esc cancel' \
  --bind 'j:down,k:up')
[ -z "$selected" ] && exit 0
num=$(echo "$selected" | cut -f1)
echo "$num" > "$dir/.f_pick"
ENDQP
    chmod +x "$_nn_dir/querypick.sh"

    # Preview helper script (file content + links + backlinks)
    cat > "$_nn_dir/preview.sh" << 'ENDPREVIEW'
#!/bin/bash
file="$1"
test -f "$file" || exit 0

# Show file content
$(command -v bat || command -v batcat) -p --color always "$file" 2>/dev/null || cat "$file"

# Collect links in parallel
tmp_links=$(mktemp); tmp_back=$(mktemp)
zk list --linked-by "$file" --format "  {{title}}" --quiet 2>/dev/null > "$tmp_links" &
zk list --link-to "$file" --format "  {{title}}" --quiet 2>/dev/null > "$tmp_back" &
wait

# Show outgoing links
if [ -s "$tmp_links" ]; then
  printf '\n\033[1;34m── Links ─────────────────────────\033[0m\n'
  cat "$tmp_links"
fi

# Show backlinks
if [ -s "$tmp_back" ]; then
  printf '\n\033[1;35m── Backlinks ─────────────────────\033[0m\n'
  cat "$tmp_back"
fi

rm -f "$tmp_links" "$tmp_back"
ENDPREVIEW
    chmod +x "$_nn_dir/preview.sh"

    # Faceted filter helper script
    cat > "$_nn_dir/filter.sh" << 'ENDFILTER'
#!/bin/bash
dir="$1"; action="$2"
cycle() {
  local dim="$1" direction="$2" cur="$3"
  local -a vals
  case "$dim" in
    type)     mapfile -t vals < "$dir/.schema_entity_values"; vals=("" "${vals[@]}") ;;
    status)   mapfile -t vals < "$dir/.schema_status_filter_cycle"; vals=("" "${vals[@]}") ;;
    priority)
      if [ "$(cat "$dir/.schema_priority_enabled")" = "false" ]; then vals=(""); else
        mapfile -t vals < "$dir/.schema_priority_filter_cycle"; vals=("" "${vals[@]}")
      fi ;;
    sort)     vals=("created" "modified" "title" "priority") ;;
    group)    vals=("" "type" "status") ;;
  esac
  local total=${#vals[@]} idx=0 i
  for i in "${!vals[@]}"; do
    [ "${vals[$i]}" = "$cur" ] && idx=$i && break
  done
  [ "$direction" = "next" ] && idx=$(( (idx + 1) % total )) \
                             || idx=$(( (idx - 1 + total) % total ))
  echo "${vals[$idx]}"
}
apply_sq() {
  local num="$1" line name args
  [ ! -f "$dir/.queries" ] && return
  line=$(sed -n "${num}p" "$dir/.queries")
  [ -z "$line" ] && return
  name="${line%%	*}"; args="${line#*	}"
  # Reset filters then apply saved query's key=value pairs
  ft=""; fs=""; fp=""; : > "$dir/.f_tags"
  for a in $args; do
    case "$a" in
      type=*) ft="${a#*=}";; status=*) fs="${a#*=}";;
      priority=*) fp="${a#*=}";; tag=*) echo "${a#*=}" >> "$dir/.f_tags";;
    esac
  done
  echo "$name" > "$dir/.f_sq"
}
ft=$(cat "$dir/.f_type"); fs=$(cat "$dir/.f_status")
fp=$(cat "$dir/.f_priority"); fa=$(cat "$dir/.f_active")
fsort=$(cat "$dir/.f_sort"); fgroup=$(cat "$dir/.f_group")
farchive=$(cat "$dir/.f_archive"); fmatch=$(cat "$dir/.f_match")
# Pinned items: when an action (priority bump, status cycle) causes an item
# to no longer match active filters, it stays visible at the top of the list
# (dimmed, marked "temporarily pinned"). Pins are cleared on any filter change
# (type/status/priority/tag/query/reset) but kept on refresh (which runs
# after actions). action.sh overwrites .pinned each time, so only the latest
# acted-on items stay pinned.
case "$action" in refresh) ;; *) : > "$dir/.pinned" ;; esac
case "$action" in
  type)     fa=type;     ft=$(cycle type next "$ft"); : > "$dir/.f_sq" ;;
  status)   fa=status;   fs=$(cycle status next "$fs"); : > "$dir/.f_sq" ;;
  priority) fa=priority; fp=$(cycle priority next "$fp"); : > "$dir/.f_sq" ;;
  sort)     fsort=$(cycle sort next "$fsort") ;;
  clear-type) ft=""; : > "$dir/.f_sq" ;;
  clear-status) fs=""; : > "$dir/.f_sq" ;;
  clear-priority) fp=""; : > "$dir/.f_sq" ;;
  clear-sort) fsort="priority" ;;
  next|prev)  # h/l: cycle through saved queries
    if [ -f "$dir/.queries" ]; then
      total=$(wc -l < "$dir/.queries")
      if [ "$total" -gt 0 ]; then
        cur_sq=$(cat "$dir/.f_sq" 2>/dev/null)
        cur_idx=0  # 0 = no query selected (show all)
        if [ -n "$cur_sq" ]; then
          n=0
          while IFS='	' read -r qn _; do
            n=$((n + 1))
            [ "$qn" = "$cur_sq" ] && cur_idx=$n && break
          done < "$dir/.queries"
        fi
        # total+1 positions: 0=all, 1..total=queries
        positions=$((total + 1))
        if [ "$action" = "next" ]; then
          cur_idx=$(( (cur_idx + 1) % positions ))
        else
          cur_idx=$(( (cur_idx - 1 + positions) % positions ))
        fi
        if [ "$cur_idx" -eq 0 ]; then
          ft=""; fs=""; fp=""; : > "$dir/.f_tags"; : > "$dir/.f_sq"
        else
          apply_sq "$cur_idx"
        fi
      fi
    fi ;;
  sq*) apply_sq "${action#sq}" ;;
  pick) [ -f "$dir/.f_pick" ] && apply_sq "$(cat "$dir/.f_pick")" && rm -f "$dir/.f_pick" ;;
  reset) ft=""; fs=""; fp=""; fmatch=""; : > "$dir/.f_tags"; : > "$dir/.f_sq"; : > "$dir/.f_match"; : > "$dir/.f_match_paths"
    { IFS= read -r fsort; IFS= read -r fgroup; IFS= read -r _a; } < "$dir/.schema_defaults"
    [ "$_a" = "true" ] && farchive="show" || farchive="" ;;
  clear-tags) : > "$dir/.f_tags" ;;
  clear-match) fmatch=""; : > "$dir/.f_match"; : > "$dir/.f_match_paths" ;;
  group) fgroup=$(cycle group next "$fgroup") ;;
  clear-group) fgroup="" ;;
  archive) [ -n "$farchive" ] && farchive="" || farchive="show" ;;
  refresh) ;;  # just re-apply filters (after tag picker)
esac
echo "$ft" > "$dir/.f_type"; echo "$fs" > "$dir/.f_status"
echo "$fp" > "$dir/.f_priority"; echo "$fa" > "$dir/.f_active"
echo "$fsort" > "$dir/.f_sort"; echo "$fgroup" > "$dir/.f_group"
echo "$farchive" > "$dir/.f_archive"
echo "$fmatch" > "$dir/.f_match"
# Build awk condition
cond='length($1) > 0'
[ -n "$ft" ] && cond="$cond && \$1==\"$ft\""
[ -n "$fs" ] && cond="$cond && \$2==\"$fs\""
# Hide archived statuses unless archive toggle is on or status is explicitly filtered
archive_cond=$(cat "$dir/.schema_archive_cond")
[ -z "$farchive" ] && [ -z "$fs" ] && cond="$cond$archive_cond"
if [ "$fp" = "none" ]; then
  cond="$cond && \$3==\"\""
elif [ -n "$fp" ]; then
  cond="$cond && \$3==\"$fp\""
fi
# Tag filter (OR: match any selected tag)
if [ -s "$dir/.f_tags" ]; then
  tag_cond=""
  while IFS= read -r tag; do
    [ -z "$tag" ] && continue
    if [ -n "$tag_cond" ]; then
      tag_cond="$tag_cond || index(\" \" \$4 \" \", \" $tag \")"
    else
      tag_cond="index(\" \" \$4 \" \", \" $tag \")"
    fi
  done < "$dir/.f_tags"
  [ -n "$tag_cond" ] && cond="$cond && ($tag_cond)"
fi
# Sort .raw before filtering (empty priority sorts after P4)
do_sort() {
  case "$1" in
    priority) awk -F'\t' 'BEGIN{OFS=FS}{if($3=="")$3=9;print}' | sort -t'	' -k3,3n -s | awk -F'\t' 'BEGIN{OFS=FS}{if($3==9)$3="";print}' ;;
    modified) sort -t'	' -k7,7r -s ;;
    created)  sort -t'	' -k8,8r -s ;;
    title)    sort -t'	' -k5,5 -s ;;
    *)        cat ;;
  esac
}
now=$(date +%s)
# Pre-filter by body match if active
_raw_input="$dir/.raw"
if [ -n "$fmatch" ] && [ -s "$dir/.f_match_paths" ]; then
  awk -F'\t' 'NR==FNR{paths[$0]=1;next} ($6 in paths)' "$dir/.f_match_paths" "$dir/.raw" > "$dir/.raw_matched"
  _raw_input="$dir/.raw_matched"
fi
awk_body=$(cat "$dir/.awk_color_body")
do_sort "$fsort" < "$_raw_input" | TZ=UTC awk -F'\t' -v now="$now" "${cond} { ${awk_body} }" > "$dir/.current"
# Count filtered items (before pinning/grouping adds extra lines)
count=$(wc -l < "$dir/.current")
# Prepend pinned items (from actions) that got filtered out
if [ -s "$dir/.pinned" ]; then
  pinned_lines=""
  pinned_awk=$(cat "$dir/.awk_color_pinned")
  while IFS= read -r pin; do
    [ -z "$pin" ] && continue
    grep -qF "$pin" "$dir/.current" && continue
    # Render the pinned item from .raw with a dim marker
    line=$(TZ=UTC awk -F'\t' -v p="$pin" -v now="$now" "\$6 == p { ${pinned_awk} }" "$dir/.raw")
    [ -n "$line" ] && pinned_lines="${pinned_lines}${line}\n"
  done < "$dir/.pinned"
  if [ -n "$pinned_lines" ]; then
    printf '%b' "$pinned_lines" | cat - "$dir/.current" > "$dir/.current.tmp" && mv "$dir/.current.tmp" "$dir/.current"
  fi
fi
# Grouping post-processing: insert separator headers between groups
if [ -n "$fgroup" ]; then
  case "$fgroup" in type) gcol=1 ;; status) gcol=2 ;; esac
  awk -F'\t' -v gcol="$gcol" '
    NR==FNR { key[$6] = $gcol; next }
    { path=$1; gk=key[path]; print gk "\t" $0 }
  ' "$dir/.raw" "$dir/.current" \
  | sort -t'	' -k1,1 -s \
  | awk -F'\t' -v gmode="$fgroup" \
    -v entity_order="$(cat "$dir/.schema_entity_order")" \
    -v status_order="$(cat "$dir/.schema_status_order")" '
    { gk=$1; sub(/^[^\t]*\t/, "")
      counts[gk]++; lines[gk] = lines[gk] $0 "\n"
    } END {
      if (gmode == "status")
        n = split(status_order, order, " ")
      else
        n = split(entity_order, order, " ")
      '"$(cat "$dir/.schema_icon_setup")"'
      for (i=1; i<=n; i++) {
        g = order[i]
        if (!(g in counts)) continue
        ic = (g in icon) ? icon[g] " " : ""
        printf "\t\033[90;1m── %s%s (%d) ──\033[0m\n", ic, g, counts[g]
        printf "%s", lines[g]
      }
    }' > "$dir/.current.tmp" && mv "$dir/.current.tmp" "$dir/.current"
fi
# Compute inline stats from filtered set
awk_stats=$(cat "$dir/.awk_color_stats")
stats_s=$(awk -F'\t' "${cond}${awk_stats}" "$dir/.raw")
# Header line 1: filter state
fmt_dim() {
  local key="$1" val="$2" is_active="$3" label suffix ic=""
  if [ "$key" = "p" ] && [ -n "$val" ]; then
    label=$(awk -F'\t' -v v="$val" '$1 == v {print $2; exit}' "$dir/.schema_priority_labels")
    [ -z "$label" ] && label="P$val"
  elif [ "$key" = "e" ] && [ -n "$val" ]; then
    ic=$(awk -F'\t' -v v="$val" '$1 == v {printf "%s ", $2; exit}' "$dir/.schema_entity_icons")
    label="${ic}${val}"
  else label="${val:-all}"; fi
  case "$key" in e) suffix="ntity";; s) suffix="tatus";; p) suffix="riority";; *) suffix="";; esac
  if [ -n "$val" ]; then
    # Filter active: cyan key, bold value
    printf ' \033[36m[\033[1;36m%s\033[0;36m]%s:\033[0m \033[1m%s\033[0m' "$key" "$suffix" "$label"
  elif [ "$is_active" = "1" ]; then
    # Active dimension, no filter: cyan key, underlined
    printf ' \033[36m[\033[1;36m%s\033[0;36m]%s:\033[0m \033[4mall\033[0m' "$key" "$suffix"
  else
    # Inactive, no filter: all dim
    printf ' \033[90m[%s]%s: all\033[0m' "$key" "$suffix"
  fi
}
ta=0; sa=0; pa=0
case "$fa" in type) ta=1;; status) sa=1;; priority) pa=1;; esac
t_s=$(fmt_dim e "$ft" $ta); s_s=$(fmt_dim s "$fs" $sa); p_s=$(fmt_dim p "$fp" $pa)
if [ -n "$fgroup" ]; then
  g_s=$(printf '\033[36m[g]\033[0mroup-by: \033[1m%s\033[0m' "$fgroup")
else
  g_s=$(printf '\033[36m[g]\033[0mroup-by: \033[90mn/a\033[0m')
fi
a_s=""
archive_label=$(cat "$dir/.schema_archive_label")
[ -n "$farchive" ] && a_s=$(printf ' \033[1mshowing %s\033[0m' "$archive_label") || a_s=$(printf ' \033[90mhiding %s\033[0m' "$archive_label")
c_s=$(printf '\033[90m── %d\033[0m' "$count")
sort_s=$(printf '\033[36m[o]\033[0mrder: \033[1m⇅ %s\033[0m' "$fsort")
# Show active tags in header if any
tag_s=""
if [ -s "$dir/.f_tags" ]; then
  tag_list=$(tr '\n' ' ' < "$dir/.f_tags" | sed 's/ $//')
  tag_s=$(printf ' \033[35mtags:%s\033[0m' "$tag_list")
fi
# Header line 2+: numbered saved queries with count badges, wrapped to terminal width
active_sq=$(cat "$dir/.f_sq" 2>/dev/null)
cols=$(tput cols 2>/dev/null || echo 80)
# Count matches for "all" (respects archive toggle)
all_cond='length($1) > 0'
[ -z "$farchive" ] && all_cond="$all_cond$archive_cond"
all_count=$(awk -F'\t' "$all_cond"'{n++} END{print n+0}' "$dir/.raw")
# 0:all highlights only when no filters, no tags, no saved query, defaults
has_tags=false; [ -s "$dir/.f_tags" ] && has_tags=true
if [ -z "$active_sq" ] && [ -z "$ft" ] && [ -z "$fs" ] && [ -z "$fp" ] && ! $has_tags; then
  sq_lines=$(printf '\033[1;7m 0:all(%d) \033[0m' "$all_count")
else
  sq_lines=$(printf '\033[90m 0:all(%d) \033[0m' "$all_count")
fi
line_len=$((8 + ${#all_count}))
if [ -f "$dir/.queries" ]; then
  n=0
  while IFS='	' read -r qname qargs; do
    n=$((n + 1))
    # Build awk condition for this query
    sq_cond='length($1) > 0'
    [ -z "$farchive" ] && sq_cond="$sq_cond$archive_cond"
    for a in $qargs; do
      case "$a" in
        type=*) sq_cond="$sq_cond && \$1==\"${a#*=}\"" ;;
        status=*) sq_cond="$sq_cond && \$2==\"${a#*=}\"" ;;
        priority=none) sq_cond="$sq_cond && \$3==\"\"" ;;
        priority=*) sq_cond="$sq_cond && \$3==\"${a#*=}\"" ;;
        tag=*) sq_cond="$sq_cond && index(\" \" \$4 \" \", \" ${a#*=} \")" ;;
      esac
    done
    sq_count=$(awk -F'\t' "$sq_cond"'{n++} END{print n+0}' "$dir/.raw")
    label=$(printf '%d:%s(%d)' "$n" "$qname" "$sq_count")
    # visible length: " label " (spaces + content)
    item_len=$(( ${#label} + 2 ))
    if [ $line_len -gt 0 ] && [ $((line_len + item_len)) -gt $cols ]; then
      sq_lines="$sq_lines"$'\n'
      line_len=0
    fi
    if [ "$qname" = "$active_sq" ]; then
      sq_lines="$sq_lines$(printf '\033[1;7m %s \033[0m' "$label")"
    else
      sq_lines="$sq_lines$(printf '\033[90m %s \033[0m' "$label")"
    fi
    line_len=$((line_len + item_len))
  done < "$dir/.queries"
fi
# Section labels and keybinding help
filters_lbl=$(printf '\033[1;90m Filters:\033[0m%s%s%s %s' "$t_s" "$s_s" "$p_s" "$c_s")
if [ -n "$tag_s" ]; then
  filters_lbl=$(printf '%s\n          \033[36m[t]\033[0mags:%s \033[90m·\033[0m \033[36m[T]\033[0m clear' "$filters_lbl" "$tag_s")
else
  filters_lbl=$(printf '%s\n          \033[36m[t]\033[0mags: \033[90mnone\033[0m' "$filters_lbl")
fi
if [ -n "$fmatch" ]; then
  filters_lbl=$(printf '%s\n          \033[36m[m]\033[0match contents: \033[1m"%s"\033[0m \033[90m·\033[0m \033[36m[M]\033[0m clear' "$filters_lbl" "$fmatch")
else
  filters_lbl=$(printf '%s\n          \033[36m[m]\033[0match contents: \033[90mnone\033[0m' "$filters_lbl")
fi
queries_lbl=$(printf '\033[1;90m Presets:\033[0m %s' "$sq_lines")
presets_hint=$(printf '\033[90m          \033[36mh\033[90m/\033[36ml\033[90m ←→  \033[36m0\033[90m-\033[36m9\033[90m/\033[36mf\033[90m jump\033[0m')
view_lbl=$(printf '\033[1;90m View:\033[0m %s \033[90m·\033[0m %s \033[90m·\033[0m \033[36m[z]\033[0m%s' "$sort_s" "$g_s" "$a_s")
actions_lbl=$(printf '\033[1;90m Actions:\033[0m \033[36m[a]\033[0mdvance status \033[90m·\033[0m \033[36m[A]\033[0m reverse advance \033[90m·\033[0m \033[36m+\033[0m/\033[36m-\033[0m pri \033[90m(alt: </>)\033[0m \033[90m·\033[0m \033[36m[n]\033[0mew \033[90m·\033[0m \033[36m[b]\033[0mulk edit')
change_lbl=$(printf '\033[1;90m Change:\033[0m \033[36m[c]\033[0m then \033[36m[s]\033[0mtatus \033[90m·\033[0m \033[36m[p]\033[0mriority \033[90m·\033[0m \033[36m[e]\033[0mntity type')
change_lbl_active=$(printf '\033[1;90m Change:\033[0m \033[1;33m[c]\033[0m \033[1;37mthen \033[1;36m[s]\033[1;37mtatus \033[90m·\033[0m \033[1;36m[p]\033[1;37mriority \033[90m·\033[0m \033[1;36m[e]\033[1;37mntity type\033[0m')
keys_lbl=$(printf '\033[1;90m Keys:\033[0m \033[36m[R]\033[0meset everything \033[90m·\033[0m \033[36m/\033[0m search \033[90m·\033[0m \033[36mq\033[0muit')
stats_lbl=$(printf '\033[1;90m Stats:\033[0m %s' "$stats_s")
printf '%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s' "$filters_lbl" "$stats_lbl" "$queries_lbl" "$presets_hint" "$view_lbl" "$actions_lbl" "$change_lbl" "$keys_lbl" > "$dir/.header"
printf '%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s' "$filters_lbl" "$stats_lbl" "$queries_lbl" "$presets_hint" "$view_lbl" "$actions_lbl" "$change_lbl_active" "$keys_lbl" > "$dir/.header-c"
total=$(awk -F'\t' 'length($1) > 0' "$dir/.raw" | wc -l)
printf ' nn · %d/%d ' "$count" "$total" > "$dir/.border"
printf 'reload(cat %s/.current)+transform-header(cat %s/.header)+change-border-label(%s)' "$dir" "$dir" "$(cat "$dir/.border")"
ENDFILTER
    chmod +x "$_nn_dir/filter.sh"

    # Generate initial results, stats, and header via filter.sh
    "$_nn_dir/filter.sh" "$_nn_dir" refresh > /dev/null

    fzf --ansi --delimiter $'\t' --with-nth 2.. < "$_nn_dir/.current" \
      --header '' --header-first \
      --border rounded \
      --border-label "$(cat "$_nn_dir/.border")" \
      --border-label-pos bottom \
      --preview "$_nn_dir/preview.sh {1}" \
      --prompt ': ' \
      --bind "e:transform[test -f /tmp/.nn-c && rm -f /tmp/.nn-c && printf '%s\n' {+1} > $_nn_dir/.c_sel && echo 'change-prompt(: )+execute($_nn_dir/bulkset.sh $_nn_dir type)+reload(cat $_nn_dir/.current)+transform-header(cat $_nn_dir/.header)+deselect-all' || $_nn_dir/filter.sh $_nn_dir type]" \
      --bind "E:transform[$_nn_dir/filter.sh $_nn_dir clear-type]" \
      --bind "s:transform[test -f /tmp/.nn-c && rm -f /tmp/.nn-c && printf '%s\n' {+1} > $_nn_dir/.c_sel && echo 'change-prompt(: )+execute($_nn_dir/bulkset.sh $_nn_dir status)+reload(cat $_nn_dir/.current)+transform-header(cat $_nn_dir/.header)+deselect-all' || $_nn_dir/filter.sh $_nn_dir status]" \
      --bind "S:transform[$_nn_dir/filter.sh $_nn_dir clear-status]" \
      --bind "p:transform[test -f /tmp/.nn-c && rm -f /tmp/.nn-c && printf '%s\n' {+1} > $_nn_dir/.c_sel && echo 'change-prompt(: )+execute($_nn_dir/bulkset.sh $_nn_dir priority)+reload(cat $_nn_dir/.current)+transform-header(cat $_nn_dir/.header)+deselect-all' || $_nn_dir/filter.sh $_nn_dir priority]" \
      --bind "P:transform[$_nn_dir/filter.sh $_nn_dir clear-priority]" \
      --bind "l:transform[$_nn_dir/filter.sh $_nn_dir next]" \
      --bind "h:transform[$_nn_dir/filter.sh $_nn_dir prev]" \
      --bind "1:transform[$_nn_dir/filter.sh $_nn_dir sq1]" \
      --bind "2:transform[$_nn_dir/filter.sh $_nn_dir sq2]" \
      --bind "3:transform[$_nn_dir/filter.sh $_nn_dir sq3]" \
      --bind "4:transform[$_nn_dir/filter.sh $_nn_dir sq4]" \
      --bind "5:transform[$_nn_dir/filter.sh $_nn_dir sq5]" \
      --bind "6:transform[$_nn_dir/filter.sh $_nn_dir sq6]" \
      --bind "7:transform[$_nn_dir/filter.sh $_nn_dir sq7]" \
      --bind "8:transform[$_nn_dir/filter.sh $_nn_dir sq8]" \
      --bind "9:transform[$_nn_dir/filter.sh $_nn_dir sq9]" \
      --bind "0:transform[$_nn_dir/filter.sh $_nn_dir reset]" \
      --bind "R:transform[$_nn_dir/filter.sh $_nn_dir reset]" \
      --bind "f:execute($_nn_dir/querypick.sh $_nn_dir)+transform[$_nn_dir/filter.sh $_nn_dir pick]" \
      --bind "t:execute($_nn_dir/tags.sh $_nn_dir)+transform[$_nn_dir/filter.sh $_nn_dir refresh]" \
      --bind "T:transform[$_nn_dir/filter.sh $_nn_dir clear-tags]" \
      --bind "m:execute($_nn_dir/match.sh $_nn_dir)+transform[$_nn_dir/filter.sh $_nn_dir refresh]" \
      --bind "M:transform[$_nn_dir/filter.sh $_nn_dir clear-match]" \
      --bind "o:transform[$_nn_dir/filter.sh $_nn_dir sort]" \
      --bind "a:execute($_nn_dir/cyclestatus.sh $_nn_dir {1} fwd)+transform[$_nn_dir/reload_at.sh $_nn_dir {1}]" \
      --bind "A:execute($_nn_dir/cyclestatus.sh $_nn_dir {1} rev)+transform[$_nn_dir/reload_at.sh $_nn_dir {1}]" \
      --bind "+:execute($_nn_dir/bumppri.sh $_nn_dir {1} down)+transform[$_nn_dir/reload_at.sh $_nn_dir {1}]" \
      --bind ">:execute($_nn_dir/bumppri.sh $_nn_dir {1} down)+transform[$_nn_dir/reload_at.sh $_nn_dir {1}]" \
      --bind "-:execute($_nn_dir/bumppri.sh $_nn_dir {1} up)+transform[$_nn_dir/reload_at.sh $_nn_dir {1}]" \
      --bind "<:execute($_nn_dir/bumppri.sh $_nn_dir {1} up)+transform[$_nn_dir/reload_at.sh $_nn_dir {1}]" \
      --bind "g:transform[$_nn_dir/filter.sh $_nn_dir group]" \
      --bind "z:transform[$_nn_dir/filter.sh $_nn_dir archive]" \
      --bind "n:execute($_nn_dir/newnote.sh $_nn_dir)+transform[$_nn_dir/reload_at.sh $_nn_dir '']" \
      --bind "c:execute-silent(touch /tmp/.nn-c)+change-prompt(c )+transform-header(cat $_nn_dir/.header-c)" \
      --bind "i:execute[test -f {1} && ${EDITOR:-nvim} {1}]" \
      --multi \
      --bind "b:execute($_nn_dir/bulkedit.sh $_nn_dir)+transform[$_nn_dir/reload_at.sh $_nn_dir '']+deselect-all" \
      --bind "start:transform-header(cat $_nn_dir/.header)+execute-silent(rm -f /tmp/.nn-s /tmp/.nn-c)" \
      --bind 'j:down,k:up,q:abort,change:clear-query' \
      --bind '/:unbind(j,k,q,change,e,E,s,S,p,P,h,l,f,t,T,m,M,R,b,o,n,a,A,c,i,g,z,+,-,<,>,0,1,2,3,4,5,6,7,8,9)+change-prompt(/ )+execute-silent(touch /tmp/.nn-s)' \
      --bind 'esc:transform[test -f /tmp/.nn-c && rm -f /tmp/.nn-c && printf "change-prompt(: )+transform-header(cat '"$_nn_dir"'/.header)" || { test -f /tmp/.nn-s && rm /tmp/.nn-s && printf "rebind(j,k,q,e,E,s,S,p,P,h,l,f,t,T,m,M,R,b,o,n,a,A,c,i,u,g,z,+,-,<,>,0,1,2,3,4,5,6,7,8,9)+change-prompt(: )" || printf "clear-query+rebind(change)"; }]' \
      --bind '::rebind(j,k,q,e,E,s,S,p,P,h,l,f,t,T,m,M,R,b,o,n,a,A,c,i,u,g,z,+,-,<,>,0,1,2,3,4,5,6,7,8,9)+change-prompt(: )+execute-silent(rm -f /tmp/.nn-s)' \
      --bind 'J:preview-page-down,K:preview-page-up' \
      --bind 'ctrl-j:preview-page-down,ctrl-k:preview-page-up' \
      --bind 'H:toggle-wrap' \
      --bind "enter:execute[test -f {1} && ${EDITOR:-nvim} {1}]"
    rm -rf "$_nn_dir"
    shopt -u nullglob
    return
  fi

  # ---- NAMED QUERY ----
  if [[ $# -ge 1 && "$1" != *=* && "$1" != -* && -n "${saved_queries[$1]}" ]]; then
    local saved="$1"; shift
    shopt -u nullglob
    notenav_main $(grep -v '^#' "${saved_queries[$saved]}") "$@"
    return
  fi

  # ---- AD-HOC QUERY ----
  declare -A filters
  local interactive=false zk_args=() parsing_filters=true

  while [[ $# -gt 0 ]]; do
    if $parsing_filters; then
      case "$1" in
        -i|--interactive) interactive=true; shift ;;
        --) parsing_filters=false; shift ;;
        *=*) filters[${1%%=*}]="${1#*=}"; shift ;;
        *) parsing_filters=false; zk_args+=("$1"); shift ;;
      esac
    else
      zk_args+=("$1"); shift
    fi
  done

  [[ ${#zk_args[@]} -eq 0 ]] && zk_args=("${_zk_path[@]}")

  local awk_cond="1"
  [[ -n "${filters[type]}" ]] && awk_cond="$awk_cond && \$1==\"${filters[type]}\""
  [[ -n "${filters[status]}" ]] && awk_cond="$awk_cond && \$2==\"${filters[status]}\""
  if [[ "${filters[priority]}" == "none" ]]; then
    awk_cond="$awk_cond && \$3==\"\""
  elif [[ -n "${filters[priority]}" ]]; then
    awk_cond="$awk_cond && \$3==\"${filters[priority]}\""
  fi
  [[ -n "${filters[tag]}" ]] && awk_cond="$awk_cond && index(\" \" \$4 \" \", \" ${filters[tag]} \") > 0"

  if $interactive; then
    local nn_tmp=$(mktemp)
    local _nn_prev=$(mktemp)
    cat > "$_nn_prev" << 'ENDPREVIEW'
#!/bin/bash
file="$1"
test -f "$file" || exit 0
$(command -v bat || command -v batcat) -p --color always "$file" 2>/dev/null || cat "$file"
tmp_links=$(mktemp); tmp_back=$(mktemp)
zk list --linked-by "$file" --format "  {{title}}" --quiet 2>/dev/null > "$tmp_links" &
zk list --link-to "$file" --format "  {{title}}" --quiet 2>/dev/null > "$tmp_back" &
wait
if [ -s "$tmp_links" ]; then
  printf '\n\033[1;34m── Links ─────────────────────────\033[0m\n'
  cat "$tmp_links"
fi
if [ -s "$tmp_back" ]; then
  printf '\n\033[1;35m── Backlinks ─────────────────────\033[0m\n'
  cat "$tmp_back"
fi
rm -f "$tmp_links" "$tmp_back"
ENDPREVIEW
    chmod +x "$_nn_prev"
    zk list "${zk_args[@]}" --format "$_fmt" --quiet 2>/dev/null \
      | awk -F'\t' "$awk_cond && length(\$1) > 0 $_awk_color" > "$nn_tmp"
    fzf --ansi --delimiter $'\t' --with-nth 2.. < "$nn_tmp" \
          --preview "$_nn_prev {1}" \
          --prompt ': ' \
          --bind 'start:execute-silent(rm -f /tmp/.nn-s)' \
          --bind 'j:down,k:up,q:abort,change:clear-query' \
          --bind '/:unbind(j,k,q,change)+change-prompt(/ )+execute-silent(touch /tmp/.nn-s)' \
          --bind 'esc:transform[test -f /tmp/.nn-s && rm /tmp/.nn-s && printf "rebind(j,k,q)+change-prompt(: )" || printf "clear-query+rebind(change)"]' \
          --bind '::rebind(j,k,q)+change-prompt(: )+execute-silent(rm -f /tmp/.nn-s)' \
          --bind 'J:preview-page-down,K:preview-page-up' \
          --bind 'ctrl-j:preview-page-down,ctrl-k:preview-page-up' \
          --bind 'H:toggle-wrap' \
          --bind "enter:execute(${EDITOR:-nvim} {1})"
    rm -f "$nn_tmp" "$_nn_prev"
  else
    zk list "${zk_args[@]}" --format "$_fmt" --quiet 2>/dev/null \
      | awk -F'\t' "$awk_cond && length(\$1) > 0 {printf \"[%s] [P%s] [%s] %s\n\", \$1, \$3, \$2, \$5}"
  fi
  shopt -u nullglob
}
