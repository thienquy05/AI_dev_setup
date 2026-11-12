# Cleanup: close what nothing needs

Long-running things that agents start (dev servers, watchers, databases, browsers, MCP servers, containers) often outlive the task. Rule: **if no agent or person needs it, it is closed.** Agents decide; `scripts/janitor.sh` makes it easy and safe.

## 1. Start long-running things through `run-bg.sh`
```
scripts/run-bg.sh <name> <command...>
```
It starts the command in its own process group, writes its log to `.handoff/logs/<name>.log`, and registers `name pid pgid start-time cwd` in `.handoff/procs`. Stop it with `scripts/run-bg.sh --stop <name>` when the task no longer needs it.

## 2. `scripts/janitor.sh`
| Command | Effect |
|---|---|
| `scripts/janitor.sh` | Report only: registered processes, orphaned agent tool trees, orphaned MCP containers, listening ports, old `.handoff/` files, cache sizes, Docker reclaimable space |
| `scripts/janitor.sh --apply` | Also closes: registered processes (whole group), orphaned agent tool trees, orphaned MCP containers, `.handoff/` files older than `JANITOR_HANDOFF_DAYS` (default 2) |

What counts as **orphaned** (never matched by name or port alone, because that can hit your own processes):
- An agent tool process (`app-server-broker`, `codex app-server`, MCP servers) whose parent is PID 1 and older than `JANITOR_ORPHAN_HOURS` (default 2), so its session has ended.
- A container labeled `harness.role=mcp`, or started from an MCP image, whose `docker run` client process is gone.

Never touched: Docker infrastructure without the MCP label, databases and servers not registered through `run-bg.sh`, anything owned by another user, caches.

## 3. When
- **End of a task:** stop what you started (`run-bg.sh --stop`), then `janitor.sh` (report) and close what is clearly yours.
- **Session end:** the `SessionEnd` hook in `.claude/settings.json` starts `janitor.sh --apply` detached (hooks have a very short time budget at session end).
- **Session start:** the `SessionStart` hook runs `janitor.sh` report-only, because a crashed session never runs its end hook.

## 4. Handoffs
Agents exchange notes in git-ignored `.handoff/`. Name each file `<task>-<topic>.md`. Delete it when the receiving agent has acted on it. Never put secrets or personal data in it. The janitor lists files older than the limit.

## 5. Caches and disk
Caches stay inside the repo that uses them (git-ignored). The janitor reports their size; clearing them is the owner's choice. Regenerable large outputs (build output, generated corpora, release bundles) are listed so they can be deleted and rebuilt when needed.
