# Templates

Reusable starting points for any project worked on with AI coding agents (Claude Code, Codex). Everything here is **general**. Nothing names a project, a person, a machine path or a stack choice as a fact. The agent working on a project copies what it needs and adapts it to that project; the owner approves the adapted result.

## What is here

| Path | Use |
|---|---|
| `AGENTS.template.md` | The single instruction file for all agents. Copy to `<repo>/AGENTS.md` and fill it in |
| `CLAUDE.template.md` | One line that makes Claude Code load `AGENTS.md`. Copy to `<repo>/CLAUDE.md` |
| `process/HARNESS_PROCESS.md` | The end-to-end process: interview → PRD → plan → implement → review → finalize |
| `process/PRD_TEMPLATE.md` | PRD outline for research / data / ML work |
| `process/PRD_TEMPLATE_APP.md` | PRD outline for applications (web, desktop, mobile, services) |
| `process/TESTING.md` | Fast verification: automation runs the checks, agents fix the failures |
| `process/REVIEW.md` | Model routing and independent review |
| `process/SECURITY_GATE.md` | Per-phase and pre-production security gate |
| `process/CLEANUP.md` | Closing processes, ports, containers and handoff files that nothing needs |
| `scripts/check.sh` | Runs every configured check in parallel; prints one short summary |
| `scripts/run-bg.sh` | Starts a long-running process and registers it so it can be stopped later |
| `scripts/janitor.sh` | Reports, and on request closes, leftovers |
| `claude/settings.template.json` | Sandbox, permission rules and the cleanup hook for `<repo>/.claude/settings.json` |
| `claude/agents/reviewer.md` | Read-only, fresh-context reviewer subagent for `<repo>/.claude/agents/` |
| `ci/gate.yml`, `ci/security.yml` | GitHub Actions starting points for `<repo>/.github/workflows/` |
| `gitignore.base` | Lines every repo needs for agent-tool state, secrets and caches |

## Starting a new project

1. Create the repository and open it in Claude Code or Codex. An empty folder with `git init` is enough.
2. Paste the kickoff prompt below with the brackets filled in. It adopts the templates, interviews you and drafts the PRD. No feature code is written yet.
3. Read `docs/PRD.md` and answer the open questions. Nothing is built until you approve it.
4. Plan: with ECC on, `/prp-plan docs/PRD.md`; otherwise ask for the plan from the master prompt in `process/HARNESS_PROCESS.md` §7.
5. Build phase by phase with that master prompt. Each phase ends with the review and the security gate.

Kickoff prompt:

```
I am starting a new project: [PROJECT_NAME], [ONE_LINE_PURPOSE], for [USERS].
Templates are at [TEMPLATES_PATH] (the `templates/` folder of the AI_dev_setup repository,
or `~/.codex/templates/` if it is installed).

1. Adopt: read [TEMPLATES_PATH]/README.md and follow "Adopting in a project". Read this repository
   first, ask me before copying anything, merge instead of overwriting. In AGENTS.md §11 set
   these tools ON: [TOOLS_ON]; and OFF: [TOOLS_OFF].
2. Interview: ask me the questions in docs/process/HARNESS_PROCESS.md §6, one block at a time.
   Anything I cannot answer goes into the PRD's open-questions table with a proposed default.
3. PRD: draft docs/PRD.md from [PRD_TEMPLATE_APP.md | PRD_TEMPLATE.md]. [ECC ON: run /prp-prd and
   move its output from .claude/PRPs/prds/ to docs/PRD.md.] Then stop so I can review it.

Known constraints: [STACK_OR_PLATFORM]; [DATA_RESTRICTIONS]; [DEADLINE_OR_NONE].
Don't miss: [EASY_TO_FORGET_REQUIREMENTS].
Do not write feature code. Do not install, commit, push or open a pull request unless I ask.
```

## Adopting in a project (the agent does this, the owner approves)

1. Read the project first: language, test runner, CI, deploy target, what already exists. Do not overwrite existing files; merge.
2. Copy `AGENTS.template.md` → `AGENTS.md` and `CLAUDE.template.md` → `CLAUDE.md`. Replace every `[PLACEHOLDER]`; delete sections that do not apply; set each tool block ON or OFF.
3. Copy `process/` → `docs/process/` (or the project's docs folder). Keep section numbers stable; plans refer to them.
4. Copy `scripts/check.sh`, `scripts/run-bg.sh`, `scripts/janitor.sh`. Write `scripts/check.cmds` for the project's real commands.
5. Merge `claude/settings.template.json` into `.claude/settings.json` and add `claude/agents/reviewer.md` to `.claude/agents/`. Adjust the sandbox entries to what the project actually needs. Only a project that must reach Docker from the sandbox (for example harness-os) adds `"allowUnixSockets": ["[HOME]/.docker/run/docker.sock"]` under `sandbox.network`; the Docker socket is close to root access on the machine.
6. Adapt `ci/*.yml` to the project's stack and copy into `.github/workflows/`. Pin every action to a full commit SHA before use.
7. Append `gitignore.base` to `.gitignore` (skip lines already present).
8. Record what was adopted and what was changed in the project's progress file.

Installing any tool: use the owner's `AI_dev_setup` repository (`./install.sh --list`, then the right category flag) or the tool's official repository, with the owner's approval.

## Rules for editing these templates

- Keep them general. If a rule only makes sense for one project, it belongs in that project's `AGENTS.md` or PRD.
- No real names, account names, absolute home paths, ports or secrets.
- When a project improves a template, bring the improvement back here in general form.
