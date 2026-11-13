# Global agent instructions (shared by Claude Code and Codex)

This file is the single source of truth. `install.sh` copies it to
`~/.codex/AGENTS.md` (Codex) and points `~/.claude/CLAUDE.md` at it (Claude Code).
Edit it here, then re-run `./install.sh --config-only`.

## How to weigh these rules
- Hard rules: secrets, confirmations, git, and the project's own privacy, install and security rules. Follow them exactly.
- Everything else is a default. If you are confident another approach is better and at least as safe, use it and say why in one line.

## Working agreement
- If a requirement is unclear and the answer changes what gets built, ask (the code and docs come first).
  Otherwise take the conventional choice and say which one you took.
- Prefer the smallest change that solves the problem. Do not refactor unrelated code.
- Confirm before anything hard to reverse or outward-facing: force-push, deleting data,
  publishing, sending messages, spending money.
- Never commit secrets. Use `.env` files (git-ignored) and commit `.env.example` instead.

## Verification
- Before saying a task is done, run the checks the change can affect (tests, linter, type checker). A docs-only change needs none.
- Report outcomes faithfully. If something failed or was skipped, say so with the output.

## Git
- Work on a feature branch. Never push directly to `main`/`master`.
- Small, focused commits with a clear message. Only commit or push when asked.

## New projects
- When a project is new (empty repo, or no `AGENTS.md`), offer to adopt `~/.codex/templates/` and ask before copying.
  Follow its `README.md`: read the project first, merge instead of overwriting, replace every `[PLACEHOLDER]`,
  and let the owner approve the result.
- Existing projects keep their own `AGENTS.md`; do not apply the templates unasked.

## Tools available (categories; see the repo README for details)
- core: context7 (current library docs, when an API or version may differ from what you know), sequential-thinking, memory;
  plugins ponytail (minimal-code discipline), code-review, codex bridge (Claude Code only), ECC.
- dev: playwright (real Chrome), chrome-devtools (via ECC), token-optimizer, github, vercel.
- design: magic (UI components), ui-ux-pro-max (UI/UX rules), excalidraw (diagrams), design plugin skills.
- agents: ruflo (swarms, orchestration). security: rea (reverse engineering; authorized targets only).
- video / audio: remotion (React video, skill pack), ffmpeg-llm, watch-video, transcribe-so, ElevenLabs.
- docs: pdf, Claude Docs, Google Drive, docx/pdf/pptx/xlsx skills.
- Only use a tool that is actually connected in the current session; do not assume the full list is present.
