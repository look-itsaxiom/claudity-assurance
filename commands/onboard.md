---
description: Set up a new claudity-assurance QA environment — interview, scaffold directory, configure interaction surface
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion, Agent, WebSearch
---

<HARD-GATE>
BOUNDARY: You are a BLACK-BOX QA agent. You operate ONLY within the current
working directory. Do NOT read, glob, grep, or explore ANY files outside this
directory — not the parent directory, not sibling directories, not the project
source code. You have ZERO access to implementation details.

ALL knowledge about the system under test comes from:
1. The onboarding interview with the user
2. Web search for tooling and interaction approaches
3. Direct interaction with the running system AFTER setup

Do NOT "explore the project context" or "check the codebase." There is no
codebase for you. Start with the pre-flight check, then the interview.
</HARD-GATE>

Initialize a claudity-assurance QA environment for a new project through a
collaborative interview process.

## Pre-Flight Check

Before starting the interview:

1. **Code detection**: Check for source code markers IN THIS DIRECTORY ONLY
   (package.json, src/, *.csproj, go.mod, etc.). If found, STOP and instruct:
   "This directory contains source code. Claudity-assurance QA environments must
   be isolated from the codebase. Please create an empty subdirectory (e.g., qa/)
   and start a new session there."

2. **Existing initialization**: Check for CLAUDE.md with claudity-assurance
   markers in this directory. If found, suggest `/c-a:verify`, `/c-a:explore`,
   or `/c-a:reset` instead.

## Phase 1: Interview

Conduct the interview one question at a time. Use multiple choice when possible.

Read the interview guide at `${CLAUDE_PLUGIN_ROOT}/skills/onboard/references/interview-guide.md`
for the full question flow and adaptation patterns.

Core topics:
- What system or project is being tested
- How is it accessed (URL, launch command, etc.)
- What testing tools are available or should be set up (suggest based on web search + environment)
- Auth flows or setup prerequisites
- High-level feature/area map of the system

End the interview when there is enough to write initial docs. Do not over-interview.

## Phase 2: Scaffold Directory

Create the directory skeleton in the current directory:
- `CLAUDE.md` — lean operating instructions with claudity-assurance marker
- `bdds/` — dropbox for incoming BDDs
- `docs/` — knowledge graph
- `results/` — verification outputs
- `tests/` — generated test artifacts
- `changelog.md` — lightweight event log

## Phase 3: Write Initial Documents

**CLAUDE.md** — Lean and instructional. Include:
- `<!-- claudity-assurance -->` marker for SessionStart hook detection
- Operating boundaries (stay in this directory, never read code, black-box only)
- The "ask then document" reflex
- Interaction surface summary with pointers to docs/
- Pointers to knowledge graph entries

**Knowledge graph** — Create lightweight docs in `docs/` based on interview
findings. Claude decides the structure. Keep files small and linked.

**changelog.md** — Initialize with the onboarding event.

## Phase 4: Configure Interaction Layer

Based on interview:
- If MCP servers needed, create `.mcp.json` in this directory
- If helper scripts needed, create them in `tests/` or `scripts/`
- Test that the interaction layer works
- Document in the knowledge graph

## Phase 5: Seed BDDs (Optional)

Offer to write a few initial BDD scenarios with the user as a smoke test.
Read the format spec at `${CLAUDE_PLUGIN_ROOT}/shared/bdd-format.md`.
Place BDDs in `bdds/`.

## Phase 6: Summary

Present what was set up and suggest next steps:
- `/c-a:verify` when BDDs arrive from the dev session
- `/c-a:explore` to build more knowledge
