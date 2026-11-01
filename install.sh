#!/usr/bin/env bash
# Category-based setup for Claude Code + Codex (plugins, MCP servers, settings, shared AGENTS.md).
# Idempotent: anything already installed is skipped. Compatible with macOS bash 3.2.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ALL_CATEGORIES="dev design video audio docs agents security"

# ---------------------------------------------------------------------------
# Catalogue. One entry per line:  category|type|name|value
#   market  : Claude/Codex plugin marketplace          value = GitHub owner/repo
#   plugin  : plugin installed from a marketplace      name  = plugin@marketplace
#   mcp     : local stdio MCP server (Claude + Codex)  value = command line
#   cmarket : Codex plugin marketplace                 value = GitHub owner/repo
#   cplugin : plugin installed from a Codex marketplace name = plugin@marketplace
#   cmcp    : MCP server for Codex only (Claude gets it from a plugin)  value = command line
#   agentskill : skill pack installed with the `skills` CLI into Claude Code and/or Codex (user scope)   value = GitHub owner/repo
#   cskill  : skill installed for Codex into ~/.agents/skills/<name>   value = install command
#   remote  : remote OAuth MCP server (Codex only,     value = URL
#             --connectors; Claude gets these from your claude.ai account)
# Items with no installer (account-synced plugins/connectors) are documented in README.md.
# ---------------------------------------------------------------------------
CATALOGUE='
core|market|ponytail|DietrichGebert/ponytail
core|market|claude-plugins-official|anthropics/claude-plugins-official
core|market|anthropic-agent-skills|anthropics/skills
core|market|openai-codex|openai/codex-plugin-cc
core|plugin|ponytail@ponytail|
core|plugin|code-review@claude-plugins-official|
core|plugin|codex@openai-codex|
core|plugin|claude-md-management@claude-plugins-official|
core|plugin|claude-code-setup@claude-plugins-official|
core|market|ecc|affaan-m/ECC
core|plugin|ecc@ecc|
core|cmarket|ponytail|DietrichGebert/ponytail
core|cplugin|ponytail@ponytail|
core|cmarket|ecc|affaan-m/ECC
core|cplugin|ecc@ecc|
core|mcp|context7|npx -y @upstash/context7-mcp@latest
core|mcp|sequential-thinking|npx -y @modelcontextprotocol/server-sequential-thinking
core|mcp|memory|npx -y @modelcontextprotocol/server-memory
dev|plugin|feature-dev@claude-plugins-official|
dev|plugin|plugin-dev@claude-plugins-official|
dev|plugin|supabase@claude-plugins-official|
dev|mcp|playwright|npx -y @playwright/mcp --browser chrome
dev|mcp|token-optimizer|npx -y token-optimizer-mcp
dev|cmcp|chrome-devtools|npx -y chrome-devtools-mcp@1.10.1
dev|remote|vercel|https://mcp.vercel.com
design|mcp|magic|npx -y @magicuidesign/mcp@latest
design|market|ui-ux-pro-max-skill|nextlevelbuilder/ui-ux-pro-max-skill
design|plugin|ui-ux-pro-max@ui-ux-pro-max-skill|
design|cskill|ui-ux-pro-max|npx -y ui-ux-pro-max-cli init --ai universal --global
design|agentskill|hallmark|nutlope/hallmark
design|remote|excalidraw|https://mcp.excalidraw.com/mcp
video|agentskill|remotion|remotion-dev/skills
audio|remote|elevenlabs|https://api.elevenlabs.io/v1/mcp
docs|cmcp|pdf|npx -y @modelcontextprotocol/server-pdf --stdio
docs|remote|claude-docs|https://api.anthropic.com/v1/pages/mcp
docs|remote|google-drive|https://drivemcp.googleapis.com/mcp/v1
docs|remote|goodnotes|https://claude-mcp-api.ml.goodnotes.com/mcp
agents|market|ruflo|ruvnet/ruflo
agents|plugin|ruflo-core@ruflo|
agents|plugin|ruflo-console@ruflo|
agents|plugin|ruflo-mods@ruflo|
agents|cmcp|ruflo|npx -y ruflo@latest mcp start
security|plugin|security-guidance@claude-plugins-official|
security|plugin|claude-security@claude-plugins-official|
security|mcp|rea|npx -y rea-agents@6.5.0 mcp
'

DO_CLAUDE=1; DO_CODEX=1
DO_PLUGINS=1; DO_MCP=1; DO_CONFIG=1
NO_ECC=0; WITH_CONNECTORS=0; DRY=0
SELECTED=""   # empty = all categories

