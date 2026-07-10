#!/usr/bin/env bash
# ============================================================================
# .opencode/init.sh
#
# Interactive init script for opencode workspace projects.
# Detects existing project files, prompts for context.md fields with defaults,
# and optionally seeds memory.md with the first architectural decision.
#
# Usage:
#   bash .opencode/init.sh
#
# Run this once when starting a new project, or to re-initialize context.md
# if it still contains template placeholders.
# ============================================================================
set -euo pipefail

# ── Colors ────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

info()  { printf "${CYAN}%s${NC}\n" "$*"; }
ok()    { printf "${GREEN}✓ %s${NC}\n" "$*"; }
warn()  { printf "${YELLOW}⚠ %s${NC}\n" "$*"; }
err()   { printf "${RED}✗ %s${NC}\n" "$*" >&2; }

# ── Paths ─────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CONTEXT_FILE="$SCRIPT_DIR/context.md"
MEMORY_FILE="$SCRIPT_DIR/memory.md"

TODAY="$(date +%Y-%m-%d)"

# ── Pre-flight ────────────────────────────────────────────────────────────
ensure_opencode_dir() {
  if [ ! -d "$SCRIPT_DIR" ]; then
    mkdir -p "$SCRIPT_DIR"
    ok "Created $SCRIPT_DIR"
  fi
}

# ── Detection helpers ─────────────────────────────────────────────────────
detect_from_package_json() {
  local pkg="$WORKSPACE_ROOT/package.json"
  [ ! -f "$pkg" ] && return 1

  local name desc runtime framework db orm frontend build_tool state_mgr ui_lib router
  name="$(node -e "try{console.log(require('$pkg').name||'')}catch(e){}" 2>/dev/null)" || name=""
  desc="$(node -e "try{console.log(require('$pkg').description||'')}catch(e){}" 2>/dev/null)" || desc=""
  runtime="Node.js"

  local deps
  deps="$(node -e "try{const d=require('$pkg').dependencies||{};console.log(Object.keys(d).join('\\n'))}catch(e){}" 2>/dev/null)" || deps=""
  local devDeps
  devDeps="$(node -e "try{const d=require('$pkg').devDependencies||{};console.log(Object.keys(d).join('\\n'))}catch(e){}" 2>/dev/null)" || devDeps=""
  local allDeps="$deps"$'\n'"$devDeps"

  if echo "$allDeps" | grep -q "express"; then framework="Express"
  elif echo "$allDeps" | grep -q "fastify"; then framework="Fastify"
  elif echo "$allDeps" | grep -q "hono"; then framework="Hono"
  elif echo "$allDeps" | grep -q "nestjs"; then framework="NestJS"
  fi

  if echo "$allDeps" | grep -q "better-sqlite3"; then db="SQLite (via better-sqlite3)"
  elif echo "$allDeps" | grep -q "pg\|postgres"; then db="PostgreSQL"
  elif echo "$allDeps" | grep -q "mysql\|mysql2"; then db="MySQL"
  elif echo "$allDeps" | grep -q "sqlite3"; then db="SQLite"
  fi

  if echo "$allDeps" | grep -q "drizzle-orm"; then orm="Drizzle ORM"
  elif echo "$allDeps" | grep -q "prisma"; then orm="Prisma"
  elif echo "$allDeps" | grep -q "kysely"; then orm="Kysely"
  elif echo "$allDeps" | grep -q "typeorm"; then orm="TypeORM"
  fi

  if echo "$allDeps" | grep -q "vue"; then frontend="Vue 3"
  elif echo "$allDeps" | grep -q "react"; then frontend="React"
  elif echo "$allDeps" | grep -q "svelte"; then frontend="Svelte"
  elif echo "$allDeps" | grep -q "solid-js"; then frontend="Solid"
  fi

  if echo "$allDeps" | grep -q "vite"; then build_tool="Vite"
  elif echo "$allDeps" | grep -q "webpack"; then build_tool="Webpack"
  elif echo "$allDeps" | grep -q "esbuild"; then build_tool="esbuild"
  fi

  if echo "$allDeps" | grep -q "pinia"; then state_mgr="Pinia"
  elif echo "$allDeps" | grep -q "redux"; then state_mgr="Redux"
  elif echo "$allDeps" | grep -q "zustand"; then state_mgr="Zustand"
  fi

  if echo "$allDeps" | grep -q "vuetify\|tailwindcss"; then ui_lib="Tailwind"
  elif echo "$allDeps" | grep -q "shadcn-vue\|shadcn"; then ui_lib="shadcn-vue"
  elif echo "$allDeps" | grep -q "element-plus\|ant-design"; then
    if echo "$frontend" | grep -q "Vue"; then ui_lib="Element Plus"
    else ui_lib="Ant Design"
    fi
  fi

  if echo "$allDeps" | grep -q "vue-router"; then router="Vue Router"
  elif echo "$allDeps" | grep -q "react-router"; then router="React Router"
  elif echo "$allDeps" | grep -q "tanstack-router\|tanstack/react-router"; then router="TanStack Router"
  fi

  local auth_method=""
  if echo "$allDeps" | grep -q "jsonwebtoken"; then auth_method="JWT"
  fi
  if echo "$allDeps" | grep -q "next-auth\|@auth"; then auth_method="NextAuth.js"
  elif echo "$allDeps" | grep -q "passport"; then auth_method="Passport.js"
  fi

  cat <<DETECT
name="${name}"
description="${desc}"
runtime="${runtime}"
framework="${framework}"
database="${db}"
orm="${orm}"
frontend="${frontend}"
build_tool="${build_tool}"
state_management="${state_mgr}"
ui_library="${ui_lib}"
router="${router}"
auth="${auth_method}"
DETECT
}

