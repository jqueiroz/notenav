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

  # Note: strtonum() and xor() require gawk
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
  # If no project workflow → use user default_workflow or "zenith"
  local workflow_name="" workflow_json="{}"
  if [[ "$_has_project_wf" == "true" ]]; then
    workflow_name=$(printf '%s' "$project_wf_json" | jq -r '.extends // empty' 2>/dev/null)
  fi
  if [[ -z "$workflow_name" && "$_has_project_wf" == "false" ]]; then
    workflow_name=$(printf '%s' "$user_json" | jq -r '.default_workflow // empty' 2>/dev/null)
    if [[ -z "$workflow_name" ]]; then
      workflow_name=$(printf '%s' "$base_json" | jq -r '.default_workflow // empty' 2>/dev/null)
    fi
    workflow_name="${workflow_name:-zenith}"
  fi

  # Step 4: Load base workflow and resolve extends chain
  if [[ -n "$workflow_name" ]]; then
    local workflow_file=""
    if [[ "$workflow_name" == https://* ]]; then
      local _cache_path
      _cache_path=$(_nn_url_cache_path "$workflow_name")
      if [[ ! -f "$_cache_path" ]]; then
        echo "notenav: remote workflow not cached: $workflow_name" >&2
        echo "notenav: run 'nn init $workflow_name' to fetch it" >&2
        return 1
      fi
      workflow_file="$_cache_path"
    elif [[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/notenav/workflows/$workflow_name.toml" ]]; then
      workflow_file="${XDG_CONFIG_HOME:-$HOME/.config}/notenav/workflows/$workflow_name.toml"
    elif [[ -f "$notenav_root/config/workflows/$workflow_name.toml" ]]; then
      workflow_file="$notenav_root/config/workflows/$workflow_name.toml"
    fi

    if [[ -z "$workflow_file" ]]; then
      echo "notenav: workflow '$workflow_name' not found, falling back to zenith" >&2
      workflow_file="$notenav_root/config/workflows/zenith.toml"
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
      local _base_file=""
      if [[ "$_extends" == https://* ]]; then
        _base_file=$(_nn_url_cache_path "$_extends")
        if [[ ! -f "$_base_file" ]]; then
          echo "notenav: remote workflow not cached: $_extends" >&2
          echo "notenav: run 'nn init $_extends' to fetch it" >&2
          return 1
        fi
      elif [[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/notenav/workflows/$_extends.toml" ]]; then
        _base_file="${XDG_CONFIG_HOME:-$HOME/.config}/notenav/workflows/$_extends.toml"
      else
        _base_file="$notenav_root/config/workflows/$_extends.toml"
      fi
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

  # Deep merge: base * workflow * user * project_queries
  # Later values win. Project queries applied last so they override user/workflow queries.
  NN_CFG_JSON=$(printf '%s\n%s\n%s\n%s' "$base_json" "$workflow_json" "$user_json" "$project_queries" \
    | jq -s '.[0] * .[1] * .[2] * .[3] | del(.queries.inherit)' 2>/dev/null)

  if [[ -z "$NN_CFG_JSON" || "$NN_CFG_JSON" == "null" ]]; then
    echo "notenav: config merge failed" >&2
    return 1
  fi

  export NN_CFG_JSON
}

# Query the merged config. Usage: nn_cfg '.type | keys[]'
nn_cfg() {
  printf '%s' "$NN_CFG_JSON" | jq -r "$1"
}

# --- Pre-compute workflow values ---
# Extracts all workflow/config values into bash variables at startup.
# Called once after nn_load_config(). Helper scripts read from temp files
# written by nn_write_workflow_files().

# Escape a string for safe interpolation into an AWK double-quoted literal.
# Handles backslash and double-quote (the two characters that break AWK strings).
_nn_awk_esc() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }

_nn_gen_awk_bodies() {
  local _v _i _esc
  # Uses NN_TYPE_DISPLAY_ORDER / NN_STATUS_DISPLAY_ORDER (set by nn_precompute_workflow)
  # for group ordering and stats display. Falls back to NN_*_VALUES if unset.

  # Type color+icon assignments
  local _typ_awk="" _first=true
  for _v in "${NN_TYPE_VALUES[@]}"; do
    _esc=$(_nn_awk_esc "${NN_TYPE_ICONS[$_v]}")
    if $_first; then
      _typ_awk="tc = \"\\033[${NN_TYPE_COLORS[$_v]}m\"; ic = \"${_esc}\""
      _first=false
    else
      _typ_awk+=$'\n'"  if (\$1 == \"$_v\") { tc = \"\\033[${NN_TYPE_COLORS[$_v]}m\"; ic = \"${_esc}\" }"
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
      _esc=$(_nn_awk_esc "${NN_PRIORITY_LABELS[$_v]}")
      _pri_awk+=$'\n'"  if (\$3 == \"$_v\") pl = \"${_esc}\""
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
  local _simple="$_typ_awk"
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
  local _full="$_typ_awk"
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

  # Pinned items AWK body (bold line + yellow-highlighted marker)
  local _pinned="$_typ_awk"
  [[ -n "$_pri_awk" ]] && _pinned+=$'\n'"  $_pri_awk"
  _pinned+=$'\n'"  $_sta_awk"
  _pinned+=$'\n''  r = "\033[0m\033[1m"'
  _pinned+=$'\n'"  $_age_awk"
  if [[ "$NN_PRIORITY_ENABLED" != "false" ]]; then
    _pinned+=$'\n''  printf "%s\t\033[1m%s%s %s%s %s%s%s %s%s%s %s%s \033[0m\033[30;43m temporarily pinned \033[0m\033[90m (after the next change, will drop from this view)\033[0m\n", $6, tc, ic, $1, r, pc, pl, r, sc, $2, r, $5, age_s'
  else
    _pinned+=$'\n''  printf "%s\t\033[1m%s%s %s%s %s%s%s %s%s \033[0m\033[30;43m temporarily pinned \033[0m\033[90m (after the next change, will drop from this view)\033[0m\n", $6, tc, ic, $1, r, sc, $2, r, $5, age_s'
  fi
  NN_AWK_COLOR_PINNED="$_pinned"

  # Stats AWK body
  local _type_order_str="${NN_TYPE_DISPLAY_ORDER[*]:-${NN_TYPE_VALUES[*]}}"
  local _status_fc_str="${NN_STATUS_FILTER_CYCLE[*]}"
  local _stats_type_lookup="" _stats_status_lookup=""
  for _v in "${NN_TYPE_VALUES[@]}"; do
    _esc=$(_nn_awk_esc "${NN_TYPE_ICONS[$_v]}")
    _stats_type_lookup+="icon[\"$_v\"] = \"${_esc}\"; clr[\"$_v\"] = \"\\033[${NN_TYPE_COLORS[$_v]}m\"; "
  done
  for _v in "${NN_STATUS_FILTER_CYCLE[@]}"; do
    _stats_status_lookup+="sc[\"$_v\"] = \"\\033[${NN_STATUS_COLORS[$_v]}m\"; "
  done
  NN_AWK_COLOR_STATS='{ types[$1]++; combos[$1, $2]++ } END {
  n = split("'"$_type_order_str"'", order, " ")
  '"$_stats_type_lookup"'
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
  NN_TYPE_ORDER_STR="$_type_order_str"
  NN_STATUS_ORDER_STR="${NN_STATUS_DISPLAY_ORDER[*]:-${NN_STATUS_VALUES[*]}}"

  # Type icon AWK snippet for grouping
  NN_AWK_ICON_SETUP=""
  for _v in "${NN_TYPE_VALUES[@]}"; do
    _esc=$(_nn_awk_esc "${NN_TYPE_ICONS[$_v]}")
    NN_AWK_ICON_SETUP+="icon[\"$_v\"] = \"${_esc}\"; "
  done
}

nn_precompute_workflow() {
  local _v
  # Note types
  mapfile -t NN_TYPE_VALUES < <(nn_cfg '.type.values[]')
  if [[ ${#NN_TYPE_VALUES[@]} -eq 0 ]]; then
    echo "notenav: no type values in config (is yq-go installed?)" >&2
    return 1
  fi
  NN_TYPE_DEFAULT_COLOR=$(nn_cfg '.type.default_color // "36"')
  declare -gA NN_TYPE_ICONS NN_TYPE_COLORS NN_TYPE_DESCS
  for _v in "${NN_TYPE_VALUES[@]}"; do
    NN_TYPE_ICONS[$_v]=$(nn_cfg ".type.\"$_v\".icon // \"*\"")
    NN_TYPE_COLORS[$_v]=$(nn_cfg ".type.\"$_v\".color // \"$NN_TYPE_DEFAULT_COLOR\"")
    NN_TYPE_DESCS[$_v]=$(nn_cfg ".type.\"$_v\".description // \"\"")
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
  mapfile -t NN_TYPE_DISPLAY_ORDER < <(nn_cfg '.type.display_order // [] | .[]')
  [[ ${#NN_TYPE_DISPLAY_ORDER[@]} -eq 0 ]] && NN_TYPE_DISPLAY_ORDER=("${NN_TYPE_VALUES[@]}")
  mapfile -t NN_STATUS_DISPLAY_ORDER < <(nn_cfg '.status.display_order // [] | .[]')
  [[ ${#NN_STATUS_DISPLAY_ORDER[@]} -eq 0 ]] && NN_STATUS_DISPLAY_ORDER=("${NN_STATUS_VALUES[@]}")

  # Defaults
  NN_DEFAULT_SORT=$(nn_cfg '.defaults.sort_by // "created"')
  NN_DEFAULT_SORT_REV=$(nn_cfg '.defaults.sort_reverse // false')
  NN_DEFAULT_GROUP=$(nn_cfg '.defaults.group_by // ""')
  NN_DEFAULT_ARCHIVE=$(nn_cfg '.defaults.show_archive // false')
  NN_DEFAULT_WRAP=$(nn_cfg '.defaults.wrap_preview // false')

  # UI preferences
  NN_UI_EDITOR=$(nn_cfg '.ui.editor // empty')
  NN_UI_COMMAND_PROMPT=$(nn_cfg '.ui.command_prompt // ": "')
  NN_UI_SEARCH_PROMPT=$(nn_cfg '.ui.search_prompt // "/ "')
  # Sanitize prompts: strip chars that break fzf action syntax in change-prompt()
  NN_UI_COMMAND_PROMPT="${NN_UI_COMMAND_PROMPT//)/}"
  NN_UI_SEARCH_PROMPT="${NN_UI_SEARCH_PROMPT//)/}"
  NN_UI_EXIT_MESSAGE=$(nn_cfg '.ui.exit_message // "none"')
  NN_UI_PRIORITY_PLUS=$(nn_cfg '.ui.priority_plus // "demote"')
  NN_UI_AFTER_CREATE=$(nn_cfg '.ui.after_create // "edit"')

  # ZK format (hardcoded – the entire pipeline assumes this exact column layout)
  NN_ZK_FMT='{{metadata.type}}\t{{metadata.status}}\t{{metadata.priority}}\t{{tags}}\t{{title}}\t{{absPath}}\t{{modified}}\t{{created}}'

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
  printf '%s\n' "${NN_TYPE_VALUES[@]}" > "$dir/.schema_type_values"
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

  # Type details (TSV: value\ticon\tcolor\tdescription)
  local _v
  for _v in "${NN_TYPE_VALUES[@]}"; do
    printf '%s\t%s\t%s\t%s\n' "$_v" "${NN_TYPE_ICONS[$_v]}" "${NN_TYPE_COLORS[$_v]}" "${NN_TYPE_DESCS[$_v]}"
  done > "$dir/.schema_types"

  # Type icon map (TSV: value\ticon)
  for _v in "${NN_TYPE_VALUES[@]}"; do
    printf '%s\t%s\n' "$_v" "${NN_TYPE_ICONS[$_v]}"
  done > "$dir/.schema_type_icons"

  # Status lifecycle (TSV: from\tto)
  for _v in "${NN_STATUS_VALUES[@]}"; do
    [[ -n "${NN_STATUS_FWD[$_v]+x}" ]] && printf '%s\t%s\n' "$_v" "${NN_STATUS_FWD[$_v]}"
  done > "$dir/.schema_status_fwd"
  for _v in "${NN_STATUS_VALUES[@]}"; do
    [[ -n "${NN_STATUS_REV[$_v]+x}" ]] && printf '%s\t%s\n' "$_v" "${NN_STATUS_REV[$_v]}"
  done > "$dir/.schema_status_rev"

  # Priority lifecycle (TSV: from\tto)
  if [[ "$NN_PRIORITY_ENABLED" != "false" ]]; then
    for _v in "${NN_PRIORITY_VALUES[@]}"; do
      [[ -n "${NN_PRIORITY_UP[$_v]+x}" ]] && printf '%s\t%s\n' "$_v" "${NN_PRIORITY_UP[$_v]}"
    done > "$dir/.schema_priority_up"
    for _v in "${NN_PRIORITY_VALUES[@]}"; do
      [[ -n "${NN_PRIORITY_DOWN[$_v]+x}" ]] && printf '%s\t%s\n' "$_v" "${NN_PRIORITY_DOWN[$_v]}"
    done > "$dir/.schema_priority_down"
  else
    : > "$dir/.schema_priority_up"
    : > "$dir/.schema_priority_down"
  fi

  printf '%s' "$NN_PRIORITY_UNSET_POS" > "$dir/.schema_priority_unset_pos"

  # Priority labels (TSV: value\tlabel)
  for _v in "${NN_PRIORITY_VALUES[@]}"; do
    printf '%s\t%s\n' "$_v" "${NN_PRIORITY_LABELS[$_v]}"
  done > "$dir/.schema_priority_labels"

  # Defaults (one per line: sort_by, group_by, show_archive, sort_reverse, wrap_preview)
  printf '%s\n%s\n%s\n%s\n%s\n' "$NN_DEFAULT_SORT" "$NN_DEFAULT_GROUP" "$NN_DEFAULT_ARCHIVE" "$NN_DEFAULT_SORT_REV" "$NN_DEFAULT_WRAP" > "$dir/.schema_defaults"

  # AWK bodies
  printf '%s' "$NN_AWK_COLOR_BODY" > "$dir/.awk_color_body"
  printf '%s' "$NN_AWK_COLOR_PINNED" > "$dir/.awk_color_pinned"
  printf '%s' "$NN_AWK_COLOR_STATS" > "$dir/.awk_color_stats"

  # Archive AWK condition
  printf '%s' "$NN_ARCHIVE_COND" > "$dir/.schema_archive_cond"

  # Type and status order strings (space-separated, for AWK split)
  printf '%s' "$NN_TYPE_ORDER_STR" > "$dir/.schema_type_order"
  printf '%s' "$NN_STATUS_ORDER_STR" > "$dir/.schema_status_order"

  # AWK icon setup for grouping
  printf '%s' "$NN_AWK_ICON_SETUP" > "$dir/.schema_icon_setup"

  # UI preferences
  printf '%s' "$(_nn_resolve_editor "$NN_UI_EDITOR")" > "$dir/.schema_editor"
  printf '%s' "$NN_UI_AFTER_CREATE" > "$dir/.schema_after_create"

  # Archive label (slash-separated status names for header display)
  local _archive_label=""
  for _v in "${NN_STATUS_ARCHIVE[@]}"; do
    [[ -n "$_archive_label" ]] && _archive_label+="/"
    _archive_label+="$_v"
  done
  printf '%s' "$_archive_label" > "$dir/.schema_archive_label"
}

# --- Doctor ---
# Diagnostic command: checks dependencies, config, workflow integrity, and zk notebook.

# Version comparison: returns 0 if $1 >= $2 (dot-separated numeric)
_nn_ver_cmp() {
  [[ -z "$1" || -z "$2" ]] && return 1
  local -a a b
  IFS=. read -ra a <<< "$1"
  IFS=. read -ra b <<< "$2"
  local i
  for ((i=0; i<${#b[@]}; i++)); do
    local av="${a[i]:-0}" bv="${b[i]:-0}"
    [[ "$av" =~ ^[0-9]+$ ]] || av=0
    [[ "$bv" =~ ^[0-9]+$ ]] || bv=0
    (( av > bv )) && return 0
    (( av < bv )) && return 1
  done
  return 0
}

nn_doctor() {
  local notenav_root="$1"
  local fails=0 warns=0

  # Output helpers (respect $NO_COLOR)
  local _green="" _yellow="" _red="" _dim="" _reset=""
  if [[ -z "${NO_COLOR:-}" ]]; then
    _green=$'\033[32m' _yellow=$'\033[33m' _red=$'\033[31m'
    _dim=$'\033[90m' _reset=$'\033[0m'
  fi
  _pass() { echo "${_green}[✓]${_reset} $*"; }
  _warn() { echo "${_yellow}[!]${_reset} $*"; (( warns++ )) || true; }
  _fail() { echo "${_red}[✗]${_reset} $*"; (( fails++ )) || true; }
  _valid_color() { [[ -z "$1" || "$1" =~ ^[0-9]+(;[0-9]+)*$ ]]; }
  _in_array() { local v="$1"; shift; local e; for e; do [[ "$v" == "$e" ]] && return 0; done; return 1; }
  _dupes() { local -A _seen; local _d="" _v; for _v; do [[ -n "${_seen[$_v]+x}" ]] && _d+="$_v, "; _seen[$_v]=1; done; printf '%s' "${_d%, }"; }

  # ── Phase 1: Dependencies ──
  echo "Dependencies:"

  # bash
  local bash_ver="${BASH_VERSINFO[0]}.${BASH_VERSINFO[1]}"
  if _nn_ver_cmp "$bash_ver" "4.0"; then
    _pass "bash $bash_ver"
  else
    _fail "bash $bash_ver (requires 4+)"
  fi

  # fzf
  if command -v fzf >/dev/null 2>&1; then
    local fzf_ver
    fzf_ver=$(fzf --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1)
    if [[ -n "$fzf_ver" ]] && _nn_ver_cmp "$fzf_ver" "0.44"; then
      _pass "fzf $fzf_ver"
    else
      _fail "fzf ${fzf_ver:-unknown} (requires 0.44+)"
    fi
  else
    _fail "fzf not found"
  fi

  # zk
  local _has_zk=false
  if command -v zk >/dev/null 2>&1; then
    local zk_ver
    zk_ver=$(zk --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1)
    _pass "zk ${zk_ver:-installed}"
    _has_zk=true
  else
    _fail "zk not found"
  fi

  # yq
  local _has_yq=false
  if command -v yq >/dev/null 2>&1; then
    local yq_ver
    yq_ver=$(yq --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1)
    # Check if it's yq-go (not yq-python)
    if yq -p=toml -o=json '.' /dev/null >/dev/null 2>&1 || yq --version 2>&1 | grep -qi 'mikefarah\|https://github.com/mikefarah'; then
      _pass "yq ${yq_ver:-installed} (yq-go)"
      _has_yq=true
    else
      _fail "yq ${yq_ver:-installed} appears to be yq-python, not yq-go"
    fi
  else
    _fail "yq not found"
  fi

  # jq
  local _has_jq=false
  if command -v jq >/dev/null 2>&1; then
    local jq_ver
    jq_ver=$(jq --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1)
    _pass "jq ${jq_ver:-installed}"
    _has_jq=true
  else
    _fail "jq not found"
  fi

  # awk (gawk required – notenav uses mktime() and strtonum())
  if command -v awk >/dev/null 2>&1; then
    local awk_variant
    awk_variant=$(awk --version 2>/dev/null | head -1 || true)
    if [[ "$awk_variant" == *GNU* || "$awk_variant" == *gawk* ]]; then
      _pass "awk (gawk)"
    else
      local awk_name
      awk_name=$(awk -W version 2>&1 | head -1 || true)
      if [[ "$awk_name" == *mawk* ]]; then
        _fail "awk: gawk required (found mawk – install gawk)"
      else
        _fail "awk: gawk required (install gawk)"
      fi
    fi
  else
    _fail "awk not found"
  fi

  # sort, sed
  local _tool
  for _tool in sort sed; do
    if command -v "$_tool" >/dev/null 2>&1; then
      _pass "$_tool"
    else
      _fail "$_tool not found"
    fi
  done

  # bat (optional)
  if command -v bat >/dev/null 2>&1; then
    local bat_ver
    bat_ver=$(bat --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1)
    _pass "bat ${bat_ver:-installed}"
  elif command -v batcat >/dev/null 2>&1; then
    local batcat_ver
    batcat_ver=$(batcat --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1)
    _pass "bat ${batcat_ver:-installed} (as batcat)"
  else
    _warn "bat not found (optional – enables syntax-highlighted preview)"
  fi

  # ── Phase 2: Config validation ──

  if [[ "$_has_yq" == "true" && "$_has_jq" == "true" ]]; then
    echo ""
    echo "Config:"

    local user_cfg="${XDG_CONFIG_HOME:-$HOME/.config}/notenav/config.toml"
    local project_nn_dir="" _search_dir="$PWD"
    while true; do
      if [[ -d "$_search_dir/.nn" ]]; then
        project_nn_dir="$_search_dir/.nn"
        break
      fi
      [[ "$_search_dir" == "/" ]] && break
      _search_dir="$(dirname "$_search_dir")"
    done
    local project_wf_file="${project_nn_dir:+$project_nn_dir/workflow.toml}"

    # User config
    if [[ -f "$user_cfg" ]]; then
      if yq -p=toml -o=json '.' "$user_cfg" >/dev/null 2>&1; then
        _pass "User config: $user_cfg"
      else
        _fail "User config: $user_cfg (parse error)"
      fi
    else
      _pass "User config: not present ${_dim}(using defaults)${_reset}"
    fi

    # Project config
    local _extends_name=""
    if [[ -n "$project_wf_file" && -f "$project_wf_file" ]]; then
      local _proj_json
      if _proj_json=$(yq -p=toml -o=json -I=0 '.' "$project_wf_file" 2>/dev/null); then
        _extends_name=$(printf '%s' "$_proj_json" | jq -r '.extends // empty' 2>/dev/null)
        if [[ -n "$_extends_name" ]]; then
          _pass "Project config: .nn/workflow.toml ${_dim}(extends $_extends_name)${_reset}"
        else
          _pass "Project config: .nn/workflow.toml"
        fi
      else
        _fail "Project config: .nn/workflow.toml (parse error)"
      fi
    else
      _pass "Project config: not present ${_dim}(using default workflow)${_reset}"
    fi

    # Resolve extends reference
    if [[ -n "$_extends_name" ]]; then
      local _wf_found=false
      if [[ "$_extends_name" == https://* ]]; then
        local _ext_cache
        _ext_cache=$(_nn_url_cache_path "$_extends_name")
        if [[ -f "$_ext_cache" ]]; then
          _wf_found=true
        fi
      elif [[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/notenav/workflows/$_extends_name.toml" ]]; then
        _wf_found=true
      elif [[ -f "$notenav_root/config/workflows/$_extends_name.toml" ]]; then
        _wf_found=true
      fi
      if [[ "$_wf_found" == "false" ]]; then
        if [[ "$_extends_name" == https://* ]]; then
          _fail "extends remote workflow – not cached (run 'nn init $_extends_name')"
        else
          _fail "extends '$_extends_name' – workflow not found"
        fi
      fi
    fi

    # Check default_workflow resolves (from user config)
    if [[ -f "$user_cfg" ]]; then
      local _dw
      _dw=$(yq -p=toml -o=json -I=0 '.' "$user_cfg" 2>/dev/null | jq -r '.default_workflow // empty' 2>/dev/null)
      if [[ -n "$_dw" ]]; then
        local _dw_found=false
        if [[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/notenav/workflows/$_dw.toml" ]]; then
          _dw_found=true
        elif [[ -f "$notenav_root/config/workflows/$_dw.toml" ]]; then
          _dw_found=true
        fi
        if [[ "$_dw_found" == "false" ]]; then
          _warn "default_workflow '$_dw' – workflow not found"
        fi
      fi
    fi

    # Unrecognized top-level keys
    local _known_keys="meta type status priority queries defaults ui extends default_workflow"
    local _check_files=()
    [[ -f "$user_cfg" ]] && _check_files+=("$user_cfg")
    [[ -n "$project_wf_file" && -f "$project_wf_file" ]] && _check_files+=("$project_wf_file")
    local _cfg_file
    for _cfg_file in "${_check_files[@]}"; do
      local _unknown=""
      while IFS= read -r _key; do
        [[ -z "$_key" ]] && continue
        if ! _in_array "$_key" $_known_keys; then
          [[ -n "$_unknown" ]] && _unknown+=", "
          _unknown+="$_key"
        fi
      done < <(yq -p=toml -o=json '.' "$_cfg_file" 2>/dev/null | jq -r 'keys[]' 2>/dev/null)
      if [[ -n "$_unknown" ]]; then
        local _short="${_cfg_file##*/}"
        _warn "Unrecognized keys in $_short: $_unknown"
      fi
    done

    # Full config merge check
    # Run in current shell (not command substitution) so NN_CFG_JSON survives
    unset NN_CFG_JSON
    local _merge_tmpf
    _merge_tmpf=$(mktemp "${TMPDIR:-/tmp}/nn-doctor-merge.XXXXXX")
    if nn_load_config "$notenav_root" 2>"$_merge_tmpf"; then
      _pass "Config merge OK"
    else
      _fail "Config merge failed: $(< "$_merge_tmpf")"
    fi
    rm -f "$_merge_tmpf"
  fi

  # ── Phase 3: Trusted sources ──

  local _ts_file="${XDG_CONFIG_HOME:-$HOME/.config}/notenav/trusted-sources"
  if [[ -f "$_ts_file" ]]; then
    echo ""
    echo "Trusted sources:"
    local _ts_count=0 _ts_url
    while IFS= read -r _ts_url || [[ -n "$_ts_url" ]]; do
      [[ -z "$_ts_url" || "$_ts_url" == \#* ]] && continue
      (( _ts_count++ ))
      local _cache_path
      _cache_path=$(_nn_url_cache_path "$_ts_url")
      if [[ -f "$_cache_path" ]]; then
        # GNU stat (Linux) first, then BSD date -r (macOS) as fallback
        local _fetch_date
        _fetch_date=$(stat -c '%y' "$_cache_path" 2>/dev/null | cut -d' ' -f1)
        [[ -z "$_fetch_date" ]] && _fetch_date=$(date -r "$_cache_path" '+%Y-%m-%d' 2>/dev/null)
        _pass "$_ts_url ${_dim}(cached${_fetch_date:+ $_fetch_date})${_reset}"
      else
        _warn "$_ts_url ${_dim}(not cached)${_reset}"
      fi
    done < "$_ts_file"
    if [[ $_ts_count -eq 0 ]]; then
      _pass "Trusted sources: none configured"
    fi
  fi

  # ── Phase 4: Workflow integrity ──
  # NOTE: This phase hardcodes known config keys, valid enum values, and filter
  # keys. When adding/removing properties, update the corresponding lists here.
  # See GUIDELINES.md § Config system.

  if [[ -n "${NN_CFG_JSON:-}" ]]; then
    echo ""
    echo "Workflow:"

    # Type checks
    local _typ_values _typ_ok=true _typ_count=0 _typ_issues=""
    mapfile -t _typ_values < <(nn_cfg '.type.values // [] | .[]')
    _typ_count=${#_typ_values[@]}
    if _in_array "" "${_typ_values[@]}"; then
      _warn "type.values contains an empty string"
    fi
    local _typ_dups
    _typ_dups=$(_dupes "${_typ_values[@]}")
    [[ -n "$_typ_dups" ]] && _warn "type.values has duplicates: $_typ_dups"
    local _typ_default_color
    _typ_default_color=$(nn_cfg '.type.default_color // empty')
    local _ev
    for _ev in "${_typ_values[@]}"; do
      local _icon _color
      _icon=$(nn_cfg ".type.\"$_ev\".icon // empty")
      _color=$(nn_cfg ".type.\"$_ev\".color // empty")
      if [[ -z "$_icon" ]]; then
        _typ_issues+="$_ev missing icon; "
        _typ_ok=false
      fi
      if [[ -z "$_color" && -z "$_typ_default_color" ]]; then
        _typ_issues+="$_ev missing color; "
        _typ_ok=false
      fi
    done
    if [[ "$_typ_ok" == "true" && $_typ_count -gt 0 ]]; then
      local _typ_names
      printf -v _typ_names '%s, ' "${_typ_values[@]}"
      _typ_names="${_typ_names%, }"
      _pass "Types: $_typ_names – all have icon + color"
    elif [[ $_typ_count -eq 0 ]]; then
      _fail "Types: none defined"
    else
      _fail "Types: ${_typ_issues%"; "}"
    fi
    # Warn on invalid color formats
    if [[ -n "$_typ_default_color" ]] && ! _valid_color "$_typ_default_color"; then
      _warn "type.default_color '$_typ_default_color' is not a valid ANSI code"
    fi
    for _ev in "${_typ_values[@]}"; do
      local _color
      _color=$(nn_cfg ".type.\"$_ev\".color // empty")
      if [[ -n "$_color" ]] && ! _valid_color "$_color"; then
        _warn "type.$_ev.color '$_color' is not a valid ANSI code"
      fi
    done
    # Validate type display_order
    local _typ_do_values
    mapfile -t _typ_do_values < <(nn_cfg '.type.display_order // [] | .[]')
    local _edo_dups
    _edo_dups=$(_dupes "${_typ_do_values[@]}")
    [[ -n "$_edo_dups" ]] && _warn "type.display_order has duplicates: $_edo_dups"
    local _edov
    for _edov in "${_typ_do_values[@]}"; do
      if ! _in_array "$_edov" "${_typ_values[@]}"; then
        _warn "type.display_order '$_edov' not in type.values"
      fi
    done
    # Validate type sub-table keys
    local _typ_known_subkeys="icon color description"
    for _ev in "${_typ_values[@]}"; do
      local _esk
      while IFS= read -r _esk; do
        [[ -z "$_esk" ]] && continue
        if ! _in_array "$_esk" $_typ_known_subkeys; then
          _warn "type.$_ev: unrecognized key '$_esk'"
        fi
      done < <(nn_cfg ".type.\"$_ev\" // {} | keys[]" 2>/dev/null)
    done
    # Warn on type-level keys that aren't in values or known top-level keys
    local _typ_known_toplevel="values default_color display_order"
    local _ek
    while IFS= read -r _ek; do
      [[ -z "$_ek" ]] && continue
      if ! _in_array "$_ek" $_typ_known_toplevel && ! _in_array "$_ek" "${_typ_values[@]}"; then
        _warn "type.$_ek is not in type.values (typo?)"
      fi
    done < <(nn_cfg '.type // {} | keys[]' 2>/dev/null)

    # Meta sub-key validation
    local _known_meta_keys="name description"
    local _mmk
    while IFS= read -r _mmk; do
      [[ -z "$_mmk" ]] && continue
      if ! _in_array "$_mmk" $_known_meta_keys; then
        _warn "meta: unrecognized key '$_mmk'"
      fi
    done < <(nn_cfg '.meta // {} | keys[]' 2>/dev/null)

    # Status checks
    local _sta_values _sta_ok=true _sta_count=0
    mapfile -t _sta_values < <(nn_cfg '.status.values // [] | .[]')
    _sta_count=${#_sta_values[@]}
    if _in_array "" "${_sta_values[@]}"; then
      _warn "status.values contains an empty string"
    fi
    local _sta_dups
    _sta_dups=$(_dupes "${_sta_values[@]}")
    [[ -n "$_sta_dups" ]] && _warn "status.values has duplicates: $_sta_dups"

    # Check each status has a color (explicit or via default_color)
    local _sta_color_issues="" _sta_default_color
    _sta_default_color=$(nn_cfg '.status.default_color // empty')
    local _stv
    for _stv in "${_sta_values[@]}"; do
      local _scolor
      _scolor=$(nn_cfg ".status.colors.\"$_stv\" // empty")
      if [[ -z "$_scolor" && -z "$_sta_default_color" ]]; then
        _sta_color_issues+="$_stv missing color; "
        _sta_ok=false
      fi
    done

    # Check initial status exists in values
    local _sta_init_issues="" _sta_initial
    _sta_initial=$(nn_cfg '.status.initial // empty')
    if [[ -n "$_sta_initial" ]] && ! _in_array "$_sta_initial" "${_sta_values[@]}"; then
      _sta_init_issues+="initial '$_sta_initial' not in values; "
      _sta_ok=false
    fi

    # Check filter_cycle values exist in values
    local _fc_values _fc_issues="" _fcv
    mapfile -t _fc_values < <(nn_cfg '.status.filter_cycle // [] | .[]')
    if [[ ${#_fc_values[@]} -eq 0 && $_sta_count -gt 0 ]]; then
      _fc_issues+="filter_cycle is empty; "
      _sta_ok=false
    fi
    for _fcv in "${_fc_values[@]}"; do
      if ! _in_array "$_fcv" "${_sta_values[@]}"; then
        _fc_issues+="filter_cycle '$_fcv' not in values; "
        _sta_ok=false
      fi
    done
    local _fc_dups
    _fc_dups=$(_dupes "${_fc_values[@]}")
    [[ -n "$_fc_dups" ]] && _warn "status.filter_cycle has duplicates: $_fc_dups"

    # Check archive values exist in values
    local _arc_values _arc_issues="" _arcv
    mapfile -t _arc_values < <(nn_cfg '.status.archive // [] | .[]')
    local _arc_dups
    _arc_dups=$(_dupes "${_arc_values[@]}")
    [[ -n "$_arc_dups" ]] && _warn "status.archive has duplicates: $_arc_dups"
    for _arcv in "${_arc_values[@]}"; do
      if ! _in_array "$_arcv" "${_sta_values[@]}"; then
        _arc_issues+="archive '$_arcv' not in values; "
        _sta_ok=false
      fi
    done

    # Check initial is not in archive
    if [[ -n "$_sta_initial" ]] && _in_array "$_sta_initial" "${_arc_values[@]}"; then
      _warn "status.initial '$_sta_initial' is in status.archive (new notes would be hidden)"
    fi

    # Check lifecycle transitions reference valid values (both source keys and targets)
    local _lc_issues="" _lcv _lc_target _lc_dir
    for _lc_dir in forward reverse; do
      while IFS=$'\t' read -r _lcv _lc_target; do
        [[ -z "$_lcv" ]] && continue
        if ! _in_array "$_lcv" "${_sta_values[@]}"; then
          _lc_issues+="$_lc_dir key '$_lcv' not in values; "
          _sta_ok=false
        fi
        if [[ -n "$_lc_target" ]] && ! _in_array "$_lc_target" "${_sta_values[@]}"; then
          _lc_issues+="$_lc_dir '$_lcv' → '$_lc_target' invalid; "
          _sta_ok=false
        fi
      done < <(nn_cfg ".status.lifecycle.$_lc_dir // {} | to_entries[] | \"\(.key)\t\(.value)\"" 2>/dev/null)
    done
    # Validate status.lifecycle sub-keys
    local _known_lc_keys="forward reverse"
    local _slck
    while IFS= read -r _slck; do
      [[ -z "$_slck" ]] && continue
      if ! _in_array "$_slck" $_known_lc_keys; then
        _warn "status.lifecycle: unrecognized key '$_slck'"
      fi
    done < <(nn_cfg '.status.lifecycle // {} | keys[]' 2>/dev/null)

    if [[ "$_sta_ok" == "true" && $_sta_count -gt 0 ]]; then
      _pass "Statuses: $_sta_count values, lifecycle valid"
    elif [[ $_sta_count -eq 0 ]]; then
      _fail "Statuses: none defined"
    else
      local _sta_all_issues="${_sta_color_issues}${_sta_init_issues}${_fc_issues}${_arc_issues}${_lc_issues}"
      _fail "Statuses: ${_sta_all_issues%"; "}"
    fi
    # Warn on invalid color formats
    if [[ -n "$_sta_default_color" ]] && ! _valid_color "$_sta_default_color"; then
      _warn "status.default_color '$_sta_default_color' is not a valid ANSI code"
    fi
    for _stv in "${_sta_values[@]}"; do
      local _scolor
      _scolor=$(nn_cfg ".status.colors.\"$_stv\" // empty")
      if [[ -n "$_scolor" ]] && ! _valid_color "$_scolor"; then
        _warn "status.colors.$_stv '$_scolor' is not a valid ANSI code"
      fi
    done
    # Validate status.colors keys reference valid values
    local _sck
    while IFS= read -r _sck; do
      [[ -z "$_sck" ]] && continue
      if ! _in_array "$_sck" "${_sta_values[@]}"; then
        _warn "status.colors.$_sck not in status.values"
      fi
    done < <(nn_cfg '.status.colors // {} | keys[]' 2>/dev/null)
    # Validate status display_order
    local _sta_do_values
    mapfile -t _sta_do_values < <(nn_cfg '.status.display_order // [] | .[]')
    local _sdo_dups
    _sdo_dups=$(_dupes "${_sta_do_values[@]}")
    [[ -n "$_sdo_dups" ]] && _warn "status.display_order has duplicates: $_sdo_dups"
    local _sdov
    for _sdov in "${_sta_do_values[@]}"; do
      if ! _in_array "$_sdov" "${_sta_values[@]}"; then
        _warn "status.display_order '$_sdov' not in status.values"
      fi
    done
    # Validate status sub-keys
    local _known_status_keys="values initial archive filter_cycle default_color colors lifecycle display_order"
    local _stk
    while IFS= read -r _stk; do
      [[ -z "$_stk" ]] && continue
      if ! _in_array "$_stk" $_known_status_keys; then
        _warn "status: unrecognized key '$_stk'"
      fi
    done < <(nn_cfg '.status // {} | keys[]' 2>/dev/null)

    # Priority checks
    local _pri_enabled
    _pri_enabled=$(nn_cfg '.priority.enabled // true')
    if [[ "$_pri_enabled" != "true" && "$_pri_enabled" != "false" ]]; then
      _warn "priority.enabled '$_pri_enabled' invalid (must be true or false)"
    fi
    if [[ "$_pri_enabled" != "false" ]]; then
      local _pri_values _pri_ok=true _pri_count=0
      mapfile -t _pri_values < <(nn_cfg '.priority.values // [] | .[]')
      _pri_count=${#_pri_values[@]}
      if _in_array "" "${_pri_values[@]}"; then
        _warn "priority.values contains an empty string"
      fi
      local _pri_dups
      _pri_dups=$(_dupes "${_pri_values[@]}")
      [[ -n "$_pri_dups" ]] && _warn "priority.values has duplicates: $_pri_dups"

      # Check each priority has a color (explicit or via default_color)
      local _pri_color_issues="" _pri_default_color
      _pri_default_color=$(nn_cfg '.priority.default_color // empty')
      local _pcv
      for _pcv in "${_pri_values[@]}"; do
        local _pcolor
        _pcolor=$(nn_cfg ".priority.colors.\"$_pcv\" // empty")
        if [[ -z "$_pcolor" && -z "$_pri_default_color" ]]; then
          _pri_color_issues+="$_pcv missing color; "
          _pri_ok=false
        fi
      done

      local _pri_fc_values _pri_fc_issues="" _pfcv
      mapfile -t _pri_fc_values < <(nn_cfg '.priority.filter_cycle // [] | .[]')
      if [[ ${#_pri_fc_values[@]} -eq 0 && $_pri_count -gt 0 ]]; then
        _pri_fc_issues+="filter_cycle is empty; "
        _pri_ok=false
      fi
      for _pfcv in "${_pri_fc_values[@]}"; do
        if ! _in_array "$_pfcv" "${_pri_values[@]}"; then
          _pri_fc_issues+="filter_cycle '$_pfcv' not in values; "
          _pri_ok=false
        fi
      done
      local _pfc_dups
      _pfc_dups=$(_dupes "${_pri_fc_values[@]}")
      [[ -n "$_pfc_dups" ]] && _warn "priority.filter_cycle has duplicates: $_pfc_dups"

      # Priority lifecycle
      local _pri_lc_issues="" _plcv _plc_target _plc_dir
      for _plc_dir in up down; do
        while IFS=$'\t' read -r _plcv _plc_target; do
          [[ -z "$_plcv" ]] && continue
          if ! _in_array "$_plcv" "${_pri_values[@]}"; then
            _pri_lc_issues+="$_plc_dir key '$_plcv' not in values; "
            _pri_ok=false
          fi
          if [[ -n "$_plc_target" ]] && ! _in_array "$_plc_target" "${_pri_values[@]}"; then
            _pri_lc_issues+="$_plc_dir '$_plcv' → '$_plc_target' invalid; "
            _pri_ok=false
          fi
        done < <(nn_cfg ".priority.lifecycle.$_plc_dir // {} | to_entries[] | \"\(.key)\t\(.value)\"" 2>/dev/null)
      done
      # Validate priority.lifecycle sub-keys
      local _known_plc_keys="up down"
      local _plck
      while IFS= read -r _plck; do
        [[ -z "$_plck" ]] && continue
        if ! _in_array "$_plck" $_known_plc_keys; then
          _warn "priority.lifecycle: unrecognized key '$_plck'"
        fi
      done < <(nn_cfg '.priority.lifecycle // {} | keys[]' 2>/dev/null)

      # Check unset_position is valid
      local _pri_unset_issues="" _pri_unset_pos
      _pri_unset_pos=$(nn_cfg '.priority.unset_position // empty')
      if [[ -n "$_pri_unset_pos" && "$_pri_unset_pos" != "first" && "$_pri_unset_pos" != "last" ]]; then
        _pri_unset_issues+="unset_position '$_pri_unset_pos' invalid (must be 'first' or 'last'); "
        _pri_ok=false
      fi

      if [[ "$_pri_ok" == "true" && $_pri_count -gt 0 ]]; then
        _pass "Priority: $_pri_count levels, lifecycle valid"
      elif [[ $_pri_count -eq 0 ]]; then
        _fail "Priority: enabled but no values defined"
      else
        local _pri_all_issues="${_pri_color_issues}${_pri_fc_issues}${_pri_lc_issues}${_pri_unset_issues}"
        _fail "Priority: ${_pri_all_issues%"; "}"
      fi
      # Warn on invalid color formats
      if [[ -n "$_pri_default_color" ]] && ! _valid_color "$_pri_default_color"; then
        _warn "priority.default_color '$_pri_default_color' is not a valid ANSI code"
      fi
      for _pcv in "${_pri_values[@]}"; do
        local _pcolor
        _pcolor=$(nn_cfg ".priority.colors.\"$_pcv\" // empty")
        if [[ -n "$_pcolor" ]] && ! _valid_color "$_pcolor"; then
          _warn "priority.colors.$_pcv '$_pcolor' is not a valid ANSI code"
        fi
      done
      # Validate priority.colors keys reference valid values
      local _prck
      while IFS= read -r _prck; do
        [[ -z "$_prck" ]] && continue
        if ! _in_array "$_prck" "${_pri_values[@]}"; then
          _warn "priority.colors.$_prck not in priority.values"
        fi
      done < <(nn_cfg '.priority.colors // {} | keys[]' 2>/dev/null)
      # Validate priority label keys reference valid values
      local _plk
      while IFS= read -r _plk; do
        [[ -z "$_plk" ]] && continue
        if ! _in_array "$_plk" "${_pri_values[@]}"; then
          _warn "priority.labels.$_plk not in priority.values"
        fi
      done < <(nn_cfg '.priority.labels // {} | keys[]' 2>/dev/null)
      # Validate priority sub-keys
      local _known_priority_keys="enabled values filter_cycle unset_position default_color colors labels lifecycle"
      local _prk
      while IFS= read -r _prk; do
        [[ -z "$_prk" ]] && continue
        if ! _in_array "$_prk" $_known_priority_keys; then
          _warn "priority: unrecognized key '$_prk'"
        fi
      done < <(nn_cfg '.priority // {} | keys[]' 2>/dev/null)
    else
      _pass "Priority: disabled"
    fi

    # Defaults validation
    local _def_sort
    _def_sort=$(nn_cfg '.defaults.sort_by // empty')
    if [[ -n "$_def_sort" ]]; then
      case "$_def_sort" in
        created|modified|title|priority) ;;
        *) _warn "defaults.sort_by '$_def_sort' invalid (must be created, modified, title, or priority)" ;;
      esac
      if [[ "$_def_sort" == "priority" && "$_pri_enabled" == "false" ]]; then
        _warn "defaults.sort_by is 'priority' but priority is disabled"
      fi
    fi
    local _def_group
    _def_group=$(nn_cfg '.defaults.group_by // empty')
    if [[ -n "$_def_group" ]]; then
      case "$_def_group" in
        type|status) ;;
        *) _warn "defaults.group_by '$_def_group' invalid (must be type or status)" ;;
      esac
    fi
    local _def_archive
    _def_archive=$(nn_cfg '.defaults.show_archive // empty')
    if [[ -n "$_def_archive" && "$_def_archive" != "true" && "$_def_archive" != "false" ]]; then
      _warn "defaults.show_archive '$_def_archive' invalid (must be true or false)"
    fi
    local _def_sort_rev
    _def_sort_rev=$(nn_cfg '.defaults.sort_reverse // empty')
    if [[ -n "$_def_sort_rev" && "$_def_sort_rev" != "true" && "$_def_sort_rev" != "false" ]]; then
      _warn "defaults.sort_reverse '$_def_sort_rev' invalid (must be true or false)"
    fi
    local _def_wrap
    _def_wrap=$(nn_cfg '.defaults.wrap_preview // empty')
    if [[ -n "$_def_wrap" && "$_def_wrap" != "true" && "$_def_wrap" != "false" ]]; then
      _warn "defaults.wrap_preview '$_def_wrap' invalid (must be true or false)"
    fi
    # Check for unrecognized keys in [defaults]
    local _known_defaults="sort_by sort_reverse group_by show_archive wrap_preview"
    local _dk
    while IFS= read -r _dk; do
      [[ -z "$_dk" ]] && continue
      if ! _in_array "$_dk" $_known_defaults; then
        _warn "defaults: unrecognized key '$_dk'"
      fi
    done < <(nn_cfg '.defaults // {} | keys[]' 2>/dev/null)

    # UI validation
    local _ui_exit
    _ui_exit=$(nn_cfg '.ui.exit_message // empty')
    if [[ -n "$_ui_exit" ]]; then
      case "$_ui_exit" in
        none|fortune) ;;
        *) _warn "ui.exit_message '$_ui_exit' invalid (must be 'none' or 'fortune')" ;;
      esac
    fi
    local _ui_pp
    _ui_pp=$(nn_cfg '.ui.priority_plus // empty')
    if [[ -n "$_ui_pp" ]]; then
      case "$_ui_pp" in
        demote|promote) ;;
        *) _warn "ui.priority_plus '$_ui_pp' invalid (must be 'demote' or 'promote')" ;;
      esac
    fi
    local _ui_ac
    _ui_ac=$(nn_cfg '.ui.after_create // empty')
    if [[ -n "$_ui_ac" ]]; then
      case "$_ui_ac" in
        edit|none) ;;
        *) _warn "ui.after_create '$_ui_ac' invalid (must be 'edit' or 'none')" ;;
      esac
    fi
    # Check for unrecognized keys in [ui]
    local _known_ui="editor command_prompt search_prompt exit_message priority_plus after_create"
    local _uk
    while IFS= read -r _uk; do
      [[ -z "$_uk" ]] && continue
      if ! _in_array "$_uk" $_known_ui; then
        _warn "ui: unrecognized key '$_uk'"
      fi
    done < <(nn_cfg '.ui // {} | keys[]' 2>/dev/null)

    # Query preset validation (warnings only)
    local _qp_count=0 _qp_warns=""

    # Validate queries.inherit if present
    local _qi
    _qi=$(nn_cfg '.queries.inherit // empty')
    if [[ -n "$_qi" && "$_qi" != "true" && "$_qi" != "false" ]]; then
      _qp_warns+="inherit must be true or false (got '$_qi'); "
    fi

    # Check for unrecognized keys in query presets
    local _qp_name _qp_key
    while IFS=$'\t' read -r _qp_name _qp_key; do
      [[ -z "$_qp_name" ]] && continue
      case "$_qp_key" in
        args|order) ;;
        *) _qp_warns+="$_qp_name: unknown key '$_qp_key'; " ;;
      esac
    done < <(nn_cfg '.queries // {} | to_entries[] | select(.key != "inherit") | .key as $n | (.value | keys[]) as $k | "\($n)\t\($k)"')

    # Validate query order values are numeric
    local _qo_name _qo_val
    while IFS=$'\t' read -r _qo_name _qo_val; do
      [[ -z "$_qo_name" ]] && continue
      if [[ -n "$_qo_val" && ! "$_qo_val" =~ ^[0-9]+$ ]]; then
        _qp_warns+="$_qo_name: order '$_qo_val' is not numeric; "
      fi
    done < <(nn_cfg '.queries // {} | to_entries[] | select(.key != "inherit") | "\(.key)\t\(.value.order // "")"')

    while IFS=$'\t' read -r _qname _qargs; do
      [[ -z "$_qname" ]] && continue
      (( _qp_count++ ))
      local _arg
      for _arg in $_qargs; do
        local _key="${_arg%%=*}" _val="${_arg#*=}"
        case "$_key" in
          type)
            if ! _in_array "$_val" "${_typ_values[@]}"; then
              _qp_warns+="$_qname: type=$_val unknown; "
            fi
            ;;
          status)
            if ! _in_array "$_val" "${_sta_values[@]}"; then
              _qp_warns+="$_qname: status=$_val unknown; "
            fi
            ;;
          priority)
            if [[ "$_val" != "none" && "$_pri_enabled" != "false" ]] && ! _in_array "$_val" "${_pri_values[@]}"; then
              _qp_warns+="$_qname: priority=$_val unknown; "
            fi
            ;;
          tag) ;;
          *) _qp_warns+="$_qname: unknown filter key '$_key'; " ;;
        esac
      done
    done < <(nn_cfg '.queries // {} | to_entries[] | select(.key != "inherit") | "\(.key)\t\(.value.args // "")"')

    if [[ -n "$_qp_warns" ]]; then
      _warn "Query presets: $_qp_count presets – ${_qp_warns%"; "}"
    elif [[ $_qp_count -gt 0 ]]; then
      _pass "Query presets: $_qp_count presets, all args valid"
    else
      _pass "Query presets: none defined"
    fi
  else
    echo ""
    echo "${_dim}Skipping workflow checks (config not loaded)${_reset}"
  fi

  # ── Phase 5: zk notebook ──

  if [[ "$_has_zk" == "true" ]]; then
    echo ""
    echo "Notebook:"
    if zk list --format '{{absPath}}' --quiet --limit 1 >/dev/null 2>&1; then
      _pass "zk notebook found"
      local _note_count
      _note_count=$(zk list --format '{{absPath}}' --quiet 2>/dev/null | wc -l | tr -d ' ')
      if [[ "$_note_count" -gt 0 ]] 2>/dev/null; then
        _pass "$_note_count notes indexed"
      else
        _warn "0 notes indexed"
      fi
    else
      _warn "No zk notebook found from current directory"
    fi
  fi

  # Summary
  echo ""
  if [[ $fails -eq 0 && $warns -eq 0 ]]; then
    echo "All checks passed."
  elif [[ $fails -eq 0 ]]; then
    echo "All checks passed ($warns warning(s))."
  else
    echo "$fails check(s) failed, $warns warning(s)."
  fi

  [[ $fails -gt 0 ]] && return 1
  return 0
}

# --- Remote workflow helpers ---

# Returns the cache file path for a remote workflow URL.
_nn_url_cache_path() {
  local url="$1"
  local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/notenav/workflows"
  local hash
  hash=$(printf '%s' "$url" | _nn_sha256 | cut -c1-16)
  printf '%s/%s.toml' "$cache_dir" "$hash"
}

# Portable sha256 – outputs hex digest on stdout.
_nn_sha256() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum | cut -d' ' -f1
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 | cut -d' ' -f1
  else
    echo "notenav: no sha256 tool found (need sha256sum or shasum)" >&2
    return 1
  fi
}

# Returns 0 if URL is in the trusted-sources allow-list.
_nn_url_is_trusted() {
  local url="$1"
  local ts_file="${XDG_CONFIG_HOME:-$HOME/.config}/notenav/trusted-sources"
  [[ -f "$ts_file" ]] || return 1
  local line
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ "$line" == "$url" ]] && return 0
  done < "$ts_file"
  return 1
}

# Appends a URL to the trusted-sources allow-list.
_nn_url_trust_add() {
  local url="$1"
  local ts_file="${XDG_CONFIG_HOME:-$HOME/.config}/notenav/trusted-sources"
  mkdir -p "$(dirname "$ts_file")" || { echo "notenav: cannot create directory for trusted-sources" >&2; return 1; }
  echo "$url" >> "$ts_file" || { echo "notenav: cannot write to $ts_file" >&2; return 1; }
}

# --- nn init ---

nn_init() {
  local notenav_root="$1"; shift

  # Intercept --help/-h
  if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    cat <<'EOF'
Usage: nn init [workflow]        create project config (.nn/workflow.toml)
       nn init --user [workflow] create user config (~/.config/notenav/config.toml)

Workflow can be a built-in name (zenith, ado, gtd, zettelkasten),
a user-defined workflow, or an https:// URL.
If omitted, defaults to zenith.

Remote URLs are fetched, validated, and cached locally. On first use
you will be prompted to trust the URL.
EOF
    return 0
  fi

  # Parse args
  local user_mode=false workflow_arg=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --user) user_mode=true; shift ;;
      *)
        if [[ -n "$workflow_arg" ]]; then
          echo "notenav: unexpected argument: $1" >&2
          return 2
        fi
        workflow_arg="$1"; shift ;;
    esac
  done

  if [[ "$user_mode" == "true" ]]; then
    _nn_init_user "$notenav_root" "$workflow_arg"
  else
    _nn_init_project "$notenav_root" "$workflow_arg"
  fi
}

_nn_init_project() {
  local notenav_root="$1" workflow_arg="$2"
  local workflow_name="${workflow_arg:-zenith}"

  # Resolve .nn/ directory (walk up from cwd, same as nn_load_config)
  local project_nn_dir="" _search_dir="$PWD"
  while true; do
    if [[ -d "$_search_dir/.nn" ]]; then
      project_nn_dir="$_search_dir/.nn"
      break
    fi
    [[ "$_search_dir" == "/" ]] && break
    _search_dir="$(dirname "$_search_dir")"
  done
  [[ -z "$project_nn_dir" ]] && project_nn_dir="$PWD/.nn"

  local wf_file="$project_nn_dir/workflow.toml"

  # If file exists, check for URL refresh case
  if [[ -f "$wf_file" ]]; then
    if [[ "$workflow_name" == https://* ]]; then
      # Check if the existing file extends this exact URL – if so, refresh cache
      local _existing_extends=""
      if ! command -v yq >/dev/null 2>&1; then
        echo "notenav: yq is required to check existing config for refresh" >&2
        return 1
      fi
      _existing_extends=$(yq -p=toml -o=json -I=0 '.' "$wf_file" 2>/dev/null \
        | jq -r '.extends // empty' 2>/dev/null)
      if [[ "$_existing_extends" == "$workflow_name" ]]; then
        _nn_fetch_remote "$workflow_name" || return 1
        echo "Refreshed cache for $workflow_name"
        return 0
      fi
    fi
    echo "notenav: project config already exists: $wf_file" >&2
    echo "notenav: edit it directly, or remove it and re-run nn init" >&2
    return 1
  fi

  # Validate workflow name/URL
  if [[ "$workflow_name" == https://* ]]; then
    _nn_fetch_remote "$workflow_name" || return 1
  else
    if ! _nn_workflow_exists "$notenav_root" "$workflow_name"; then
      echo "notenav: workflow '$workflow_name' not found" >&2
      _nn_list_workflows "$notenav_root" >&2
      return 2
    fi
  fi

  # Create .nn/ directory and workflow.toml
  # Writes workflow_name via printf %s to avoid shell expansion of $ in URLs.
  mkdir -p "$project_nn_dir" || { echo "notenav: cannot create directory: $project_nn_dir" >&2; return 1; }
  {
    echo '# Project workflow – see https://github.com/jqueiroz/notenav/blob/main/docs/configuration.md'
    printf 'extends = "%s"\n' "$workflow_name"
    echo ''
    echo '# Add project-specific query presets below.'
    echo '# [queries.backlog]'
    echo '# args = "tag=backlog"'
  } > "$wf_file"

  echo "Created $wf_file (extends $workflow_name)"
  if [[ "$workflow_name" != https://* ]]; then
    _nn_list_workflows "$notenav_root"
  fi
}

_nn_init_user() {
  local notenav_root="$1" workflow_arg="$2"
  local target="${XDG_CONFIG_HOME:-$HOME/.config}/notenav/config.toml"

  if [[ -f "$target" ]]; then
    echo "notenav: user config already exists: $target" >&2
    echo "notenav: edit it directly, or remove it and re-run nn init" >&2
    return 1
  fi

  # Validate workflow name/URL if given
  if [[ -n "$workflow_arg" ]]; then
    if [[ "$workflow_arg" == https://* ]]; then
      _nn_fetch_remote "$workflow_arg" || return 1
    elif ! _nn_workflow_exists "$notenav_root" "$workflow_arg"; then
      echo "notenav: workflow '$workflow_arg' not found" >&2
      _nn_list_workflows "$notenav_root" >&2
      return 2
    fi
  fi

  local _sample="$notenav_root/samples/user-config.toml"
  if [[ ! -f "$_sample" ]]; then
    echo "notenav: sample config not found at $_sample" >&2
    return 1
  fi
  mkdir -p "$(dirname "$target")" || { echo "notenav: cannot create directory: $(dirname "$target")" >&2; return 1; }
  cp "$_sample" "$target"

  # Uncomment and set default_workflow if a name/URL was given.
  # Uses awk to avoid sed delimiter injection from URLs or special characters.
  if [[ -n "$workflow_arg" ]]; then
    local _tmp
    _tmp=$(mktemp)
    wf="$workflow_arg" awk \
      '/^# default_workflow = / { print "default_workflow = \"" ENVIRON["wf"] "\""; next } { print }' \
      "$target" > "$_tmp" \
      && mv "$_tmp" "$target" \
      || rm -f "$_tmp"
  fi

  echo "Created $target"
  echo "Edit it to customize your preferences."
}

# Checks if a workflow name exists in built-in or user workflow directories.
_nn_workflow_exists() {
  local notenav_root="$1" name="$2"
  [[ -f "$notenav_root/config/workflows/$name.toml" ]] && return 0
  [[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/notenav/workflows/$name.toml" ]] && return 0
  return 1
}

# Lists available workflows.
_nn_list_workflows() {
  local notenav_root="$1"
  local names=()
  local f name
  for f in "$notenav_root"/config/workflows/*.toml; do
    [[ -f "$f" ]] || continue
    name="${f##*/}"
    names+=("${name%.toml}")
  done
  local user_wf_dir="${XDG_CONFIG_HOME:-$HOME/.config}/notenav/workflows"
  if [[ -d "$user_wf_dir" ]]; then
    for f in "$user_wf_dir"/*.toml; do
      [[ -f "$f" ]] || continue
      name="${f##*/}"
      names+=("${name%.toml}")
    done
  fi
  # Deduplicate (user workflows may shadow built-in names)
  local -A _seen
  local unique=()
  local n
  for n in "${names[@]}"; do
    [[ -n "${_seen[$n]+x}" ]] && continue
    _seen[$n]=1
    unique+=("$n")
  done
  if [[ ${#unique[@]} -gt 0 ]]; then
    local list
    printf -v list '%s, ' "${unique[@]}"
    echo "Available workflows: ${list%, }"
  fi
}

# Downloads, validates, and caches a remote workflow URL.
_nn_fetch_remote() {
  local url="$1"

  if ! command -v curl >/dev/null 2>&1; then
    echo "notenav: curl is required for remote workflows" >&2
    return 1
  fi
  if ! command -v yq >/dev/null 2>&1; then
    echo "notenav: yq is required for remote workflows" >&2
    return 1
  fi

  # Trust check
  if ! _nn_url_is_trusted "$url"; then
    if [[ -t 0 ]]; then
      printf 'Trust %s?\nThis adds it to %s/notenav/trusted-sources. [y/N] ' \
        "$url" "${XDG_CONFIG_HOME:-$HOME/.config}"
      local reply
      read -r reply
      case "$reply" in
        [yY]|[yY][eE][sS]) ;;
        *) echo "Aborted."; return 1 ;;
      esac
    else
      echo "notenav: URL not trusted: $url" >&2
      echo "notenav: run interactively or add to ${XDG_CONFIG_HOME:-$HOME/.config}/notenav/trusted-sources" >&2
      return 1
    fi
  fi

  # Download to temp file
  local tmpfile
  tmpfile=$(mktemp)
  trap 'rm -f "$tmpfile"' RETURN
  if ! curl -fsSL "$url" -o "$tmpfile"; then
    echo "notenav: failed to download $url" >&2
    return 1
  fi

  # Validate TOML
  if ! yq -p=toml -o=json '.' "$tmpfile" >/dev/null 2>&1; then
    echo "notenav: downloaded file is not valid TOML" >&2
    return 1
  fi

  # Write to cache with header (atomic: temp + mv)
  local cache_path _cache_tmp
  cache_path=$(_nn_url_cache_path "$url")
  mkdir -p "$(dirname "$cache_path")"
  _cache_tmp=$(mktemp)
  {
    printf '# Cached from: %s\n' "$url"
    printf '# Fetched: %s\n' "$(date '+%Y-%m-%d')"
    cat "$tmpfile"
  } > "$_cache_tmp" && mv "$_cache_tmp" "$cache_path" || { rm -f "$_cache_tmp"; return 1; }

  # Add to allow-list if not already trusted
  if ! _nn_url_is_trusted "$url"; then
    _nn_url_trust_add "$url"
  fi
}

# Write the shared preview script to a given path.
# Used by both faceted browser and ad-hoc interactive mode.
_nn_write_preview() {
  local target="$1"
  cat > "$target" << 'ENDPREVIEW'
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
_bat=$(command -v bat || command -v batcat || true)
if [ -n "$_bat" ]; then
  "$_bat" -p --color always "$file" 2>/dev/null || cat "$file"
else
  cat "$file"
fi

# Collect links in parallel
tmp_links=$(mktemp); tmp_back=$(mktemp)
trap 'rm -f "$tmp_links" "$tmp_back"' EXIT
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
  chmod +x "$target"
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
       nn init [workflow]        create project config (.nn/workflow.toml)
       nn init --user [workflow] create user config
       nn doctor                 check setup and diagnose problems

Options:
  -h, --help       Show this help
  -V, --version    Show version

Filter keys: type, status, priority, tag
Example: nn type=task status=active

Config:
  Project:  .nn/workflow.toml
  User:     ~/.config/notenav/config.toml
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
    local _ee_dir; _ee_dir=$(mktemp -d "${TMPDIR:-/tmp}/nn-ee.XXXXXX")
    _nn_easteregg_decode "$_ee_dir" "$_nn_k"
    cat "$_ee_dir/.empty_easteregg_override" 2>/dev/null && echo
    rm -rf "$_ee_dir"
    return 0
  fi

  # nn doctor: diagnostic checks (dispatched before config loading)
  if [[ "$1" == "doctor" ]]; then
    nn_doctor "$NOTENAV_ROOT"
    return $?
  fi

  # nn init: bootstrap config files (dispatched before config loading)
  if [[ "$1" == "init" ]]; then
    shift
    nn_init "$NOTENAV_ROOT" "$@"
    return $?
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
  # If we're in a subdirectory of a zk notebook, scope to current directory.
  local _zk_path=()
  local _zk_root="$PWD"
  while true; do
    [[ -d "$_zk_root/.zk" ]] && break
    [[ "$_zk_root" == "/" ]] && { _zk_root=""; break; }
    _zk_root="$(dirname "$_zk_root")"
  done
  [[ -n "$_zk_root" && "$PWD" != "$_zk_root" ]] && _zk_path=("$(pwd)")

  # Resolve editor
  local _nn_editor
  _nn_editor="$(_nn_resolve_editor "$NN_UI_EDITOR")"

  # Check that zk can reach a notebook from here
  local _zk_check_err
  if ! _zk_check_err=$(zk list --format '{{absPath}}' --quiet --limit 1 "${_zk_path[@]}" 2>&1 >/dev/null); then
    echo "notenav: no zk notebook found from $(pwd)" >&2
    [[ -n "$_zk_check_err" ]] && echo "notenav: $_zk_check_err" >&2
    echo "notenav: run 'zk init' to create one, or 'nn doctor' to diagnose" >&2
    return 1
  fi

  # ---- FACETED BROWSER (no args) ----
  if [[ $# -eq 0 ]]; then
    if [[ "${TERM:-dumb}" == "dumb" ]]; then
      echo "notenav: interactive TUI requires a terminal (TERM is 'dumb')" >&2
      return 1
    fi
    local _nn_dir; _nn_dir=$(mktemp -d "${TMPDIR:-/tmp}/nn.XXXXXX")
    trap 'rm -rf "$_nn_dir"' EXIT
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
    [[ "$NN_DEFAULT_SORT_REV" == "true" ]] && echo "rev" > "$_nn_dir/.f_sort_rev" || : > "$_nn_dir/.f_sort_rev"
    echo "$NN_DEFAULT_GROUP" > "$_nn_dir/.f_group"
    [[ "$NN_DEFAULT_ARCHIVE" == "true" ]] && echo "show" > "$_nn_dir/.f_archive" || : > "$_nn_dir/.f_archive"
    : > "$_nn_dir/.f_match"
    : > "$_nn_dir/.f_name"
    [[ "$NN_DEFAULT_WRAP" == "true" ]] && echo "on" > "$_nn_dir/.f_wrap" || : > "$_nn_dir/.f_wrap"

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
if [ -z "$tags" ]; then
  printf '\n  \033[33mNo tags found in notebook.\033[0m\n\n' > /dev/tty
  sleep 1
  exit 0
fi
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
  --ansi --header $'Filter the view to only include notes matching the selected tags.\n\033[36mSpace\033[0m/\033[36mTab\033[0m toggle \033[90m·\033[0m \033[36mEnter\033[0m apply \033[90m·\033[0m \033[36mEsc\033[0m cancel' \
  --bind 'j:down,k:up,ctrl-j:page-down,ctrl-k:page-up,space:toggle' ${start_bind:+--bind "$start_bind"})
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
while IFS= read -r p || [ -n "$p" ]; do [ -n "$p" ] && zk_path+=("$p"); done < "$dir/.zk_path"
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
  --header $'Filter the view to only include notes whose body matches the query.\n\033[36mEnter\033[0m apply \033[90m·\033[0m \033[36mEsc\033[0m cancel' \
  --bind "start:reload:$dir/match_search.sh $dir {q}" \
  --bind "change:reload:$dir/match_search.sh $dir {q}" \
  --preview "$dir/preview.sh {1}" \
  --delimiter $'\t' --with-nth 2 \
  --print-query \
  --bind 'j:down,k:up,ctrl-j:page-down,ctrl-k:page-up' \
  --reverse)
rc=$?
query=$(printf '%s' "$result" | head -1)
if [ $rc -eq 0 ] && [ -n "$query" ]; then
  zk_path=()
  while IFS= read -r p || [ -n "$p" ]; do [ -n "$p" ] && zk_path+=("$p"); done < "$dir/.zk_path"
  zk list "${zk_path[@]}" --match "$query" --format '{{absPath}}' --quiet 2>/dev/null > "$dir/.f_match_paths"
  echo "$query" > "$dir/.f_match"
elif [ $rc -eq 0 ]; then
  : > "$dir/.f_match"
  : > "$dir/.f_match_paths"
fi
ENDMATCH
    chmod +x "$_nn_dir/match.sh"

    # Name filter: mini fzf popup to capture a title substring
    cat > "$_nn_dir/namefilt.sh" << 'ENDNAMEFILT'
#!/usr/bin/env bash
dir="$1"
cur=""
[ -s "$dir/.f_name" ] && cur=$(cat "$dir/.f_name")
result=$(: | fzf --ansi --disabled --query "$cur" \
  --prompt 'filter name: ' \
  --header $'Filter the view to only include notes whose title matches the query.\n\033[36mEnter\033[0m apply \033[90m·\033[0m \033[36mEsc\033[0m cancel' \
  --print-query \
  --bind 'j:down,k:up' \
  --reverse --border --color 'border:yellow')
rc=$?
query=$(printf '%s' "$result" | head -1)
if [ $rc -ne 130 ]; then
  printf '%s\n' "$query" > "$dir/.f_name"
fi
ENDNAMEFILT
    chmod +x "$_nn_dir/namefilt.sh"

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
printf '%s → %s' "$field" "$value" > "$dir/.last_action"
# Regenerate raw data
fmt=$(cat "$dir/.zk_fmt")
zk_path=()
while IFS= read -r p || [ -n "$p" ]; do [ -n "$p" ] && zk_path+=("$p"); done < "$dir/.zk_path"
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
    while IFS=$'\t' read -r v ic clr desc || [ -n "$v" ]; do
      [ -n "$vals" ] && vals="$vals\n"
      vals="$vals$(printf '\033[%sm%s %s\033[0m' "$clr" "$ic" "$v")"
    done < "$dir/.schema_types" ;;
  *) exit 1 ;;
esac
hdr="Enter apply · Esc cancel"
[ -n "$ctx" ] && hdr=$(printf '%s\n%s' "$ctx" "$hdr")
selected=$(printf '%b' "$vals" | fzf --ansi --reverse --prompt "set $field: " \
  --border --border-label " Set $field " \
  --header "$hdr" \
  --bind 'j:down,k:up,ctrl-j:page-down,ctrl-k:page-up')
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
  while IFS= read -r f || [ -n "$f" ]; do [ -n "$f" ] && files+=("$f"); done < "$dir/.c_sel"
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
while IFS= read -r new_line || [ -n "$new_line" ]; do
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
  while IFS= read -r vt || [ -n "$vt" ]; do [ "$new_type" = "$vt" ] && valid=true && break; done < "$dir/.schema_type_values"
  $valid || { errors="${errors}Invalid type '$new_type' for $(basename "$path")\n"; continue; }
  # Validate status
  if [ -n "$new_status" ]; then
    valid=false
    while IFS= read -r vs || [ -n "$vs" ]; do [ "$new_status" = "$vs" ] && valid=true && break; done < "$dir/.schema_status_values"
    $valid || { errors="${errors}Invalid status '$new_status' for $(basename "$path")\n"; continue; }
  fi
  # Validate priority
  if [ -n "$new_pri" ]; then
    if [ "$(cat "$dir/.schema_priority_enabled")" != "false" ]; then
      valid=false
      while IFS= read -r vp || [ -n "$vp" ]; do [ "$new_pri" = "$vp" ] && valid=true && break; done < "$dir/.schema_priority_values"
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
# Report results to user
if [ -n "$errors" ]; then
  printf '\n\033[31m%b\033[0m' "$errors" > /dev/tty
fi
if [ "$count" -gt 0 ]; then
  printf '\033[32mUpdated %d note(s)\033[0m\n' "$count" > /dev/tty
else
  [ -z "$errors" ] && printf '\033[90mNo changes\033[0m\n' > /dev/tty
fi
# Regenerate raw data and re-filter
fmt=$(cat "$dir/.zk_fmt")
zk_path=()
while IFS= read -r p || [ -n "$p" ]; do [ -n "$p" ] && zk_path+=("$p"); done < "$dir/.zk_path"
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
while IFS=$'\t' read -r fpath _rest || [ -n "$fpath" ]; do
  [ -z "$fpath" ] && continue
  awk -F'\t' -v p="$fpath" '$6 == p { printf "%s\t%s\t%s\t%s\t%s\t%s\n", $1, $2, $3, $4, $5, $6 }' "$dir/.raw" >> "$tmpfile"
done < <(awk '{a[NR]=$0} END{for(i=NR;i>0;i--)print a[i]}' "$dir/.current")
# Footer with valid values from workflow
printf '\n# type: %s\n' "$(paste -sd', ' "$dir/.schema_type_values")" >> "$tmpfile"
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

    # Quick note creation: inline title prompt → type selection → zk new → editor
    cat > "$_nn_dir/newnote.sh" << 'ENDNN'
#!/usr/bin/env bash
dir="$1"
cols=$(tput cols 2>/dev/null || printf '80')
inner=$(( cols - 6 ))
[ "$inner" -gt 80 ] && inner=80
[ "$inner" -lt 40 ] && inner=40

# Clear screen so previous execute() output doesn't stack
printf '\033[H\033[J' > /dev/tty

# ── Determine mode: auto (single type or filter active) vs pick ──
type_count=$(wc -l < "$dir/.schema_types")
cur_type=$(cat "$dir/.f_type" 2>/dev/null)
if [ "$type_count" -eq 1 ] || [ -n "$cur_type" ]; then
  mode=auto
  if [ -n "$cur_type" ]; then
    auto_type="$cur_type"
  else
    auto_type=$(head -1 "$dir/.schema_types" | cut -f1)
  fi
  while IFS=$'\t' read -r v ic clr desc || [ -n "$v" ]; do
    if [ "$v" = "$auto_type" ]; then
      auto_icon="$ic"; auto_color="$clr"; auto_desc="$desc"; break
    fi
  done < "$dir/.schema_types"
else
  mode=pick
fi

# ── Read title with cursor movement and Esc-to-cancel ──
# Uses current value of $title (caller sets it before calling).
# Supports: left/right arrows, Home/End, Ctrl+A/E, Ctrl+U, backspace.
# On Esc: clears title and returns. On Enter: returns with current title.
_nn_read_title() {
  local ch rest pos tail_len after
  pos=${#title}
  [ "$pos" -gt 0 ] && printf '%s' "$title" > /dev/tty
  while true; do
    IFS= read -rsn1 ch < /dev/tty
    case "$ch" in
      $'\033')
        IFS= read -rsn2 -t 0.05 rest < /dev/tty
        case "$rest" in
          '[C')  # Right
            if [ "$pos" -lt "${#title}" ]; then
              pos=$((pos + 1)); printf '\033[C' > /dev/tty
            fi ;;
          '[D')  # Left
            if [ "$pos" -gt 0 ]; then
              pos=$((pos - 1)); printf '\033[D' > /dev/tty
            fi ;;
          '[H'|OH)  # Home
            if [ "$pos" -gt 0 ]; then
              printf '\033[%dD' "$pos" > /dev/tty; pos=0
            fi ;;
          '[F'|OF)  # End
            tail_len=$(( ${#title} - pos ))
            if [ "$tail_len" -gt 0 ]; then
              printf '\033[%dC' "$tail_len" > /dev/tty; pos=${#title}
            fi ;;
          '')  # Plain Esc → cancel
            tail_len=$(( ${#title} - pos ))
            [ "$tail_len" -gt 0 ] && printf '\033[%dC' "$tail_len" > /dev/tty
            if [ "${#title}" -gt 0 ]; then
              printf '\033[%dD%*s\033[%dD' "${#title}" "${#title}" "" "${#title}" > /dev/tty
            fi
            title=""
            printf '\n' > /dev/tty
            break ;;
          *) ;;  # Ignore other sequences
        esac ;;
      $'\001')  # Ctrl+A → Home
        if [ "$pos" -gt 0 ]; then
          printf '\033[%dD' "$pos" > /dev/tty; pos=0
        fi ;;
      $'\005')  # Ctrl+E → End
        tail_len=$(( ${#title} - pos ))
        if [ "$tail_len" -gt 0 ]; then
          printf '\033[%dC' "$tail_len" > /dev/tty; pos=${#title}
        fi ;;
      $'\025')  # Ctrl+U → Kill to beginning of line
        if [ "$pos" -gt 0 ]; then
          after="${title:pos}"
          printf '\033[%dD' "$pos" > /dev/tty
          printf '%s%*s' "$after" "$pos" "" > /dev/tty
          printf '\033[%dD' "$(( ${#after} + pos ))" > /dev/tty
          title="$after"
          pos=0
        fi ;;
      $'\177'|$'\010')  # Backspace / DEL
        if [ "$pos" -gt 0 ]; then
          after="${title:pos}"
          title="${title:0:pos-1}${after}"
          pos=$((pos - 1))
          printf '\033[D%s ' "$after" > /dev/tty
          printf '\033[%dD' "$(( ${#after} + 1 ))" > /dev/tty
        fi ;;
      '')  # Enter → accept
        printf '\n' > /dev/tty
        break ;;
      *)  # Regular character → insert at cursor
        after="${title:pos}"
        title="${title:0:pos}${ch}${after}"
        pos=$((pos + 1))
        printf '%s' "${ch}${after}" > /dev/tty
        [ "${#after}" -gt 0 ] && printf '\033[%dD' "${#after}" > /dev/tty ;;
    esac
  done
}

if [ "$mode" = "auto" ]; then
  # ── Auto: type-colored single-step box ──
  label="New ${auto_type} ${auto_icon} "
  label_len=${#label}
  top_pad=$((inner - label_len - 2))
  [ "$top_pad" -lt 1 ] && top_pad=1
  top_dashes=$(printf '%*s' "$top_pad" '' | sed 's/ /─/g')
  bot_dashes=$(printf '%*s' "$inner" '' | sed 's/ /─/g')
  hint="Enter to create · Esc cancels"
  hint_pad=$((inner - ${#hint} - 2))
  c="$auto_color"

  # Truncate description for display
  auto_desc_disp="$auto_desc"
  desc_max=$((inner - 2))
  [ ${#auto_desc_disp} -gt "$desc_max" ] && auto_desc_disp="${auto_desc_disp:0:$((desc_max - 3))}..."
  desc_line_pad=$((inner - 2 - ${#auto_desc_disp}))

  printf '\n' > /dev/tty
  printf '  \033[%sm╭─ %s%s╮\033[0m\n' "$c" "$label" "$top_dashes" > /dev/tty
  printf '  \033[%sm│\033[0m%*s\033[%sm│\033[0m\n' "$c" "$inner" "" "$c" > /dev/tty
  printf '  \033[%sm│\033[0m  Title: %*s\033[%sm│\033[0m\n' "$c" "$((inner - 9))" "" "$c" > /dev/tty
  printf '  \033[%sm│\033[0m  \033[90m%s\033[0m%*s\033[%sm│\033[0m\n' "$c" "$auto_desc_disp" "$desc_line_pad" "" "$c" > /dev/tty
  printf '  \033[%sm│\033[0m%*s\033[%sm│\033[0m\n' "$c" "$inner" "" "$c" > /dev/tty
  printf '  \033[%sm│\033[0m  \033[90m%s\033[0m%*s\033[%sm│\033[0m\n' "$c" "$hint" "$hint_pad" "" "$c" > /dev/tty
  printf '  \033[%sm╰%s╯\033[0m\n' "$c" "$bot_dashes" > /dev/tty
  # Cursor: up 5 to title line, column 13 (after "  │  Title: ")
  printf '\033[5A\033[13G' > /dev/tty
  title=""
  _nn_read_title
  if [ -z "$title" ]; then
    # Move past box bottom (4 lines down from title+1)
    printf '\033[4B' > /dev/tty
    printf '\r  \033[90mCancelled\033[0m\033[K\n' > /dev/tty
    exit 0
  fi
  # Move past box bottom (4 lines down from title+1)
  printf '\033[4B' > /dev/tty
  selected="$auto_type"
  tc=$(printf '\033[%sm' "$auto_color")
  icon="$auto_icon"

else
  # ── Pick: two-step with inline type picker ──
  top_pad=$((inner - 11))
  top_dashes=$(printf '%*s' "$top_pad" '' | sed 's/ /─/g')
  bot_dashes=$(printf '%*s' "$inner" '' | sed 's/ /─/g')
  hint="Enter to continue · Esc cancels"
  hint_pad=$((inner - ${#hint} - 2))

  # Load types into arrays (constant across loop iterations)
  t_vals=(); t_icons=(); t_colors=(); t_descs=()
  max_name=0
  while IFS=$'\t' read -r v ic clr desc || [ -n "$v" ]; do
    t_vals+=("$v"); t_icons+=("$ic"); t_colors+=("$clr"); t_descs+=("$desc")
    [ ${#v} -gt "$max_name" ] && max_name=${#v}
  done < "$dir/.schema_types"
  max_type_width=$((inner - 11))
  [ "$max_name" -gt "$max_type_width" ] && max_name="$max_type_width"
  desc_avail=$((max_type_width - max_name))

  # Precompute truncated descriptions
  t_tdescs=()
  for ((i = 0; i < type_count; i++)); do
    d="${t_descs[$i]}"
    if [ "$desc_avail" -gt 3 ] && [ -n "$d" ]; then
      [ ${#d} -gt "$desc_avail" ] && d="${d:0:$((desc_avail - 3))}..."
    elif [ "$desc_avail" -le 3 ]; then
      d=""
    fi
    t_tdescs+=("$d")
  done

  # Precompute step-2 border labels and dashes per type
  # e.g. "New task ◆ " with matching dash fill
  step2_labels=(); step2_dashes_arr=()
  for ((i = 0; i < type_count; i++)); do
    l="New ${t_vals[$i]} ${t_icons[$i]} "
    step2_labels+=("$l")
    lpad=$((inner - ${#l} - 2))
    [ "$lpad" -lt 1 ] && lpad=1
    step2_dashes_arr+=("$(printf '%*s' "$lpad" '' | sed 's/ /─/g')")
  done

  hint2="j/k · Enter · Esc back"
  hint2_pad=$((inner - ${#hint2} - 2))

  # Helper: draw a single type line (no trailing newline)
  _nn_draw_type_line() {
    local i="$1" sel="$2" bc="${3:-36}"
    local name="${t_vals[$i]}" ic="${t_icons[$i]}" clr="${t_colors[$i]}"
    local d="${t_tdescs[$i]}"
    local name_pad=$((max_name - ${#name}))
    local d_pad=$((desc_avail - ${#d}))
    [ "$d_pad" -lt 0 ] && d_pad=0
    if [ "$i" -eq "$sel" ]; then
      printf '  \033[%sm│\033[0m     \033[1;%sm▸ %s %s\033[0m%*s  \033[90m%s\033[0m%*s\033[%sm│\033[0m' \
        "$bc" "$clr" "$ic" "$name" "$name_pad" "" "$d" "$d_pad" "" "$bc"
    else
      printf '  \033[%sm│\033[0m     \033[90m  %s %s%*s  %s\033[0m%*s\033[%sm│\033[0m' \
        "$bc" "$ic" "$name" "$name_pad" "" "$d" "$d_pad" "" "$bc"
    fi
  }

  # Helper: draw entire step-2 box
  _nn_draw_step2() {
    local sel="$1" bc="$2" i
    printf '  \033[%sm╭─ %s%s╮\033[0m\n' "$bc" "${step2_labels[$sel]}" "${step2_dashes_arr[$sel]}"
    printf '  \033[%sm│\033[0m%*s\033[%sm│\033[0m\n' "$bc" "$inner" "" "$bc"
    printf '  \033[%sm│\033[0m  \033[32m✓\033[0m %s%*s\033[%sm│\033[0m\n' \
      "$bc" "$disp_title" "$((inner - 4 - ${#disp_title}))" "" "$bc"
    printf '  \033[%sm│\033[0m  \033[1m2. Type:\033[0m%*s\033[%sm│\033[0m\n' \
      "$bc" "$((inner - 10))" "" "$bc"
    for ((i = 0; i < type_count; i++)); do
      _nn_draw_type_line "$i" "$sel" "$bc"
      printf '\n'
    done
    printf '  \033[%sm│\033[0m%*s\033[%sm│\033[0m\n' "$bc" "$inner" "" "$bc"
    printf '  \033[%sm│\033[0m  \033[90m%s\033[0m%*s\033[%sm│\033[0m\n' \
      "$bc" "$hint2" "$hint2_pad" "" "$bc"
    printf '  \033[%sm╰%s╯\033[0m\n' "$bc" "$bot_dashes"
  }

  # ── Step 1 ↔ Step 2 loop (Esc in step 2 goes back to step 1) ──
  title=""
  selected=""
  sel=0
  while true; do
  printf '\033[H\033[J' > /dev/tty

  # Step 1: title prompt
  printf '\n' > /dev/tty
  printf '  \033[36m╭─ New Note %s╮\033[0m\n' "$top_dashes" > /dev/tty
  printf '  \033[36m│\033[0m%*s\033[36m│\033[0m\n' "$inner" "" > /dev/tty
  printf '  \033[36m│\033[0m  \033[1m1. Title:\033[0m%*s\033[36m│\033[0m\n' "$((inner - 11))" "" > /dev/tty
  printf '  \033[36m│\033[0m  \033[90m2. Type\033[0m%*s\033[36m│\033[0m\n' "$((inner - 9))" "" > /dev/tty
  printf '  \033[36m│\033[0m%*s\033[36m│\033[0m\n' "$inner" "" > /dev/tty
  printf '  \033[36m│\033[0m  \033[90m%s\033[0m%*s\033[36m│\033[0m\n' "$hint" "$hint_pad" "" > /dev/tty
  printf '  \033[36m╰%s╯\033[0m\n' "$bot_dashes" > /dev/tty
  # Cursor: up 5 to title line, column 16 (after "  │  1. Title: ")
  printf '\033[5A\033[16G' > /dev/tty
  _nn_read_title
  if [ -z "$title" ]; then
    # Move past box bottom (4 lines down from type line)
    printf '\033[4B' > /dev/tty
    printf '\r  \033[90mCancelled\033[0m\033[K\n' > /dev/tty
    exit 0
  fi

  # Transition to step 2
  printf '\033[4A\033[J' > /dev/tty

  disp_title="$title"
  max_disp=$((inner - 4))
  if [ ${#disp_title} -gt "$max_disp" ]; then
    disp_title="${disp_title:0:$((max_disp - 3))}..."
  fi

  bc="${t_colors[$sel]}"
  printf '\n' > /dev/tty
  _nn_draw_step2 "$sel" "$bc" > /dev/tty
  printf '\033[%dA' "$((type_count + 7))" > /dev/tty

  # Hide cursor; restore on exit/interrupt
  trap 'printf "\033[?25h" > /dev/tty' EXIT
  printf '\033[?25l' > /dev/tty

  # Navigation loop
  selected=""
  while true; do
    IFS= read -rsn1 key < /dev/tty
    case "$key" in
      $'\033')
        IFS= read -rsn2 -t 0.05 rest < /dev/tty
        case "$rest" in
          '[A') key=up ;;
          '[B') key=down ;;
          *)    key=esc ;;
        esac ;;
      j) key=down ;; k) key=up ;;
      '') key=enter ;; *) continue ;;
    esac
    case "$key" in
      up)    sel=$(( sel > 0 ? sel - 1 : type_count - 1 )) ;;
      down)  sel=$(( sel < type_count - 1 ? sel + 1 : 0 )) ;;
      enter) selected="${t_vals[$sel]}"; break ;;
      esc)   break ;;
    esac

    # Redraw entire box with updated border color
    bc="${t_colors[$sel]}"
    _nn_draw_step2 "$sel" "$bc" > /dev/tty
    printf '\033[%dA' "$((type_count + 7))" > /dev/tty
  done

  # Show cursor
  printf '\033[?25h' > /dev/tty
  trap - EXIT

  # Move past box bottom
  printf '\033[%dB' "$((type_count + 7))" > /dev/tty

  [ -n "$selected" ] && break
  # Esc in step 2 → back to step 1 (title preserved)
  done

  # Look up icon and color for result message
  tc=""; icon=""
  while IFS=$'\t' read -r v ic clr desc || [ -n "$v" ]; do
    [ "$v" = "$selected" ] && tc=$(printf '\033[%sm' "$clr") && icon="$ic" && break
  done < "$dir/.schema_types"
fi

# ── Create note ──
_zk_err=$(mktemp)
new_path=$(zk new . --template "${selected}.md" --title "$title" --no-input --print-path 2>"$_zk_err")
if [ -z "$new_path" ]; then
  _zk_msg=$(cat "$_zk_err")
  rm -f "$_zk_err"
  if [ -n "$_zk_msg" ]; then
    printf '\n  \033[31m%s\033[0m\n\n' "$_zk_msg" > /dev/tty
  else
    printf '\n  \033[31mFailed to create note\033[0m\n\n' > /dev/tty
  fi
  exit 0
fi
rm -f "$_zk_err"

# ── Ensure essential frontmatter fields are present ──
_nn_now=$(date '+%Y-%m-%dT%H:%M:%S')
_nn_initial_status=$(cat "$dir/.schema_status_initial" 2>/dev/null)
_nn_has_fm=$(head -1 "$new_path" 2>/dev/null)
if [ "$_nn_has_fm" = "---" ]; then
  # Patch existing frontmatter – add missing type/status, always set created
  awk -v nn_type="$selected" -v nn_status="$_nn_initial_status" -v nn_created="$_nn_now" '
    NR==1 && /^---/ { in_fm=1; print; next }
    in_fm && /^---/ {
      in_fm=0
      if (!found_type)    print "type: " nn_type
      if (!found_status && nn_status != "")  print "status: " nn_status
      if (!found_created) print "created: " nn_created
      print; next
    }
    in_fm && /^type:( |$)/    { found_type=1 }
    in_fm && /^status:( |$)/  { found_status=1 }
    in_fm && /^created:( |$)/ { print "created: " nn_created; found_created=1; next }
    { print }
  ' "$new_path" > "$new_path.tmp" && mv "$new_path.tmp" "$new_path"
else
  # No frontmatter – prepend one
  {
    printf '%s\n' "---"
    printf 'type: %s\n' "$selected"
    [ -n "$_nn_initial_status" ] && printf 'status: %s\n' "$_nn_initial_status"
    printf 'created: %s\n' "$_nn_now"
    printf '%s\n' "---"
    cat "$new_path"
  } > "$new_path.tmp" && mv "$new_path.tmp" "$new_path"
fi

after_create=$(cat "$dir/.schema_after_create" 2>/dev/null)
rel_path="${new_path#$PWD/}"
if [ "$after_create" = "edit" ]; then
  printf '\n  %s%s %s · %s – Created!\033[0m Opening in editor...\n  \033[90m%s\033[0m\n\n' "$tc" "$icon" "$selected" "$title" "$rel_path" > /dev/tty
else
  printf '\n  %s%s %s · %s – Created!\033[0m\n  \033[90m%s\033[0m\n\n' "$tc" "$icon" "$selected" "$title" "$rel_path" > /dev/tty
fi
# Regenerate raw
fmt=$(cat "$dir/.zk_fmt")
zk_path=()
while IFS= read -r p || [ -n "$p" ]; do [ -n "$p" ] && zk_path+=("$p"); done < "$dir/.zk_path"
zk list "${zk_path[@]}" --format "$fmt" --quiet 2>/dev/null > "$dir/.raw"
"$dir/filter.sh" "$dir" refresh > /dev/null
# Open in editor
if [ "$after_create" = "edit" ]; then
  nn_editor=$(cat "$dir/.schema_editor" 2>/dev/null)
  ${nn_editor:-vi} "$new_path" < /dev/tty > /dev/tty
fi
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
if [ -z "$cur" ]; then
  # No priority set – enter at lowest priority
  next=$(tail -1 "$dir/.schema_priority_values")
  [ -z "$next" ] && exit 0
else
  case "$direction" in
    up)   next=$(awk -F'\t' -v cur="$cur" '$1 == cur {print $2; exit}' "$dir/.schema_priority_up") ;;
    down) next=$(awk -F'\t' -v cur="$cur" '$1 == cur {print $2; exit}' "$dir/.schema_priority_down") ;;
  esac
  [ -z "$next" ] && exit 0
fi
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
while IFS='	' read -r qname qargs || [ -n "$qname" ]; do
  n=$((n + 1))
  list="$list$(printf '%d\t%s\t%s\n' "$n" "$qname" "$qargs")"$'\n'
done < "$dir/.queries"
[ -z "$list" ] && exit 0
selected=$(printf '%s' "$list" | fzf --reverse --prompt 'query: ' \
  --delimiter '\t' --with-nth '1,2' \
  --header 'Enter apply · Esc cancel' \
  --bind 'j:down,k:up,ctrl-j:page-down,ctrl-k:page-up')
[ -z "$selected" ] && exit 0
num=$(echo "$selected" | cut -f1)
echo "$num" > "$dir/.f_pick"
ENDQP
    chmod +x "$_nn_dir/querypick.sh"

    # Preview helper script (file content + links + backlinks)
    _nn_write_preview "$_nn_dir/preview.sh"

    # Faceted filter helper script
    cat > "$_nn_dir/filter.sh" << 'ENDFILTER'
#!/usr/bin/env bash
dir="$1"; action="$2"
cycle() {
  local dim="$1" direction="$2" cur="$3"
  local -a vals
  case "$dim" in
    type)     mapfile -t vals < "$dir/.schema_type_values"; vals=("" "${vals[@]}") ;;
    status)   mapfile -t vals < "$dir/.schema_status_filter_cycle"; vals=("" "${vals[@]}") ;;
    priority)
      if [ "$(cat "$dir/.schema_priority_enabled")" = "false" ]; then vals=(""); else
        mapfile -t vals < "$dir/.schema_priority_filter_cycle"; vals=("" "${vals[@]}" "none")
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
  ft=""; fs=""; fp=""; fname=""; : > "$dir/.f_tags"; : > "$dir/.f_name"
  for a in $args; do
    case "$a" in
      type=*) ft="${a#*=}";; status=*) fs="${a#*=}";;
      priority=*) fp="${a#*=}";; tag=*) echo "${a#*=}" >> "$dir/.f_tags";;
    esac
  done
  echo "$name" > "$dir/.f_sq"
}
ft=$(cat "$dir/.f_type"); fs=$(cat "$dir/.f_status")
fp=$(cat "$dir/.f_priority")
fsort=$(cat "$dir/.f_sort"); fsort_rev=$(cat "$dir/.f_sort_rev" 2>/dev/null); fgroup=$(cat "$dir/.f_group")
farchive=$(cat "$dir/.f_archive"); fmatch=$(cat "$dir/.f_match")
fname=$(cat "$dir/.f_name" 2>/dev/null)
fwrap=$(cat "$dir/.f_wrap" 2>/dev/null)
fwrap_was="$fwrap"
# Pinned items: when an action (priority bump, status cycle) causes an item
# to no longer match active filters, it stays visible at the top of the list
# (marked "pinned" in bold red). Pins are cleared on any filter change
# (type/status/priority/tag/query/reset) but kept on refresh (which runs
# after actions). action.sh overwrites .pinned each time, so only the latest
# acted-on items stay pinned.
case "$action" in refresh) ;; *) : > "$dir/.pinned" ;; esac
case "$action" in
  type)     ft=$(cycle type next "$ft"); : > "$dir/.f_sq" ;;
  status)   fs=$(cycle status next "$fs"); : > "$dir/.f_sq" ;;
  priority) fp=$(cycle priority next "$fp"); : > "$dir/.f_sq" ;;
  sort)     fsort=$(cycle sort next "$fsort"); fsort_rev="" ;;
  sort-reverse) [ -n "$fsort_rev" ] && fsort_rev="" || fsort_rev="rev" ;;
  clear-type) ft=""; : > "$dir/.f_sq" ;;
  clear-status) fs=""; : > "$dir/.f_sq" ;;
  clear-priority) fp=""; : > "$dir/.f_sq" ;;
  clear-sort) IFS= read -r fsort < "$dir/.schema_defaults"; fsort_rev="" ;;
  next|prev)  # [/]: cycle through query presets
    if [ -f "$dir/.queries" ]; then
      total=$(wc -l < "$dir/.queries")
      if [ "$total" -gt 0 ]; then
        cur_sq=$(cat "$dir/.f_sq" 2>/dev/null)
        cur_idx=0  # 0 = no query selected (show all)
        if [ -n "$cur_sq" ]; then
          n=0
          while IFS='	' read -r qn _ || [ -n "$qn" ]; do
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
          ft=""; fs=""; fp=""; fname=""; : > "$dir/.f_tags"; : > "$dir/.f_sq"; : > "$dir/.f_name"
        else
          apply_sq "$cur_idx"
        fi
      fi
    fi ;;
  sq*) apply_sq "${action#sq}" ;;
  pick) [ -f "$dir/.f_pick" ] && apply_sq "$(cat "$dir/.f_pick")" && rm -f "$dir/.f_pick" ;;
  reset) ft=""; fs=""; fp=""; fmatch=""; fname=""; : > "$dir/.f_tags"; : > "$dir/.f_sq"; : > "$dir/.f_match"; : > "$dir/.f_match_paths"; : > "$dir/.f_name"
    { IFS= read -r fsort; IFS= read -r fgroup; IFS= read -r _a; IFS= read -r _sr; IFS= read -r _w; } < "$dir/.schema_defaults"
    [ "$_a" = "true" ] && farchive="show" || farchive=""
    [ "$_sr" = "true" ] && fsort_rev="rev" || fsort_rev=""
    echo "$fsort_rev" > "$dir/.f_sort_rev"
    [ "$_w" = "true" ] && fwrap="on" || fwrap=""
    echo "$fwrap" > "$dir/.f_wrap" ;;
  clear-tags) : > "$dir/.f_tags" ;;
  clear-match) fmatch=""; : > "$dir/.f_match"; : > "$dir/.f_match_paths" ;;
  group) fgroup=$(cycle group next "$fgroup") ;;
  clear-group) fgroup="" ;;
  archive) [ -n "$farchive" ] && farchive="" || farchive="show" ;;
  refresh) ;;  # just re-apply filters (after tag picker)
esac
echo "$ft" > "$dir/.f_type"; echo "$fs" > "$dir/.f_status"
echo "$fp" > "$dir/.f_priority"
echo "$fsort" > "$dir/.f_sort"; echo "$fsort_rev" > "$dir/.f_sort_rev"; echo "$fgroup" > "$dir/.f_group"
echo "$farchive" > "$dir/.f_archive"
echo "$fmatch" > "$dir/.f_match"
printf '%s\n' "$fname" > "$dir/.f_name"
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
  while IFS= read -r tag || [ -n "$tag" ]; do
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
# Name filter (case-insensitive title substring match)
if [ -n "$fname" ]; then
  cond="$cond && index(tolower(\$5), tolower(\"$(awk_esc "$fname")\"))"
fi
# Sort .raw before filtering
do_sort() {
  local _rev=""
  [ -n "$fsort_rev" ] && _rev=yes
  case "$1" in
    priority)
      local unset_pos; unset_pos=$(cat "$dir/.schema_priority_unset_pos")
      local placeholder=9; [ "$unset_pos" = "first" ] && placeholder=0
      local _pdir=n; [ -n "$_rev" ] && _pdir=nr
      awk -F'\t' -v p="$placeholder" 'BEGIN{OFS=FS}{if($3=="")$3=p;print}' | sort -t'	' -k3,3${_pdir} -s | awk -F'\t' -v p="$placeholder" 'BEGIN{OFS=FS}{if($3==p)$3="";print}' ;;
    modified) if [ -n "$_rev" ]; then sort -t'	' -k7,7 -s; else sort -t'	' -k7,7r -s; fi ;;
    created)  if [ -n "$_rev" ]; then sort -t'	' -k8,8 -s; else sort -t'	' -k8,8r -s; fi ;;
    title)    if [ -n "$_rev" ]; then sort -t'	' -k5,5r -s; else sort -t'	' -k5,5 -s; fi ;;
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
# Pipeline: AWK filter → count → grouping → empty-view → pinning → border/output
# INVARIANT: pinning is the LAST transformation of .current, so nothing can drop pinned items.
count=$(awk 'END{print NR}' "$dir/.current")
# Grouping post-processing: insert separator headers between groups
if [ -n "$fgroup" ]; then
  case "$fgroup" in type) gcol=1 ;; status) gcol=2 ;; esac
  awk -F'\t' -v gcol="$gcol" '
    NR==FNR { key[$6] = $gcol; next }
    { path=$1; gk=key[path]; print gk "\t" $0 }
  ' "$dir/.raw" "$dir/.current" \
  | sort -t'	' -k1,1 -s \
  | awk -F'\t' -v gmode="$fgroup" \
    -v type_order="$(cat "$dir/.schema_type_order")" \
    -v status_order="$(cat "$dir/.schema_status_order")" '
    { gk=$1; sub(/^[^\t]*\t/, "")
      counts[gk]++; lines[gk] = lines[gk] $0 "\n"
    } END {
      if (gmode == "status")
        n = split(status_order, order, " ")
      else
        n = split(type_order, order, " ")
      '"$(cat "$dir/.schema_icon_setup")"'
      for (i=1; i<=n; i++) {
        g = order[i]
        if (!(g in counts)) continue
        printed[g] = 1
        ic = (g in icon) ? icon[g] " " : ""
        printf "\t\033[90;1m── %s%s (%d) ──\033[0m\n", ic, g, counts[g]
        printf "%s", lines[g]
      }
      for (g in counts) {
        if (g in printed) continue
        label = (g == "") ? "(none)" : g
        printf "\t\033[90;1m── %s (%d) ──\033[0m\n", label, counts[g]
        printf "%s", lines[g]
      }
    }' > "$dir/.current.tmp" && mv "$dir/.current.tmp" "$dir/.current"
fi
# Compute inline stats from filtered set
awk_stats=$(cat "$dir/.awk_color_stats")
stats_s=$(awk -F'\t' "${cond}${awk_stats}" "$_raw_input")
# Header line 1: filter state
fmt_dim() {
  local key="$1" val="$2" label suffix ic=""
  if [ "$key" = "p" ] && [ -n "$val" ]; then
    if [ "$val" = "none" ]; then label="<unset>"
    else
      label=$(awk -F'\t' -v v="$val" '$1 == v {print $2; exit}' "$dir/.schema_priority_labels")
      [ -z "$label" ] && label="P$val"
    fi
  elif [ "$key" = "t" ] && [ -n "$val" ]; then
    ic=$(awk -F'\t' -v v="$val" '$1 == v {printf "%s ", $2; exit}' "$dir/.schema_type_icons")
    label="${ic}${val}"
  else label="${val:-all}"; fi
  case "$key" in t) suffix="ype";; s) suffix="tatus";; p) suffix="riority";; *) suffix="";; esac
  if [ -n "$val" ]; then
    # Filter active: cyan key, bold value
    printf ' \033[36m[\033[1;36m%s\033[0;36m]%s:\033[0m \033[1m%s\033[0m' "$key" "$suffix" "$label"
  else
    # No filter: all dim
    printf ' \033[90m[%s]%s: all\033[0m' "$key" "$suffix"
  fi
}
t_s=$(fmt_dim t "$ft"); s_s=$(fmt_dim s "$fs"); p_s=$(fmt_dim p "$fp")
c_s=$(printf '\033[90m── %d\033[0m' "$count")
# Show active tags in header if any
tag_s=""
if [ -s "$dir/.f_tags" ]; then
  tag_list=$(tr '\n' ' ' < "$dir/.f_tags" | sed 's/ $//')
  tag_s=$(printf ' \033[35m%s\033[0m' "$tag_list")
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
  while IFS='	' read -r qname qargs || [ -n "$qname" ]; do
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
# Filters section: type/status/priority + per-line filter-by options with [f] hint + value
filters_top=$(printf '\033[1;90m Filters:\033[0m%s%s%s %s' "$t_s" "$s_s" "$p_s" "$c_s")
# Each filter-by option: [f] [key] label: value (normal + active variants)
if [ -n "$tag_s" ]; then
  ftags_s=$(printf '       \033[36m[f]\033[0m then \033[36m[t]\033[0mags:%s' "$tag_s")
  ftags_s_active=$(printf '       \033[1;33m[f]\033[0m \033[1;37mthen \033[1;36m[t]\033[1;37mags:%s' "$tag_s")
else
  ftags_s=$(printf '       \033[36m[f]\033[0m then \033[36m[t]\033[0mags: \033[90mnone\033[0m')
  ftags_s_active=$(printf '       \033[1;33m[f]\033[0m \033[1;37mthen \033[1;36m[t]\033[1;37mags: \033[90mnone\033[0m')
fi
if [ -n "$fmatch" ]; then
  fmatch_s=$(printf '       \033[36m[f]\033[0m then \033[36m[c]\033[0montents: \033[1m"%s"\033[0m' "$fmatch")
  fmatch_s_active=$(printf '       \033[1;33m[f]\033[0m \033[1;37mthen \033[1;36m[c]\033[1;37montents: \033[1m"%s"\033[0m' "$fmatch")
else
  fmatch_s=$(printf '       \033[36m[f]\033[0m then \033[36m[c]\033[0montents: \033[90mnone\033[0m')
  fmatch_s_active=$(printf '       \033[1;33m[f]\033[0m \033[1;37mthen \033[1;36m[c]\033[1;37montents: \033[90mnone\033[0m')
fi
if [ -n "$fname" ]; then
  fname_s=$(printf '       \033[36m[f]\033[0m then \033[36m[n]\033[0mame: \033[1m"%s"\033[0m' "$fname")
  fname_s_active=$(printf '       \033[1;33m[f]\033[0m \033[1;37mthen \033[1;36m[n]\033[1;37mame: \033[1m"%s"\033[0m' "$fname")
else
  fname_s=$(printf '       \033[36m[f]\033[0m then \033[36m[n]\033[0mame: \033[90mnone\033[0m')
  fname_s_active=$(printf '       \033[1;33m[f]\033[0m \033[1;37mthen \033[1;36m[n]\033[1;37mame: \033[90mnone\033[0m')
fi
filters_lbl=$(printf '%s\n%s\n%s\n%s' "$filters_top" "$ftags_s" "$fmatch_s" "$fname_s")
filters_lbl_f=$(printf '%s\n%s\n%s\n%s' "$filters_top" "$ftags_s_active" "$fmatch_s_active" "$fname_s_active")
# Display section: per-line [z] options with current value
default_sort=$(head -1 "$dir/.schema_defaults")
sort_hint="$fsort"; [ "$fsort" = "$default_sort" ] && sort_hint="$fsort (default order)"
# Field-aware sort direction description
case "$fsort" in
  modified|created) if [ -n "$fsort_rev" ]; then sort_dir="oldest first"; else sort_dir="newest first"; fi ;;
  title)            if [ -n "$fsort_rev" ]; then sort_dir="Z–A"; else sort_dir="A–Z"; fi ;;
  priority)         if [ -n "$fsort_rev" ]; then sort_dir="lowest first"; else sort_dir="highest first"; fi ;;
  *)                sort_dir="" ;;
