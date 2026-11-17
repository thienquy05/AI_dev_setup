# Harness engineering process

A repeatable way to take any project from idea to reviewed, documented code with AI coding agents. Copy this file into a project's `docs/process/` folder; everything specific to one project goes in that project's `docs/PRD.md` and `AGENTS.md`. The agent adapting it may change wording to fit the project; it records what it changed in the progress file.

Companion files: [PRD_TEMPLATE.md](PRD_TEMPLATE.md) (research/ML), [PRD_TEMPLATE_APP.md](PRD_TEMPLATE_APP.md) (applications), [TESTING.md](TESTING.md), [REVIEW.md](REVIEW.md), [SECURITY_GATE.md](SECURITY_GATE.md), [CLEANUP.md](CLEANUP.md).

## 1. Tools and what they do

Install tools from the owner's `AI_dev_setup` repository (https://github.com/thienquy05/AI_dev_setup) or the tool's official repository, with approval. Before relying on a tool, check on the machine that it is installed and which version (`claude plugin list`, `claude mcp list`, `docker ps`).

| Tool | What it is | Notes |
|---|---|---|
| **Claude Code** / **Codex** | Coding agents | One writes, the other reviews; see `REVIEW.md` |
| **harness-os** | Governance MCP server (Docker + Postgres) plus per-project hooks | Tools such as `get_constitution`, `create_spec`, `assess_risk`, `request_review`, `run_workflow`, `record_decision`. Workflows: `new-feature`, `hotfix`, `security-change`. Rules: no gated code without a validated spec; a test observed RED before the code and GREEN after; config files integrity-checked. Needs its containers running (`docker ps` shows `harness_postgres`, `harness_gate_daemon`) |
| **ECC** (Everything Claude Code) | Plugin of agents, skills, commands, hooks | Planning commands (Claude Code only): `/prp-prd` → `/prp-plan` → `/prp-implement`, `/plan` for small work, `spec-miner` agent to extract specs from existing code. Reviewers (`code-reviewer`, `security-reviewer`, language reviewers), `orch-review`, `harness-audit`, GateGuard hooks. Check the installed version has the commands and skills the project relies on |
| **ponytail** | Minimal-code discipline plugin | Never waives tests, security, privacy or accessibility |
| **graphify** | Code knowledge graph | Orient before changing code; output git-ignored |
| **ruflo** | Orchestration and memory | Use only the parts the project enables; data folders git-ignored |
| **Browser tool** (Playwright MCP or the built-in browser) | Drives a real browser | Used for every frontend or full-stack change; use whichever is connected |
| **context7** | Current library documentation | When a library's current API or version may differ from what the agent knows |

## 2. File and naming convention

All documents live in `docs/`. A subfolder is used when several files share a purpose.

| File | Purpose |
|---|---|
| `docs/PRD.md` | Source of truth: what, why, data, evaluation, acceptance checklist |
| `docs/plans/<feature>_plan.md` | Implementation plan derived from the PRD |
| `docs/plans/<feature>_progress.md` | Live status and design decisions, updated after every step |
| `docs/process/` | This process and its companion files |
| `.handoff/` (git-ignored) | Temporary notes between agents; deleted when used |

## 3. The process

Scale the process to the change. A new project or feature runs every step; a small fix runs test → fix → check → review; a docs or config edit runs check only. The security gate (step 8) is never skipped at a phase end.

1. **Interview and PRD.** The agent asks the questions in §6, then drafts `docs/PRD.md` from the right template. Remove sections that do not apply. The agent never guesses: unclear points go to the PRD's open-questions table with a default. With ECC ON in Claude Code, `/prp-prd <idea>` runs the interview and drafts the PRD; ECC saves under `.claude/PRPs/prds/`, so move the result to `docs/PRD.md` and keep the template's sections. Keep a section titled `Implementation Phases` with a status per phase (pending / in progress / complete) so `/prp-plan` can pick the next pending phase. For an existing codebase with no specs, run the `spec-miner` agent first. Codex follows the steps by hand.
2. **Privacy gate.** Before any text leaves the machine (git, another tool, a chat), check it for real names, IDs, dates, paths and data. Use placeholders.
3. **Owner reviews the PRD.** Nothing is implemented until the owner has read and approved it.
4. **Plan.** In a fresh session: read the PRD, explore the codebase, ask clarifying questions, then write `docs/plans/<feature>_plan.md`. Phases come from the PRD's phases section, tests from its testing section. With ECC ON, `/prp-plan docs/PRD.md` does this and captures the codebase patterns to follow; ECC saves under `.claude/PRPs/plans/`, so move the result to `docs/plans/<feature>_plan.md`. For a small change, `/plan <description>` is enough and waits for the owner's confirmation.
5. **Challenge the plan.** An independent reviewer (another model or provider, if the privacy gate allows) looks for holes. Revise and note what changed.
6. **Implement in small steps with a verification loop** (`TESTING.md`). With ECC ON, `/prp-implement docs/plans/<feature>_plan.md` can drive the steps; the rules below (test first, progress file) still apply:
   1. for new behavior or a bug fix, write the test or execution script first and see it fail (RED);
   2. implement the step until it passes (GREEN);
   3. run `scripts/check.sh` in the background and continue; act on its summary;
   4. if results differ from expectations, debug before moving on;
   5. update the progress file with status and every design decision.
