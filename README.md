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
5. [Codex coverage](#5-codex-coverage)
6. [Manual commands](#6-manual-commands)
7. [Configuration files](#7-configuration-files)
8. [Shared AGENTS.md](#8-shared-agentsmd)
9. [Account-synced items](#9-account-synced-items)
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
| Node.js 22.20+ | `skills` CLI used for the Remotion and Hallmark skill packs | `brew install node` |
| Claude Code 2.1.287+ | `agents` category (ruflo mods) | `claude update` |
| Python 3 | `ui-ux-pro-max` search scripts | `brew install python` |
| ffmpeg, yt-dlp (video category) | `ffmpeg-llm`, `watch-video` | `brew install ffmpeg yt-dlp` |
| Playwright npm package, ffmpeg (optional) | `unslop` live-site snapshots and story videos (run in the project) | `npm install -D playwright && npx playwright install chromium` |
| Figma Dev or Full seat (optional) | `figma` MCP beyond 6 tool calls a month | https://www.figma.com/pricing |

## 2. Installer usage

`./install.sh` always installs the **core** set. With no category flag it installs every category. With one or more category flags it installs core plus only those categories.

| Command | Result |
|---|---|
| `./install.sh` | core + all categories, both tools |
| `./install.sh --design --video` | core + design + video |
| `./install.sh --claude` / `--codex` | one tool only |
| `./install.sh --plugins-only` / `--mcp-only` / `--config-only` | one part only |
| `./install.sh --no-ecc` | skip Everything Claude Code (installed by default as part of core) |
| `./install.sh --with-connectors` | also add the selected categories' remote OAuth connectors to Codex |
| `./install.sh --list` | print the catalogue per category |
| `./install.sh --dry-run` | print commands, change nothing |

Category flags: `--dev --design --video --audio --docs --agents --security`.

After installing:
- Restart Claude Code / Codex.
- Codex: open `/hooks`, trust the plugin hooks, start a new thread.
- Remote connectors in Codex: run `codex mcp login <name>` once per connector.

## 3. How it works

1. **Plugins** come from marketplaces (GitHub repos with a manifest). `plugin marketplace add <owner/repo>` registers one; `plugin install <plugin>@<marketplace>` installs from it.
2. **MCP servers** expose tools to the agent. Local servers run through `npx` over stdio; remote servers are HTTPS URLs authorized with OAuth. `claude mcp add` / `codex mcp add` store how to reach them.
3. **Catalogue**: `install.sh` holds one table (`category|type|name|value`). Types: `market`, `plugin`, `mcp`, `remote`. Category flags filter this table.
4. **Settings merge**: `scripts/merge-json.mjs` merges `claude/settings.base.json` into `~/.claude/settings.json`. Objects merge recursively, arrays are unioned, existing values are never overwritten, and a `.bak` copy is written first.
5. **Shared instructions**: `shared/AGENTS.md` is copied to `~/.codex/AGENTS.md`; `~/.claude/CLAUDE.md` receives the line `@~/.codex/AGENTS.md`; `templates/` is copied to `~/.codex/templates/`.
6. **Idempotency**: each step checks `list` output first and skips existing entries. Failed steps are listed at the end and the exit code is non-zero.
7. **Claude vs Codex remote connectors**: Claude Code receives claude.ai connectors from the signed-in account, so the script only adds remote connectors to Codex.

### Repository layout

```text
AI_dev_setup/
├── install.sh                      installer: tool catalogue, category flags, settings merge, AGENTS.md and templates deploy
├── README.md                       this file
├── .env.example                    names of the optional environment variables (copy to .env; no secrets committed)
├── .gitignore                      keeps .env, *.bak and .DS_Store out of git
├── claude/
│   └── settings.base.json          Claude Code defaults merged into ~/.claude/settings.json (model, plugins, marketplaces)
├── codex/
│   └── config.snippet.toml         MCP servers to append to ~/.codex/config.toml by hand instead of `codex mcp add`
├── scripts/
│   └── merge-json.mjs              deep-merges the base settings into the target without overwriting existing values
├── shared/
│   └── AGENTS.md                   global instructions for Claude Code and Codex, deployed to ~/.codex/AGENTS.md
└── templates/                      project-neutral starting points for a new repository (deployed to ~/.codex/templates/)
    ├── README.md                   how to adopt the templates, plus the new-project kickoff prompt
    ├── AGENTS.template.md          the one instruction file for a project; fill in the [PLACEHOLDERS]
    ├── CLAUDE.template.md          one line that makes Claude Code load AGENTS.md
    ├── gitignore.base              lines every repo needs for agent state, secrets and caches
    ├── process/                    the working process: harness process, PRD templates, testing, review, security gate, cleanup
    ├── scripts/                    check.sh (parallel checks), run-bg.sh (tracked background processes), janitor.sh (leftovers); tests/ holds selfcheck.sh and janitor_test.sh
    ├── claude/                     settings.template.json (sandbox and permissions) and agents/reviewer.md (read-only reviewer)
    └── ci/                         GitHub Actions starting points: gate.yml (fast checks) and security.yml
```

## 4. Categories

Installer column: **script** = installed by `install.sh`; **account** = synced from the claude.ai account (see [section 9](#9-account-synced-items)).

### core (always installed)

| Tool | Type | Installer | Purpose |
|---|---|---|---|
| ponytail | plugin, [DietrichGebert/ponytail](https://github.com/DietrichGebert/ponytail) | script (Claude Code + Codex) | Minimal-code discipline: before writing code, check whether it is needed, already in the repo, or covered by stdlib/platform; keeps validation, security and accessibility; adds one small test for risky logic. Commands: `/ponytail [lite\|full\|ultra\|off]`, `/ponytail-review`, `/ponytail-audit`, `/ponytail-debt`, `/ponytail-gain`, `/ponytail-help`; cost/token band in Claude Code. In Codex, commands are skills: `$ponytail:ponytail-review`. |
| code-review | plugin, `claude-plugins-official` | script (Claude Code) | `/code-review` of a diff or PR. Codex has a built-in `/review`. |
| codex | plugin, [openai/codex-plugin-cc](https://github.com/openai/codex-plugin-cc) | script (Claude Code) | Calls Codex from Claude Code: `/codex:review`, `/codex:adversarial-review`, `/codex:rescue`, `/codex:status`, `/codex:result`, `/codex:cancel`, `/codex:setup`. Requires `codex login`. |
| claude-md-management | plugin, `claude-plugins-official` | script (Claude Code) | Audits and improves `CLAUDE.md` files and captures session learnings into them. |
| claude-code-setup | plugin, `claude-plugins-official` | script (Claude Code) | Analyzes a codebase and recommends Claude Code automations (hooks, skills, MCP servers, subagents). |
| context7 | MCP, `@upstash/context7-mcp` | script | Current, version-specific library documentation. |
| anthropic-agent-skills | marketplace, [anthropics/skills](https://github.com/anthropics/skills) | script (registered only) | Optional skill packs: `/plugin install document-skills@anthropic-agent-skills`, `/plugin install example-skills@anthropic-agent-skills`. |
| cowork-plugin-management | plugin | account | Create and customize plugins. |
| ECC | plugin `ecc@ecc`, [affaan-m/ECC](https://github.com/affaan-m/ECC) | script (Claude Code + Codex); skip with `--no-ecc` | Everything Claude Code: agents, skills, command shims, hooks, rules, memory/continuous learning and AgentShield scanning of prompts, hooks and MCP config. Also provides the `chrome-devtools` MCP (`npx -y chrome-devtools-mcp`, Chrome DevTools debugging and performance traces) as `plugin:ecc:chrome-devtools`. Do not combine with a manual ECC install; the install may print a note that `package.json` overrides were not applied, which does not affect the plugin. |

### dev (`--dev`)

| Tool | Type | Installer | Purpose |
|---|---|---|---|
| playwright | MCP, `@playwright/mcp --browser chrome` | script | Controls a real Chrome browser: navigate, click, screenshot, test UIs. |
| feature-dev | plugin, `claude-plugins-official` | script (Claude Code) | `/feature-dev`: guided feature development with codebase exploration, architecture design and review agents. |
| plugin-dev | plugin, `claude-plugins-official` | script (Claude Code) | Toolkit for building Claude Code plugins: skills for hooks, MCP integration, commands, agents and plugin structure. |
| supabase | plugin, `claude-plugins-official` | script (Claude Code) | Supabase MCP integration: manage databases, auth, storage and edge functions (needs authorization). |
| token-optimizer | MCP, `token-optimizer-mcp` | script | Context-window optimization: stores large content externally with caching and compression so it does not occupy the context. |
| chrome-devtools | MCP, `chrome-devtools-mcp@1.10.1` | Claude Code: bundled with ECC; Codex: script | Chrome DevTools debugging and performance traces. |
| github | MCP, `@modelcontextprotocol/server-github` | script, needs `GITHUB_PERSONAL_ACCESS_TOKEN` | Repositories, issues, pull requests, code search. The npm package is no longer actively developed; maintained alternative: https://github.com/github/github-mcp-server. |
| vercel | remote MCP, `https://mcp.vercel.com` | account (Claude Code), script `--with-connectors` (Codex) | Deployments, logs, projects, domains, environment variables. |
| engineering | plugin | account | Skills: architecture, code-review, debug, deploy-checklist, documentation, incident-response, standup, system-design, tech-debt, testing-strategy. Bundles connectors for Slack, Linear, Atlassian, Notion, Datadog, PagerDuty, GitHub (each needs authorization). |

### design (`--design`)

| Tool | Type | Installer | Purpose |
|---|---|---|---|
| magic | MCP, `@magicuidesign/mcp` | script | Magic UI component library: look up and generate animated React/Tailwind components. |
| ui-ux-pro-max | plugin, [nextlevelbuilder/ui-ux-pro-max-skill](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill) | script (Claude Code) | UI/UX design intelligence skill: searchable databases of 79 styles, 192 palettes, 74 font pairings, 25 chart types and 22 stack guidelines (React, Next.js, Vue, Svelte, SwiftUI, Flutter, Tailwind, shadcn/ui and others). Requires Python 3. Codex: installed by the script as a skill in `~/.agents/skills/` (`npx -y ui-ux-pro-max-cli init --ai universal --global`). |
| hallmark | skill, [nutlope/hallmark](https://github.com/nutlope/hallmark) (MIT, by Together AI) | script (Claude Code + Codex, user scope) | Anti-AI-slop design skill for building new pages. Deals three themes from a catalogue of 50, builds the page around the visitor's job, then lints it in a real browser (`sloplint --render`: contrast, focus rings, phone layout, invented facts, empty frames) and has a fresh-context reviewer sign off. `/hallmark <prompt>` (Codex: `$hallmark`), `/hallmark redesign <path>` (keeps content and wiring), `/hallmark audit <path>` (report only), or say *custom* to drop the themes. Output is self-contained HTML/CSS and is not framework-aware by default. Optional extras: browser checks need `npm i -g puppeteer-core` and Chrome; AI image generation needs `TOGETHER_API_KEY` (not set up here). Only invoked on new designs or when named, so it does not touch existing pages unprompted; use `unslop` for existing screens. |
| modern-web-guidance | plugin, [GoogleChrome/modern-web-guidance](https://github.com/GoogleChrome/modern-web-guidance) | script (Claude Code + Codex) | Searchable guidance on current HTML, CSS and client-side JS platform patterns (dialogs, popovers, forms, view transitions, Core Web Vitals). Technical only; it sets no visual style. |
| unslop | plugin `unslop@heydamir`, [heydamir/unslop](https://github.com/heydamir/unslop) (CC BY 4.0) | script (Claude Code: plugin; Codex: skill in `~/.agents/skills/`) | Restyles an **existing** screen that looks AI-generated. Audits it against a list of tells (purple gradients, glows, emoji icons, tracked-caps labels, uneven spacing), proposes a five-line direction and waits for approval, then fixes it in nine passes: spacing, color, icons, copy, type, layout, details, visuals, motion. Keeps the product's sections and content. `/unslop <screen or URL>` (Codex: `$unslop`). Works in the project's own stack. Live-site snapshots and the optional story video need the Playwright npm package in the project, and the video also needs ffmpeg (section 1). The license requires crediting the author; story videos carry a credit. If an old copy sits in `~/.claude/skills/unslop`, delete it or it shadows the plugin. |
| figma | plugin `figma@claude-plugins-official` (official, [figma/mcp-server-guide](https://github.com/figma/mcp-server-guide)); remote MCP `https://mcp.figma.com/mcp` | script (Claude Code: plugin; Codex: `--with-connectors`) | Figma's own MCP server: reads designs into code (`get_design_context` as React + Tailwind, `get_variable_defs`, `get_screenshot`, `get_metadata`) and writes to the canvas (free during the beta). Authorize on first use. **Limits:** Starter plans and View/Collab seats get 6 tool calls a month; Dev/Full seats on paid plans get per-minute limits. The account-synced `design` plugin also bundles a Figma connector (`plugin:design:figma`) pointing at the same server; keep one of them enabled to avoid duplicate tools. |
| excalidraw | remote MCP, `https://mcp.excalidraw.com/mcp` | account (Claude Code), script `--with-connectors` (Codex) | Create diagrams and whiteboard drawings. |
| design | plugin | account | Skills: accessibility-review (WCAG 2.1 AA), design-critique, design-handoff, design-system, research-synthesis, user-research, ux-copy. Bundles connectors for Figma, Asana, Intercom, Linear, Notion, Slack, Atlassian (each needs authorization). |

### video (`--video`)

| Tool | Type | Installer | Purpose |
|---|---|---|---|
| remotion | skill pack, [remotion-dev/skills](https://github.com/remotion-dev/skills) for [remotion-dev/remotion](https://github.com/remotion-dev/remotion) | script (Claude Code + Codex, user scope) | Remotion creates videos from React code: compositions are React components, previewed in Remotion Studio and rendered to video or images (locally, Lambda, Vercel); also usable for batch rendering and embedded video editors. The skills teach the agent the workflow: `/remotion-create`, `/remotion-markup`, `/remotion-studio`, `/remotion-render`, `/remotion-docs`, `/remotion-best-practices`, plus captions, maps and Mediabunny. Start a project with `npx create-video@latest`. **License:** free for individuals, for-profit companies with up to 3 employees, non-profits and evaluation; larger for-profit companies need a company license (remotion.pro: Creators $25 per seat per month; Automators $0.01 per render, $100 per month minimum; Enterprise from $500 per month). Rendering on AWS Lambda or Vercel is billed by those providers. Terms change in Remotion 5.0; check https://remotion.dev/license. |
| ffmpeg-llm | plugin | account | `/ffmpeg`: FFmpeg command from a plain-language description; `ffmpeg-expert` agent for failed commands, encoder tuning and filtergraphs. Requires `ffmpeg`. |
| watch-video | plugin | account | Analyzes a video (local file, URL via yt-dlp, Jira attachment): extracts keyframes with ffmpeg and transcribes audio with faster-whisper. |
| video-to-code-skill | plugin (v1.3) | account | Listed in `claude plugin list`; no description was available when this repo was written. |

`./install.sh --video` installs the Remotion skill pack. The other three entries are account-synced: install `ffmpeg` and `yt-dlp` (section 1) and sign in to claude.ai so they sync.

### audio (`--audio`)

| Tool | Type | Installer | Purpose |
|---|---|---|---|
| elevenlabs | remote MCP, `https://api.elevenlabs.io/v1/mcp` | account (Claude Code), script `--with-connectors` (Codex) | Text-to-speech, voice design, transcription, conversational agents; the full connector also generates image, video and music. A restricted variant (`https://api.elevenlabs.io/v1/mcp-claude-marketplace`) exists in claude.ai only. Generations spend ElevenLabs credits. |
| transcribe-so | plugin + MCP, `https://transcribe.so/mcp` | account | Transcribes audio/video (YouTube, podcasts, files) into speaker-labelled transcripts with chapters, subtitles and cited Q&A. Needs authorization. |

### docs (`--docs`)

| Tool | Type | Installer | Purpose |
|---|---|---|---|
| pdf | MCP, `@modelcontextprotocol/server-pdf --stdio` | Codex: script; Claude Code: provided by the `pdf-viewer` plugin (same server, so it is not added twice) | Open and read PDFs. |
| pdf-viewer | plugin | account | Interactive PDF viewer: annotate, fill forms, sign. |
| claude-docs | remote MCP, `https://api.anthropic.com/v1/pages/mcp` | account (Claude Code), script `--with-connectors` (Codex) | Create and edit shareable docs. |
| google-drive | remote MCP, `https://drivemcp.googleapis.com/mcp/v1` | account / `--with-connectors` | Search and read Drive files. |
| goodnotes | remote MCP, `https://claude-mcp-api.ml.goodnotes.com/mcp` | account / `--with-connectors` | Access Goodnotes notes. |
| docx, pdf, pptx, xlsx, docs, google-workspace, deep-research, skill-creator, import-memory, morning | Anthropic built-in skills | account | Create/edit Word, PDF, PowerPoint, Excel and Google files; multi-source research reports; skill authoring. |

### agents (`--agents`)

| Tool | Type | Installer | Purpose |
|---|---|---|---|
| ruflo-core | plugin, [ruvnet/ruflo](https://github.com/ruvnet/ruflo) | script (Claude Code) | Agent meta-harness core: registers the Ruflo MCP server, commands and orchestration patterns (swarms, agent teams, memory). Requires Claude Code 2.1.287+. |
| ruflo-console | plugin | script (Claude Code) | Cockpit as a Claude Code mod: `/ruflo` opens overview, swarm topology, cost gauge, agent timeline, approvals and plugin catalog (early access). |
| ruflo-mods | plugin | script (Claude Code) | Runtime mods: in-process prompt routing, edit-learning signals, tighten-only tool checks from ruflo policy, cost budget ladder (early access). Mods run with account permissions and are not sandboxed; review the code before installing. |
| ruflo (MCP) | MCP, `npx -y ruflo@latest mcp start` | script (Codex) | Ruflo MCP server for Codex. Full project setup: `npx ruflo@latest init wizard` (run per project). |

### security (`--security`)

| Tool | Type | Installer | Purpose |
|---|---|---|---|
| security-guidance | plugin, `claude-plugins-official` | script (Claude Code) | Hook that warns about security issues (injection, XSS, unsafe patterns) when files are edited. |
| claude-security | plugin, `claude-plugins-official` | script (Claude Code) | `/claude-security`: multi-stage security scan of a codebase or change (threat model, research, adversarial review). |

## 5. Codex coverage

Codex-only install: `./install.sh --codex` (add `--with-connectors` for remote servers, then `codex mcp login <name>`). Codex loads skills from `~/.agents/skills` (user) and `<repo>/.agents/skills` (project), MCP servers from `~/.codex/config.toml`, and instructions from `~/.codex/AGENTS.md`.

| Category | Installed for Codex | Not available for Codex |
|---|---|---|
| core | ponytail, ECC, context7, shared `AGENTS.md` | `code-review` (Codex has built-in `/review`), `claude-md-management`, `claude-code-setup`, `codex` bridge plugin (Claude Code only), account-synced plugins |
| dev | playwright, chrome-devtools, token-optimizer, github (with token); vercel via `--with-connectors` | `feature-dev`, `plugin-dev`, `supabase`, `engineering` plugin |
| design | magic, ui-ux-pro-max skill, hallmark skill pack, modern-web-guidance, unslop skill; figma, excalidraw via `--with-connectors` | `design` plugin |
| video | remotion skill pack | `ffmpeg-llm`, `watch-video`, `video-to-code-skill` (claude.ai account only) |
| audio | elevenlabs via `--with-connectors` | `transcribe-so` plugin |
| docs | pdf; claude-docs, google-drive, goodnotes via `--with-connectors` | `pdf-viewer`, Anthropic built-in skills |
| agents | ruflo MCP | `ruflo-core`, `ruflo-console`, `ruflo-mods` (Claude Code mods) |
| security | (none) | `security-guidance`, `claude-security` (Claude Code plugins) |

Remote servers use OAuth. Some were issued for claude.ai and may refuse authorization from Codex; failures are reported at the end of the run.

## 6. Manual commands

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
claude plugin install claude-md-management@claude-plugins-official --scope user
claude plugin install claude-code-setup@claude-plugins-official --scope user
claude mcp add --scope user context7 -- npx -y @upstash/context7-mcp@latest

# dev
claude mcp add --scope user token-optimizer -- npx -y token-optimizer-mcp
claude mcp add --scope user playwright -- npx -y @playwright/mcp --browser chrome
claude mcp add --scope user github -e GITHUB_PERSONAL_ACCESS_TOKEN=ghp_xxx -- npx -y @modelcontextprotocol/server-github
claude plugin install feature-dev@claude-plugins-official --scope user
claude plugin install plugin-dev@claude-plugins-official --scope user
claude plugin install supabase@claude-plugins-official --scope user

# design
claude mcp add --scope user magic -- npx -y @magicuidesign/mcp@latest
claude plugin marketplace add nextlevelbuilder/ui-ux-pro-max-skill
claude plugin install ui-ux-pro-max@ui-ux-pro-max-skill --scope user
npx -y skills add nutlope/hallmark -g -a claude-code -s '*' -y
claude plugin marketplace add GoogleChrome/modern-web-guidance
claude plugin install modern-web-guidance@googlechrome --scope user
claude plugin marketplace add heydamir/unslop
claude plugin install unslop@heydamir --scope user
claude plugin install figma@claude-plugins-official --scope user

# video
npx -y skills add remotion-dev/skills -g -a claude-code -s '*' -y

# agents
claude plugin marketplace add ruvnet/ruflo
claude plugin install ruflo-core@ruflo --scope user
claude plugin install ruflo-console@ruflo --scope user
claude plugin install ruflo-mods@ruflo --scope user

# security
claude plugin install security-guidance@claude-plugins-official --scope user
claude plugin install claude-security@claude-plugins-official --scope user

# core (ECC)
claude plugin marketplace add affaan-m/ECC
claude plugin install ecc@ecc --scope user
```

Equivalent in-session commands: `/plugin marketplace add <owner/repo>`, `/plugin install <plugin>@<marketplace>`, `/reload-plugins`, `/codex:setup`.

Verify: `claude plugin list`, `claude mcp list`.

### Codex

```bash
# core
codex plugin marketplace add DietrichGebert/ponytail
codex plugin add ponytail@ponytail
codex mcp add context7 -- npx -y @upstash/context7-mcp@latest
codex plugin marketplace add affaan-m/ECC && codex plugin add ecc@ecc

# dev
codex mcp add chrome-devtools -- npx -y chrome-devtools-mcp@1.10.1
codex mcp add token-optimizer -- npx -y token-optimizer-mcp
codex mcp add playwright -- npx -y @playwright/mcp --browser chrome
codex mcp add github --env GITHUB_PERSONAL_ACCESS_TOKEN=ghp_xxx -- npx -y @modelcontextprotocol/server-github

# design
codex mcp add magic -- npx -y @magicuidesign/mcp@latest
npx -y ui-ux-pro-max-cli init --ai universal --global   # installs the skill into ~/.agents/skills/ (read by Codex)
npx -y skills add nutlope/hallmark -g -a codex -s '*' -y
codex plugin marketplace add GoogleChrome/modern-web-guidance && codex plugin add modern-web-guidance@googlechrome
npx -y skills add heydamir/unslop -g -a codex -s unslop -y   # installs the skill into ~/.agents/skills/
codex mcp add figma --url https://mcp.figma.com/mcp && codex mcp login figma

# agents
codex mcp add ruflo -- npx -y ruflo@latest mcp start

# security

# video
npx -y skills add remotion-dev/skills -g -a codex -s '*' -y

# docs
codex mcp add pdf -- npx -y @modelcontextprotocol/server-pdf --stdio

# remote connectors (example), then authorize
codex mcp add vercel --url https://mcp.vercel.com
codex mcp login vercel

```

Verify: `codex mcp list`, `codex plugin list --json`. TOML alternative: [`codex/config.snippet.toml`](codex/config.snippet.toml).

## 7. Configuration files

Items that only work once present in a config file. `install.sh` writes them; manual equivalents below.

**`~/.claude/settings.json`** (source: [`claude/settings.base.json`](claude/settings.base.json))

| Key | Purpose |
|---|---|
| `enabledPlugins` | enables `ponytail@ponytail`, `code-review@claude-plugins-official`, `codex@openai-codex`, `ecc@ecc`; plugins from other categories are enabled by `claude plugin install` |
| `extraKnownMarketplaces` | declares marketplaces: ponytail, anthropic-agent-skills, ecc, openai-codex, ruflo, ui-ux-pro-max-skill, googlechrome, heydamir |
| `sandbox.excludedCommands` | `["codex"]`, lets the Codex plugin run outside the sandbox |
| `model`, `effortLevel` | defaults `opus` / `high`, applied only when unset |

**`~/.codex/config.toml`**: `[mcp_servers.<name>]` blocks, created by `codex mcp add`.

**`~/.codex/AGENTS.md`** and **`~/.claude/CLAUDE.md`**: see section 8.

Not copied: `permissions.allow` (project-specific paths) and `statusLine` (hard-coded versioned plugin path).

## 8. Shared AGENTS.md

[`shared/AGENTS.md`](shared/AGENTS.md) is the single source of truth for agent instructions: ask instead of guessing, match local style, minimal diffs, verify before reporting done, no direct pushes to `main`, no secrets in git, and the category tool list.

- Codex reads `~/.codex/AGENTS.md` (copied by the installer).
- Claude Code reads `~/.claude/CLAUDE.md`, which imports it with `@~/.codex/AGENTS.md`.
- Edit `shared/AGENTS.md`, then run `./install.sh --config-only` to redeploy.
- Per-project override: add `AGENTS.md` to the repository (Codex) and a `CLAUDE.md` containing `@AGENTS.md` (Claude Code).

### Project templates

[`templates/`](templates/) holds general, project-neutral starting points for a new repository: `AGENTS.template.md`, a process set (PRD, plan, testing, review, security gate, cleanup), helper scripts (`check.sh`, `run-bg.sh`, `janitor.sh`), a sandboxed `settings.template.json`, one read-only `reviewer` subagent, CI starting points and a base `.gitignore`. `install.sh` (also with `--config-only`) copies them to `~/.codex/templates/`, and the shared `AGENTS.md` tells every agent to offer them when a project is new (empty repo or no `AGENTS.md`). The agent copies and adapts what it needs, following [`templates/README.md`](templates/README.md), and you approve the result; existing projects are left alone. Edit `templates/` here, then re-run `./install.sh --config-only` to redeploy. Check the scripts with `bash templates/scripts/tests/selfcheck.sh`.

## 9. Account-synced items

Plugins and connectors marked **account** sync when Claude Code is signed in to the same claude.ai account. They cannot be installed from a repository.

- Plugins: `engineering`, `design`, `pdf-viewer`, `transcribe-so`, `ffmpeg-llm`, `video-to-code-skill`, `watch-video`, `cowork-plugin-management`.
- Connectors: enable in claude.ai → Settings → Connectors. URLs are listed per category in section 4.
- Plugin-bundled MCP entries (`plugin:engineering:*`, `plugin:design:*`) show "Needs authentication" until authorized in Claude Code. Asana reports "does not support dynamic client registration"; this is a server limitation.
- Remote connector URLs were taken from Claude Code. Authorization from Codex is not guaranteed for every server (some are issued for claude.ai only); a failure is reported at the end of the run and does not stop other steps.

## 10. Troubleshooting

| Symptom | Action |
|---|---|
| "already exists" on marketplace or plugin | Harmless; verify with `claude plugin list`. |
| Plugin installed at two scopes | `claude plugin list` shows scope; uninstall the unwanted one. |
| MCP "Failed to connect" | Run its command from section 4 in a terminal; usually Node is missing or outdated. |
| Codex plugin inactive | Open `/hooks`, trust hooks, start a new thread. |
| Remote connector not authorized in Codex | `codex mcp login <name>`; if refused, use the connector in Claude Code only. |
| `ruflo-*` plugins not loading | Requires Claude Code 2.1.287+; run `claude update`, then `/reload-plugins`. |
| ECC duplicated skills or hooks | Follow "Reset / Uninstall ECC" in the ECC README; do not mix plugin and manual installs. |
| Restore previous config | `~/.claude/settings.json.bak`, `~/.codex/AGENTS.md.bak`. |

## 11. Maintenance

1. Capture the current state: `claude plugin marketplace list`, `claude plugin list`, `claude mcp list`, `codex mcp list`, `cat ~/.codex/config.toml`.
2. Add new items as a row in the `CATALOGUE` block of `install.sh` (`category|type|name|value`).
3. Add the item to its category table in section 4 (and to `shared/AGENTS.md` if agents should know about it).
4. Merge tool lists from every machine in use (the catalogue is a union).
5. Run `./install.sh --list` and `./install.sh --dry-run`, then commit.