esac
sort_desc="$sort_hint"; [ -n "$sort_dir" ] && sort_desc="$sort_hint, $sort_dir"
zorder_s=$(printf '       \033[36m[z]\033[0m then \033[36m[o]\033[0mrder-by: \033[1m%s\033[0m' "$sort_desc")
zorder_s_active=$(printf '       \033[1;33m[z]\033[0m \033[1;37mthen \033[1;36m[o]\033[1;37mrder-by: \033[1m%s\033[0m' "$sort_desc")
if [ -n "$fsort_rev" ]; then
  zrev_s=$(printf '       \033[36m[z]\033[0m then \033[36m[r]\033[0meverse: \033[1mon\033[0m')
  zrev_s_active=$(printf '       \033[1;33m[z]\033[0m \033[1;37mthen \033[1;36m[r]\033[1;37meverse: \033[1mon\033[0m')
else
  zrev_s=$(printf '       \033[36m[z]\033[0m then \033[36m[r]\033[0meverse: \033[90moff\033[0m')
  zrev_s_active=$(printf '       \033[1;33m[z]\033[0m \033[1;37mthen \033[1;36m[r]\033[1;37meverse: \033[90moff\033[0m')
fi
if [ -n "$fgroup" ]; then
  zgroup_s=$(printf '       \033[36m[z]\033[0m then \033[36m[g]\033[0mroup-by: \033[1m%s\033[0m' "$fgroup")
  zgroup_s_active=$(printf '       \033[1;33m[z]\033[0m \033[1;37mthen \033[1;36m[g]\033[1;37mroup-by: \033[1m%s\033[0m' "$fgroup")
