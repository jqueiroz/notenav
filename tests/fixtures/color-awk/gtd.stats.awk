{ types[$1]++; combos[$1, $2]++ } END {
  n = split("actionprojectreference", order, "\\036")
  icon["action"] = "◆"; clr["action"] = "\033[36m"; icon["project"] = "◈"; clr["project"] = "\033[35m"; icon["reference"] = "▪"; clr["reference"] = "\033[33m"; 
  sc["inbox"] = "\033[33m"; sc["next"] = "\033[32m"; sc["waiting"] = "\033[34m"; sc["someday"] = "\033[90m"; sc["done"] = "\033[90m"; 
  first = 1
  for (o = 1; o <= n; o++) {
    t = order[o]
    if (!(t in types)) continue
    printed[t] = 1
    if (!first) printf " \033[90m·\033[0m "
    first = 0
    tc = (t in clr) ? clr[t] : "\033[36m"
    ic = (t in icon) ? icon[t] : "*"
    tl = t; if (types[t] != 1) { if (match(t, /(s|x|z|ch|sh)$/)) tl = t "es"; else if (match(t, /[^aeiou]y$/)) tl = substr(t, 1, length(t)-1) "ies"; else tl = t "s" }
    printf "%s%s %d %s\033[0m", tc, ic, types[t], tl
    printf " ("
    sn = split("inboxnextwaitingsomedaydone", statuses, "\\036")
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
  unknown = 0
  for (t in types) { if (t != "" && !(t in printed)) unknown += types[t] }
  if (unknown > 0) {
    if (!first) printf " \033[90m·\033[0m "
    first = 0
    printf "\033[90m· %d unknown\033[0m", unknown
  }
  if ("" in types) {
    if (!first) printf " \033[90m·\033[0m "
    printf "\033[90m· %d untyped\033[0m", types[""]
  }
}