# AI_dev_setup

One repo to get **Claude Code** and **Codex** (app, CLI, IDE extension) to the same working state on any new machine:
the same plugins, the same MCP servers, the same base settings and one shared `AGENTS.md`.

```bash
git clone https://github.com/thienquy05/AI_dev_setup.git && cd AI_dev_setup
export GITHUB_PERSONAL_ACCESS_TOKEN=ghp_xxx     # optional, enables the github MCP server
./install.sh                                    # Claude Code + Codex, everything
```

The script is idempotent: re-run it any time and it skips what is already installed. Use `--dry-run` first to see every command.

## Contents

- [Prerequisites](#prerequisites)
- [Quick start](#quick-start)
- [What gets installed](#what-gets-installed) (plugins, MCP servers)
- [How it works](#how-it-works)
- [Manual commands, tool by tool](#manual-commands-tool-by-tool)
- [Settings that must be in JSON / TOML](#settings-that-must-be-in-json--toml)
- [Shared AGENTS.md](#shared-agentsmd)
- [Account-synced items (nothing to install)](#account-synced-items-nothing-to-install)
- [Not included on purpose](#not-included-on-purpose)
- [Troubleshooting](#troubleshooting)

## Prerequisites

| Need | Why | Install |
|---|---|---|
| Node.js 18.18+ (`node`, `npx`) | Most MCP servers run through `npx`; the settings merge uses `node` | `brew install node` |
| Claude Code CLI | `claude plugin …`, `claude mcp …` | see https://docs.claude.com/en/docs/claude-code |
| Codex CLI | `codex plugin …`, `codex mcp …`. The Codex **app** and IDE extension read the same `~/.codex/config.toml`, but this script drives the CLI | `npm install -g @openai/codex`, then `codex login` |
| Google Chrome | the `playwright` MCP is launched with `--browser chrome` | `brew install --cask google-chrome` |
| GitHub token (optional) | the `github` MCP server | create a fine-grained PAT at https://github.com/settings/tokens |

## Quick start

| Goal | Command |
|---|---|
| Everything, both tools | `./install.sh` |
| Preview only | `./install.sh --dry-run` |
| Only Claude Code | `./install.sh --claude` |
| Only Codex | `./install.sh --codex` |
| Only plugins / only MCP / only settings+AGENTS.md | `--plugins-only` / `--mcp-only` / `--config-only` |
| Also install ECC (Everything Claude Code) | `./install.sh --with-ecc` |
| Also add remote connectors (Gmail, Drive, Calendar, Slack, Vercel, Excalidraw) to Codex | `./install.sh --with-connectors`, then `codex mcp login <name>` for each |

Afterwards restart Claude Code / Codex. In Codex, open `/hooks` once and trust the plugin hooks, then start a new thread.

## What gets installed

### Plugins

| Plugin | Source | What it does | Claude Code | Codex |
|---|---|---|---|---|
| **ponytail** | [DietrichGebert/ponytail](https://github.com/DietrichGebert/ponytail) | A "lazy senior dev" ruleset: before writing code the agent checks whether it is needed, already exists in the repo, or is a stdlib/platform feature, and writes the minimum that works (keeps validation, security, accessibility, and leaves one small test for risky logic). Adds `/ponytail [lite\|full\|ultra\|off]`, `/ponytail-review`, `/ponytail-audit`, `/ponytail-debt`, `/ponytail-gain`, and a cost/token "band" above the prompt in Claude Code. | yes | yes (`$ponytail:ponytail-review`) |
| **code-review** | [anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official) | `/code-review` of a PR or diff using several review passes. | yes | n/a (Codex has a built-in `/review`) |
| **codex** (Codex for Claude Code) | [openai/codex-plugin-cc](https://github.com/openai/codex-plugin-cc) | Lets Claude Code call Codex: `/codex:review`, `/codex:adversarial-review`, `/codex:rescue` (delegate a task), `/codex:status`, `/codex:result`, `/codex:cancel`, `/codex:setup`. Needs Codex logged in. | yes | n/a |
| **ECC** (optional, `--with-ecc`) | [affaan-m/ECC](https://github.com/affaan-m/ECC) | Everything Claude Code: ~70 agents, hundreds of skills, command shims, hooks, rules, memory/continuous learning and AgentShield security scanning for prompts/hooks/MCP config. | yes (`ecc@ecc`) | yes (`ecc@ecc`) |

Notes
- ECC is **opt-in** because it is large and installs hooks. Its docs say not to stack install methods: use the plugin *or* a manual install, not both. Your current setup had the `ecc` marketplace added but the plugin itself was not installed, so the default run only registers the marketplace.
- Your marketplace was added as `affaan-m/everything-claude-code`; the project now documents `affaan-m/ECC` as the official source (the old name is a legacy alias), so this repo uses the new one.
- Marketplaces registered for Claude Code: `ponytail`, `claude-plugins-official`, `anthropic-agent-skills` ([anthropics/skills](https://github.com/anthropics/skills): document skills such as docx/pdf/pptx/xlsx, browse with `/plugin`), `openai-codex`, and `ecc`.

### MCP servers (local, installed into both tools)

| Name | Command | What it does |
|---|---|---|
| **context7** | `npx -y @upstash/context7-mcp@latest` | Fetches current, version-specific library docs so the agent stops hallucinating old APIs. Add "use context7" to a prompt. |
| **sequential-thinking** | `npx -y @modelcontextprotocol/server-sequential-thinking` | Step-by-step reasoning tool for planning and hard problems. |
| **memory** | `npx -y @modelcontextprotocol/server-memory` | Knowledge-graph memory that persists facts across sessions. |
| **playwright** | `npx -y @playwright/mcp --browser chrome` | Drives a real Chrome browser: navigate, click, screenshot, test UIs. |
| **magic** | `npx -y @magicuidesign/mcp@latest` | Magic UI component library: look up and generate animated React/Tailwind components. |
| **pdf** | `npx -y @modelcontextprotocol/server-pdf --stdio` | Opens and reads PDFs (this is what the `pdf-viewer` plugin ships). |
| **github** (needs token) | `npx -y @modelcontextprotocol/server-github` | Repos, issues, PRs, code search. Env: `GITHUB_PERSONAL_ACCESS_TOKEN`. That npm package is no longer actively developed; the maintained alternative is GitHub's own server (https://github.com/github/github-mcp-server). Kept as-is to match your current setup. |

Stored scope: for Claude Code these are added with `--scope user` (available in every project, kept in `~/.claude.json`). For Codex they go into `~/.codex/config.toml`. The GitHub token is written into those files in plain text, so keep them out of git.

## How it works

1. **Plugins** come from *marketplaces*, which are just GitHub repos with a manifest. `claude plugin marketplace add <owner/repo>` registers one, `claude plugin install <plugin>@<marketplace>` installs from it. Codex has the same two-step flow (`codex plugin marketplace add`, `codex plugin add`).
2. **MCP servers** are small programs (stdio via `npx`) or remote URLs that expose tools to the agent. `claude mcp add` / `codex mcp add` just record how to launch them; the agent starts them on demand.
3. **Settings** (`claude/settings.base.json`) are merged into `~/.claude/settings.json` by `scripts/merge-json.mjs`: objects merge recursively, arrays are unioned, and **values you already have are never overwritten**. A `settings.json.bak` is written first.
4. **Shared instructions**: `shared/AGENTS.md` is copied to `~/.codex/AGENTS.md` (Codex reads it globally) and `~/.claude/CLAUDE.md` gets one line, `@~/.codex/AGENTS.md`, which makes Claude Code import the same file. One file, two tools.
5. **Idempotency**: before each add, the script checks `list` output and skips what exists. Failed steps are collected and printed at the end.

## Manual commands, tool by tool

### Claude Code

Run in a terminal:

```bash
# marketplaces
claude plugin marketplace add DietrichGebert/ponytail
claude plugin marketplace add anthropics/claude-plugins-official
claude plugin marketplace add anthropics/skills
claude plugin marketplace add openai/codex-plugin-cc
claude plugin marketplace add affaan-m/ECC            # optional

# plugins
claude plugin install ponytail@ponytail --scope user
claude plugin install code-review@claude-plugins-official --scope user
claude plugin install codex@openai-codex --scope user
claude plugin install ecc@ecc --scope user            # optional

# MCP servers
claude mcp add --scope user context7 -- npx -y @upstash/context7-mcp@latest
claude mcp add --scope user sequential-thinking -- npx -y @modelcontextprotocol/server-sequential-thinking
claude mcp add --scope user memory -- npx -y @modelcontextprotocol/server-memory
claude mcp add --scope user playwright -- npx -y @playwright/mcp --browser chrome
claude mcp add --scope user magic -- npx -y @magicuidesign/mcp@latest
claude mcp add --scope user pdf -- npx -y @modelcontextprotocol/server-pdf --stdio
claude mcp add --scope user github -e GITHUB_PERSONAL_ACCESS_TOKEN=ghp_xxx -- npx -y @modelcontextprotocol/server-github
```

The same plugin steps work inside a Claude Code session as slash commands:

```
/plugin marketplace add DietrichGebert/ponytail
/plugin install ponytail@ponytail
/plugin marketplace add openai/codex-plugin-cc
/plugin install codex@openai-codex
/reload-plugins
/codex:setup
```

Check: `claude plugin list`, `claude mcp list`.

### Codex (app, CLI, IDE)

```bash
# plugins
codex plugin marketplace add DietrichGebert/ponytail
codex plugin add ponytail@ponytail
codex plugin marketplace add affaan-m/ECC            # optional
codex plugin add ecc@ecc                              # optional
codex plugin list --json

# MCP servers
codex mcp add context7 -- npx -y @upstash/context7-mcp@latest
codex mcp add sequential-thinking -- npx -y @modelcontextprotocol/server-sequential-thinking
codex mcp add memory -- npx -y @modelcontextprotocol/server-memory
codex mcp add playwright -- npx -y @playwright/mcp --browser chrome
codex mcp add magic -- npx -y @magicuidesign/mcp@latest
codex mcp add pdf -- npx -y @modelcontextprotocol/server-pdf --stdio
codex mcp add github --env GITHUB_PERSONAL_ACCESS_TOKEN=ghp_xxx -- npx -y @modelcontextprotocol/server-github

# remote OAuth connectors (optional)
codex mcp add vercel --url https://mcp.vercel.com && codex mcp login vercel
```

Then in Codex: `/hooks` → trust the plugin hooks → new thread. `codex mcp list` verifies. If you prefer editing the file, see [`codex/config.snippet.toml`](codex/config.snippet.toml).

## Settings that must be in JSON / TOML

Some things have no install command and only work once they are in a config file. The installer handles both, here is what it writes.

**Claude Code: `~/.claude/settings.json`** (source: [`claude/settings.base.json`](claude/settings.base.json))

| Key | Purpose |
|---|---|
| `enabledPlugins` | turns the installed plugins on (`ponytail@ponytail`, `code-review@claude-plugins-official`, `codex@openai-codex`) |
| `extraKnownMarketplaces` | declares the marketplaces so a new machine knows where plugins come from (ponytail, anthropic-agent-skills, ecc, openai-codex) |
| `sandbox.excludedCommands: ["codex"]` | lets the Codex plugin run `codex` outside Claude's sandbox |
| `model: "opus"`, `effortLevel: "high"` | your defaults, only applied if you have not set them |

Deliberately **not** copied: the `permissions.allow` list (it was full of project-specific paths) and the `statusLine` entry (it hard-codes ponytail's versioned cache path, and recent ponytail versions provide their own band).

**Codex: `~/.codex/config.toml`** gets `[mcp_servers.*]` blocks from `codex mcp add`; `~/.codex/AGENTS.md` holds the shared instructions.

## Shared AGENTS.md

[`shared/AGENTS.md`](shared/AGENTS.md) is a starting point: ask-don't-guess, match local style, minimal diffs, verify before "done", no pushes to main, no secrets in git, and a pointer to the tools above. It is a draft written from your stated preference, so edit it, then run `./install.sh --config-only` to redeploy it to both tools. Per-project overrides still work: put an `AGENTS.md` in a repo (Codex) and a `CLAUDE.md` containing `@AGENTS.md` (Claude Code).

## Account-synced items (nothing to install)

These appeared in your `claude plugin list` / `claude mcp list` but come from your **claude.ai account**, so they sync automatically when you sign in to Claude Code and cannot be installed from a repo.

**Synced plugins** (Anthropic/organization-provided): `engineering`, `design`, `finance`, `investment-banking`, `pdf-viewer`, `transcribe-so`, `ffmpeg-llm`, `video-to-code-skill`, `watch-video`, `cowork-plugin-management`.

**claude.ai connectors** (sign in once on claude.ai → Settings → Connectors; they then appear in Claude Code):

| Connector | URL |
|---|---|
| Gmail | https://gmailmcp.googleapis.com/mcp/v1 |
| Google Drive | https://drivemcp.googleapis.com/mcp/v1 |
| Google Calendar | https://calendarmcp.googleapis.com/mcp/v1 |
| Slack | https://mcp.slack.com/mcp |
| Vercel | https://mcp.vercel.com |
| Excalidraw | https://mcp.excalidraw.com/mcp |
| Claude Docs | https://api.anthropic.com/v1/pages/mcp |
| ElevenLabs | https://api.elevenlabs.io/v1/mcp |
| AgentMail | https://mcp.agentmail.to/mcp |
| Coursera | https://api.coursera.com/mcp |
| Indeed / Dice / ZipRecruiter / JobDataLake / Jobs and Careers | https://mcp.indeed.com/claude/mcp, https://mcp.dice.com/mcp, https://api.ziprecruiter.com/mcp, https://mcp.jobdatalake.com, https://jobs-and-careers-gpt-app.sonicapply.com/mcp |
| Goodnotes | https://claude-mcp-api.ml.goodnotes.com/mcp |

For Codex, `--with-connectors` adds the first six (Gmail, Drive, Calendar, Slack, Vercel, Excalidraw); any other row can be added the same way with `codex mcp add <name> --url <URL>` followed by `codex mcp login <name>`.

## Not included on purpose

- **Robinhood, Intuit TurboTax**: connectors with access to financial accounts. Left out of a public, copy-paste repo; add them by hand if you want them.
- **harness-os**: a Docker MCP tied to your local `~/Project/harness_os` and a local Postgres. Project-specific.
- **token-optimizer** (`npx -y token-optimizer-mcp`): it failed to connect (`CONNECTION_CLOSED`) in your list, so it is excluded until you confirm it works.
- **`plugin:*` MCP entries** (`plugin:engineering:slack`, `…:linear`, `…:atlassian`, `…:notion`, `…:datadog`, `…:figma`, `…:intercom`, `…:asana`, …): these belong to the synced plugins and show "Needs authentication" until you authorize them from Claude Code. Asana fails with "does not support dynamic client registration", which is a server limitation, not something this repo can fix.
- **Permissions allow-list and per-project paths** from `settings.json`.

## Troubleshooting

- **`claude plugin …` reports a marketplace/plugin already exists**: harmless, the script skips these; otherwise check `claude plugin list`.
- **Plugin shows installed twice** (e.g. at project and user scope): `claude plugin list` shows scope; uninstall the one you do not want.
- **MCP shows "Failed to connect"**: run the command from the table directly in a terminal to see the error; most often Node is missing or too old.
- **Codex plugin does nothing**: open `/hooks`, trust the hooks, start a *new* thread.
- **Reset ECC**: see ECC's "Reset / Uninstall ECC" section in its README; do not layer manual and plugin installs.
- **Restore settings**: `~/.claude/settings.json.bak` and `~/.codex/AGENTS.md.bak` are written before changes.

## Updating this repo

Installed something new? Add it to `install.sh` (`MCP_SERVERS` array or the plugin lines), add a row to the tables above, and commit. Re-run `claude plugin list && claude mcp list` to diff against this README.
