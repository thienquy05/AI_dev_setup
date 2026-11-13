#!/usr/bin/env bash
# Self-check for check.sh, run-bg.sh and janitor.sh. Runs in a temp git repo; touches nothing else.
# Usage: bash scripts/tests/selfcheck.sh   (exit 0 = all assertions passed)
set -u
here=$(cd "$(dirname "$0")/.." && pwd)
t=$(mktemp -d "${TMPDIR:-/tmp}/selfcheck.XXXXXX") && [ -d "$t" ] || { echo "selfcheck: cannot create a temp dir; refusing to run" >&2; exit 2; }
trap 'rm -rf "$t"' EXIT
fails=0
ok() { echo "ok   $1"; }
no() { echo "FAIL $1"; fails=$((fails + 1)); }
check() { if eval "$2"; then ok "$1"; else no "$1"; fi; }

cd "$t" && git init -q . && mkdir scripts && cp "$here"/*.sh scripts/ && printf '.cache/\n.handoff/\n' >.gitignore

# check.sh
printf '# comment\nfine|true\nbad|echo boom; false\npiped|false | cat\n' >scripts/check.cmds
out=$(scripts/check.sh 2>&1); rc=$?
check "check.sh exits 1 when a check fails"       '[ $rc = 1 ]'
check "check.sh reports PASS for a passing check" 'echo "$out" | grep -q "PASS  fine"'
check "check.sh fails a failing pipeline"         'echo "$out" | grep -q "FAIL  piped"'
check "check.sh shows the failing log tail"       'echo "$out" | grep -q "boom"'
scripts/check.sh fine >/dev/null 2>&1; rc=$?
check "check.sh runs only the named check"        '[ $rc = 0 ]'

# run-bg.sh: a child and a grandchild must both stop
scripts/run-bg.sh srv bash -c 'sleep 300 & sleep 300' >/dev/null
sleep 1
pid=$(awk '$1=="srv"{print $2}' .handoff/procs)
check "run-bg.sh registers the process"           '[ -n "$pid" ] && kill -0 "$pid"'
scripts/run-bg.sh srv true >/dev/null 2>&1; rc=$?
check "run-bg.sh refuses a duplicate name"        '[ $rc = 1 ]'
scripts/run-bg.sh --stop srv >/dev/null
sleep 1
check "run-bg.sh --stop ends the process"         '! kill -0 "$pid" 2>/dev/null'
check "run-bg.sh --stop ends the whole group"     '! kill -0 -- "-$pid" 2>/dev/null'
check "run-bg.sh --stop unregisters"              '! grep -q "^srv " .handoff/procs'

# janitor.sh (repo-only by default: never looks at real processes or containers)
check "etime 05:07 = 307 s"                       '[ "$(scripts/janitor.sh --etime-seconds 05:07)" = 307 ]'
check "etime 01:00:00 = 3600 s"                   '[ "$(scripts/janitor.sh --etime-seconds 01:00:00)" = 3600 ]'
check "etime 2-03:04:05 = 183845 s"               '[ "$(scripts/janitor.sh --etime-seconds 2-03:04:05)" = 183845 ]'
set -m; sleep 300 & orphan=$!; set +m   # own process group, as run-bg.sh does
echo "dev $orphan $orphan $(date +%s) 999999 $t" >>.handoff/procs   # owner 999999: a session that no longer exists
echo note >.handoff/old-note.md; touch -t 202001010000 .handoff/old-note.md
echo note >.handoff/new-note.md
rep=$(scripts/janitor.sh)
check "janitor report lists the old handoff file"  'echo "$rep" | grep -q old-note.md'
check "janitor report flags the ownerless process" 'echo "$rep" | grep -q "dev pid=$orphan: the agent session that started it has ended"'
check "janitor report changes nothing"             '[ -f .handoff/old-note.md ] && kill -0 "$orphan"'
scripts/janitor.sh --apply >/dev/null
sleep 1
check "janitor --apply removes the old file"       '[ ! -f .handoff/old-note.md ]'
check "janitor --apply keeps the new file"         '[ -f .handoff/new-note.md ]'
check "janitor --apply stops the ownerless proc"   '! kill -0 "$orphan" 2>/dev/null'
kill "$orphan" 2>/dev/null

echo; [ $fails = 0 ] && echo "all passed" || { echo "$fails failed"; exit 1; }
