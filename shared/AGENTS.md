# Global agent instructions (shared by Claude Code and Codex)

This file is the single source of truth. `install.sh` copies it to
`~/.codex/AGENTS.md` (Codex) and points `~/.claude/CLAUDE.md` at it (Claude Code).
Edit it here, then re-run `./install.sh --config-only`.

## Working agreement
- If a requirement is unclear, ask. Do not guess or assume.
- Read the code before changing it. Match the surrounding style, naming and comment density.
- Prefer the smallest change that solves the problem. Do not refactor unrelated code.
- Confirm before anything hard to reverse or outward-facing: force-push, deleting data,
  publishing, sending messages, spending money.
- Never commit secrets. Use `.env` files (git-ignored) and commit `.env.example` instead.

## Verification
- Run the project's tests, linter and type checker before saying a task is done.
- Report outcomes faithfully. If something failed or was skipped, say so with the output.

## Git
- Work on a feature branch. Never push directly to `main`/`master`.
- Small, focused commits with a clear message. Only commit or push when asked.

## Tools available (categories; see the repo README for details)
- core: context7 (current library docs, use instead of memory), sequential-thinking, memory;
  plugins ponytail (minimal-code discipline), code-review, codex bridge (Claude Code only), ECC.
- dev: playwright (real Chrome), chrome-devtools (via ECC), token-optimizer, github, vercel.
- design: magic (UI components), ui-ux-pro-max (UI/UX rules), excalidraw (diagrams), design plugin skills.
- agents: ruflo (swarms, orchestration). security: rea (reverse engineering; authorized targets only).
- video / audio: remotion (React video, skill pack), ffmpeg-llm, watch-video, transcribe-so, ElevenLabs.
- docs: pdf, Claude Docs, Google Drive, docx/pdf/pptx/xlsx skills.
- productivity, jobs, learning, finance: Gmail, Calendar, Slack, AgentMail; Indeed, Dice, ZipRecruiter,
  JobDataLake; Coursera; finance and investment-banking skills.
- Only use a tool that is actually connected in the current session; do not assume the full list is present.