usage() {
  cat <<USAGE
Usage: ./install.sh [options]

Targets (default: both)
  --claude              set up Claude Code only
  --codex               set up Codex only (app, CLI and IDE extension share ~/.codex/config.toml)

Categories (default: core + every category). Passing any category flag installs core + only those.
  --dev --design --video --audio --docs --agents --security
  --list                print the catalogue per category and exit

Parts (default: all)
  --plugins-only        plugins/marketplaces only
  --mcp-only            MCP servers only
  --config-only         settings.json merge + AGENTS.md only

Extras
  --no-ecc              skip Everything Claude Code (ecc@ecc is installed by default as part of core)
  --with-connectors     add remote OAuth connectors of the selected categories to Codex
  --dry-run             print commands, change nothing
  -h, --help

Env: GITHUB_PERSONAL_ACCESS_TOKEN enables the github MCP server (dev category).
Account-synced plugins/connectors have no installer entries: see README.md.
USAGE
}

add_cat() { case " $SELECTED " in *" $1 "*) ;; *) SELECTED="$SELECTED $1" ;; esac; }

for a in "$@"; do
  case "$a" in
    --claude) DO_CODEX=0 ;;
    --codex) DO_CLAUDE=0 ;;
    --dev|--design|--video|--audio|--docs|--agents|--security) add_cat "${a#--}" ;;
    --plugins-only) DO_MCP=0; DO_CONFIG=0 ;;
    --mcp-only) DO_PLUGINS=0; DO_CONFIG=0 ;;
    --config-only) DO_PLUGINS=0; DO_MCP=0 ;;
    --no-ecc) NO_ECC=1 ;;
    --with-connectors) WITH_CONNECTORS=1 ;;
    --dry-run) DRY=1 ;;
    --list)
      for c in core $ALL_CATEGORIES; do
        echo "[$c]"; echo "$CATALOGUE" | awk -F'|' -v c="$c" '$1==c && $2!="market" {printf "  %-7s %s %s\n",$2,$3,$4}'
      done
      exit 0 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $a" >&2; usage; exit 1 ;;
  esac
done
[ -z "$SELECTED" ] && SELECTED="$ALL_CATEGORIES"
SELECTED="core $SELECTED"

FAILED=()
say() { printf '\n\033[1m==> %s\033[0m\n' "$*"; }
run() {
  echo "+ $*"
  [ "$DRY" = 1 ] && return 0
  "$@" || { echo "  ! failed: $*" >&2; FAILED+=("$*"); }
}
have() { command -v "$1" >/dev/null 2>&1; }

# entries <type>  -> "name|value" lines of selected categories
entries() {
  echo "$CATALOGUE" | awk -F'|' -v t="$1" -v sel="$SELECTED" -v noecc="$NO_ECC" \
    'BEGIN{n=split(sel,s," "); for(i=1;i<=n;i++) ok[s[i]]=1}
     NF && $2==t && ok[$1] && !(noecc==1 && $3 ~ /^ecc(@|$)/) {print $3 "|" $4}'
}

install_agents_md() {
  local dst="$HOME/.codex/AGENTS.md"
  [ "$DRY" = 1 ] && { echo "+ copy shared/AGENTS.md -> $dst"; return; }
  mkdir -p "$HOME/.codex"
  [ -f "$dst" ] && ! cmp -s "$dst" "$ROOT/shared/AGENTS.md" && cp "$dst" "$dst.bak"
  cp "$ROOT/shared/AGENTS.md" "$dst" && echo "wrote $dst"
}

install_claude_md() {
  local f="$HOME/.claude/CLAUDE.md" line="@~/.codex/AGENTS.md"
  install_agents_md
  if [ -f "$f" ] && grep -qF "$line" "$f"; then echo "CLAUDE.md already imports AGENTS.md"
  elif [ "$DRY" = 1 ]; then echo "+ append '$line' to $f"
  else mkdir -p "$HOME/.claude"; printf '\n# Shared instructions (managed by AI_dev_setup)\n%s\n' "$line" >> "$f"; echo "updated $f"; fi
}

# ======================= Claude Code =======================
claude_setup() {
  say "Claude Code  [categories: $SELECTED]"
  have claude || { echo "claude CLI not found: https://docs.claude.com/en/docs/claude-code" >&2; FAILED+=("claude CLI missing"); return; }

  if [ "$DO_PLUGINS" = 1 ]; then
    local markets plugins name value
    markets="$(claude plugin marketplace list 2>/dev/null || true)"
    plugins="$(claude plugin list 2>/dev/null || true)"
    while IFS='|' read -r name value; do
      [ -z "$name" ] && continue
      if grep -qE "❯ ${name}\$" <<<"$markets"; then echo "marketplace $name already added"; else run claude plugin marketplace add "$value"; fi
    done < <(entries market)
    while IFS='|' read -r name value; do
      [ -z "$name" ] && continue
      if grep -qE "❯ ${name}\$" <<<"$plugins"; then echo "plugin $name already installed"; else run claude plugin install "$name" --scope user; fi
    done < <(entries plugin)
  fi

  if [ "$DO_MCP" = 1 ]; then
    local existing; existing="$(claude mcp list 2>/dev/null || true)"
    while IFS='|' read -r name value; do
      [ -z "$name" ] && continue
      if grep -q "^$name:" <<<"$existing"; then echo "mcp $name already configured"; else
        # shellcheck disable=SC2086
        run claude mcp add --scope user "$name" -- $value
      fi
    done < <(entries mcp)
    case " $SELECTED " in *" dev "*)
      if [ -n "${GITHUB_PERSONAL_ACCESS_TOKEN:-}" ]; then
        grep -q "^github:" <<<"$existing" || \
          run claude mcp add --scope user github -e GITHUB_PERSONAL_ACCESS_TOKEN="$GITHUB_PERSONAL_ACCESS_TOKEN" -- npx -y @modelcontextprotocol/server-github
      else echo "skip github MCP: export GITHUB_PERSONAL_ACCESS_TOKEN and re-run"; fi ;;
    esac
  fi

  if [ "$DO_CONFIG" = 1 ]; then
    if have node; then run node "$ROOT/scripts/merge-json.mjs" "$ROOT/claude/settings.base.json" "$HOME/.claude/settings.json"
    else echo "node missing: cannot merge settings.json" >&2; FAILED+=("settings merge (node missing)"); fi
    install_claude_md
  fi
}

