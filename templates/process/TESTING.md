# Testing: automation runs the checks, agents fix the failures

Goal: agents spend their time fixing problems, not watching test output. Deterministic tools run the checks; an agent reads a short summary when they finish.

## 1. The loop

1. Start the checks as a **background task**: `scripts/check.sh` (Claude Code: run it with `run_in_background`; you are notified when it exits). Keep working on something that does not depend on the result.
2. `check.sh` reads `scripts/check.cmds`, runs every check in parallel, keeps each full log in `.cache/check/<name>.log`, and prints only `PASS`/`FAIL` per check plus the last lines of each failing log. Exit code is non-zero if anything failed.
3. When notified, read the summary. Open a full log only for a failing check. Fix, then rerun only that check: `scripts/check.sh <name>`.
4. At the end of a unit of work, run all checks once more. CI runs them again on the PR.

## 2. `scripts/check.cmds`

One check per line, `name|command`, run from the repo root. Fastest checks first. Examples to adapt (keep only what the project has):

```
types|npm run typecheck
lint|npm run lint
unit|npm test
e2e|npm run test:e2e
py-lint|ruff check . && ruff format --check .
py-types|pyright
py-test|pytest -q -n auto
```

Rules:
- A check must return a correct exit code. Never pipe a test command into `tail`/`head`/`grep`; it hides failures (and breaks gates that observe exit codes).
- Each check must be safe to run in parallel with the others (separate ports, temp dirs, databases). If two cannot run together, put them in one line joined with `&&`.
- No check may reach the internet or real user data.

## 3. Speed without agents

| Lever | How |
|---|---|
| Run only what changed while iterating | Single files (`node --test path/to/x.test.ts`, `vitest run path`, `pytest path::test`), `vitest --changed`, `pytest --lf` |
| Parallel inside one machine | Node test runner runs files in parallel processes (`--test-concurrency`); Vitest uses workers; pytest with `pytest-xdist -n auto`; Playwright workers |
| Split across CI jobs | Node `--test-shard=i/n`, Vitest `--shard=i/n`, Playwright `--shard=i/n`, a CI matrix |
| Typecheck and lint first | They are the fastest signal and catch most mistakes before tests run |
| Watch mode for long sessions | `tsc --watch`, `vitest` (watch), writing to a log the agent reads when needed |
| Isolate shared resources | One port, database or schema per parallel worker or worktree; never share a migration target |

## 4. Where agents help
- **Triage, not execution.** When several areas fail, one subagent per failing area reads that area's log and proposes a fix.
- **Flaky tests.** Rerun the single test in isolation 3 times before calling it flaky. Record flakes with the test name and the observed failure in the progress file; do not silently retry in CI.

## 5. Sandbox notes
Some tests cannot run inside the agent sandbox (binding ports, Unix sockets, launching desktop apps, listing processes). Prefer a narrow sandbox allowance in `.claude/settings.json` (for example `sandbox.network.allowLocalBinding`) over running the whole command unsandboxed. Record which checks need it in `check.cmds` comments.