detect_from_composer_json() {
  local f="$WORKSPACE_ROOT/composer.json"
  [ ! -f "$f" ] && return 1
  local name desc
  name="$(php -r "echo json_decode(file_get_contents('$f'))->name??'';" 2>/dev/null)" || name=""
  desc="$(php -r "echo json_decode(file_get_contents('$f'))->description??'';" 2>/dev/null)" || desc=""
  echo "runtime=PHP"
  [ -n "$name" ] && echo "name=${name}"
  [ -n "$desc" ] && echo "description=${desc}"
}

detect_from_cargo_toml() {
  local f="$WORKSPACE_ROOT/Cargo.toml"
  [ ! -f "$f" ] && return 1
  # Minimal TOML parsing — extract name & description
  local name desc
  name="$(grep -m1 '^name\s*=' "$f" | sed 's/^name\s*=\s*"\(.*\)".*/\1/' 2>/dev/null)" || name=""
  desc="$(grep -m1 '^description\s*=' "$f" | sed 's/^description\s*=\s*"\(.*\)".*/\1/' 2>/dev/null)" || desc=""
  echo "runtime=Rust"
  [ -n "$name" ] && echo "name=${name}"
  [ -n "$desc" ] && echo "description=${desc}"
}

detect_from_go_mod() {
  local f="$WORKSPACE_ROOT/go.mod"
  [ ! -f "$f" ] && return 1
  local module
  module="$(head -1 "$f" | awk '{print $2}' 2>/dev/null)" || module=""
  echo "runtime=Go"
  [ -n "$module" ] && echo "name=${module##*/}"
}

detect_infrastructure() {
  local cloud="" ci="" services=""
  if [ -f "$WORKSPACE_ROOT/Dockerfile" ] || ls "$WORKSPACE_ROOT/Dockerfile."* 1>/dev/null 2>&1; then
    services="Docker"
  fi
  if [ -f "$WORKSPACE_ROOT/docker-compose.yml" ] || [ -f "$WORKSPACE_ROOT/docker-compose.yaml" ]; then
    services="${services:+${services}, }Docker Compose"
  fi
  if [ -d "$WORKSPACE_ROOT/.github/workflows" ]; then
    ci="GitHub Actions"
  fi
  if [ -d "$WORKSPACE_ROOT/.gitlab-ci.yml" ]; then
    ci="GitLab CI"
  fi
  # Check for common cloud provider config files
  if [ -f "$WORKSPACE_ROOT/serverless.yml" ] || [ -f "$WORKSPACE_ROOT/serverless.yaml" ]; then
    cloud="AWS (serverless)"
  fi
  if [ -d "$WORKSPACE_ROOT/terraform" ] || ls "$WORKSPACE_ROOT/*.tf" 1>/dev/null 2>&1; then
    cloud="${cloud:+${cloud} }/ Terraform (multi-cloud)"
  fi
  if [ -f "$WORKSPACE_ROOT/.aws/config" ] || [ -d "$WORKSPACE_ROOT/.aws" ]; then
    cloud="${cloud:-AWS}"
  fi

  cat <<DETECT
cloud="${cloud}"
ci="${ci}"
services="${services}"
DETECT
}