# ======================= Codex =======================
codex_setup() {
  say "Codex  [categories: $SELECTED]"
  have codex || { echo "codex CLI not found: npm install -g @openai/codex" >&2; FAILED+=("codex CLI missing"); return; }

  if [ "$DO_PLUGINS" = 1 ]; then
    local cname cvalue
    while IFS='|' read -r cname cvalue; do
      [ -z "$cname" ] && continue
      run codex plugin marketplace add "$cvalue"
    done < <(entries cmarket)
    while IFS='|' read -r cname cvalue; do
      [ -z "$cname" ] && continue
      run codex plugin add "$cname"
    done < <(entries cplugin)
    echo "NOTE: open /hooks in Codex, trust the plugin hooks, start a new thread."
  fi

  if [ "$DO_MCP" = 1 ]; then
    local existing name value; existing="$(codex mcp list 2>/dev/null || true)"
    while IFS='|' read -r name value; do
      [ -z "$name" ] && continue
      if grep -qE "^$name( |\$)" <<<"$existing"; then echo "mcp $name already configured"; else
        # shellcheck disable=SC2086
        run codex mcp add "$name" -- $value
      fi
    done < <(entries mcp)
    while IFS='|' read -r name value; do
      [ -z "$name" ] && continue
      if grep -qE "^$name( |\$)" <<<"$existing"; then echo "mcp $name already configured"; else
        # shellcheck disable=SC2086
        run codex mcp add "$name" -- $value
      fi
    done < <(entries cmcp)
    case " $SELECTED " in *" dev "*)
      if [ -n "${GITHUB_PERSONAL_ACCESS_TOKEN:-}" ]; then
        grep -qE "^github( |\$)" <<<"$existing" || \
          run codex mcp add github --env GITHUB_PERSONAL_ACCESS_TOKEN="$GITHUB_PERSONAL_ACCESS_TOKEN" -- npx -y @modelcontextprotocol/server-github
      fi ;;
    esac
    if [ "$WITH_CONNECTORS" = 1 ]; then
      while IFS='|' read -r name value; do
        [ -z "$name" ] && continue
        if grep -qE "^$name( |\$)" <<<"$existing"; then echo "mcp $name already configured"; else
          run codex mcp add "$name" --url "$value"
          echo "  -> authorize with: codex mcp login $name"
        fi
      done < <(entries remote)
    fi
  fi

  if [ "$DO_PLUGINS" = 1 ]; then
    local sname scmd
    while IFS='|' read -r sname scmd; do
      [ -z "$sname" ] && continue
      if [ -d "$HOME/.agents/skills/$sname" ]; then echo "skill $sname already in ~/.agents/skills"; else
        # shellcheck disable=SC2086
        run $scmd
      fi
    done < <(entries cskill)
  fi

  [ "$DO_CONFIG" = 1 ] && install_agents_md
  return 0
}

# Skill packs installed with the `skills` CLI (needs Node 22.20+). One call targets whichever tools are selected.
skillpacks_setup() {
  [ "$DO_PLUGINS" = 1 ] || return 0
  local sname srepo agents=""
  [ "$DO_CLAUDE" = 1 ] && agents="$agents -a claude-code"
  [ "$DO_CODEX" = 1 ] && agents="$agents -a codex"
  while IFS='|' read -r sname srepo; do
    [ -z "$sname" ] && continue
    say "Skill pack: $sname ($srepo)"
    have npx || { echo "npx missing" >&2; FAILED+=("skill pack $sname (npx missing)"); continue; }
    # shellcheck disable=SC2086
    run npx -y skills add "$srepo" -g $agents -s '*' -y
  done < <(entries agentskill)
}

[ "$DO_CLAUDE" = 1 ] && claude_setup
[ "$DO_CODEX" = 1 ] && codex_setup
skillpacks_setup

say "Done"
if [ "${#FAILED[@]}" -gt 0 ]; then
  echo "Failed steps (fix and re-run; the script is idempotent):"
  printf '  - %s\n' "${FAILED[@]}"
  exit 1
fi
echo "Completed. Restart Claude Code / Codex to load new plugins and MCP servers."
