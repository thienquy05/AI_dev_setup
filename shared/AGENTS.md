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

## Tools available (see the repo README for what each does)
- MCP: context7 (up-to-date library docs), sequential-thinking, memory, playwright (browser),
  magic (UI components), github, pdf.
- Plugins: ponytail (minimal-code discipline), code-review, ECC (optional), codex <-> claude bridge.
- Use context7 for library/API docs instead of relying on memory.
