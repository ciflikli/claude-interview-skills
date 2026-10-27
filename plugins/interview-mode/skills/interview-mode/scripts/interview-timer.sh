#!/usr/bin/env bash
# Time-boxed session countdown (build phase, then discussion phase). State is per project:
# <project>/.claude/interview-timer, holding "start build_end discuss_end" in epoch seconds.
#   interview-timer.sh start <build_min> <discuss_min>   start now; also records the git base sha
#   interview-timer.sh status    one line for the status line (reads Claude's JSON on stdin)
#   interview-timer.sh hook      context line for UserPromptSubmit (silent when no timer)
#   interview-timer.sh watch     live countdown for a second terminal
#   interview-timer.sh stop
set -u
proj() {
  local d=""
  if [ "${1:-}" = stdin ] && [ ! -t 0 ]; then
    d=$(jq -r '.workspace.project_dir // .cwd // empty' 2>/dev/null)
  fi
  echo "${d:-${CLAUDE_PROJECT_DIR:-$PWD}}"
}
setpaths() { STATE="$1/.claude/interview-timer"; BASE="$1/.claude/session-base"; }

hm() { date -r "$1" +%H:%M 2>/dev/null || date -d "@$1" +%H:%M; }  # BSD/macOS, then GNU
load() { [ -f "$STATE" ] || return 1; read -r START BUILD_END DISC_END < "$STATE"; }

line() {
  load || { echo ""; return; }
  now=$(date +%s)
  if [ "$now" -lt "$BUILD_END" ]; then left=$((BUILD_END - now)); PHASE=BUILD
  elif [ "$now" -lt "$DISC_END" ]; then left=$((DISC_END - now)); PHASE=DISCUSS
  else left=$((now - DISC_END)); PHASE=OVER; fi
  LEFT_MIN=$((left / 60))
  CLOCK=$(printf '%02d:%02d' "$LEFT_MIN" $((left % 60)))
  if [ "$PHASE" = OVER ]; then echo "⏱ OVER +$CLOCK"
  elif [ "$PHASE" = BUILD ]; then m=$(( (left + 59) / 60 )); [ "$m" -eq 1 ] && u=minute || u=minutes; echo "⏱ BUILD $m $u remaining"
  else echo "⏱ $PHASE $CLOCK left"; fi
}

# Build phase only: green >37.5% of build left, orange 12.5-37.5%, red <12.5% (15/5 min of a 40 min build).
colored() {
  out=$(line); [ -n "$out" ] || { echo ""; return; }
  line >/dev/null  # $(...) runs in a subshell; re-run to set PHASE/left here
  if [ "$PHASE" != BUILD ]; then echo "$out"; return; fi
  total=$((BUILD_END - START))
  if [ $((left * 1000)) -gt $((total * 375)) ]; then c='\033[32m'; elif [ $((left * 1000)) -ge $((total * 125)) ]; then c='\033[38;5;208m'; else c='\033[1;91m'; fi
  printf "${c}%s\033[0m\n" "$out"
}

case "${1:-status}" in
  start)
    P=$(proj); setpaths "$P"; mkdir -p "$P/.claude"
    b=${2:-40}; d=${3:-20}; now=$(date +%s)
    echo "$now $((now + b*60)) $((now + b*60 + d*60))" > "$STATE"
    if git -C "$P" rev-parse --git-dir >/dev/null 2>&1; then
      git -C "$P" rev-parse HEAD > "$BASE" 2>/dev/null || rm -f "$BASE"
      ex="$(git -C "$P" rev-parse --git-path info/exclude)"; case "$ex" in /*) ;; *) ex="$P/$ex";; esac
      mkdir -p "$(dirname "$ex")"
      for f in .claude/interview-timer .claude/session-base ".claude/failed-*.patch"; do grep -qxF "$f" "$ex" 2>/dev/null || echo "$f" >> "$ex"; done
    fi
    echo "Timer started: build ${b}m (ends $(hm $((now + b*60)))), discussion ${d}m (ends $(hm $((now + b*60 + d*60))))" ;;
  status) P=$(proj stdin); setpaths "$P"; colored ;;
  hook)
    P=$(proj); setpaths "$P"
    out=$(line); [ -z "$out" ] && exit 0; line >/dev/null
    msg="[interview timer] $out."
    total=$((BUILD_END - START))
    if [ "$PHASE" = BUILD ] && [ $((left * 1000)) -lt $((total * 125)) ]; then
      msg="$msg FREEZE: no new features or Codex runs. Make the current state demo-able, then list cuts."
    elif [ "$PHASE" = BUILD ] && [ $((left * 1000)) -le $((total * 375)) ]; then
      msg="$msg Finish the current slice only; anything not started is a 'describe, don't build' item."
    elif [ "$PHASE" = DISCUSS ] || [ "$PHASE" = OVER ]; then
      msg="$msg Build is over: no code changes unless asked."
    fi
    echo "$msg" ;;
  watch) P=$(proj); setpaths "$P"; while true; do printf '\r\033[K%s' "$(colored)"; sleep 1; done ;;
  stop) P=$(proj); setpaths "$P"; rm -f "$STATE"; echo "Timer stopped" ;;
  *) echo "usage: interview-timer.sh start|status|hook|watch|stop" >&2; exit 1 ;;
esac