detect_all() {
  # Merge all detection results into a single env-file-like output
  # Later sources override earlier ones for the same key
  local tmpdir
  tmpdir="$(mktemp -d)"
  detect_from_package_json > "$tmpdir/01_pkg" 2>/dev/null || true
  detect_from_composer_json > "$tmpdir/02_composer" 2>/dev/null || true
  detect_from_cargo_toml > "$tmpdir/03_cargo" 2>/dev/null || true
  detect_from_go_mod > "$tmpdir/04_go" 2>/dev/null || true
  detect_infrastructure > "$tmpdir/05_infra" 2>/dev/null || true

  # Flatten into a single key=value map (last wins)
  awk -F= '!seen[$1]++' "$tmpdir"/* 2>/dev/null || true
  rm -rf "$tmpdir"
}

# shellcheck disable=SC2016
prompt_with_default() {
  local prompt="$1" default="$2" var_name="$3" optional="${4:-}"
  local display_default="${default:-(none)}"
  if [ -n "$default" ]; then
    printf "${CYAN}%s${NC} [${GREEN}%s${NC}]: " "$prompt" "$default"
  else
    printf "${CYAN}%s${NC}: " "$prompt"
  fi
  read -r input
  if [ -z "$input" ] && [ -n "$default" ]; then
    input="$default"
  fi
  if [ -z "$input" ] && [ "$optional" != "optional" ]; then
    warn "'$prompt' cannot be empty. Try again."
    prompt_with_default "$prompt" "$default" "$var_name" "$optional"
    return
  fi
  eval "$var_name=\"\$input\""
}

# ── Check existing context.md ─────────────────────────────────────────────
check_existing_context() {
  if [ ! -f "$CONTEXT_FILE" ]; then
    info "No context.md found. Will create a new one."
    return 0
  fi

  # Detect if it still has template placeholders
  if grep -q "<!-- e.g\." "$CONTEXT_FILE" 2>/dev/null || \
     grep -q "Example desition" "$CONTEXT_FILE" 2>/dev/null || \
     grep -q "Example"$'\n'" " "$CONTEXT_FILE" 2>/dev/null; then
    warn "context.md still has template placeholders."
    printf "${YELLOW}Overwrite it with fresh values? [y/N]${NC}: "
    read -r answer
    case "$answer" in
      y|Y|yes|YES) return 0 ;;
      *) info "Aborting. context.md left unchanged."; exit 0 ;;
    esac
  else
    warn "context.md already has content."
    printf "${YELLOW}Re-initialize anyway? This will OVERWRITE it. [y/N]${NC}: "
    read -r answer
    case "$answer" in
      y|Y|yes|YES) return 0 ;;
      *) info "Aborting. context.md left unchanged."; exit 0 ;;
    esac
  fi
}

# ── Generate context.md ───────────────────────────────────────────────────
generate_context() {
  info "Gathering project information..."

  # ── Project basics ──────────────────────────────────────────────────
  prompt_with_default "Project name" "${DETECTED[name]:-}" PROJECT_NAME
  prompt_with_default "Description" "${DETECTED[description]:-}" PROJECT_DESC
  prompt_with_default "Status (planning/in-development/beta/production)" "planning" PROJECT_STATUS

  # ── Backend ──────────────────────────────────────────────────────────
  echo
  info "--- Backend ---"
  prompt_with_default "Runtime" "${DETECTED[runtime]:-Node.js}" BACKEND_RUNTIME
  prompt_with_default "Framework" "${DETECTED[framework]:-}" BACKEND_FRAMEWORK "optional"
  prompt_with_default "Database" "${DETECTED[database]:-}" BACKEND_DB "optional"
  prompt_with_default "Query layer / ORM" "${DETECTED[orm]:-}" BACKEND_ORM "optional"
  prompt_with_default "Auth method" "${DETECTED[auth]:-}" BACKEND_AUTH "optional"

  # ── Frontend ─────────────────────────────────────────────────────────
  echo
  info "--- Frontend ---"
  prompt_with_default "Framework" "${DETECTED[frontend]:-}" FRONTEND_FRAMEWORK "optional"
  prompt_with_default "Build tool" "${DETECTED[build_tool]:-Vite}" FRONTEND_BUILD "optional"
  prompt_with_default "State management" "${DETECTED[state_management]:-}" FRONTEND_STATE "optional"
  prompt_with_default "UI library" "${DETECTED[ui_library]:-}" FRONTEND_UI "optional"
  prompt_with_default "Router" "${DETECTED[router]:-}" FRONTEND_ROUTER "optional"

  # ── Edge / Local ─────────────────────────────────────────────────────
  echo
  info "--- Edge / Local Device ---"
  prompt_with_default "Edge runtime" "${DETECTED[edge_runtime]:-}" EDGE_RUNTIME "optional"
  prompt_with_default "Local DB" "${DETECTED[local_db]:-SQLite}" EDGE_DB "optional"
  prompt_with_default "Hardware" "" EDGE_HARDWARE "optional"
  prompt_with_default "Connectivity (always-on/intermittent/offline-first)" "always-on" EDGE_CONNECTIVITY

  # ── Infrastructure ───────────────────────────────────────────────────
  echo
  info "--- Infrastructure ---"
  prompt_with_default "Cloud provider" "${DETECTED[cloud]:-}" INFRA_CLOUD "optional"
  prompt_with_default "Services in use" "${DETECTED[services]:-}" INFRA_SERVICES "optional"
  prompt_with_default "CI/CD" "${DETECTED[ci]:-}" INFRA_CI "optional"
  prompt_with_default "Tenancy model (single-tenant/multi-tenant)" "single-tenant" INFRA_TENANCY

  # ── Phase & decisions ────────────────────────────────────────────────
  echo
  info "--- Current Work ---"
  prompt_with_default "Current phase description" "Initial project setup" PHASE_DESC
  prompt_with_default "Active development areas (comma-separated)" "" ACTIVE_AREAS "optional"
  prompt_with_default "Known issues / tech debt" "" KNOWN_ISSUES "optional"
  prompt_with_default "Out of scope (for now)" "" OUT_OF_SCOPE "optional"

  # ── Write context.md ─────────────────────────────────────────────────
  cat > "$CONTEXT_FILE" <<CONTEXTEOF
# Project Context

> This file is the single source of truth for the active project state.
> Read it at the start of every session. Update it when phase, stack, or focus changes.

---

## Active Project

**Name**: ${PROJECT_NAME}
**Description**: ${PROJECT_DESC}
**Status**: ${PROJECT_STATUS}
**Last updated**: ${TODAY}

---

## Tech Stack

### Backend

- **Runtime**: ${BACKEND_RUNTIME:-TBD — decision needed}
- **Framework**: ${BACKEND_FRAMEWORK:-TBD — decision needed}
- **Language**: ${DETECTED[lang]:-TypeScript}
- **Database**: ${BACKEND_DB:-TBD — decision needed}
- **Query layer**: ${BACKEND_ORM:-TBD — decision needed}
- **Auth**: ${BACKEND_AUTH:-TBD — decision needed}

### Frontend

- **Framework**: ${FRONTEND_FRAMEWORK:-TBD — decision needed}
- **Build tool**: ${FRONTEND_BUILD:-TBD — decision needed}
- **State management**: ${FRONTEND_STATE:-TBD — decision needed}
- **UI library**: ${FRONTEND_UI:-TBD — decision needed}
- **Routing**: ${FRONTEND_ROUTER:-TBD — decision needed}

### Edge / Local Device

- **Runtime**: ${EDGE_RUNTIME:-TBD — decision needed}
- **Local DB**: ${EDGE_DB:-TBD — decision needed}
- **Hardware**: ${EDGE_HARDWARE:-TBD — decision needed}
- **Connectivity**: ${EDGE_CONNECTIVITY:-TBD — decision needed}

### Infrastructure

- **Cloud**: ${INFRA_CLOUD:-TBD — decision needed}
- **Services in use**: ${INFRA_SERVICES:-TBD — decision needed}
- **CI/CD**: ${INFRA_CI:-TBD — decision needed}
- **Tenancy model**: ${INFRA_TENANCY:-TBD — decision needed}

---

## Current Phase

${PHASE_DESC}

---

## Active Development Areas

$(if [ -n "$ACTIVE_AREAS" ]; then
  echo "$ACTIVE_AREAS" | tr ',' '\n' | sed 's/^ *//; s/ *$//' | sed 's/^/- /'
else
  echo "- (none yet)"
fi)