else
  zgroup_s=$(printf '       \033[36m[z]\033[0m then \033[36m[g]\033[0mroup-by: \033[90mnone\033[0m')
  zgroup_s_active=$(printf '       \033[1;33m[z]\033[0m \033[1;37mthen \033[1;36m[g]\033[1;37mroup-by: \033[90mnone\033[0m')
fi
archive_label=$(cat "$dir/.schema_archive_label")
if [ -n "$farchive" ]; then
  zarchive_s=$(printf '       \033[36m[z]\033[0m then \033[36m[h]\033[0midden: \033[1mshowing %s\033[0m' "$archive_label")
  zarchive_s_active=$(printf '       \033[1;33m[z]\033[0m \033[1;37mthen \033[1;36m[h]\033[1;37midden: \033[1mshowing %s\033[0m' "$archive_label")
else
  zarchive_s=$(printf '       \033[36m[z]\033[0m then \033[36m[h]\033[0midden: \033[90mhiding %s\033[0m' "$archive_label")
  zarchive_s_active=$(printf '       \033[1;33m[z]\033[0m \033[1;37mthen \033[1;36m[h]\033[1;37midden: \033[90mhiding %s\033[0m' "$archive_label")
fi
if [ -n "$fwrap" ]; then
  zwrap_s=$(printf '       \033[36m[z]\033[0m then \033[36m[w]\033[0mrap preview: \033[1mon\033[0m')
  zwrap_s_active=$(printf '       \033[1;33m[z]\033[0m \033[1;37mthen \033[1;36m[w]\033[1;37mrap preview: \033[1mon\033[0m')
