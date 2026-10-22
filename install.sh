#!/usr/bin/env bash
# One-shot setup for Claude Code + Codex (plugins, MCP servers, settings, shared AGENTS.md).
# Safe to re-run: anything already installed is skipped.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DO_CLAUDE=1; DO_CODEX=1
DO_PLUGINS=1; DO_MCP=1; DO_CONFIG=1
WITH_ECC=0; WITH_CONNECTORS=0; DRY=0

usage() {
  cat <<'USAGE'
Usage: ./install.sh [options]

Targets (default: both)
  --claude            only set up Claude Code
  --codex             only set up Codex (app, CLI and IDE share the same config)

Parts (default: all)
  --plugins-only      only plugins/marketplaces
  --mcp-only          only MCP servers
  --config-only       only settings.json merge + AGENTS.md

Extras (off by default)
  --with-ecc          also install Everything Claude Code (ecc@ecc)
  --with-connectors   also add remote OAuth connectors (Gmail, Drive, Calendar, Slack, Vercel, Excalidraw) to Codex

Other
  --dry-run           print what would run, change nothing
  -h, --help          this help

Optional env: GITHUB_PERSONAL_ACCESS_TOKEN (enables the github MCP server)
USAGE
}

for a in "$@"; do
  case "$a" in
    --claude) DO_CODEX=0 ;;
    --codex) DO_CLAUDE=0 ;;
    --plugins-only) DO_MCP=0; DO_CONFIG=0 ;;
    --mcp-only) DO_PLUGINS=0; DO_CONFIG=0 ;;
    --config-only) DO_PLUGINS=0; DO_MCP=0 ;;
    --with-ecc) WITH_ECC=1 ;;
    --with-connectors) WITH_CONNECTORS=1 ;;
    --dry-run) DRY=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $a" >&2; usage; exit 1 ;;
  esac
done

FAILED=()
say() { printf '\n\033[1m==> %s\033[0m\n' "$*"; }
run() {
  echo "+ $*"
  [ "$DRY" = 1 ] && return 0
  "$@" || { echo "  ! failed: $*" >&2; FAILED+=("$*"); }
}
have() { command -v "$1" >/dev/null 2>&1; }

# ---------- MCP server catalogue (name | command...) ----------
# stdio servers launched with npx. Format: "name::command arg arg"
MCP_SERVERS=(
  "context7::npx -y @upstash/context7-mcp@latest"
  "sequential-thinking::npx -y @modelcontextprotocol/server-sequential-thinking"
  "memory::npx -y @modelcontextprotocol/server-memory"
  "playwright::npx -y @playwright/mcp --browser chrome"
  "magic::npx -y @magicuidesign/mcp@latest"
  "pdf::npx -y @modelcontextprotocol/server-pdf --stdio"
)
# name|url — remote OAuth servers (Codex only; Claude gets these from your claude.ai account)
CONNECTORS=(
  "gmail|https://gmailmcp.googleapis.com/mcp/v1"
  "google-drive|https://drivemcp.googleapis.com/mcp/v1"
  "google-calendar|https://calendarmcp.googleapis.com/mcp/v1"
  "slack|https://mcp.slack.com/mcp"
  "vercel|https://mcp.vercel.com"
  "excalidraw|https://mcp.excalidraw.com/mcp"
)

# ======================= Claude Code =======================
claude_setup() {
  say "Claude Code"
  have claude || { echo "claude CLI not found. Install: https://docs.claude.com/en/docs/claude-code" >&2; FAILED+=("claude CLI missing"); return; }

  if [ "$DO_PLUGINS" = 1 ]; then
    local markets; markets="$(claude plugin marketplace list 2>/dev/null || true)"
    add_market() { # name repo
      if grep -q "❯ $1\b" <<<"$markets"; then echo "marketplace $1 already added"; else run claude plugin marketplace add "$2"; fi
    }
    add_market ponytail DietrichGebert/ponytail
    add_market claude-plugins-official anthropics/claude-plugins-official
    add_market anthropic-agent-skills anthropics/skills
    add_market openai-codex openai/codex-plugin-cc
    [ "$WITH_ECC" = 1 ] && add_market ecc affaan-m/ECC

    local plugins; plugins="$(claude plugin list 2>/dev/null || true)"
    add_plugin() { # name@market
      if grep -q "❯ $1" <<<"$plugins"; then echo "plugin $1 already installed"; else run claude plugin install "$1" --scope user; fi
    }
    add_plugin ponytail@ponytail
    add_plugin code-review@claude-plugins-official
    add_plugin codex@openai-codex
    [ "$WITH_ECC" = 1 ] && add_plugin ecc@ecc
  fi

  if [ "$DO_MCP" = 1 ]; then
    local existing; existing="$(claude mcp list 2>/dev/null || true)"
    for entry in "${MCP_SERVERS[@]}"; do
      local name="${entry%%::*}" cmd="${entry#*::}"
      if grep -q "^$name:" <<<"$existing"; then echo "mcp $name already configured"; else
        # shellcheck disable=SC2086
        run claude mcp add --scope user "$name" -- $cmd
      fi
    done
    if [ -n "${GITHUB_PERSONAL_ACCESS_TOKEN:-}" ]; then
      grep -q "^github:" <<<"$existing" || \
        run claude mcp add --scope user github -e GITHUB_PERSONAL_ACCESS_TOKEN="$GITHUB_PERSONAL_ACCESS_TOKEN" -- npx -y @modelcontextprotocol/server-github
    else
      echo "skip github MCP: export GITHUB_PERSONAL_ACCESS_TOKEN=... and re-run to enable"
    fi
  fi

  if [ "$DO_CONFIG" = 1 ]; then
    if have node; then run node "$ROOT/scripts/merge-json.mjs" "$ROOT/claude/settings.base.json" "$HOME/.claude/settings.json"
    else echo "node missing: cannot merge settings.json" >&2; FAILED+=("settings merge (node missing)"); fi
    install_claude_md
  fi
}