---

## Recent Decisions

<!-- The last 3–5 significant technical decisions.
     Older decisions that should never be re-discussed belong in memory.md.
     Format: YYYY-MM-DD: [what was decided and brief reason] -->

- (none yet — see memory.md for initial decisions)

---

## Known Issues / Tech Debt

$(if [ -n "$KNOWN_ISSUES" ]; then
  echo "$KNOWN_ISSUES" | tr ',' '\n' | sed 's/^ *//; s/ *$//' | sed 's/^/- /'
else
  echo "- (none yet)"
fi)

---

## Out of Scope (for now)

$(if [ -n "$OUT_OF_SCOPE" ]; then
  echo "$OUT_OF_SCOPE" | tr ',' '\n' | sed 's/^ *//; s/ *$//' | sed 's/^/- /'
else
  echo "- (none yet)"
fi)
CONTEXTEOF
  ok "Written $CONTEXT_FILE"
}

# ── Seed memory.md ────────────────────────────────────────────────────────
seed_memory() {
  info "Would you like to record the first architectural decision in memory.md?"
  printf "${CYAN}Record a decision? [Y/n]${NC}: "
  read -r answer
  case "$answer" in
    n|N|no|NO) info "Skipping memory.md seeding."; return 0 ;;
  esac

  echo
  info "--- First Architectural Decision ---"
  prompt_with_default "Decision title (e.g. Use SQLite as local store)" \
    "Initial project setup with ${PROJECT_NAME}" DECISION_TITLE
  prompt_with_default "Decision (what was chosen)" \
    "Initialize ${PROJECT_NAME} as a ${BACKEND_RUNTIME:-multi-language} project using ${BACKEND_FRAMEWORK:-the chosen framework} with ${BACKEND_DB:-the chosen database}" DECISION_BODY
  prompt_with_default "Rationale (why this over alternatives)" \
    "Chosen based on project requirements and team expertise" DECISION_RATIONALE
  prompt_with_default "Alternatives considered" \
    "Other stacks and architectures were evaluated during initial planning" DECISION_ALTERNATIVES
  prompt_with_default "Trade-offs accepted" \
    "TBD as the project evolves" DECISION_TRADEOFFS

  cat >> "$MEMORY_FILE" <<MEMEOF