else
  zwrap_s=$(printf '       \033[36m[z]\033[0m then \033[36m[w]\033[0mrap preview: \033[90moff\033[0m')
  zwrap_s_active=$(printf '       \033[1;33m[z]\033[0m \033[1;37mthen \033[1;36m[w]\033[1;37mrap preview: \033[90moff\033[0m')
fi
display_lbl=$(printf '\033[1;90m Display:\033[0m\n%s\n%s\n%s\n%s\n%s' "$zorder_s" "$zrev_s" "$zgroup_s" "$zarchive_s" "$zwrap_s")
display_lbl_z=$(printf '\033[1;90m Display:\033[0m\n%s\n%s\n%s\n%s\n%s' "$zorder_s_active" "$zrev_s_active" "$zgroup_s_active" "$zarchive_s_active" "$zwrap_s_active")
queries_lbl=$(printf '\033[1;90m Query presets:\033[0m %s' "$sq_lines")
presets_hint=$(printf '\033[90m          \033[36mtab\033[90m/\033[36mshift-tab\033[90m ←→ next/prev  \033[36m[0-9]\033[90m jump to preset \033[90m·\033[0m \033[36m[g]\033[90m pick preset\033[0m')
actions_lbl=$(printf '\033[1;90m Actions:\033[0m \033[36m[a]\033[0mdvance status \033[90m·\033[0m \033[36m[A]\033[0m reverse advance \033[90m·\033[0m \033[36m+\033[0m/\033[36m-\033[0m pri \033[90m(alt: </>)\033[0m \033[90m·\033[0m \033[36m[e]\033[0mdit \033[90m·\033[0m \033[36m[n]\033[0mew \033[90m·\033[0m \033[36m[b]\033[0mulk edit')
change_lbl=$(printf '\033[1;90m Change:\033[0m \033[36m[c]\033[0m then \033[36m[s]\033[0mtatus \033[90m·\033[0m \033[36m[p]\033[0mriority \033[90m·\033[0m \033[36m[t]\033[0mype')
change_lbl_active=$(printf '\033[1;90m Change:\033[0m \033[1;33m[c]\033[0m \033[1;37mthen \033[1;36m[s]\033[1;37mtatus \033[90m·\033[0m \033[1;36m[p]\033[1;37mriority \033[90m·\033[0m \033[1;36m[t]\033[1;37mype\033[0m')
keys_lbl=$(printf '\033[1;90m Keys:\033[0m \033[36m[enter]\033[0m open note \033[90m·\033[0m \033[36m[R]\033[0meset everything \033[90m·\033[0m \033[36m[q]\033[0muit')
stats_lbl=$(printf '\033[1;90m Results:\033[0m %s' "$stats_s")
printf '%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s' "$queries_lbl" "$presets_hint" "$filters_lbl" "$stats_lbl" "$display_lbl" "$actions_lbl" "$change_lbl" "$keys_lbl" > "$dir/.header"
printf '%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s' "$queries_lbl" "$presets_hint" "$filters_lbl" "$stats_lbl" "$display_lbl" "$actions_lbl" "$change_lbl_active" "$keys_lbl" > "$dir/.header-c"
printf '%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s' "$queries_lbl" "$presets_hint" "$filters_lbl_f" "$stats_lbl" "$display_lbl" "$actions_lbl" "$change_lbl" "$keys_lbl" > "$dir/.header-f"
printf '%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s' "$queries_lbl" "$presets_hint" "$filters_lbl" "$stats_lbl" "$display_lbl_z" "$actions_lbl" "$change_lbl" "$keys_lbl" > "$dir/.header-z"
# Always write Dylan placeholder for preview when no item is selected
    printf '\n  [34m╭─────────────────────────────────────────────────╮[0m\n  [34m│[0m                                                 [34m│[0m\n  [34m│[0m                                                 [34m│[0m\n  [34m│[0m                [35m♩[0m [1;36m♪[0m [32m♫[0m [36m♩[0m [35m♪[0m [31m♫[0m [32m♩[0m [1;36m♪[0m [35m♩[0m                [34m│[0m\n  [34m│[0m                                                 [34m│[0m\n  [34m│[0m    ───────────────────────────────────────────  [34m│[0m\n  [34m│[0m                                                 [34m│[0m\n  [34m│[0m    [3;37mHow many notes must a man write down,[0m        [34m│[0m\n  [34m│[0m    [3;37mbefore vim comes to a crawl?[0m                 [34m│[0m\n  [34m│[0m                                                 [34m│[0m\n  [34m│[0m    [3;37mHow many thoughts can a man jot down,[0m        [34m│[0m\n  [34m│[0m    [3;37mbefore they turn to a scrawl?[0m                [34m│[0m\n  [34m│[0m                                                 [34m│[0m\n  [34m│[0m    [1;33mThe answer, my friend, can save us all.[0m      [34m│[0m\n  [34m│[0m                                                 [34m│[0m\n  [34m│[0m    [3;37mHow many notes must a man write down,[0m        [34m│[0m\n  [34m│[0m    [3;37mbefore we call vim unprepared?[0m               [34m│[0m\n  [34m│[0m                                                 [34m│[0m\n  [34m│[0m    [3;37mHow many thoughts can a man jot down,[0m        [34m│[0m\n  [34m│[0m    [3;37mbefore adrift he'\''s declared?[0m                 [34m│[0m\n  [34m│[0m                                                 [34m│[0m\n  [34m│[0m    [1;33mThe answer, my friend, is simply [1;31mn²[0m[1;33m.[0m         [34m│[0m\n  [34m│[0m                                                 [34m│[0m\n  [34m│[0m    [3;37mHow many notes must a man write down,[0m        [34m│[0m\n  [34m│[0m    [3;37mbefore dear vim hits a wall?[0m                 [34m│[0m\n  [34m│[0m                                                 [34m│[0m\n  [34m│[0m    [1;33mThe answer, my friend, is [1;31mnn[0m[1;33m, after all.[0m     [34m│[0m\n  [34m│[0m                                                 [34m│[0m\n  [34m│[0m                                                 [34m│[0m\n  [34m│[0m            [35m♩[0m                                    [34m│[0m\n  [34m│[0m                                                 [34m│[0m\n  [34m│[0m                      [36m♪[0m                          [34m│[0m\n  [34m│[0m                                                 [34m│[0m\n  [34m│[0m         [35m♫[0m                                       [34m│[0m\n  [34m│[0m                                                 [34m│[0m\n  [34m│[0m                   [32m♩[0m                             [34m│[0m\n  [34m│[0m                                                 [34m│[0m\n  [34m│[0m                                                 [34m│[0m\n  [34m│[0m                                                 [34m│[0m\n  [34m╰─────────────────────────────────────────────────╯[0m\n' > "$dir/.empty_placeholder"
[ -f "$dir/.empty_easteregg_override" ] && cat "$dir/.empty_easteregg_override" > "$dir/.empty_placeholder"
# Show Adams placeholder + dummy entry when view is truly empty (skip if pinned items present)
if [ "$count" -eq 0 ] && [ ! -s "$dir/.pinned" ]; then
  raw_total=$(awk -F'\t' 'length($1) > 0' "$dir/.raw" | wc -l)
  if [ "$raw_total" -eq 0 ]; then
    printf '\n  [90m╭─────────────────────────────────────────────────╮[0m\n  [90m│[0m                                                 [90m│[0m\n  [90m│[0m                                                 [90m│[0m\n  [90m│[0m                   [1;33mDON'\''T PANIC[0m                   [90m│[0m\n  [90m│[0m                                                 [90m│[0m\n  [90m│[0m    ───────────────────────────────────────────  [90m│[0m\n  [90m│[0m                                                 [90m│[0m\n  [90m│[0m    No notes here – yet.                         [90m│[0m\n  [90m│[0m    Press [36mn[0m to create your first note.           [90m│[0m\n  [90m│[0m                                                 [90m│[0m\n  [90m│[0m                                                 [90m│[0m\n  [90m│[0m                                                 [90m│[0m\n  [90m│[0m              [31m·[0m       [35m✦[0m                          [90m│[0m\n  [90m│[0m                                                 [90m│[0m\n  [90m│[0m         [36m✦[0m                [32m·[0m                      [90m│[0m\n  [90m│[0m                                                 [90m│[0m\n  [90m│[0m                  [1;37m·[0m                              [90m│[0m\n  [90m│[0m                                                 [90m│[0m\n  [90m│[0m             [35m✦[0m            [34m·[0m                      [90m│[0m\n  [90m│[0m                                                 [90m│[0m\n  [90m│[0m                                                 [90m│[0m\n  [90m│[0m                                                 [90m│[0m\n  [90m│[0m    [37mTip: check out the keybinding[0m                [90m│[0m\n  [90m│[0m    [37mindications on the footer, and[0m               [90m│[0m\n  [90m│[0m    [37mhappy note-taking![0m                           [90m│[0m\n  [90m│[0m                                                 [90m│[0m\n  [90m│[0m                                                 [90m│[0m\n  [90m╰─────────────────────────────────────────────────╯[0m\n' > "$dir/.empty_placeholder"
  fi
  printf '%s\t\033[90m  ~\033[0m\n' "$dir/.empty_placeholder" > "$dir/.current"
fi
# Prepend pinned items (from actions) that got filtered out
# This runs LAST so no subsequent stage can overwrite pinned items.
if [ -s "$dir/.pinned" ]; then
  pinned_lines=""
  pinned_awk=$(cat "$dir/.awk_color_pinned")
  while IFS= read -r pin || [ -n "$pin" ]; do
    [ -z "$pin" ] && continue
    awk -F'\t' -v p="$pin" '$1==p{found=1;exit} END{exit !found}' "$dir/.current" && continue
    # Render the pinned item from .raw with a dim marker
    line=$(TZ=UTC awk -F'\t' -v p="$pin" -v now="$now" "\$6 == p { ${pinned_awk} }" "$dir/.raw")
    [ -n "$line" ] && pinned_lines="${pinned_lines}${line}\n"
  done < "$dir/.pinned"
  if [ -n "$pinned_lines" ]; then
    printf '%b' "$pinned_lines" | cat - "$dir/.current" > "$dir/.current.tmp" && mv "$dir/.current.tmp" "$dir/.current"
  fi
fi
total=$(awk -F'\t' 'length($1) > 0' "$dir/.raw" | wc -l)
last_action=""; [ -s "$dir/.last_action" ] && { last_action=" · last change: $(cat "$dir/.last_action")"; : > "$dir/.last_action"; }
printf ' nn · %d/%d%s ' "$count" "$total" "$last_action" > "$dir/.border"
[ "$fwrap_was" != "$fwrap" ] && printf 'toggle-wrap+'
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

    # Mode file: empty = command mode, "c" = change, "f" = filter-by, "z" = display
    : > "$_nn_dir/.nn-mode"

    # Wrap toggle helper: toggles .f_wrap state, outputs toggle-wrap+filter refresh
    cat > "$_nn_dir/wrapkey.sh" << 'ENDWK'
#!/bin/sh
dir="$1"; prompt="$2"
m=$(cat "$dir/.nn-mode" 2>/dev/null)
if test "$m" = z; then
  : > "$dir/.nn-mode"
  if test -n "$(cat "$dir/.f_wrap" 2>/dev/null)"; then : > "$dir/.f_wrap"; else echo on > "$dir/.f_wrap"; fi
  printf 'change-prompt(%s)+toggle-wrap+' "$prompt"
  "$dir/filter.sh" "$dir" refresh
fi
ENDWK
    chmod +x "$_nn_dir/wrapkey.sh"

    # Editor helper: isolates editor command from fzf binding syntax
    cat > "$_nn_dir/edit.sh" << 'ENDEDIT'
#!/usr/bin/env bash
dir=$(dirname "$0")
nn_editor=$(cat "$dir/.schema_editor" 2>/dev/null)
target=$(cat "$dir/.edit_target" 2>/dev/null)
[ -f "$target" ] && ${nn_editor:-vi} "$target"
ENDEDIT
    chmod +x "$_nn_dir/edit.sh"

    local _nn_fzf_wrap=()
    [[ "$NN_DEFAULT_WRAP" == "true" ]] && _nn_fzf_wrap=(--wrap)

    fzf --ansi --delimiter $'\t' --with-nth 2.. < "$_nn_dir/.current" \
      --header '' --header-first \
      --border rounded \
      --border-label "$(cat "$_nn_dir/.border")" \
      --border-label-pos bottom \
      --preview "$_nn_dir/preview.sh {1}" \
      --prompt "$NN_UI_COMMAND_PROMPT" \
      "${_nn_fzf_wrap[@]}" \
      --bind "t:transform[m=\$(cat $_nn_dir/.nn-mode); if test \"\$m\" = f; then : > $_nn_dir/.nn-mode; echo 'change-prompt($NN_UI_COMMAND_PROMPT)+execute($_nn_dir/tags.sh $_nn_dir)+transform($_nn_dir/filter.sh $_nn_dir refresh)'; elif test \"\$m\" = c; then : > $_nn_dir/.nn-mode; printf '%s\n' {+1} > $_nn_dir/.c_sel; echo 'change-prompt($NN_UI_COMMAND_PROMPT)+execute($_nn_dir/bulkset.sh $_nn_dir type)+reload(cat $_nn_dir/.current)+transform-header(cat $_nn_dir/.header)+deselect-all'; elif test -z \"\$m\"; then $_nn_dir/filter.sh $_nn_dir type; fi]" \
      --bind "T:transform[m=\$(cat $_nn_dir/.nn-mode); if test -z \"\$m\"; then $_nn_dir/filter.sh $_nn_dir clear-type; fi]" \
      --bind "s:transform[m=\$(cat $_nn_dir/.nn-mode); if test \"\$m\" = c; then : > $_nn_dir/.nn-mode; printf '%s\n' {+1} > $_nn_dir/.c_sel; echo 'change-prompt($NN_UI_COMMAND_PROMPT)+execute($_nn_dir/bulkset.sh $_nn_dir status)+reload(cat $_nn_dir/.current)+transform-header(cat $_nn_dir/.header)+deselect-all'; elif test -z \"\$m\"; then $_nn_dir/filter.sh $_nn_dir status; fi]" \
      --bind "S:transform[m=\$(cat $_nn_dir/.nn-mode); if test -z \"\$m\"; then $_nn_dir/filter.sh $_nn_dir clear-status; fi]" \
      --bind "p:transform[m=\$(cat $_nn_dir/.nn-mode); if test \"\$m\" = c; then : > $_nn_dir/.nn-mode; printf '%s\n' {+1} > $_nn_dir/.c_sel; echo 'change-prompt($NN_UI_COMMAND_PROMPT)+execute($_nn_dir/bulkset.sh $_nn_dir priority)+reload(cat $_nn_dir/.current)+transform-header(cat $_nn_dir/.header)+deselect-all'; elif test -z \"\$m\"; then $_nn_dir/filter.sh $_nn_dir priority; fi]" \
      --bind "P:transform[m=\$(cat $_nn_dir/.nn-mode); if test -z \"\$m\"; then $_nn_dir/filter.sh $_nn_dir clear-priority; fi]" \
      --bind "]:transform[m=\$(cat $_nn_dir/.nn-mode); if test -z \"\$m\"; then $_nn_dir/filter.sh $_nn_dir next; fi]" \
      --bind "[:transform[m=\$(cat $_nn_dir/.nn-mode); if test -z \"\$m\"; then $_nn_dir/filter.sh $_nn_dir prev; fi]" \
      --bind "h:transform[m=\$(cat $_nn_dir/.nn-mode); if test \"\$m\" = z; then : > $_nn_dir/.nn-mode; printf 'change-prompt($NN_UI_COMMAND_PROMPT)+'; $_nn_dir/filter.sh $_nn_dir archive; fi]" \
      --bind "1:transform[m=\$(cat $_nn_dir/.nn-mode); if test -z \"\$m\"; then $_nn_dir/filter.sh $_nn_dir sq1; fi]" \
      --bind "2:transform[m=\$(cat $_nn_dir/.nn-mode); if test -z \"\$m\"; then $_nn_dir/filter.sh $_nn_dir sq2; fi]" \
      --bind "3:transform[m=\$(cat $_nn_dir/.nn-mode); if test -z \"\$m\"; then $_nn_dir/filter.sh $_nn_dir sq3; fi]" \
      --bind "4:transform[m=\$(cat $_nn_dir/.nn-mode); if test -z \"\$m\"; then $_nn_dir/filter.sh $_nn_dir sq4; fi]" \
      --bind "5:transform[m=\$(cat $_nn_dir/.nn-mode); if test -z \"\$m\"; then $_nn_dir/filter.sh $_nn_dir sq5; fi]" \
      --bind "6:transform[m=\$(cat $_nn_dir/.nn-mode); if test -z \"\$m\"; then $_nn_dir/filter.sh $_nn_dir sq6; fi]" \
      --bind "7:transform[m=\$(cat $_nn_dir/.nn-mode); if test -z \"\$m\"; then $_nn_dir/filter.sh $_nn_dir sq7; fi]" \
      --bind "8:transform[m=\$(cat $_nn_dir/.nn-mode); if test -z \"\$m\"; then $_nn_dir/filter.sh $_nn_dir sq8; fi]" \
      --bind "9:transform[m=\$(cat $_nn_dir/.nn-mode); if test -z \"\$m\"; then $_nn_dir/filter.sh $_nn_dir sq9; fi]" \
      --bind "0:transform[m=\$(cat $_nn_dir/.nn-mode); if test -z \"\$m\"; then $_nn_dir/filter.sh $_nn_dir reset; fi]" \
      --bind "R:transform[m=\$(cat $_nn_dir/.nn-mode); if test -z \"\$m\"; then $_nn_dir/filter.sh $_nn_dir reset; fi]" \
      --bind "g:transform[m=\$(cat $_nn_dir/.nn-mode); if test \"\$m\" = z; then : > $_nn_dir/.nn-mode; printf 'change-prompt($NN_UI_COMMAND_PROMPT)+'; $_nn_dir/filter.sh $_nn_dir group; elif test -z \"\$m\"; then echo 'execute($_nn_dir/querypick.sh $_nn_dir)+transform($_nn_dir/filter.sh $_nn_dir pick)'; fi]" \
      --bind "a:transform[m=\$(cat $_nn_dir/.nn-mode); if test -z \"\$m\"; then $_nn_dir/cyclestatus.sh $_nn_dir {1} fwd; $_nn_dir/reload_at.sh $_nn_dir {1}; fi]" \
      --bind "A:transform[m=\$(cat $_nn_dir/.nn-mode); if test -z \"\$m\"; then $_nn_dir/cyclestatus.sh $_nn_dir {1} rev; $_nn_dir/reload_at.sh $_nn_dir {1}; fi]" \
      --bind "+:transform[m=\$(cat $_nn_dir/.nn-mode); if test -z \"\$m\"; then $_nn_dir/bumppri.sh $_nn_dir {1} $_nn_plus_dir; $_nn_dir/reload_at.sh $_nn_dir {1}; fi]" \
      --bind ">:transform[m=\$(cat $_nn_dir/.nn-mode); if test -z \"\$m\"; then $_nn_dir/bumppri.sh $_nn_dir {1} $_nn_plus_dir; $_nn_dir/reload_at.sh $_nn_dir {1}; fi]" \
      --bind "-:transform[m=\$(cat $_nn_dir/.nn-mode); if test -z \"\$m\"; then $_nn_dir/bumppri.sh $_nn_dir {1} $_nn_minus_dir; $_nn_dir/reload_at.sh $_nn_dir {1}; fi]" \
      --bind "<:transform[m=\$(cat $_nn_dir/.nn-mode); if test -z \"\$m\"; then $_nn_dir/bumppri.sh $_nn_dir {1} $_nn_minus_dir; $_nn_dir/reload_at.sh $_nn_dir {1}; fi]" \
      --bind "n:transform[m=\$(cat $_nn_dir/.nn-mode); if test \"\$m\" = f; then : > $_nn_dir/.nn-mode; echo 'change-prompt($NN_UI_COMMAND_PROMPT)+execute($_nn_dir/namefilt.sh $_nn_dir)+transform($_nn_dir/filter.sh $_nn_dir refresh)'; elif test -z \"\$m\"; then echo 'execute($_nn_dir/newnote.sh $_nn_dir)+transform($_nn_dir/reload_at.sh $_nn_dir)'; fi]" \
      --bind "c:transform[m=\$(cat $_nn_dir/.nn-mode); if test \"\$m\" = f; then : > $_nn_dir/.nn-mode; echo 'change-prompt($NN_UI_COMMAND_PROMPT)+execute($_nn_dir/match.sh $_nn_dir)+transform($_nn_dir/filter.sh $_nn_dir refresh)'; else echo c > $_nn_dir/.nn-mode; echo 'change-prompt(c )+transform-header(cat $_nn_dir/.header-c)'; fi]" \
      --bind "e:transform[m=\$(cat $_nn_dir/.nn-mode); if test -z \"\$m\"; then printf '%s' {1} > $_nn_dir/.edit_target; echo 'execute($_nn_dir/edit.sh)'; fi]" \
      --bind "f:transform[echo f > $_nn_dir/.nn-mode; echo 'change-prompt(f )+transform-header(cat $_nn_dir/.header-f)']" \
      --bind "z:transform[echo z > $_nn_dir/.nn-mode; echo 'change-prompt(z )+transform-header(cat $_nn_dir/.header-z)']" \
      --bind "o:transform[m=\$(cat $_nn_dir/.nn-mode); if test \"\$m\" = z; then : > $_nn_dir/.nn-mode; printf 'change-prompt($NN_UI_COMMAND_PROMPT)+'; $_nn_dir/filter.sh $_nn_dir sort; fi]" \
      --bind "r:transform[m=\$(cat $_nn_dir/.nn-mode); if test \"\$m\" = z; then : > $_nn_dir/.nn-mode; printf 'change-prompt($NN_UI_COMMAND_PROMPT)+'; $_nn_dir/filter.sh $_nn_dir sort-reverse; fi]" \
      --bind "w:transform[$_nn_dir/wrapkey.sh $_nn_dir '$NN_UI_COMMAND_PROMPT']" \
      --multi \
      --bind "b:transform[m=\$(cat $_nn_dir/.nn-mode); if test -z \"\$m\"; then echo 'execute($_nn_dir/bulkedit.sh $_nn_dir)+transform($_nn_dir/reload_at.sh $_nn_dir)+deselect-all'; fi]" \
      --bind "start:transform-header(cat $_nn_dir/.header)" \
      --bind 'j:down,k:up,ctrl-j:page-down,ctrl-k:page-up,space:toggle,q:abort,change:clear-query' \
      --bind "tab:transform[m=\$(cat $_nn_dir/.nn-mode); if test -z \"\$m\"; then $_nn_dir/filter.sh $_nn_dir next; fi]" \
      --bind "shift-tab:transform[m=\$(cat $_nn_dir/.nn-mode); if test -z \"\$m\"; then $_nn_dir/filter.sh $_nn_dir prev; fi]" \
      --bind "esc:transform[m=\$(cat $_nn_dir/.nn-mode); if test -n \"\$m\"; then : > $_nn_dir/.nn-mode; echo 'change-prompt($NN_UI_COMMAND_PROMPT)+transform-header(cat $_nn_dir/.header)'; else echo clear-query; fi]" \
      --bind 'J:preview-page-down,K:preview-page-up' \
      --bind "enter:transform[m=\$(cat $_nn_dir/.nn-mode); if test -z \"\$m\"; then printf '%s' {1} > $_nn_dir/.edit_target; echo 'execute($_nn_dir/edit.sh)'; fi]"
    trap - EXIT
    rm -rf "$_nn_dir"
    shopt -u nullglob
    [[ "$NN_UI_EXIT_MESSAGE" == "fortune" ]] && echo "So long, and thanks for all the notes."
    return
  fi

  # ---- NAMED QUERY ----
  if [[ $# -ge 1 && "$1" != *=* && "$1" != -* && -n "${saved_queries[$1]+x}" ]]; then
    local _nn_qdepth=${_NN_QUERY_DEPTH:-0}
    if (( _nn_qdepth >= 5 )); then
      echo "notenav: query preset recursion too deep (circular reference?)" >&2
      return 1
    fi
    _NN_QUERY_DEPTH=$(( _nn_qdepth + 1 ))
    local saved="$1"; shift
    local _saved_args="${saved_queries[$saved]}"
    shopt -u nullglob
    set -f
    notenav_main $_saved_args "$@"
    set +f
    return
  fi

  # Bare word that isn't a known query preset: warn if it doesn't look like a path
  if [[ $# -ge 1 && "$1" != *=* && "$1" != -* && "$1" != */* && ! -e "$1" ]]; then
    echo "notenav: '$1' is not a query preset" >&2
    if [[ ${#saved_queries[@]} -gt 0 ]]; then
      local _pnames
      printf -v _pnames '%s, ' "${!saved_queries[@]}"
      echo "notenav: available presets: ${_pnames%, }" >&2
    fi
    echo "notenav: run 'nn --help' for usage" >&2
    return 1
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
  [[ -n "${filters[type]}" ]] && awk_cond="$awk_cond && \$1==\"$(_nn_awk_esc "${filters[type]}")\""
  [[ -n "${filters[status]}" ]] && awk_cond="$awk_cond && \$2==\"$(_nn_awk_esc "${filters[status]}")\""
  if [[ "${filters[priority]}" == "none" ]]; then
    awk_cond="$awk_cond && \$3==\"\""
  elif [[ -n "${filters[priority]}" ]]; then
    awk_cond="$awk_cond && \$3==\"$(_nn_awk_esc "${filters[priority]}")\""
  fi
  [[ -n "${filters[tag]}" ]] && awk_cond="$awk_cond && index(\" \" \$4 \" \", \" $(_nn_awk_esc "${filters[tag]}") \") > 0"

  if $interactive; then
    if [[ "${TERM:-dumb}" == "dumb" ]]; then
      echo "notenav: interactive mode requires a terminal (TERM is 'dumb')" >&2
      return 1
    fi
    local nn_tmp; nn_tmp=$(mktemp)
    local _nn_prev; _nn_prev=$(mktemp)
    local _nn_edit; _nn_edit=$(mktemp)
    local _nn_sflag; _nn_sflag=$(mktemp)
    trap 'rm -f "$nn_tmp" "$_nn_prev" "$_nn_edit" "$_nn_edit.editor" "$_nn_sflag"' EXIT
    _nn_write_preview "$_nn_prev"
    printf '%s' "$_nn_editor" > "$_nn_edit.editor"
    printf '#!/usr/bin/env bash\nnn_editor=$(cat "%s" 2>/dev/null)\n[ -f "$1" ] && ${nn_editor:-vi} "$1"\n' "$_nn_edit.editor" > "$_nn_edit"
    chmod +x "$_nn_edit"
    zk list "${zk_args[@]}" --format "$_fmt" --quiet 2>/dev/null \
      | awk -F'\t' "$awk_cond && length(\$1) > 0 $_awk_color" > "$nn_tmp"
    fzf --ansi --delimiter $'\t' --with-nth 2.. < "$nn_tmp" \
          --preview "$_nn_prev {1}" \
          --prompt "$NN_UI_COMMAND_PROMPT" \
          --bind "start:execute-silent(rm -f $_nn_sflag)" \
          --bind 'j:down,k:up,ctrl-j:page-down,ctrl-k:page-up,q:abort,change:clear-query' \
          --bind "/:unbind(j,k,q,change)+change-prompt($NN_UI_SEARCH_PROMPT)+execute-silent(touch $_nn_sflag)" \
          --bind "esc:transform[test -f $_nn_sflag && rm $_nn_sflag && printf 'rebind(j,k,q)+change-prompt($NN_UI_COMMAND_PROMPT)' || printf 'clear-query+rebind(change)']" \
          --bind "::rebind(j,k,q)+change-prompt($NN_UI_COMMAND_PROMPT)+execute-silent(rm -f $_nn_sflag)" \
          --bind 'J:preview-page-down,K:preview-page-up' \
          --bind 'H:toggle-wrap' \
          --bind "enter:execute($_nn_edit {1})"
    rm -f "$nn_tmp" "$_nn_prev" "$_nn_edit" "$_nn_edit.editor" "$_nn_sflag"
    trap - EXIT
  else
    local _adhoc_fmt
    if [[ "$NN_PRIORITY_ENABLED" != "false" ]]; then
      local _adhoc_pl='pl = "P" $3'
      local _v
      for _v in "${NN_PRIORITY_VALUES[@]}"; do
        [[ "${NN_PRIORITY_LABELS[$_v]}" == "P$_v" ]] && continue
        local _esc_label; _esc_label=$(_nn_awk_esc "${NN_PRIORITY_LABELS[$_v]}")
        _adhoc_pl+="; if (\$3 == \"$_v\") pl = \"${_esc_label}\""
      done
      _adhoc_fmt="{ $_adhoc_pl; "'printf "[%s] [%s] [%s] %s\n", $1, pl, $2, $5 }'
    else
      _adhoc_fmt='{printf "[%s] [%s] %s\n", $1, $2, $5}'
    fi
    zk list "${zk_args[@]}" --format "$_fmt" --quiet 2>/dev/null \
      | awk -F'\t' "$awk_cond && length(\$1) > 0 $_adhoc_fmt"
  fi
  shopt -u nullglob
}
