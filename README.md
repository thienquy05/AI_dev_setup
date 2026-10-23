# AI_dev_setup

Reproducible setup of plugins, skills, MCP servers, settings and shared instructions for **Claude Code** and **Codex** (app, CLI and IDE extension). Tools are grouped into categories and can be installed all at once or per category.

```bash
git clone https://github.com/thienquy05/AI_dev_setup.git && cd AI_dev_setup
export GITHUB_PERSONAL_ACCESS_TOKEN=ghp_xxx   # optional, enables the github MCP server
./install.sh --dry-run                        # print every command first
./install.sh                                  # core + all categories, Claude Code and Codex
```

## Contents

1. [Requirements](#1-requirements)
2. [Installer usage](#2-installer-usage)
3. [How it works](#3-how-it-works)
4. [Categories](#4-categories)
5. [Manual commands](#5-manual-commands)
6. [Configuration files](#6-configuration-files)
7. [Shared AGENTS.md](#7-shared-agentsmd)
8. [Account-synced items](#8-account-synced-items)
9. [Excluded items](#9-excluded-items)
10. [Troubleshooting](#10-troubleshooting)
11. [Maintenance](#11-maintenance)

## 1. Requirements

| Requirement | Used for | Install |
|---|---|---|
| Node.js 18.18+ (`node`, `npx`) | MCP servers launched via `npx`; settings merge | `brew install node` |
| Claude Code CLI | `claude plugin`, `claude mcp` | https://docs.claude.com/en/docs/claude-code |
| Codex CLI | `codex plugin`, `codex mcp` (the Codex app and IDE extension read the same `~/.codex/config.toml`) | `npm install -g @openai/codex`, then `codex login` |
| Google Chrome | `playwright` MCP (`--browser chrome`) | `brew install --cask google-chrome` |
| GitHub token (optional) | `github` MCP | https://github.com/settings/tokens |
| ffmpeg, yt-dlp (video category) | `ffmpeg-llm`, `watch-video` | `brew install ffmpeg yt-dlp` |

## 2. Installer usage

`./install.sh` always installs the **core** set. With no category flag it installs every category. With one or more category flags it installs core plus only those categories.

| Command | Result |
|---|---|
| `./install.sh` | core + all categories, both tools |
| `./install.sh --design --video` | core + design + video |
| `./install.sh --claude` / `--codex` | one tool only |
| `./install.sh --plugins-only` / `--mcp-only` / `--config-only` | one part only |
| `./install.sh --with-ecc` | also install Everything Claude Code (`ecc@ecc`) |
| `./install.sh --with-connectors` | also add the selected categories' remote OAuth connectors to Codex |
| `./install.sh --list` | print the catalogue per category |
| `./install.sh --dry-run` | print commands, change nothing |

Category flags: `--dev --design --video --audio --docs --productivity --jobs --learning --finance`.

After installing:
- Restart Claude Code / Codex.
- Codex: open `/hooks`, trust the plugin hooks, start a new thread.
- Remote connectors in Codex: run `codex mcp login <name>` once per connector.

## 3. How it works

1. **Plugins** come from marketplaces (GitHub repos with a manifest). `plugin marketplace add <owner/repo>` registers one; `plugin install <plugin>@<marketplace>` installs from it.
2. **MCP servers** expose tools to the agent. Local servers run through `npx` over stdio; remote servers are HTTPS URLs authorized with OAuth. `claude mcp add` / `codex mcp add` store how to reach them.
3. **Catalogue**: `install.sh` holds one table (`category|type|name|value`). Types: `market`, `plugin`, `mcp`, `remote`. Category flags filter this table.
4. **Settings merge**: `scripts/merge-json.mjs` merges `claude/settings.base.json` into `~/.claude/settings.json`. Objects merge recursively, arrays are unioned, existing values are never overwritten, and a `.bak` copy is written first.
5. **Shared instructions**: `shared/AGENTS.md` is copied to `~/.codex/AGENTS.md`; `~/.claude/CLAUDE.md` receives the line `@~/.codex/AGENTS.md`.
6. **Idempotency**: each step checks `list` output first and skips existing entries. Failed steps are listed at the end and the exit code is non-zero.
7. **Claude vs Codex remote connectors**: Claude Code receives claude.ai connectors from the signed-in account, so the script only adds remote connectors to Codex.

## 4. Categories

Installer column: **script** = installed by `install.sh`; **account** = synced from the claude.ai account (see [section 8](#8-account-synced-items)).

### core (always installed)

| Tool | Type | Installer | Purpose |
|---|---|---|---|
| ponytail | plugin, [DietrichGebert/ponytail](https://github.com/DietrichGebert/ponytail) | script (Claude Code + Codex) | Minimal-code discipline: before writing code, check whether it is needed, already in the repo, or covered by stdlib/platform; keeps validation, security and accessibility; adds one small test for risky logic. Commands: `/ponytail [lite\|full\|ultra\|off]`, `/ponytail-review`, `/ponytail-audit`, `/ponytail-debt`, `/ponytail-gain`, `/ponytail-help`; cost/token band in Claude Code. In Codex, commands are skills: `$ponytail:ponytail-review`. |
| code-review | plugin, `claude-plugins-official` | script (Claude Code) | `/code-review` of a diff or PR. Codex has a built-in `/review`. |
| codex | plugin, [openai/codex-plugin-cc](https://github.com/openai/codex-plugin-cc) | script (Claude Code) | Calls Codex from Claude Code: `/codex:review`, `/codex:adversarial-review`, `/codex:rescue`, `/codex:status`, `/codex:result`, `/codex:cancel`, `/codex:setup`. Requires `codex login`. |
| context7 | MCP, `@upstash/context7-mcp` | script | Current, version-specific library documentation. |
| sequential-thinking | MCP, `@modelcontextprotocol/server-sequential-thinking` | script | Stepwise reasoning tool for planning and debugging. |
| memory | MCP, `@modelcontextprotocol/server-memory` | script | Knowledge-graph memory persisted across sessions. |
| anthropic-agent-skills | marketplace, [anthropics/skills](https://github.com/anthropics/skills) | script (registered only) | Optional skill packs: `/plugin install document-skills@anthropic-agent-skills`, `/plugin install example-skills@anthropic-agent-skills`. |
| cowork-plugin-management | plugin | account | Create and customize plugins. |
| ECC (opt-in) | plugin `ecc@ecc`, [affaan-m/ECC](https://github.com/affaan-m/ECC) | script, `--with-ecc` (Claude Code + Codex) | Agents, skills, command shims, hooks, rules, memory and AgentShield scanning. Do not combine with a manual ECC install. |

### dev (`--dev`)

| Tool | Type | Installer | Purpose |
|---|---|---|---|
| playwright | MCP, `@playwright/mcp --browser chrome` | script | Controls a real Chrome browser: navigate, click, screenshot, test UIs. |
| github | MCP, `@modelcontextprotocol/server-github` | script, needs `GITHUB_PERSONAL_ACCESS_TOKEN` | Repositories, issues, pull requests, code search. The npm package is no longer actively developed; maintained alternative: https://github.com/github/github-mcp-server. |
| vercel | remote MCP, `https://mcp.vercel.com` | account (Claude Code), script `--with-connectors` (Codex) | Deployments, logs, projects, domains, environment variables. |
| engineering | plugin | account | Skills: architecture, code-review, debug, deploy-checklist, documentation, incident-response, standup, system-design, tech-debt, testing-strategy. Bundles connectors for Slack, Linear, Atlassian, Notion, Datadog, PagerDuty, GitHub (each needs authorization). |

### design (`--design`)

| Tool | Type | Installer | Purpose |
|---|---|---|---|
| magic | MCP, `@magicuidesign/mcp` | script | Magic UI component library: look up and generate animated React/Tailwind components. |
| excalidraw | remote MCP, `https://mcp.excalidraw.com/mcp` | account (Claude Code), script `--with-connectors` (Codex) | Create diagrams and whiteboard drawings. |
| design | plugin | account | Skills: accessibility-review (WCAG 2.1 AA), design-critique, design-handoff, design-system, research-synthesis, user-research, ux-copy. Bundles connectors for Figma, Asana, Intercom, Linear, Notion, Slack, Atlassian (each needs authorization). |

### video (`--video`)

| Tool | Type | Installer | Purpose |
|---|---|---|---|
| ffmpeg-llm | plugin | account | `/ffmpeg`: FFmpeg command from a plain-language description; `ffmpeg-expert` agent for failed commands, encoder tuning and filtergraphs. Requires `ffmpeg`. |
| watch-video | plugin | account | Analyzes a video (local file, URL via yt-dlp, Jira attachment): extracts keyframes with ffmpeg and transcribes audio with faster-whisper. |
| video-to-code-skill | plugin (v1.3) | account | Listed in `claude plugin list`; no description was available when this repo was written. |

No script installer exists for this category. `./install.sh --video` installs core only; install `ffmpeg` and `yt-dlp` (section 1) and sign in to claude.ai so the plugins sync.

### audio (`--audio`)

| Tool | Type | Installer | Purpose |
|---|---|---|---|
| elevenlabs | remote MCP, `https://api.elevenlabs.io/v1/mcp` | account (Claude Code), script `--with-connectors` (Codex) | Text-to-speech, voice design, transcription, conversational agents; the full connector also generates image, video and music. A restricted variant (`https://api.elevenlabs.io/v1/mcp-claude-marketplace`) exists in claude.ai only. Generations spend ElevenLabs credits. |
| transcribe-so | plugin + MCP, `https://transcribe.so/mcp` | account | Transcribes audio/video (YouTube, podcasts, files) into speaker-labelled transcripts with chapters, subtitles and cited Q&A. Needs authorization. |

### docs (`--docs`)

| Tool | Type | Installer | Purpose |
|---|---|---|---|
| pdf | MCP, `@modelcontextprotocol/server-pdf --stdio` | script | Open and read PDFs. |
| pdf-viewer | plugin | account | Interactive PDF viewer: annotate, fill forms, sign. |
| claude-docs | remote MCP, `https://api.anthropic.com/v1/pages/mcp` | account (Claude Code), script `--with-connectors` (Codex) | Create and edit shareable docs. |
| google-drive | remote MCP, `https://drivemcp.googleapis.com/mcp/v1` | account / `--with-connectors` | Search and read Drive files. |
| goodnotes | remote MCP, `https://claude-mcp-api.ml.goodnotes.com/mcp` | account / `--with-connectors` | Access Goodnotes notes. |
| docx, pdf, pptx, xlsx, docs, google-workspace, deep-research, skill-creator, import-memory, morning | Anthropic built-in skills | account | Create/edit Word, PDF, PowerPoint, Excel and Google files; multi-source research reports; skill authoring. |

### productivity (`--productivity`)

| Tool | Type | Installer | Purpose |
|---|---|---|---|
| gmail | remote MCP, `https://gmailmcp.googleapis.com/mcp/v1` | account / `--with-connectors` | Search, read, draft and send mail. |
| google-calendar | remote MCP, `https://calendarmcp.googleapis.com/mcp/v1` | account / `--with-connectors` | Read and manage events. |
| slack | remote MCP, `https://mcp.slack.com/mcp` | account / `--with-connectors` | Read and post in Slack. |
| agentmail | remote MCP, `https://mcp.agentmail.to/mcp` | account / `--with-connectors` | Agent-owned inboxes and third-party app sign-ups. |

### jobs (`--jobs`)

| Tool | Type | Installer | Purpose |
|---|---|---|---|
| indeed | remote MCP, `https://mcp.indeed.com/claude/mcp` | account / `--with-connectors` | Job search, company data, resume. |
| dice | remote MCP, `https://mcp.dice.com/mcp` | account / `--with-connectors` | Job search and company lookup. |
| ziprecruiter | remote MCP, `https://api.ziprecruiter.com/mcp` | account / `--with-connectors` | Job search. |
| jobdatalake | remote MCP, `https://mcp.jobdatalake.com` | account / `--with-connectors` | Search 1M+ enriched job listings; salary, skills, location filters. |
| jobs-and-careers | remote MCP, `https://jobs-and-careers-gpt-app.sonicapply.com/mcp` | account / `--with-connectors` | Job search. |

### learning (`--learning`)

| Tool | Type | Installer | Purpose |
|---|---|---|---|
| coursera | remote MCP, `https://api.coursera.com/mcp` | account / `--with-connectors` | Search courses, videos and hands-on projects; read course material. |

### finance (`--finance`)

| Tool | Type | Installer | Purpose |
|---|---|---|---|
| finance | plugin | account | Skills: audit-support, close-management, financial-statements, journal-entry, reconciliation, sox-testing, variance-analysis. Bundles BigQuery, Snowflake, Databricks connectors. |
| investment-banking | plugin | account | Skills: buyer-list, CIM, deal-tracker, merger-model, one-pager, process-letter, teaser, datapack-builder, pitch-deck, strip-profile. |

No script installer exists for this category.

## 5. Manual commands

### Claude Code

```bash
# core
claude plugin marketplace add DietrichGebert/ponytail
claude plugin marketplace add anthropics/claude-plugins-official
claude plugin marketplace add anthropics/skills
claude plugin marketplace add openai/codex-plugin-cc
claude plugin install ponytail@ponytail --scope user
claude plugin install code-review@claude-plugins-official --scope user
claude plugin install codex@openai-codex --scope user
claude mcp add --scope user context7 -- npx -y @upstash/context7-mcp@latest
claude mcp add --scope user sequential-thinking -- npx -y @modelcontextprotocol/server-sequential-thinking
claude mcp add --scope user memory -- npx -y @modelcontextprotocol/server-memory

# dev
claude mcp add --scope user playwright -- npx -y @playwright/mcp --browser chrome
claude mcp add --scope user github -e GITHUB_PERSONAL_ACCESS_TOKEN=ghp_xxx -- npx -y @modelcontextprotocol/server-github

# design
claude mcp add --scope user magic -- npx -y @magicuidesign/mcp@latest

# docs
claude mcp add --scope user pdf -- npx -y @modelcontextprotocol/server-pdf --stdio

# optional
claude plugin marketplace add affaan-m/ECC && claude plugin install ecc@ecc --scope user
```

Equivalent in-session commands: `/plugin marketplace add <owner/repo>`, `/plugin install <plugin>@<marketplace>`, `/reload-plugins`, `/codex:setup`.

Verify: `claude plugin list`, `claude mcp list`.

### Codex

```bash
# core
codex plugin marketplace add DietrichGebert/ponytail
codex plugin add ponytail@ponytail
codex mcp add context7 -- npx -y @upstash/context7-mcp@latest
codex mcp add sequential-thinking -- npx -y @modelcontextprotocol/server-sequential-thinking
codex mcp add memory -- npx -y @modelcontextprotocol/server-memory

# dev
codex mcp add playwright -- npx -y @playwright/mcp --browser chrome
codex mcp add github --env GITHUB_PERSONAL_ACCESS_TOKEN=ghp_xxx -- npx -y @modelcontextprotocol/server-github

# design
codex mcp add magic -- npx -y @magicuidesign/mcp@latest

# docs
codex mcp add pdf -- npx -y @modelcontextprotocol/server-pdf --stdio

# remote connectors (example), then authorize
codex mcp add vercel --url https://mcp.vercel.com
codex mcp login vercel

# optional
codex plugin marketplace add affaan-m/ECC && codex plugin add ecc@ecc
```

Verify: `codex mcp list`, `codex plugin list --json`. TOML alternative: [`codex/config.snippet.toml`](codex/config.snippet.toml).

## 6. Configuration files

Items that only work once present in a config file. `install.sh` writes them; manual equivalents below.

**`~/.claude/settings.json`** (source: [`claude/settings.base.json`](claude/settings.base.json))

| Key | Purpose |
|---|---|
| `enabledPlugins` | enables `ponytail@ponytail`, `code-review@claude-plugins-official`, `codex@openai-codex` |
| `extraKnownMarketplaces` | declares marketplaces: ponytail, anthropic-agent-skills, ecc, openai-codex |
| `sandbox.excludedCommands` | `["codex"]`, lets the Codex plugin run outside the sandbox |
| `model`, `effortLevel` | defaults `opus` / `high`, applied only when unset |

**`~/.codex/config.toml`**: `[mcp_servers.<name>]` blocks, created by `codex mcp add`.

**`~/.codex/AGENTS.md`** and **`~/.claude/CLAUDE.md`**: see section 7.

Not copied: `permissions.allow` (project-specific paths) and `statusLine` (hard-coded versioned plugin path).

## 7. Shared AGENTS.md

[`shared/AGENTS.md`](shared/AGENTS.md) is the single source of truth for agent instructions: ask instead of guessing, match local style, minimal diffs, verify before reporting done, no direct pushes to `main`, no secrets in git, and the category tool list.

- Codex reads `~/.codex/AGENTS.md` (copied by the installer).
- Claude Code reads `~/.claude/CLAUDE.md`, which imports it with `@~/.codex/AGENTS.md`.
- Edit `shared/AGENTS.md`, then run `./install.sh --config-only` to redeploy.
- Per-project override: add `AGENTS.md` to the repository (Codex) and a `CLAUDE.md` containing `@AGENTS.md` (Claude Code).

## 8. Account-synced items

Plugins and connectors marked **account** sync when Claude Code is signed in to the same claude.ai account. They cannot be installed from a repository.

- Plugins: `engineering`, `design`, `finance`, `investment-banking`, `pdf-viewer`, `transcribe-so`, `ffmpeg-llm`, `video-to-code-skill`, `watch-video`, `cowork-plugin-management`.
- Connectors: enable in claude.ai → Settings → Connectors. URLs are listed per category in section 4.
- Plugin-bundled MCP entries (`plugin:engineering:*`, `plugin:design:*`, `plugin:finance:*`) show "Needs authentication" until authorized in Claude Code. Asana reports "does not support dynamic client registration"; this is a server limitation.
- Remote connector URLs were taken from Claude Code. Authorization from Codex is not guaranteed for every server (some are issued for claude.ai only); a failure is reported at the end of the run and does not stop other steps.

## 9. Excluded items

| Item | Reason |
|---|---|
| Robinhood, Intuit TurboTax connectors | Access financial accounts; not published in a public repository. Add manually. |
| harness-os | Docker MCP bound to local `~/Project/harness_os` and a local Postgres. |
| token-optimizer (`npx -y token-optimizer-mcp`) | Failed to connect (`CONNECTION_CLOSED`). |
| `permissions.allow`, per-project paths | Project-specific. |

## 10. Troubleshooting

| Symptom | Action |
|---|---|
| "already exists" on marketplace or plugin | Harmless; verify with `claude plugin list`. |
| Plugin installed at two scopes | `claude plugin list` shows scope; uninstall the unwanted one. |
| MCP "Failed to connect" | Run its command from section 4 in a terminal; usually Node is missing or outdated. |
| Codex plugin inactive | Open `/hooks`, trust hooks, start a new thread. |
| Remote connector not authorized in Codex | `codex mcp login <name>`; if refused, use the connector in Claude Code only. |
| ECC duplicated skills or hooks | Follow "Reset / Uninstall ECC" in the ECC README; do not mix plugin and manual installs. |
| Restore previous config | `~/.claude/settings.json.bak`, `~/.codex/AGENTS.md.bak`. |

## 11. Maintenance

1. Capture the current state: `claude plugin marketplace list`, `claude plugin list`, `claude mcp list`, `codex mcp list`, `cat ~/.codex/config.toml`.
2. Add new items as a row in the `CATALOGUE` block of `install.sh` (`category|type|name|value`).
3. Add the item to its category table in section 4 (and to `shared/AGENTS.md` if agents should know about it).
4. Run `./install.sh --list` and `./install.sh --dry-run`, then commit.
