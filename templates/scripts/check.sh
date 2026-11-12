#!/usr/bin/env bash
# Run every check listed in scripts/check.cmds in parallel and print one short summary.
# Usage: scripts/check.sh [name ...]      (no names = all checks)
# check.cmds: one "name|command" per line, run from the repo root; '#' starts a comment.
# Full logs: .cache/check/<name>.log. Exit code: 0 if every selected check passed, 1 otherwise.
# Meant to be started as a background task; read the summary when it finishes (docs/process/TESTING.md).
set -u

root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cmds=${CHECK_CMDS:-$root/scripts/check.cmds}
out=${CHECK_OUT:-$root/.cache/check}
tail_n=${CHECK_TAIL:-30}
[ -f "$cmds" ] || { echo "check.sh: missing $cmds (one 'name|command' per line)" >&2; exit 2; }
mkdir -p "$out"

names=(); pids=(); start=$(date +%s)
trap 'for p in "${pids[@]-}"; do [ -n "$p" ] && kill "$p" 2>/dev/null; done; exit 130' INT TERM

while IFS='|' read -r name cmd; do
  name=$(printf '%s' "$name" | tr -d '[:space:]')
  case "$name" in ''|'#'*) continue ;; esac
  if [ $# -gt 0 ]; then
    want=0; for n in "$@"; do [ "$n" = "$name" ] && want=1; done
    [ $want = 1 ] || continue
  fi
  # pipefail: a failing command inside a pipeline still fails the check.
  (cd "$root" && exec bash -o pipefail -c "$cmd") >"$out/$name.log" 2>&1 &
  names+=("$name"); pids+=("$!")
done <"$cmds"

[ ${#names[@]} -gt 0 ] || { echo "check.sh: no matching checks in $cmds" >&2; exit 2; }

failed=()
for i in "${!pids[@]}"; do
  if wait "${pids[$i]}"; then echo "PASS  ${names[$i]}"; else echo "FAIL  ${names[$i]}"; failed+=("${names[$i]}"); fi
done
echo "-- ${#names[@]} checks, ${#failed[@]} failed, $(( $(date +%s) - start ))s; logs in ${out#"$root"/}/"

for n in "${failed[@]-}"; do
  [ -n "$n" ] || continue
  echo; echo "== $n (last $tail_n lines)"; tail -n "$tail_n" "$out/$n.log"
done
[ ${#failed[@]} -eq 0 ]
