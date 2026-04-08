---
name: onboard
description: >
  This skill should be used when a user wants to set up a new claudity-assurance
  QA environment for a project. Trigger phrases include "onboard this project",
  "set up QA", "initialize QA environment", "start QA for this project",
  "c-a onboard", "new QA project", and "I want to start testing this system".
  Also activates when a user starts a session in an empty directory and asks
  about testing or verification.
---

# Onboard

## Overview

Initialize a claudity-assurance QA environment through a collaborative interview
process. Scaffold the directory structure, write the initial CLAUDE.md and
knowledge graph documents, configure the interaction surface, and optionally seed
initial BDD scenarios.

The onboarding process establishes how the QA session will interact with the
system under test. The interaction layer is fully agnostic — it could be browser
automation, API calls, MCP servers for game engines, desktop automation tools,
or any combination. The user and Claude define this together.

## When to Use

- Starting QA for a new project in an empty or near-empty directory
- The current directory has no claudity-assurance markers (no CLAUDE.md with c-a markers)
- The user explicitly asks to set up or initialize QA

## When NOT to Use

- The directory is already initialized (has CLAUDE.md with c-a markers + skeleton directories) — suggest `/c-a:verify` or `/c-a:explore` instead
- The user wants to re-onboard — suggest `/c-a:reset` which handles archival
- The current directory contains source code — inform the user that QA must run in an isolated directory

## Pre-Flight Check

Before starting the interview:

1. **Code detection**: Check for source code markers (package.json, src/, *.csproj, go.mod, etc.). If found, STOP and instruct the user:
   "This directory contains source code. Claudity-assurance QA environments must be isolated from the codebase. Please create an empty subdirectory (e.g., `qa/`) and start a new session there."

2. **Existing initialization**: Check for CLAUDE.md with claudity-assurance markers. If found, inform the user this environment is already onboarded and suggest `/c-a:verify`, `/c-a:explore`, or `/c-a:reset`.

## Workflow

### Phase 1: Interview

Conduct the interview one question at a time. Use multiple choice when possible.
Claude should supplement user answers with web search and environment detection
to suggest interaction approaches. Consult `references/interview-guide.md` for
the question flow and adaptation patterns.

Core topics to cover:
- What system or project is being tested
- How is it accessed (URL, launch command, connection string, etc.)
- What testing tools are available or should be set up
- Auth flows or setup prerequisites
- High-level feature/area map of the system

End the interview when there is enough understanding to write initial docs and
configure an interaction layer. Do not over-interview — gaps can be filled during
exploration and verification.

### Phase 2: Scaffold Directory

Create the claudity-assurance directory skeleton:

```
CLAUDE.md
bdds/
docs/
results/
tests/
changelog.md
```

### Phase 3: Write Initial Documents

**CLAUDE.md** — Lean and instructional. Include:
- claudity-assurance marker (for SessionStart hook detection)
- Operating boundaries (stay in this directory, never read code, black-box only)
- The "ask then document" reflex description
- Interaction surface summary with pointers to detailed docs
- Pointers to key knowledge graph entries

**Knowledge graph entries** — Create lightweight documents in `docs/` based on
what was learned in the interview. Claude decides the structure — there is no
prescribed template. Typical first entries might cover the system overview and
the interaction surface details.

**changelog.md** — Initialize with the onboarding event.

All documents must stay **lightweight**. Prefer small, linked files over large
monoliths. Build a graph of knowledge, not a master reference.

### Phase 4: Configure Interaction Layer

Based on the interview:
- If MCP servers are needed, create or update `.mcp.json` in the QA directory
- If helper scripts are needed, create them in `tests/` or `scripts/`
- Test that the interaction layer works (e.g., can the browser reach the app? does the API respond?)
- Document the configuration in the knowledge graph

Use web search to find appropriate tools or MCP servers if the user describes a
system type Claude hasn't encountered before. Propose solutions and let the user
confirm before configuring.

### Phase 5: Seed BDDs (Optional)

Offer to collaboratively write a few initial BDD scenarios with the user. These
serve as:
- A smoke test of the verification workflow
- An initial regression baseline
- A way to validate the interaction layer works end-to-end

If the user accepts, write BDDs following the format at
`${CLAUDE_PLUGIN_ROOT}/shared/bdd-format.md`, place them in `bdds/`, and run a
quick verification pass to confirm the setup works.

### Phase 6: Summary

Present a summary of what was set up:
- System under test
- Interaction layer configured
- Documents created
- BDDs seeded (if any)
- Suggested next steps (`/c-a:verify` when BDDs arrive, `/c-a:explore` to build knowledge)

## Key Principles

- **One question at a time** during the interview
- **Claude suggests, user confirms** for interaction layer decisions
- **Lightweight everything** — small linked docs, not monoliths
- **Test the setup** before declaring onboarding complete
- **Document as you go** — the knowledge graph starts growing during onboarding
