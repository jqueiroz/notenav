# notenav — TUI faceted browser for markdown notes
# https://github.com/jqueiroz/notenav

NOTENAV_VERSION="0.1.0-dev"

# --- Easter egg ---
# set n=... to unlock a hidden message

_nn_easteregg_check() {
  command -v sha256sum >/dev/null 2>&1 || return 3
  [[ -z "$1" ]] && return 2

  local rounded
  rounded=$(printf '%.3f' "$1" 2>/dev/null) || return 1
  [[ "$rounded" =~ ^[0-9]+\.[0-9]{3}$ ]] || return 1
  local input=$((10#${rounded//./}))
  [[ $input -lt 100000 ]] || return 1

  local coefficients=(478163329 2894506496 2182702633 3660101090 597685614 2020430640 1889601852 734327944 1084777536 758250474 998822545 1766542899 3173536327 355100180 2179492741 3816728157 1278376636 1667089154 3887582301 3253864259 4193354942 3989547217 648178753 2410780885 3791898873 7885616 2302562119 1467395858 2499420820 2033773707 867619779 2343570920 1596536781 1626641437 583237955 2242419488 1051193280 3112708489 1718868056 1335273333 1971527598 3293782164 1453750005 3609555441 69821561 3911544398 4283407753 3414433470 3436727748 1379971978 3803078527 2263375611 2073045463 3020285318 412109359 1748123240 4264778964 1200888842 4233012650 572719158 643502654 3629435192 172650176 643557518 123450946 2776605007 1141730249 634631165 551563603 3648811782 1856381367 1696247178 192403849 304303819 3379665302 1833754732 121417114 3374065137)
  local my_favorite_prime=4294967291
  local result=0
  local coeff
  for coeff in "${coefficients[@]}"; do
    result=$(( (result * input + coeff) % my_favorite_prime ))
  done

  local hash
  hash=$(printf '%s' "$result" | sha256sum | cut -d' ' -f1)
  if [[ "$hash" == "da0a93cda40c3e97383533a5eb0341ce68ec3d80b39405376661db6dee1abfde" ]]; then
    printf 'ans2:%s' "$result"
  elif [[ "$hash" == "2ddded04a91fb628ff828032b665440e71e53c14f27c34fd663d4ccc92301f78" ]]; then
    printf 'ans1:%s' "$result"
  else
    return 1
  fi
}

_nn_easteregg_decode() {
  local dir="$1"
  local variant="${2%%:*}"
  local seed="${2#*:}"
  local blob chunks
  if [[ "$variant" == "ans1" ]]; then
    chunks=44
    blob="f194670959860393332baf55f4102b72ffffbac447f07b63d1f2025464996743609a4694e6ade2c651c4f165171c404c71c52940e7a4aac505613e01e604dbfab395c6cfa13263e80f9e7d5330fa6a6fdc272e370c3f74b7434227f7d6f7fd264359ddf3b04bdf26f4561cfca007511840826a468bbed63482cd1912a1e598cb1b611b94e4b4dabeb371281061a7379fcfbee6d20d2c22e110877b9717edf3b0ff04ceb0a8c1cec2d80b1524ea5065542ff9e3b796cc29be87308c7f8e76bfac2461f2dca448815c4bfcf571c1bf11a358efd60023f31c2154ddbe3e37896e4d1f994b1977d2a9868d103516d2c55c54c9a3dba039cb77ef60699e6988ab10999283b6bf58a2bab607e5de85ec1ac182a3422229f6635689daa6340a7b6b00bc38e04655841b1b2b3c60a651de3451176bbb9d6faa18189d7df7d87d7ae2d4fd1dabec3d26d11de4e2bc65ef7bd34e034711d9ea781ad8039cbb8f775ed8fa771c693610f509acfa0970fd34c99854eac693660bfd377e13bc8fbd6a4a3ca8385eff3040c8dc9bf000e85a8c839c88dbb79b159ea9a874e6cb0461825bd7969398c20f347d490c814613022b30e2526e155fc516fe6b7ae6dafc1d3aba0f76cd713cc4cde66a6525e1a5378039997de2c215dc10287a10853b61c6f9361640ba496462cd1233bfa2c5b79de5bb5bc7e391102e19c82918f493c342e0bae94b1e6d6ad3c92ce346ec8f1f0f492f408452c48d4aa5cf676123d93b2ff996c0dad2526fa4fc42f51761191409c937139b5d9057a002660a2860def44a7f2ffa282318c720ba75749eac88b0ce5568eeb72391133e8e14606e4adefe42158253a046aeee8a6ffe6a4809cda8fc8ca0f4d0422b2647f741cb0ec51b782bc8f2704923b2bbd144bc9c68a853087e663ce59841f85f0f8877ccfb4ca2da8457c8b34c5b53399645ad264155d7c70b048d280c8d9e4584f86bf8e4bf5876f343dc948f1a9306482dd8d607361d7ec7a49d85e91234fc34fa276097134066db178206c75fd29cd30bcad43e582278ce89904664ee735308d9542e98cba7b08075e0dd570b596a7a71e3deb7d409ed6870263461b57d7ffdf5c9617501f20650f872a2e36192d091b8930736429ee316b27d69e600884161360c97c4181a360faed5b2d04be6d6b4aaf2e831575273ff946be39482244124baaf31a76cbebf28bb52cd5cf8ed9149bada0c6ae8cbe45983218f8fa52543a2646c68cedb875ff5292d3f0d65e91ca4899571117ee46c0b3e1d39ca122cec9448c5c138b3bfb7a00536e817b52e57e67973e17ec96649c597c10cbe94482e976dbf36750398723896a776d11fba91424f96b711cc2acae58c94b7df35c3df4e299f6b7f0363e2255f7022f4f6d9c36809082b1ac7ba278937f744015080af72735d96d084a17984b2dd2e361f004a37c038ceb32fb342df9873d734e2daedaa80edd9d3f08916b65687ddaccecb2ee969902890b962a4e44cd5e1af916f047f19099cfe8530821cb693993053d3e084001003076256a869f810bcc573bbf5b66b7a60c206f02f75e99ae0a7e2345e1ab4d1615a5287e38fbd93bdf65cc2bd966d025cc82439c9d28a70d28b0c1f0e9e6727031af9c048791480fc1b9d0e3c92c493771c6ed26959ab9feccda95d4984958c70e35042b116f1b4b2775d48d539d87b9c9eff0f3c8a12640e8d29837ab71dc4b374da581b75045836790adef4b9f11ae97063c58c59fcbb2ee34be61eca72bb8895785dfd36bde1531635b2f5f8552e265f22187d69bb0643514292f1b63a8c1d68808ee0a06b81bcb71ba8ac0e7f35d22cf9c6ea219225b1d5883c970cb9fe4f21ad23a7ef4d147bd6c72627328a24146aa641011e4ec4768d22be411c78d87aa53a168146132883da633b3ab73d27d00c5c93f5d3cf0f5dbe946d26673b6bcfdd51c1698dd6ec"
  else
    chunks=60
    blob="9841491db6abfbaf68d41874e4c1be3ebb64487a0dc85fee1cde362036172c999c2c2c89fbfab9422e3b670dce34e24d3a69fa980a47f148527ab27db71ff4368b313df1cc2c5c1e0c887942b48fe1aba9a1f07e3bd9753189b3afe5fcfbecf12090b3693ce5a4b5ce060edc69b8cc90249cc07d3075c1a7a107c0e18e7489bc1807d40bd27bd747893edd32b8fab999f73e07749d299e681d296cc6691e778b81cecdf15a139934477a11793fad7640b36045ed7a031e6e6ef736bcb8628cd8e0df10bff3a6bb388a05ae638d3b3eaa5a6d0967790d94bcd64a007190904474151f07819f6d79aae1e87747a5bc80e4fcb258ea592e84e865bf2bcad61b036d800152671df16c70e56cbd5d1198843f8b9e2f7692451469cb50efbfc57adfdce6505b3da1676de0e767ee6df3f5854ac584c85245766ed6683dd93d3a6d63b22af68e7e6310ca43ea4762c32921f843e757a9b47bd6ae0382b3e3d6215846d0e255de3375d6903722c8bab3cf60a269b43647060735fcb3dce378abf0c37c8fc33674352a02d56a69fbb77af7dc465175c5142dda9840af4867d5a79fb93290750fcc5c2abb0e8f8784f5ce2964298aa63619e732f546f5da87145c9022b6ded9770380d315ffc8e62ad007135a27c0ca1d989c24f4f089c905cf1278cb68cb5776e6108542dfb756e03090bc016ae5fefc01e491b6e7693b8999b93d36ca998aa584df0583ce458d6f37bdf7605766648c7ddd9ed460b863cde58c9d3b024c61138ddc704058760695f39a271831d3b5aa3ba29328bbee435c18aacde0fb62bcdadad536ad6d6e0dd7448a2e9bca274f9eae2ac5994c4d3bf8f2910526ee0840c68a3dbd81fbc53b1b16a4aaf31ca630f29e0c33f1e0563eef7c0bcd3af1d6ca6bfa8ae11df7d0276e8222bdafaa066062c6c3d46ee6c34e6a4132bb2c9ab16114dd276f75bd123373b883181216d5cf280f8e158f7614a15bb2c90e3bdc64cf9e00a30d8aaba2fcb2c45b1388bd6b2d18db134a412f69f70c49e34b7680aee7bc15d42031b62191008832cf0f6f96875d7b145d326057b7cc1f5cfcb53bbd97e6a7cef3718cba16772214a78bd8d2beaec98e1119c22fa61641185c712f6678e7676d6c022b32d2d80908eb97bdf400f1dbeda38b1266f62234c02ceeefa68422b344268e23db629d3edbc0da33b4671a64cc3f254bf2e04ce675c3189baf7d1247cf1e4cd8613ef023ab2b057a57ea1d3f8c08411bbdca630ac42c49536bf83bacbbcbcfb8f14977402b4fef8d80f4284c391ddd36b24816a9913d6fd8abfd8f5ffaec803b976567208ac512bdf014ce18f73ca7d4c473d95b995b324b936b860bc2ae552903f7d94cbb76a2d9f580abb3b223ba7c35936745cd2950675c2032fde3661f6133d126ec2322701e0ce80952460aefd1a9165f3595bad0513a4f94b1721f882f84cbf8a262e7e364dd640ab7e633a0d82ef5ac579e4a7b2041a3d081b28c9cbf43c65f4919d60ea028a0ea1bc1cc86bf1e8d7e619fa8a57fd089f64a7144fb4236a06a45bdccadb5ff43006e4e5a54668c0153fa7ff9ee8625ca912b275c022f3012b55fd605fccafbc1975be7c7df059ee6a7d1df4319e297c5790a3532ed92cd41b036b8fbd05cb693f0716a5124cf8d4ac2b11037a29622f167b82807b2fdfb2be2315b8e183e44acdafa6dfe0e6fae497078b2feae6c8d72f7616619c43c74917b7f6b7cb301e88d3004a7798869e6ffa9a96fab73ad8e00618c0445c7187dcfd4b13158c9ec7073953a0a0bff32ff24e76e9c8701581e51386adfaed38c6792f6efb2de014a3b56ac1a2202b673ff7c3d3bdcf475248df8bf4e95cbb4006995bcea0fe8f598ad29e7539d69d59601d40e24d6cc93f6e90bf0320331bee478b516e1d5af3f7f483770cc5b3ac40eb8a0cda76c0a8648454257b0775f7a0cc989667ab5f5dcd3733e4c38e7e6d9b6b4c4d00bf72bcb14a9fc6186686d12fce46b5200f7df614b5626b92b2af27f3bbd3ca3365bd8a2810aad564727efdbc34e79eecbca4a1ba4ba759de6db0ad1a3e1af53cf519dfd5926bfc22aee0fb53fd2f67e684850ec530189dd41eda6f3691359064595fbb715e642f4fced3efd3dcc4c2bf86bdb1bfbd2c445959d6a2d922b4f8628bb87326de8998de0aed39b9ecda82605871d74c98b55466204c65a84584a889dbb379f8cad69406b884a31215d624b3f6483c0b2fc5153c8a1d3079b6817b7ce84959697346bb3ea9254b3c1a2a6dfae1a1a818115457671408adc77e697cd70cabd643ff80962db990f1f5f050f86a14993dedc48332a7ff75a0297e380a3151b2b42e5b99f7e54e4bf427a6473ccd0c03680a54fef215c734909a8446b0c6156e611c3fd6eb82c7b17f83a12c6d329ecb13d8c4ef09e38bb29ecb41fac463db989520177594ded246e34520b395d4edce162a88623cdded9c7e531d0c54827642e732a44290cd86f584a65adabb02cedea01d6d3701c6e64231431a4fbe7fc1092c8c0229ed7e394a3ddbf5c6a330ad260b223ba3010da0456b95ffde1918ddcab53f434981543cad926caff0076d3bb9d1f957aee3fd3010f701fad6b1b3fee31c86b10bec9ca614b9284941f2511faff11407fd41fba95efb2952b0efd5dc14c4fee68b8568a26a58894e3dbddf33f906730ca"
  fi
  local keystream="" i
  for ((i=0; i<chunks; i++)); do
    keystream+=$(printf '%s%d' "$seed" "$i" | sha256sum | cut -d' ' -f1)
  done

  echo "$blob" | awk -v ks="$keystream" '{
    len = length($0) / 2; valid = 1
    for (i = 0; i < len; i++) {
      enc = strtonum("0x" substr($0, i*2+1, 2))
      key = strtonum("0x" substr(ks, i*2+1, 2))
      dec[i] = xor(enc, key)
      if (!(dec[i]==10 || dec[i]==27 || (dec[i]>=32 && dec[i]<=126) || dec[i]>=128)) { valid=0; break }
    }
    if (valid) for (i = 0; i < len; i++) printf "%c", dec[i]
  } END { exit(valid ? 0 : 1) }' > "$dir/.empty_easteregg_override" 2>/dev/null \
    || rm -f "$dir/.empty_easteregg_override"
}

# --- Editor resolution ---
# Fallback chain: config ui.editor > $EDITOR > nvim > vim > vi > nano > emacs
# All in good spirit – emacs users, you know you can set $EDITOR.
_nn_resolve_editor() {
  local cfg_editor="$1"
  if [[ -n "$cfg_editor" ]]; then
    printf '%s' "$cfg_editor"
  elif [[ -n "$EDITOR" ]]; then
    printf '%s' "$EDITOR"
  else
    local cmd
    for cmd in nvim vim vi nano emacs; do
      if command -v "$cmd" >/dev/null 2>&1; then
        printf '%s' "$cmd"
        return
      fi
    done
    printf 'vi'
  fi
}

# --- Config loader ---
# Parses TOML workflow/config files via yq (TOML→JSON), merges with jq.
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

  # Step 1: Load base and user configs
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

  local base_json="{}" user_json="{}"
  if [[ -f "$base_cfg" ]]; then
    base_json=$(yq -p=toml -o=json -I=0 '.' "$base_cfg" 2>/dev/null) || base_json="{}"
  fi
  if [[ -f "$user_cfg" ]]; then
    user_json=$(yq -p=toml -o=json -I=0 '.' "$user_cfg" 2>/dev/null) || user_json="{}"
  fi

  # Step 2: Load project workflow (.nn/workflow.toml)
  # This single file replaces the old .nn/schema.toml + .nn/config.toml split.
  # It can extend a built-in workflow and/or define project queries.
  local project_wf_json="{}"
  local project_wf_file="${project_nn_dir:+$project_nn_dir/workflow.toml}"
  local _has_project_wf=false
  if [[ -n "$project_wf_file" && -f "$project_wf_file" ]]; then
    project_wf_json=$(yq -p=toml -o=json -I=0 '.' "$project_wf_file" 2>/dev/null) || project_wf_json="{}"
    [[ "$project_wf_json" != "{}" ]] && _has_project_wf=true
  fi

  # Step 3: Determine base workflow to load
  # If project workflow has extends → use that as the base
  # If project workflow exists without extends → it IS the full definition (no base needed)
  # If no project workflow → use user default_workflow or "compass"
  local workflow_name="" workflow_json="{}"
  if [[ "$_has_project_wf" == "true" ]]; then
    workflow_name=$(printf '%s' "$project_wf_json" | jq -r '.extends // empty' 2>/dev/null)
  fi
  if [[ -z "$workflow_name" && "$_has_project_wf" == "false" ]]; then
    workflow_name=$(printf '%s' "$user_json" | jq -r '.default_workflow // empty' 2>/dev/null)
    if [[ -z "$workflow_name" ]]; then
      workflow_name=$(printf '%s' "$base_json" | jq -r '.default_workflow // empty' 2>/dev/null)
    fi
    workflow_name="${workflow_name:-compass}"
  fi

  # Step 4: Load base workflow and resolve extends chain
  if [[ -n "$workflow_name" ]]; then
    local workflow_file=""
    if [[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/notenav/workflows/$workflow_name.toml" ]]; then
      workflow_file="${XDG_CONFIG_HOME:-$HOME/.config}/notenav/workflows/$workflow_name.toml"
    elif [[ -f "$notenav_root/config/workflows/$workflow_name.toml" ]]; then
      workflow_file="$notenav_root/config/workflows/$workflow_name.toml"
    fi

    if [[ -z "$workflow_file" ]]; then
      echo "notenav: workflow '$workflow_name' not found, falling back to compass" >&2
      workflow_file="$notenav_root/config/workflows/compass.toml"
    fi

    if [[ ! -f "$workflow_file" ]]; then
      echo "notenav: no workflow file found at $workflow_file" >&2
      return 1
    fi

    workflow_json=$(yq -p=toml -o=json -I=0 '.' "$workflow_file" 2>/dev/null)
    if [[ -z "$workflow_json" || "$workflow_json" == "null" ]]; then
      echo "notenav: failed to parse workflow $workflow_file (requires yq-go, not yq-python)" >&2
      return 1
    fi

    # Resolve extends chain on the base workflow itself (max depth 5)
    local _extends _depth=0
    _extends=$(printf '%s' "$workflow_json" | jq -r '.extends // empty' 2>/dev/null)
    while [[ -n "$_extends" && $_depth -lt 5 ]]; do
      if [[ "$_extends" == https://* ]]; then
        echo "notenav: remote workflow extends not yet supported: $_extends" >&2
        return 1
      fi
      local _base_file="$notenav_root/config/workflows/$_extends.toml"
      if [[ ! -f "$_base_file" ]]; then
        echo "notenav: extended workflow '$_extends' not found" >&2
        return 1
      fi
      local _base_json
      _base_json=$(yq -p=toml -o=json -I=0 '.' "$_base_file" 2>/dev/null)
      if [[ -z "$_base_json" || "$_base_json" == "null" ]]; then
        echo "notenav: failed to parse base workflow $_base_file" >&2
        return 1
      fi
      workflow_json=$(printf '%s\n%s' "$_base_json" "$workflow_json" \
        | jq -s '.[0] * .[1] | del(.extends)' 2>/dev/null)
      _extends=$(printf '%s' "$_base_json" | jq -r '.extends // empty' 2>/dev/null)
      (( _depth++ ))
    done
    if [[ $_depth -ge 5 ]]; then
      echo "notenav: workflow extends chain too deep (max 5)" >&2
      return 1
    fi
  fi

  # Step 5: Apply project workflow overrides and extract project queries
  # Project queries are applied last in the merge so they win over user/workflow queries.
  local project_queries="{}"
  if [[ "$_has_project_wf" == "true" ]]; then
    project_queries=$(printf '%s' "$project_wf_json" | jq '{queries: (.queries // {})}' 2>/dev/null) || project_queries="{}"
    if [[ -n "$workflow_name" ]]; then
      # Has extends — merge project overrides (minus queries/extends) onto base
      local _project_overrides
      _project_overrides=$(printf '%s' "$project_wf_json" | jq 'del(.queries) | del(.extends)' 2>/dev/null)
      if [[ -n "$_project_overrides" && "$_project_overrides" != "{}" && "$_project_overrides" != "null" ]]; then
        workflow_json=$(printf '%s\n%s' "$workflow_json" "$_project_overrides" \
          | jq -s '.[0] * .[1]' 2>/dev/null)
      fi
    else
      # Full custom definition — the file IS the workflow (minus queries)
      workflow_json=$(printf '%s' "$project_wf_json" | jq 'del(.queries)' 2>/dev/null)
    fi
  fi

  # Handle queries.inherit: if false in project or user config,
  # strip workflow queries so only explicit queries survive
  local _inherit
  _inherit=$(printf '%s' "$project_wf_json" | jq -r '.queries.inherit // empty' 2>/dev/null)
  if [[ -z "$_inherit" ]]; then
    _inherit=$(printf '%s' "$user_json" | jq -r '.queries.inherit // empty' 2>/dev/null)
  fi
  if [[ "$_inherit" == "false" ]]; then
    workflow_json=$(printf '%s' "$workflow_json" | jq 'del(.queries)' 2>/dev/null)
  fi

  # Deep merge: workflow * base * user * project_queries
  # Later values win. Project queries applied last so they override user/workflow queries.
  NN_CFG_JSON=$(printf '%s\n%s\n%s\n%s' "$workflow_json" "$base_json" "$user_json" "$project_queries" \
    | jq -s '.[0] * .[1] * .[2] * .[3] | del(.queries.inherit)' 2>/dev/null)

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

# --- Pre-compute workflow values ---
# Extracts all workflow/config values into bash variables at startup.
# Called once after nn_load_config(). Helper scripts read from temp files
# written by nn_write_workflow_files().

_nn_gen_awk_bodies() {
  local _v _i
  # Uses NN_ENTITY_DISPLAY_ORDER / NN_STATUS_DISPLAY_ORDER (set by nn_precompute_workflow)
  # for group ordering and stats display. Falls back to NN_*_VALUES if unset.

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

  # Age computation (constant across workflows)
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
  local _default_icon="${NN_ENTITY_ICONS[${NN_ENTITY_VALUES[0]:-_}]:-*}"
  _pinned+=$'\n'"  ic = \"$_default_icon\""
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
  local _entity_order_str="${NN_ENTITY_DISPLAY_ORDER[*]:-${NN_ENTITY_VALUES[*]}}"
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

  # Group ordering strings (use display_order)
  NN_ENTITY_ORDER_STR="$_entity_order_str"
  NN_STATUS_ORDER_STR="${NN_STATUS_DISPLAY_ORDER[*]:-${NN_STATUS_VALUES[*]}}"

  # Entity icon AWK snippet for grouping
  NN_AWK_ICON_SETUP=""
  for _v in "${NN_ENTITY_VALUES[@]}"; do
    NN_AWK_ICON_SETUP+="icon[\"$_v\"] = \"${NN_ENTITY_ICONS[$_v]}\"; "
  done
}

nn_precompute_workflow() {
  local _v
  # Entity types
  mapfile -t NN_ENTITY_VALUES < <(nn_cfg '.entity.values[]')
  if [[ ${#NN_ENTITY_VALUES[@]} -eq 0 ]]; then
    echo "notenav: no entity values in config (is yq-go installed?)" >&2
    return 1
  fi
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

  # Status initial (starting state for notes without a status)
  NN_STATUS_INITIAL=$(nn_cfg '.status.initial // empty')

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
    NN_PRIORITY_UNSET_POS=$(nn_cfg '.priority.unset_position // "last"')
    for _v in "${NN_PRIORITY_VALUES[@]}"; do
      NN_PRIORITY_COLORS[$_v]=$(nn_cfg ".priority.colors.\"$_v\" // \"$NN_PRIORITY_DEFAULT_COLOR\"")
      local _label; _label=$(nn_cfg ".priority.labels.\"$_v\" // empty")
      NN_PRIORITY_LABELS[$_v]="${_label:-P$_v}"
    done
    # Empty-string key ("unset priority") can't be stored in bash assoc arrays
    NN_PRIORITY_UP_UNSET=$(nn_cfg '.priority.lifecycle.up."" // empty')
    NN_PRIORITY_DOWN_UNSET=$(nn_cfg '.priority.lifecycle.down."" // empty')
    for _v in "${NN_PRIORITY_VALUES[@]}"; do
      local _up; _up=$(nn_cfg ".priority.lifecycle.up.\"$_v\" // empty")
      [[ -n "$_up" ]] && NN_PRIORITY_UP[$_v]=$_up
      local _down; _down=$(nn_cfg ".priority.lifecycle.down.\"$_v\" // empty")
      [[ -n "$_down" ]] && NN_PRIORITY_DOWN[$_v]=$_down
    done
  else
    NN_PRIORITY_VALUES=()
    NN_PRIORITY_FILTER_CYCLE=()
    NN_PRIORITY_DEFAULT_COLOR="33"
    NN_PRIORITY_UNSET_POS="last"
  fi

  # Display order (falls back to values order if not specified)
  mapfile -t NN_ENTITY_DISPLAY_ORDER < <(nn_cfg '.entity.display_order // [] | .[]')
  [[ ${#NN_ENTITY_DISPLAY_ORDER[@]} -eq 0 ]] && NN_ENTITY_DISPLAY_ORDER=("${NN_ENTITY_VALUES[@]}")
  mapfile -t NN_STATUS_DISPLAY_ORDER < <(nn_cfg '.status.display_order // [] | .[]')
  [[ ${#NN_STATUS_DISPLAY_ORDER[@]} -eq 0 ]] && NN_STATUS_DISPLAY_ORDER=("${NN_STATUS_VALUES[@]}")

  # Defaults
  NN_DEFAULT_SORT=$(nn_cfg '.defaults.sort_by // "created"')
  NN_DEFAULT_GROUP=$(nn_cfg '.defaults.group_by // ""')
  NN_DEFAULT_ARCHIVE=$(nn_cfg '.defaults.show_archive // false')

  # UI preferences
  NN_UI_EDITOR=$(nn_cfg '.ui.editor // empty')
  NN_UI_COMMAND_PROMPT=$(nn_cfg '.ui.command_prompt // ": "')
  NN_UI_SEARCH_PROMPT=$(nn_cfg '.ui.search_prompt // "/ "')
  NN_UI_FORTUNE=$(nn_cfg '.ui.fortune // false')
  NN_UI_PRIORITY_PLUS=$(nn_cfg '.ui.priority_plus // "demote"')

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

nn_write_workflow_files() {
  local dir="$1" _v
  printf '%s\n' "${NN_ENTITY_VALUES[@]}" > "$dir/.schema_entity_values"
  printf '%s\n' "${NN_STATUS_VALUES[@]}" > "$dir/.schema_status_values"
  printf '%s' "$NN_STATUS_INITIAL" > "$dir/.schema_status_initial"
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

  # Priority lifecycle (TSV: from\tto; empty first field = unset priority)
  if [[ "$NN_PRIORITY_ENABLED" != "false" ]]; then
    { [[ -n "$NN_PRIORITY_UP_UNSET" ]] && printf '\t%s\n' "$NN_PRIORITY_UP_UNSET"
      for _v in "${NN_PRIORITY_VALUES[@]}"; do
        [[ -n "${NN_PRIORITY_UP[$_v]+x}" ]] && printf '%s\t%s\n' "$_v" "${NN_PRIORITY_UP[$_v]}"
      done
    } > "$dir/.schema_priority_up"
    { [[ -n "$NN_PRIORITY_DOWN_UNSET" ]] && printf '\t%s\n' "$NN_PRIORITY_DOWN_UNSET"
      for _v in "${NN_PRIORITY_VALUES[@]}"; do
        [[ -n "${NN_PRIORITY_DOWN[$_v]+x}" ]] && printf '%s\t%s\n' "$_v" "${NN_PRIORITY_DOWN[$_v]}"
      done
    } > "$dir/.schema_priority_down"
  else
    : > "$dir/.schema_priority_up"
    : > "$dir/.schema_priority_down"
  fi

  printf '%s' "$NN_PRIORITY_UNSET_POS" > "$dir/.schema_priority_unset_pos"

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

  # UI preferences
  printf '%s' "$(_nn_resolve_editor "$NN_UI_EDITOR")" > "$dir/.schema_editor"

  # Archive label (slash-separated status names for header display)
  local _archive_label=""
  for _v in "${NN_STATUS_ARCHIVE[@]}"; do
    [[ -n "$_archive_label" ]] && _archive_label+="/"
    _archive_label+="$_v"
  done
  printf '%s' "$_archive_label" > "$dir/.schema_archive_label"
}

notenav_main() {
  # --version / --help
  if [[ "$1" == "--version" || "$1" == "-V" ]]; then
    echo "notenav $NOTENAV_VERSION"
    return 0
  fi
  if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    cat <<'EOF'
Usage: nn                        interactive TUI
       nn <query-name>           run a saved query preset
       nn key=value ...          ad-hoc filter (plain output)
       nn key=value ... -i       ad-hoc filter (interactive)

Options:
  -h, --help       Show this help
  -V, --version    Show version

Filter keys: type, status, priority, tag
Example: nn type=task status=active
EOF
    return 0
  fi

  # --easter-egg: print hidden message if n= is correct
  if [[ "$1" == "--easter-egg" ]]; then
    local _nn_k _nn_rc
    _nn_k=$(_nn_easteregg_check "${n:-}")
    _nn_rc=$?
    if [[ $_nn_rc -eq 3 ]]; then
      echo "Sorry, you need sha256sum installed and on the PATH." >&2; return 1
    elif [[ $_nn_rc -eq 2 ]]; then
      echo "You must set n!"; return 1
    elif [[ $_nn_rc -ne 0 ]]; then
      echo "Invalid n!"; return 1
    fi
    _nn_easteregg_decode "/tmp" "$_nn_k"
    cat "/tmp/.empty_easteregg_override" 2>/dev/null && echo
    rm -f "/tmp/.empty_easteregg_override"
    return 0
  fi

  # Load config (workflow + user preferences)
  nn_load_config "$NOTENAV_ROOT" || { echo "notenav: config loading failed" >&2; return 1; }
  nn_precompute_workflow || return 1

  shopt -s nullglob

  # Extract query presets from merged config (workflow + user + project)
  declare -A saved_queries saved_query_order
  while IFS=$'\t' read -r _qname _qorder _qargs; do
    [[ -z "$_qname" ]] && continue
    saved_queries[$_qname]="$_qargs"
    saved_query_order[$_qname]="$_qorder"
  done < <(nn_cfg '.queries // {} | to_entries[] | select(.key != "inherit") | "\(.key)\t\(.value.order // 100)\t\(.value.args // "")"')

  # Format and color from config
  local _fmt="$NN_ZK_FMT"
  local _awk_color="$NN_AWK_COLOR"

  # Default zk path args based on cwd
  local _zk_path=()
  local _gr
  _gr=$(git rev-parse --show-toplevel 2>/dev/null)
  [[ -n "$_gr" && "$PWD" != "$_gr" ]] && _zk_path=("$(pwd)")

  # Resolve editor
  local _nn_editor="$(_nn_resolve_editor "$NN_UI_EDITOR")"

  # ---- FACETED BROWSER (no args) ----
  if [[ $# -eq 0 ]]; then
    local _nn_dir=$(mktemp -d)
    trap "rm -rf '${_nn_dir}'" EXIT
    nn_write_workflow_files "$_nn_dir"

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

    # set n=... to unlock a hidden message
    local _nn_k
    _nn_k=$(_nn_easteregg_check "${n:-}") && _nn_easteregg_decode "$_nn_dir" "$_nn_k"

    # Write query preset definitions for filter.sh, sorted by order
    : > "$_nn_dir/.queries"
    if [[ ${#saved_queries[@]} -gt 0 ]]; then
      local _sq_unsorted=()
      for _qname in "${!saved_queries[@]}"; do
        _sq_unsorted+=("${saved_query_order[$_qname]:-100}	$_qname	${saved_queries[$_qname]}")
      done
      printf '%s\n' "${_sq_unsorted[@]}" | sort -t'	' -k1,1n -k2,2 | \
        while IFS=$'\t' read -r _ _qname _qargs; do
          echo "$_qname	$_qargs" >> "$_nn_dir/.queries"
        done
    fi

    # Tag picker script (opens sub-fzf for multi-select)
    cat > "$_nn_dir/tags.sh" << 'ENDTAGS'
#!/usr/bin/env bash
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
#!/usr/bin/env bash
dir="$1"; query="$2"
zk_path=()
while IFS= read -r p; do [ -n "$p" ] && zk_path+=("$p"); done < "$dir/.zk_path"
if [ -n "$query" ]; then
  zk list "${zk_path[@]}" --match "$query" --format "{{absPath}}	{{title}}" --quiet 2>/dev/null || true
else
  zk list "${zk_path[@]}" --format "{{absPath}}	{{title}}" --quiet 2>/dev/null || true
fi
ENDMSEARCH
    chmod +x "$_nn_dir/match_search.sh"

    cat > "$_nn_dir/match.sh" << 'ENDMATCH'
#!/usr/bin/env bash
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
#!/usr/bin/env bash
# Usage: action.sh <dir> <field> <value> <file1> [file2 ...]
dir="$1"; field="$2"; value="$3"; shift 3
count=0
for file in "$@"; do
  [ ! -f "$file" ] && continue
  # Update field within YAML frontmatter (between first --- and second ---)
  awk -v field="$field" -v value="$value" '
    NR==1 && /^---/ { in_fm=1; print; next }
    in_fm && /^---/ { in_fm=0; if (!found) print field ": " value; print; next }
    in_fm && $0 ~ "^"field":( |$)" { print field ": " value; found=1; next }
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
#!/usr/bin/env bash
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
selected=$(printf '%b' "$vals" | fzf --ansi --reverse --prompt "set $field: " \
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
#!/usr/bin/env bash
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
#!/usr/bin/env bash
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
#!/usr/bin/env bash
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
#!/usr/bin/env bash
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
# Footer with valid values from workflow
printf '\n# type: %s\n' "$(paste -sd', ' "$dir/.schema_entity_values")" >> "$tmpfile"
printf '# status: %s (or empty)\n' "$(paste -sd', ' "$dir/.schema_status_values")" >> "$tmpfile"
if [ "$(cat "$dir/.schema_priority_enabled")" != "false" ]; then
  printf '# priority: %s (or empty)\n' "$(paste -sd', ' "$dir/.schema_priority_values")" >> "$tmpfile"
fi
printf '# tags: space-separated\n' >> "$tmpfile"
# Save original for diffing
cp "$tmpfile" "$origfile"
# Open editor
nn_editor=$(cat "$dir/.schema_editor" 2>/dev/null)
${nn_editor:-vi} "$tmpfile" </dev/tty >/dev/tty
# Apply changes
"$dir/bulkedit_apply.sh" "$dir" "$origfile" "$tmpfile"
ENDBE
    chmod +x "$_nn_dir/bulkedit.sh"

    # Quick note creation: type picker → title prompt → zk new → editor
    cat > "$_nn_dir/newnote.sh" << 'ENDNN'
#!/usr/bin/env bash
dir="$1"
# Pick type (default to current type filter)
cur_type=$(cat "$dir/.f_type")
types="" cur_line=""
while IFS=$'\t' read -r v ic clr desc; do
  line=$(printf '\033[%sm%s %s\033[0m\t\033[90m  %s\033[0m' "$clr" "$ic" "$v" "$desc")
  if [ "$v" = "$cur_type" ]; then
    cur_line="$line"
  else
    [ -n "$types" ] && types="$types"$'\n'
    types="$types$line"
  fi
done < "$dir/.schema_entities"
# Put filtered type first so fzf pre-selects it
[ -n "$cur_line" ] && types="$cur_line${types:+$'\n'$types}"
selected=$(printf '%s' "$types" | fzf --reverse --prompt "type: " \
  --ansi --border --border-label ' New Note ' --delimiter '\t' --with-nth '1,2' \
  --header $'Select note type\n\033[36mEnter\033[0m confirm \033[90m·\033[0m \033[36mEsc\033[0m cancel' \
  --bind "j:down,k:up" | awk '{print $2}')
[ -z "$selected" ] && exit 0
# Styled title prompt — look up icon and color from workflow
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
nn_editor=$(cat "$dir/.schema_editor" 2>/dev/null)
${nn_editor:-vi} "$new_path" < /dev/tty > /dev/tty
ENDNN
    chmod +x "$_nn_dir/newnote.sh"

    # Inline status cycling: advance/reverse status through lifecycle
    cat > "$_nn_dir/cyclestatus.sh" << 'ENDCS'
#!/usr/bin/env bash
dir="$1"; file="$2"; direction="${3:-fwd}"
[ ! -f "$file" ] && exit 0
cur=$(awk -F'\t' -v p="$file" '$6 == p {print $2; exit}' "$dir/.raw")
if [ -z "$cur" ]; then
  # No status set – assign the workflow's initial status
  next=$(cat "$dir/.schema_status_initial" 2>/dev/null)
  [ -z "$next" ] && exit 0
else
  if [ "$direction" = "rev" ]; then
    next=$(awk -F'\t' -v cur="$cur" '$1 == cur {print $2; exit}' "$dir/.schema_status_rev")
  else
    next=$(awk -F'\t' -v cur="$cur" '$1 == cur {print $2; exit}' "$dir/.schema_status_fwd")
  fi
  [ -z "$next" ] && next="$cur"
fi
"$dir/action.sh" "$dir" status "$next" "$file"
ENDCS
    chmod +x "$_nn_dir/cyclestatus.sh"

    # Quick priority bump: increase/decrease urgency
    cat > "$_nn_dir/bumppri.sh" << 'ENDBP'
#!/usr/bin/env bash
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
#!/usr/bin/env bash
dir="$1"; path="$2"
n=$(awk -F'\t' -v p="$path" '$1==p{print NR;exit}' "$dir/.current")
border=$(cat "$dir/.border" 2>/dev/null || echo " nn ")
printf 'reload(cat %s/.current)+pos(%s)+transform-header(cat %s/.header)+change-border-label(%s)' "$dir" "${n:-1}" "$dir" "$border"
ENDRA
    chmod +x "$_nn_dir/reload_at.sh"

    # Query picker script (opens sub-fzf to select a query preset)
    cat > "$_nn_dir/querypick.sh" << 'ENDQP'
#!/usr/bin/env bash
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
#!/usr/bin/env bash
dir="$(dirname "$0")"
file="$1"
if [ ! -f "$file" ]; then
  [ -f "$dir/.empty_placeholder" ] && cat "$dir/.empty_placeholder"
  exit 0
fi

# Placeholder file: show content only, no links
case "$file" in *.empty_placeholder) cat "$file"; exit 0 ;; esac

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
#!/usr/bin/env bash
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
    sort)
      vals=("created" "modified" "title")
      [ "$(cat "$dir/.schema_priority_enabled")" != "false" ] && vals+=("priority") ;;
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
  # Reset filters then apply query preset's key=value pairs
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
  clear-sort) IFS= read -r fsort < "$dir/.schema_defaults" ;;
  next|prev)  # h/l: cycle through query presets
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
# Sanitize values for safe interpolation into awk expressions
awk_esc() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }
cond='length($1) > 0'
[ -n "$ft" ] && cond="$cond && \$1==\"$(awk_esc "$ft")\""
[ -n "$fs" ] && cond="$cond && \$2==\"$(awk_esc "$fs")\""
# Hide archived statuses unless archive toggle is on or status is explicitly filtered
archive_cond=$(cat "$dir/.schema_archive_cond")
[ -z "$farchive" ] && [ -z "$fs" ] && cond="$cond$archive_cond"
if [ "$fp" = "none" ]; then
  cond="$cond && \$3==\"\""
elif [ -n "$fp" ]; then
  cond="$cond && \$3==\"$(awk_esc "$fp")\""
fi
# Tag filter (OR: match any selected tag)
if [ -s "$dir/.f_tags" ]; then
  tag_cond=""
  while IFS= read -r tag; do
    [ -z "$tag" ] && continue
    _etag=$(awk_esc "$tag")
    if [ -n "$tag_cond" ]; then
      tag_cond="$tag_cond || index(\" \" \$4 \" \", \" $_etag \")"
    else
      tag_cond="index(\" \" \$4 \" \", \" $_etag \")"
    fi
  done < "$dir/.f_tags"
  [ -n "$tag_cond" ] && cond="$cond && ($tag_cond)"
fi
# Sort .raw before filtering
do_sort() {
  case "$1" in
    priority)
      local unset_pos=$(cat "$dir/.schema_priority_unset_pos")
      local placeholder=9; [ "$unset_pos" = "first" ] && placeholder=0
      awk -F'\t' -v p="$placeholder" 'BEGIN{OFS=FS}{if($3=="")$3=p;print}' | sort -t'	' -k3,3n -s | awk -F'\t' -v p="$placeholder" 'BEGIN{OFS=FS}{if($3==p)$3="";print}' ;;
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
count=$(awk 'END{print NR}' "$dir/.current")
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
# Header line 2+: numbered query presets with count badges, wrapped to terminal width
active_sq=$(cat "$dir/.f_sq" 2>/dev/null)
cols=$(tput cols 2>/dev/null || echo 80)
# Count matches for "all" (respects archive toggle)
all_cond='length($1) > 0'
[ -z "$farchive" ] && all_cond="$all_cond$archive_cond"
all_count=$(awk -F'\t' "$all_cond"'{n++} END{print n+0}' "$dir/.raw")
# 0:all highlights only when no filters, no tags, no query preset, defaults
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
      _av=$(awk_esc "${a#*=}")
      case "$a" in
        type=*) sq_cond="$sq_cond && \$1==\"$_av\"" ;;
        status=*) sq_cond="$sq_cond && \$2==\"$_av\"" ;;
        priority=none) sq_cond="$sq_cond && \$3==\"\"" ;;
        priority=*) sq_cond="$sq_cond && \$3==\"$_av\"" ;;
        tag=*) sq_cond="$sq_cond && index(\" \" \$4 \" \", \" $_av \")" ;;
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
queries_lbl=$(printf '\033[1;90m Query presets:\033[0m %s' "$sq_lines")
presets_hint=$(printf '\033[90m          \033[36mh\033[90m/\033[36ml\033[90m ←→  \033[36m0\033[90m-\033[36m9\033[90m/\033[36mf\033[90m jump\033[0m')
view_lbl=$(printf '\033[1;90m View:\033[0m %s \033[90m·\033[0m %s \033[90m·\033[0m \033[36m[z]\033[0m%s' "$sort_s" "$g_s" "$a_s")
actions_lbl=$(printf '\033[1;90m Actions:\033[0m \033[36m[a]\033[0mdvance status \033[90m·\033[0m \033[36m[A]\033[0m reverse advance \033[90m·\033[0m \033[36m+\033[0m/\033[36m-\033[0m pri \033[90m(alt: </>)\033[0m \033[90m·\033[0m \033[36m[n]\033[0mew \033[90m·\033[0m \033[36m[b]\033[0mulk edit')
change_lbl=$(printf '\033[1;90m Change:\033[0m \033[36m[c]\033[0m then \033[36m[s]\033[0mtatus \033[90m·\033[0m \033[36m[p]\033[0mriority \033[90m·\033[0m \033[36m[e]\033[0mntity type')
change_lbl_active=$(printf '\033[1;90m Change:\033[0m \033[1;33m[c]\033[0m \033[1;37mthen \033[1;36m[s]\033[1;37mtatus \033[90m·\033[0m \033[1;36m[p]\033[1;37mriority \033[90m·\033[0m \033[1;36m[e]\033[1;37mntity type\033[0m')
keys_lbl=$(printf '\033[1;90m Keys:\033[0m \033[36m[R]\033[0meset everything \033[90m·\033[0m \033[36m/\033[0m search \033[90m·\033[0m \033[36mq\033[0muit')
stats_lbl=$(printf '\033[1;90m Stats:\033[0m %s' "$stats_s")
printf '%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s' "$filters_lbl" "$stats_lbl" "$queries_lbl" "$presets_hint" "$view_lbl" "$actions_lbl" "$change_lbl" "$keys_lbl" > "$dir/.header"
printf '%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s' "$filters_lbl" "$stats_lbl" "$queries_lbl" "$presets_hint" "$view_lbl" "$actions_lbl" "$change_lbl_active" "$keys_lbl" > "$dir/.header-c"
# Always write Dylan placeholder for preview when no item is selected
    printf '\n  [34m╭─────────────────────────────────────────────────╮[0m\n  [34m│[0m                                                 [34m│[0m\n  [34m│[0m                                                 [34m│[0m\n  [34m│[0m                [35m♩[0m [1;36m♪[0m [32m♫[0m [36m♩[0m [35m♪[0m [31m♫[0m [32m♩[0m [1;36m♪[0m [35m♩[0m                [34m│[0m\n  [34m│[0m                                                 [34m│[0m\n  [34m│[0m    ───────────────────────────────────────────  [34m│[0m\n  [34m│[0m                                                 [34m│[0m\n  [34m│[0m    [3;37mHow many notes must a man write down,[0m        [34m│[0m\n  [34m│[0m    [3;37mbefore vim comes to a crawl?[0m                 [34m│[0m\n  [34m│[0m                                                 [34m│[0m\n  [34m│[0m    [3;37mHow many thoughts can a man jot down,[0m        [34m│[0m\n  [34m│[0m    [3;37mbefore they turn to a scrawl?[0m                [34m│[0m\n  [34m│[0m                                                 [34m│[0m\n  [34m│[0m    [1;33mThe answer, my friend, can save us all.[0m      [34m│[0m\n  [34m│[0m                                                 [34m│[0m\n  [34m│[0m    [3;37mHow many notes must a man write down,[0m        [34m│[0m\n  [34m│[0m    [3;37mbefore we call vim unprepared?[0m               [34m│[0m\n  [34m│[0m                                                 [34m│[0m\n  [34m│[0m    [3;37mHow many thoughts can a man jot down,[0m        [34m│[0m\n  [34m│[0m    [3;37mbefore adrift he'\''s declared?[0m                 [34m│[0m\n  [34m│[0m                                                 [34m│[0m\n  [34m│[0m    [1;33mThe answer, my friend, is simply [1;31mn²[0m[1;33m.[0m         [34m│[0m\n  [34m│[0m                                                 [34m│[0m\n  [34m│[0m    [3;37mHow many notes must a man write down,[0m        [34m│[0m\n  [34m│[0m    [3;37mbefore dear vim hits a wall?[0m                 [34m│[0m\n  [34m│[0m                                                 [34m│[0m\n  [34m│[0m    [1;33mThe answer, my friend, is [1;31mnn[0m[1;33m, after all.[0m     [34m│[0m\n  [34m│[0m                                                 [34m│[0m\n  [34m│[0m                                                 [34m│[0m\n  [34m│[0m            [35m♩[0m                                    [34m│[0m\n  [34m│[0m                                                 [34m│[0m\n  [34m│[0m                      [36m♪[0m                          [34m│[0m\n  [34m│[0m                                                 [34m│[0m\n  [34m│[0m         [35m♫[0m                                       [34m│[0m\n  [34m│[0m                                                 [34m│[0m\n  [34m│[0m                   [32m♩[0m                             [34m│[0m\n  [34m│[0m                                                 [34m│[0m\n  [34m│[0m                                                 [34m│[0m\n  [34m│[0m                                                 [34m│[0m\n  [34m╰─────────────────────────────────────────────────╯[0m\n' > "$dir/.empty_placeholder"
[ -f "$dir/.empty_easteregg_override" ] && cat "$dir/.empty_easteregg_override" > "$dir/.empty_placeholder"
# Show Adams placeholder + dummy entry when notebook is truly empty
if [ "$count" -eq 0 ]; then
  raw_total=$(awk -F'\t' 'length($1) > 0' "$dir/.raw" | wc -l)
  if [ "$raw_total" -eq 0 ]; then
    printf '\n  [90m╭─────────────────────────────────────────────────╮[0m\n  [90m│[0m                                                 [90m│[0m\n  [90m│[0m                                                 [90m│[0m\n  [90m│[0m                   [1;33mDON'\''T PANIC[0m                   [90m│[0m\n  [90m│[0m                                                 [90m│[0m\n  [90m│[0m    ───────────────────────────────────────────  [90m│[0m\n  [90m│[0m                                                 [90m│[0m\n  [90m│[0m    No notes here – yet.                         [90m│[0m\n  [90m│[0m    Press [36mn[0m to create your first note.           [90m│[0m\n  [90m│[0m                                                 [90m│[0m\n  [90m│[0m                                                 [90m│[0m\n  [90m│[0m                                                 [90m│[0m\n  [90m│[0m              [31m·[0m       [35m✦[0m                          [90m│[0m\n  [90m│[0m                                                 [90m│[0m\n  [90m│[0m         [36m✦[0m                [32m·[0m                      [90m│[0m\n  [90m│[0m                                                 [90m│[0m\n  [90m│[0m                  [1;37m·[0m                              [90m│[0m\n  [90m│[0m                                                 [90m│[0m\n  [90m│[0m             [35m✦[0m            [34m·[0m                      [90m│[0m\n  [90m│[0m                                                 [90m│[0m\n  [90m│[0m                                                 [90m│[0m\n  [90m│[0m                                                 [90m│[0m\n  [90m│[0m    [37mTip: check out the keybinding[0m                [90m│[0m\n  [90m│[0m    [37mindications on the footer, and[0m               [90m│[0m\n  [90m│[0m    [37mhappy note-taking![0m                           [90m│[0m\n  [90m│[0m                                                 [90m│[0m\n  [90m│[0m                                                 [90m│[0m\n  [90m╰─────────────────────────────────────────────────╯[0m\n' > "$dir/.empty_placeholder"
  fi
  printf '%s\t\033[90m  ~\033[0m\n' "$dir/.empty_placeholder" > "$dir/.current"
fi
total=$(awk -F'\t' 'length($1) > 0' "$dir/.raw" | wc -l)
printf ' nn · %d/%d ' "$count" "$total" > "$dir/.border"
printf 'reload(cat %s/.current)+transform-header(cat %s/.header)+change-border-label(%s)' "$dir" "$dir" "$(cat "$dir/.border")"
ENDFILTER
    chmod +x "$_nn_dir/filter.sh"

    # Generate initial results, stats, and header via filter.sh
    "$_nn_dir/filter.sh" "$_nn_dir" refresh > /dev/null

    # Priority key direction: "demote" = + lowers urgency, "promote" = + raises urgency
    local _nn_plus_dir="down" _nn_minus_dir="up"
    if [[ "$NN_UI_PRIORITY_PLUS" == "promote" ]]; then
      _nn_plus_dir="up"
      _nn_minus_dir="down"
    fi

    fzf --ansi --delimiter $'\t' --with-nth 2.. < "$_nn_dir/.current" \
      --header '' --header-first \
      --border rounded \
      --border-label "$(cat "$_nn_dir/.border")" \
      --border-label-pos bottom \
      --preview "$_nn_dir/preview.sh {1}" \
      --prompt "$NN_UI_COMMAND_PROMPT" \
      --bind "e:transform[test -f $_nn_dir/.nn-c && rm -f $_nn_dir/.nn-c && printf '%s\n' {+1} > $_nn_dir/.c_sel && echo 'change-prompt($NN_UI_COMMAND_PROMPT)+execute($_nn_dir/bulkset.sh $_nn_dir type)+reload(cat $_nn_dir/.current)+transform-header(cat $_nn_dir/.header)+deselect-all' || $_nn_dir/filter.sh $_nn_dir type]" \
      --bind "E:transform[$_nn_dir/filter.sh $_nn_dir clear-type]" \
      --bind "s:transform[test -f $_nn_dir/.nn-c && rm -f $_nn_dir/.nn-c && printf '%s\n' {+1} > $_nn_dir/.c_sel && echo 'change-prompt($NN_UI_COMMAND_PROMPT)+execute($_nn_dir/bulkset.sh $_nn_dir status)+reload(cat $_nn_dir/.current)+transform-header(cat $_nn_dir/.header)+deselect-all' || $_nn_dir/filter.sh $_nn_dir status]" \
      --bind "S:transform[$_nn_dir/filter.sh $_nn_dir clear-status]" \
      --bind "p:transform[test -f $_nn_dir/.nn-c && rm -f $_nn_dir/.nn-c && printf '%s\n' {+1} > $_nn_dir/.c_sel && echo 'change-prompt($NN_UI_COMMAND_PROMPT)+execute($_nn_dir/bulkset.sh $_nn_dir priority)+reload(cat $_nn_dir/.current)+transform-header(cat $_nn_dir/.header)+deselect-all' || $_nn_dir/filter.sh $_nn_dir priority]" \
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
      --bind "+:execute($_nn_dir/bumppri.sh $_nn_dir {1} $_nn_plus_dir)+transform[$_nn_dir/reload_at.sh $_nn_dir {1}]" \
      --bind ">:execute($_nn_dir/bumppri.sh $_nn_dir {1} $_nn_plus_dir)+transform[$_nn_dir/reload_at.sh $_nn_dir {1}]" \
      --bind "-:execute($_nn_dir/bumppri.sh $_nn_dir {1} $_nn_minus_dir)+transform[$_nn_dir/reload_at.sh $_nn_dir {1}]" \
      --bind "<:execute($_nn_dir/bumppri.sh $_nn_dir {1} $_nn_minus_dir)+transform[$_nn_dir/reload_at.sh $_nn_dir {1}]" \
      --bind "g:transform[$_nn_dir/filter.sh $_nn_dir group]" \
      --bind "z:transform[$_nn_dir/filter.sh $_nn_dir archive]" \
      --bind "n:execute($_nn_dir/newnote.sh $_nn_dir)+transform[$_nn_dir/reload_at.sh $_nn_dir '']" \
      --bind "c:execute-silent(touch $_nn_dir/.nn-c)+change-prompt(c )+transform-header(cat $_nn_dir/.header-c)" \
      --bind "i:execute[test -f {1} && $_nn_editor {1}]" \
      --multi \
      --bind "b:execute($_nn_dir/bulkedit.sh $_nn_dir)+transform[$_nn_dir/reload_at.sh $_nn_dir '']+deselect-all" \
      --bind "start:transform-header(cat $_nn_dir/.header)+execute-silent(rm -f $_nn_dir/.nn-s $_nn_dir/.nn-c)" \
      --bind 'j:down,k:up,q:abort,change:clear-query' \
      --bind "/:unbind(j,k,q,change,e,E,s,S,p,P,h,l,f,t,T,m,M,R,b,o,n,a,A,c,i,g,z,+,-,<,>,0,1,2,3,4,5,6,7,8,9)+change-prompt($NN_UI_SEARCH_PROMPT)+execute-silent(touch $_nn_dir/.nn-s)" \
      --bind "esc:transform[test -f $_nn_dir/.nn-c && rm -f $_nn_dir/.nn-c && printf 'change-prompt($NN_UI_COMMAND_PROMPT)+transform-header(cat $_nn_dir/.header)' || { test -f $_nn_dir/.nn-s && rm $_nn_dir/.nn-s && printf 'rebind(j,k,q,e,E,s,S,p,P,h,l,f,t,T,m,M,R,b,o,n,a,A,c,i,g,z,+,-,<,>,0,1,2,3,4,5,6,7,8,9)+change-prompt($NN_UI_COMMAND_PROMPT)' || printf 'clear-query+rebind(change)'; }]" \
      --bind "::rebind(j,k,q,e,E,s,S,p,P,h,l,f,t,T,m,M,R,b,o,n,a,A,c,i,g,z,+,-,<,>,0,1,2,3,4,5,6,7,8,9)+change-prompt($NN_UI_COMMAND_PROMPT)+execute-silent(rm -f $_nn_dir/.nn-s)" \
      --bind 'J:preview-page-down,K:preview-page-up' \
      --bind 'H:toggle-wrap' \
      --bind "enter:execute[test -f {1} && $_nn_editor {1}]"
    rm -rf "$_nn_dir"
    trap - EXIT
    shopt -u nullglob
    [[ "$NN_UI_FORTUNE" == "true" ]] && echo "So long, and thanks for all the notes."
    return
  fi

  # ---- NAMED QUERY ----
  if [[ $# -ge 1 && "$1" != *=* && "$1" != -* && -n "${saved_queries[$1]+x}" ]]; then
    local saved="$1"; shift
    shopt -u nullglob
    notenav_main ${saved_queries[$saved]} "$@"
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

  # Sanitize values for safe interpolation into awk expressions
  _awk_esc() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }
  local awk_cond="1"
  [[ -n "${filters[type]}" ]] && awk_cond="$awk_cond && \$1==\"$(_awk_esc "${filters[type]}")\""
  [[ -n "${filters[status]}" ]] && awk_cond="$awk_cond && \$2==\"$(_awk_esc "${filters[status]}")\""
  if [[ "${filters[priority]}" == "none" ]]; then
    awk_cond="$awk_cond && \$3==\"\""
  elif [[ -n "${filters[priority]}" ]]; then
    awk_cond="$awk_cond && \$3==\"$(_awk_esc "${filters[priority]}")\""
  fi
  [[ -n "${filters[tag]}" ]] && awk_cond="$awk_cond && index(\" \" \$4 \" \", \" $(_awk_esc "${filters[tag]}") \") > 0"

  if $interactive; then
    local nn_tmp=$(mktemp)
    local _nn_prev=$(mktemp)
    local _nn_sflag=$(mktemp -u)
    trap "rm -f '${nn_tmp}' '${_nn_prev}' '${_nn_sflag}'" EXIT
    cat > "$_nn_prev" << 'ENDPREVIEW'
#!/usr/bin/env bash
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
          --prompt "$NN_UI_COMMAND_PROMPT" \
          --bind "start:execute-silent(rm -f $_nn_sflag)" \
          --bind 'j:down,k:up,q:abort,change:clear-query' \
          --bind "/:unbind(j,k,q,change)+change-prompt($NN_UI_SEARCH_PROMPT)+execute-silent(touch $_nn_sflag)" \
          --bind "esc:transform[test -f $_nn_sflag && rm $_nn_sflag && printf 'rebind(j,k,q)+change-prompt($NN_UI_COMMAND_PROMPT)' || printf 'clear-query+rebind(change)']" \
          --bind "::rebind(j,k,q)+change-prompt($NN_UI_COMMAND_PROMPT)+execute-silent(rm -f $_nn_sflag)" \
          --bind 'J:preview-page-down,K:preview-page-up' \
          --bind 'H:toggle-wrap' \
          --bind "enter:execute($_nn_editor {1})"
    rm -f "$nn_tmp" "$_nn_prev" "$_nn_sflag"
    trap - EXIT
  else
    local _adhoc_fmt
    if [[ "$NN_PRIORITY_ENABLED" != "false" ]]; then
      _adhoc_fmt='{printf "[%s] [P%s] [%s] %s\n", $1, $3, $2, $5}'
    else
      _adhoc_fmt='{printf "[%s] [%s] %s\n", $1, $2, $5}'
    fi
    zk list "${zk_args[@]}" --format "$_fmt" --quiet 2>/dev/null \
      | awk -F'\t' "$awk_cond && length(\$1) > 0 $_adhoc_fmt"
  fi
  shopt -u nullglob
}