7. **Review** (`REVIEW.md`). A fresh-context reviewer reviews the diff against the plan and PRD: correctness, performance, security, privacy. Fix valid findings test-first; re-review the fix.
8. **Security gate** at the end of each phase (`SECURITY_GATE.md`).
9. **Clean up** (`CLEANUP.md`). Stop what you started; run `scripts/janitor.sh`; delete used handoff files.
10. **Finalize.** Update the plan and progress file with what was actually built and why. Commit only when the owner says so.

### The harness pipeline inside step 6

When harness-os governance is active for the project, each unit of work follows its order: **Constitution → Specification → Test Suite → Generate Code → Code Review**, run through `run_workflow` (`new-feature`, `hotfix` or `security-change`). The server advances a stage only when it observes evidence (for example a test run observed failing). Run the configured test command exactly as configured, never piped, so the observed exit code is real.

## 4. Before turning harness-os governance on for a project

`harness init` is a one-time, per-project step. Decide it deliberately:

- It writes `.claude/` (hooks, `settings.json`, `harness.config.json`, `agents/AGENTS.md`) **and makes a git commit**.
- Writes to files matching `gatedGlobs` are blocked until a validated spec covers the file and its test has been seen failing.
- The gate daemon only sees projects under the folder mounted as `HARNESS_PROJECTS_ROOT`; the project must live under it.
- Follow the harness-os `RUNBOOK.md` for machine setup; it uses environment variables, not fixed paths.
- Risk is classified by keywords in the request text and paths; per-project overrides adjust it. Read the rationale of an unexpected level rather than ignoring it.
- Config files are integrity-checked; after a deliberate edit the owner runs `harness reconcile-config <project>`.
- `harness init`, `approve` and `reconcile-config` are the owner's commands (they need a real terminal).

Ask the owner before running `harness init`, and say plainly that it commits.

## 5. Verification loop by project type

| Project part | Loop |
|---|---|
| Backend / library | Typecheck, linter, unit tests, an end-to-end run on synthetic data |
| Frontend / full-stack | A real browser (Playwright MCP or built-in browser): open the page, look at the rendering, check the console and the key flows. Do not infer correctness from code |
| Data / ML (add these) | Leakage tests (no row or group in two folds; scalers fit on training data only), fixed seeds, forbidden-column assertions, baselines next to every model, a reload-and-reproduce test for saved models |

Set these loops up in `scripts/check.cmds` before the agent starts implementing, and run them after every significant change.

## 6. Questions the agent asks at the start of every project

Ask only what the repository, existing docs and the owner's request do not already answer.

**Goal and users**
1. What problem is solved, for whom, and what is the cost of not solving it?
2. What does "done" mean, and who decides?
3. What is explicitly out of scope?

**Data and privacy**
4. What data exists, how much, and what is restricted? What may never appear in git, chats or documents?
5. Where may data be stored and moved?
6. Which names, IDs and dates need placeholders?

**Technical**
7. Language, frameworks, and what must keep working (operating systems, versions, CI)?
8. Where does it run (local, remote machine, cloud), and how is it reached and monitored?
9. How are results and artifacts retrieved and re-used?

**Quality**
10. Which risks matter most (security, correctness, privacy, performance, leakage)?
11. What are the known edge cases and failure modes?
12. What must be tested before code is written?

**Process**
13. Is harness-os governance on for this project (see §4)? Which tools are ON or OFF (`AGENTS.md` §11)?
14. May the agent commit and push, or only when told?
15. Which external review tools are allowed, and on what material?
16. Deadline, reviewers, and the gates where the owner wants to stop and look?

## 7. Master prompt (fill the brackets per project)

```
I want to implement [project/feature]. The PRD is at docs/PRD.md; read it in full first.
It is the source of truth; this prompt sets the process, not the spec.

1. Plan: write docs/plans/[feature]_plan.md. Take phases, tests and "done" from the PRD.
   Ask me clarifying questions before writing it. [ECC ON: use /prp-plan docs/PRD.md and
   move its output from .claude/PRPs/plans/ to docs/plans/.]
2. Implement phase by phase, test-first for new behavior and bug fixes. Run scripts/check.sh
   after each significant change and act on its summary. Record progress and decisions in
   docs/plans/[feature]_progress.md.
3. Frontend: verify in a real browser by looking at what renders.
4. If harness-os governance is on, follow its pipeline and do not skip stages.
5. After each non-trivial unit, have a fresh-context reviewer review the diff
   (docs/process/REVIEW.md).
   Rules in AGENTS.md §3, §4 and the security gate are hard rules. Process and method are
   defaults: if you are confident another approach is better and at least as safe, use it
   and tell me why in one line.
6. End each phase with docs/process/SECURITY_GATE.md.
7. Stop what you started and run scripts/janitor.sh before calling a task done.
8. Do not commit, push or open a pull request unless I ask. Ask me when anything is unclear.

Don't miss these (project-specific): [easy-to-forget requirements]
```

Keep the progress file current throughout; it must always show the real status, not a snapshot from when the plan was written.
