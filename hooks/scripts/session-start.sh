#!/usr/bin/env bash
# claudity-assurance SessionStart hook
# Detects whether the current directory is a QA environment or a dev environment
# and injects appropriate context for each mode.

set -euo pipefail

CWD="${CLAUDE_PROJECT_DIR:-.}"

# --- QA Mode Detection ---
# Check for claudity-assurance markers: CLAUDE.md with c-a marker, bdds/, docs/
CA_MARKER=false
if [ -f "$CWD/CLAUDE.md" ] && grep -q "claudity-assurance" "$CWD/CLAUDE.md" 2>/dev/null; then
    CA_MARKER=true
fi

if [ "$CA_MARKER" = true ] && [ -d "$CWD/bdds" ] && [ -d "$CWD/docs" ]; then
    # --- QA MODE ---
    # Validate environment: check for code files that shouldn't be here
    CODE_DETECTED=false
    for marker in package.json Cargo.toml go.mod requirements.txt Gemfile pom.xml build.gradle; do
        if [ -f "$CWD/$marker" ]; then
            CODE_DETECTED=true
            break
        fi
    done
    for dir in src lib app; do
        if [ -d "$CWD/$dir" ]; then
            CODE_DETECTED=true
            break
        fi
    done

    if [ "$CODE_DETECTED" = true ]; then
        cat <<'WARN'
WARNING: This claudity-assurance QA directory contains source code files. The QA session must operate in isolation from the codebase to maintain black-box testing integrity. Please move code files out of this directory or start a new QA directory.
WARN
        exit 0
    fi

    cat <<'QA_CONTEXT'
You are operating as a claudity-assurance QA session. Your role is to verify software behavior through black-box testing.

CRITICAL BOUNDARIES:
- You operate ENTIRELY within this directory. Never read files outside it.
- You NEVER read source code, implementation files, or config files from the project.
- Your only inputs: your internal docs (docs/), incoming BDDs (bdds/), and direct interaction with the running system.
- When stuck: check your docs first, try the interaction surface, then ask the user. ALWAYS document what you learn.
- Never ask the same question twice — if you learned it, it should be in your docs.

Read CLAUDE.md for your operating instructions and knowledge graph pointers.

Available commands:
  /c-a:verify   — Ingest BDDs, test against the system, produce verification report
  /c-a:explore  — Exploratory testing to build knowledge
  /c-a:reset    — Re-onboard or troubleshoot documentation approach
QA_CONTEXT
    exit 0
fi

# --- Check for uninitialized QA directory ---
# Empty directory or directory with only bdds/ — suggest onboarding
FILE_COUNT=$(find "$CWD" -maxdepth 1 -not -name '.' | wc -l)
if [ "$FILE_COUNT" -le 2 ]; then
    # Possibly empty or near-empty — check for code markers first
    CODE_DETECTED=false
    for marker in package.json Cargo.toml go.mod requirements.txt Gemfile pom.xml build.gradle; do
        if [ -f "$CWD/$marker" ]; then
            CODE_DETECTED=true
            break
        fi
    done

    if [ "$CODE_DETECTED" = false ]; then
        cat <<'ONBOARD_HINT'
This looks like a new or empty directory. If you're setting up a claudity-assurance QA environment, run /c-a:onboard to get started.
ONBOARD_HINT
        exit 0
    fi
fi

# --- DEV MODE ---
# Light nudge about BDD generation — only if qa/bdds/ exists nearby
# (indicates this project has a QA environment set up)
if [ -d "$CWD/qa/bdds" ] || [ -d "$CWD/qa" ]; then
    cat <<'DEV_CONTEXT'
claudity-assurance: This project has a QA environment at qa/. When you finish brainstorming or planning a feature, consider running /c-a:generate-bdds to produce behavioral specs for the QA session. You can also use /c-a:brainstorm-with-bdds to combine brainstorming with BDD generation. IMPORTANT: You may ONLY write files to qa/bdds/ — do not read or modify anything else in qa/.
DEV_CONTEXT
    exit 0
fi

# No QA environment detected — silent exit
exit 0
