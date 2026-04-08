---
description: Exploratory testing to build knowledge about the system — discover behaviors, map flows, and grow the QA knowledge graph
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion, Agent, WebSearch, mcp__claude-in-chrome__*
---

Conduct ad-hoc exploratory testing of the system under test. This command is for
building knowledge outside of specific BDD verification — discovering how the
system works, mapping interaction patterns, and expanding the QA knowledge graph.

## Pre-Flight Check

Verify this is an initialized claudity-assurance QA environment:
- CLAUDE.md exists with claudity-assurance markers
- `docs/` directory exists

If not initialized, suggest `/c-a:onboard` first.

## Step 1: Choose Focus

Ask the user what to explore, or propose an area based on gaps in the knowledge graph:
- "What area of the system should we explore?"
- Or: "Based on my docs, I have thin coverage of [area]. Want to explore that?"

If the user gives a general direction ("just poke around"), pick the least-documented
area from the knowledge graph and start there.

## Step 2: Explore

Interact with the system using the configured interaction surface:
- Navigate UI flows, try different paths
- Probe API endpoints, test different inputs
- Discover behaviors not yet documented
- Note anything surprising or unexpected

Think like a curious tester — try the happy path, then the edges. What happens
if you do things out of order? What happens with empty inputs? What are the
boundaries?

## Step 3: Document Findings

After each significant discovery, update the knowledge graph:
- Create new doc files for newly discovered areas
- Update existing docs with new details
- Link related documents together
- Keep everything lightweight — small files, clear links

## Step 4: Offer BDD Generation

If exploration reveals behaviors worth adding to the regression baseline:
"I discovered [behavior]. Want me to write a BDD scenario for this so it becomes
part of the regression baseline?"

Write BDDs following the format at `${CLAUDE_PLUGIN_ROOT}/shared/bdd-format.md`
and place them in `bdds/`.

## Step 5: Update Changelog

Record the exploration event in `changelog.md`.

## Key Rules

- **Never leave the QA directory** to look at source code
- **Always document** what you find — exploration without documentation is wasted
- **Ask the user** if you encounter something you can't figure out through the interaction surface
- **Update docs immediately** — don't batch documentation to the end
