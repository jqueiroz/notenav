tc = "\033[36m"; ic = "◆"
  if ($1 == "project") { tc = "\033[35m"; ic = "◈" }
  if ($1 == "reference") { tc = "\033[33m"; ic = "▪" }
  if ($1 != "action" && $1 != "project" && $1 != "reference") { tc = "\033[90m"; ic = ($1 == "" ? "·" : "?") }
  pc = "\033[33m"
  if ($3+0 == 1) pc = "\033[31;1m"
  if ($3+0 == 3) pc = "\033[90m"
  pl = "P" $3
  sc = "\033[90m"
  if ($2 == "next") sc = "\033[32m"
  if ($2 == "waiting") sc = "\033[34m"
  if ($2 == "inbox") sc = "\033[33m"
  r = "\033[0m"
  age = ""
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
  age_s = (age != "") ? " \033[90m" age r : ""
  printf "%s\t%s%s %s%s %s%s%s %s%s%s %s%s\n", $6, tc, ic, $1, r, pc, pl, r, sc, $2, r, $5, age_s