install_claude_md() {
  local f="$HOME/.claude/CLAUDE.md" line="@~/.codex/AGENTS.md"
  run mkdir -p "$HOME/.claude" "$HOME/.codex"
  # Claude imports the shared file; make sure the file it points at exists even for --claude only.
  install_agents_md
  if [ -f "$f" ] && grep -qF "$line" "$f"; then echo "CLAUDE.md already imports AGENTS.md"
  elif [ "$DRY" = 1 ]; then echo "+ append '$line' to $f"
  else printf '\n# Shared instructions (managed by ai-dev-setup)\n%s\n' "$line" >> "$f"; echo "updated $f"; fi
}

# ======================= Codex =======================
install_agents_md() {
  local dst="$HOME/.codex/AGENTS.md"
  [ "$DRY" = 1 ] && { echo "+ copy shared/AGENTS.md -> $dst"; return; }
  mkdir -p "$HOME/.codex"
  [ -f "$dst" ] && ! cmp -s "$dst" "$ROOT/shared/AGENTS.md" && cp "$dst" "$dst.bak"
  cp "$ROOT/shared/AGENTS.md" "$dst" && echo "wrote $dst"
}

codex_setup() {
  say "Codex"
  have codex || { echo "codex CLI not found. Install: npm install -g @openai/codex   (the app bundles its own; the CLI is needed for this script)" >&2; FAILED+=("codex CLI missing"); return; }

  if [ "$DO_PLUGINS" = 1 ]; then
    run codex plugin marketplace add DietrichGebert/ponytail
    run codex plugin add ponytail@ponytail
    if [ "$WITH_ECC" = 1 ]; then
      run codex plugin marketplace add affaan-m/ECC
      run codex plugin add ecc@ecc
    fi
    echo "NOTE: open /hooks in Codex and trust the plugin hooks, then start a new thread."
  fi

  if [ "$DO_MCP" = 1 ]; then
    local existing; existing="$(codex mcp list 2>/dev/null || true)"
    for entry in "${MCP_SERVERS[@]}"; do
      local name="${entry%%::*}" cmd="${entry#*::}"
      if grep -qE "^$name( |\$)" <<<"$existing"; then echo "mcp $name already configured"; else
        # shellcheck disable=SC2086
        run codex mcp add "$name" -- $cmd
      fi
    done
    if [ -n "${GITHUB_PERSONAL_ACCESS_TOKEN:-}" ]; then
      grep -qE "^github( |\$)" <<<"$existing" || \
        run codex mcp add github --env GITHUB_PERSONAL_ACCESS_TOKEN="$GITHUB_PERSONAL_ACCESS_TOKEN" -- npx -y @modelcontextprotocol/server-github
    fi
    if [ "$WITH_CONNECTORS" = 1 ]; then
      for entry in "${CONNECTORS[@]}"; do
        local name="${entry%%|*}" url="${entry#*|}"
        if grep -qE "^$name( |\$)" <<<"$existing"; then echo "mcp $name already configured"; else
          run codex mcp add "$name" --url "$url"
          echo "  -> authorize with: codex mcp login $name"
        fi
      done
    fi
  fi

  [ "$DO_CONFIG" = 1 ] && install_agents_md
}

[ "$DO_CLAUDE" = 1 ] && claude_setup
[ "$DO_CODEX" = 1 ] && codex_setup

say "Done"
if [ "${#FAILED[@]}" -gt 0 ]; then
  echo "These steps failed (re-run after fixing, the script is idempotent):"
  printf '  - %s\n' "${FAILED[@]}"
  exit 1
fi
echo "All steps completed. Restart Claude Code / Codex so new plugins and MCP servers load."