### [${TODAY}] ${DECISION_TITLE}

**Decision**: ${DECISION_BODY}
**Rationale**: ${DECISION_RATIONALE}
**Alternatives considered**: ${DECISION_ALTERNATIVES}
**Trade-offs accepted**: ${DECISION_TRADEOFFS}
MEMEOF
  ok "Appended decision to $MEMORY_FILE"
}

# ── Summary ───────────────────────────────────────────────────────────────
print_summary() {
  echo
  info "╔══════════════════════════════════════════════════════════════╗"
  info "║                     INIT COMPLETE                            ║"
  info "╚══════════════════════════════════════════════════════════════╝"
  ok "context.md  → $CONTEXT_FILE"
  ok "memory.md   → $MEMORY_FILE"
  echo
  info "Next steps:"
  info "  1. Review the generated files and tweak as needed"
  info "  2. Tell the architect:  /bootstrap"
  info "     (or start working:   /new-feature: <your feature>)"
  echo
}

# ══════════════════════════════════════════════════════════════════════════
# MAIN
# ══════════════════════════════════════════════════════════════════════════

main() {
  echo
  info "╔══════════════════════════════════════════════════════════════╗"
  info "║        opencode workspace — Project Initialization           ║"
  info "╚══════════════════════════════════════════════════════════════╝"
  echo

  ensure_opencode_dir
  check_existing_context

  # Detect project files
  info "Scanning workspace for existing project files..."
  DETECTED_RAW="$(detect_all)"
  # Parse key=value lines into an associative array
  declare -A DETECTED
  while IFS='=' read -r key value; do
    [ -n "$key" ] && DETECTED["$key"]="$value"
  done <<< "$DETECTED_RAW"

  if [ ${#DETECTED[@]} -gt 0 ]; then
    ok "Detected ${#DETECTED[@]} fields from project files"
  else
    info "No existing project files detected — starting from scratch."
  fi

  # Language detection based on runtime
  case "${DETECTED[runtime]:-}" in
    Node.js) DETECTED[lang]="TypeScript" ;;
    Rust)    DETECTED[lang]="Rust" ;;
    Go)      DETECTED[lang]="Go" ;;
    PHP)     DETECTED[lang]="PHP" ;;
    *)       DETECTED[lang]="TypeScript" ;;
  esac

  generate_context
  seed_memory
  print_summary
}

main "$@"
