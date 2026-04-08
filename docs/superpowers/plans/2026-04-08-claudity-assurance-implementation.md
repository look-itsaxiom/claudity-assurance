# Claudity-Assurance Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the claudity-assurance Claude Code plugin — a self-learning, two-session QA environment for solo developers.

**Architecture:** Plugin with 4 commands, 2 skills, 1 SessionStart hook (context-detecting), and shared BDD format reference. Session 1 (dev) surface is lightweight (nudge + BDD generation). Session 2 (QA) surface is full (onboard, verify, explore, reset). All components namespaced under `c-a:`.

**Tech Stack:** Claude Code plugin system (markdown commands/skills, JSON config, bash hooks)

**Spec:** `docs/superpowers/specs/2026-04-08-claudity-assurance-design.md`

---

### Task 1: Plugin Scaffold & Manifests

**Files:**
- Create: `.claude-plugin/plugin.json`
- Create: `.claude-plugin/marketplace.json`

- [ ] **Step 1: Create plugin directory structure**

```bash
mkdir -p .claude-plugin commands skills/onboard/references skills/verify/references hooks/scripts shared
```

- [ ] **Step 2: Write plugin.json**

Create `.claude-plugin/plugin.json`:

```json
{
  "name": "claudity-assurance",
  "version": "0.1.0",
  "description": "Self-learning QA plugin — builds testing knowledge, verifies BDDs, guards regressions",
  "author": {
    "name": "Chase Skibeness",
    "url": "https://github.com/look-itsaxiom"
  },
  "repository": "https://github.com/look-itsaxiom/claudity-assurance",
  "license": "MIT",
  "keywords": ["qa", "testing", "bdd", "verification", "regression", "solo-dev"],
  "skills": "./skills/",
  "commands": "./commands/",
  "hooks": "./hooks/hooks.json"
}
```

- [ ] **Step 3: Write marketplace.json**

Create `.claude-plugin/marketplace.json`:

```json
{
  "name": "claudity-assurance",
  "owner": {
    "name": "look-itsaxiom"
  },
  "plugins": [
    {
      "name": "claudity-assurance",
      "source": "./",
      "description": "A self-learning QA environment that builds institutional testing knowledge, verifies BDDs, and guards against regressions for solo developers",
      "version": "0.1.0",
      "author": {
        "name": "Chase Skibeness"
      }
    }
  ]
}
```

- [ ] **Step 4: Verify manifest structure**

Run: `cat .claude-plugin/plugin.json | jq .`
Expected: Valid JSON output with all fields present.

Run: `cat .claude-plugin/marketplace.json | jq .`
Expected: Valid JSON output with plugins array.

- [ ] **Step 5: Commit**

```bash
git add .claude-plugin/plugin.json .claude-plugin/marketplace.json
git commit -m "scaffold: add plugin and marketplace manifests"
```

---

### Task 2: SessionStart Hook

**Files:**
- Create: `hooks/hooks.json`
- Create: `hooks/scripts/session-start.sh`

- [ ] **Step 1: Write hooks.json**

Create `hooks/hooks.json`:

```json
{
  "description": "Claudity-assurance session detection — detects dev vs QA context and injects appropriate guidance",
  "hooks": {
    "SessionStart": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "bash ${CLAUDE_PLUGIN_ROOT}/hooks/scripts/session-start.sh",
            "timeout": 10
          }
        ]
      }
    ]
  }
}
```

- [ ] **Step 2: Write session-start.sh**

Create `hooks/scripts/session-start.sh`:

```bash
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
```

- [ ] **Step 3: Make script executable**

Run: `chmod +x hooks/scripts/session-start.sh`

- [ ] **Step 4: Validate hooks.json**

Run: `cat hooks/hooks.json | jq .`
Expected: Valid JSON with `description` and `hooks.SessionStart` array.

- [ ] **Step 5: Test hook script locally**

Run: `CLAUDE_PROJECT_DIR="$(pwd)" bash hooks/scripts/session-start.sh`
Expected: No output (no QA markers, no qa/ directory yet — silent exit with code 0).

- [ ] **Step 6: Commit**

```bash
git add hooks/hooks.json hooks/scripts/session-start.sh
git commit -m "feat: add SessionStart hook with dev/QA context detection"
```

---

### Task 3: Shared BDD Format Reference

**Files:**
- Create: `shared/bdd-format.md`

- [ ] **Step 1: Write bdd-format.md**

Create `shared/bdd-format.md`:

```markdown
# BDD Format Specification

## File Convention

BDD files use Gherkin syntax with YAML frontmatter. One file per plan/spec scope.

**Location:** `qa/bdds/`
**Naming:** `YYYY-MM-DD-<feature-slug>.feature.md`

## Frontmatter Fields

| Field | Required | Purpose |
|---|---|---|
| `feature` | Yes | Human-readable feature name |
| `source` | Yes | Path to the spec/plan that produced this BDD (traceability metadata only — the QA session does not follow this path) |
| `priority` | Yes | Verification ordering: `high`, `medium`, `low` |
| `area` | Yes | Domain area — links to QA knowledge graph (e.g., `auth`, `billing`, `dashboard`) |
| `evidence-level` | Yes | Depth of verification evidence required |
| `tags` | No | Testing approach hints: `ui-flow`, `api-contract`, `data-integrity`, `state-transition`, etc. |
| `acceptance-criteria` | No | Explicit AC mapping for traceability |
| `notes` | No | Freeform context — environment quirks, constraints, gotchas |

## Evidence Levels

| Level | Output |
|---|---|
| `light` | Text notes describing what was observed vs. expected |
| `medium` | Text notes + screenshots at key verification points |
| `heavy` | Text notes + screenshots + video/screen recording of the verification |

## Template

~~~markdown
---
feature: <Feature Name>
source: <path/to/spec-or-plan.md>
priority: <high|medium|low>
area: <domain-area>
evidence-level: <light|medium|heavy>
tags:
  - <testing-hint>
acceptance-criteria:
  - AC1: <criterion description>
notes: |
  <Any relevant context, constraints, or gotchas.>
---

Feature: <Feature Name>

  Scenario: <Descriptive scenario name>
    Given <precondition>
    When <action>
    Then <expected outcome>
~~~

## Conventions

- Scenarios are **implementation-agnostic** — no CSS selectors, API endpoint paths, framework references, or code snippets
- Testing approach hints belong in frontmatter `tags`, not inline Gherkin tags
- One feature per file, scoped to match a single plan or spec document
- The `source` field is for traceability only — the QA session operates in isolation and never reads files at that path
- The `area` field should match terms the QA session uses in its knowledge graph so it can cross-reference during regression checks

## Example

~~~markdown
---
feature: Password Reset via Email
source: docs/superpowers/specs/2026-04-08-password-reset-design.md
priority: high
area: auth
evidence-level: medium
tags:
  - ui-flow
  - api-contract
acceptance-criteria:
  - AC1: User can reset password via email link
  - AC2: Invalid emails show generic confirmation
notes: |
  Rate limiting: 3 attempts/hour/email.
  Test env needs mailhog or equivalent for email capture.
---

Feature: Password Reset via Email

  Scenario: Successful reset with valid email
    Given a registered user with email "user@example.com"
    When they request a password reset
    And they follow the reset link from their email
    And they enter a new valid password
    Then they can sign in with the new password

  Scenario: Reset attempt with unregistered email
    Given no account exists for "unknown@example.com"
    When they request a password reset
    Then they see a generic confirmation message
    And no email is sent

  Scenario: Expired reset link
    Given a user has requested a password reset
    When they follow the reset link after 24 hours
    Then they see an expiration message
    And are prompted to request a new link
~~~
```

- [ ] **Step 2: Commit**

```bash
git add shared/bdd-format.md
git commit -m "docs: add shared BDD format specification"
```

---

### Task 4: Session 1 Commands — generate-bdds

**Files:**
- Create: `commands/generate-bdds.md`

- [ ] **Step 1: Write generate-bdds.md**

Create `commands/generate-bdds.md`:

```markdown
---
description: Generate implementation-agnostic BDD scenarios from a spec or plan document and drop them in the QA dropbox (qa/bdds/)
allowed-tools: Read, Write, Glob, Grep, AskUserQuestion
---

Generate behavioral specifications (BDDs) from a design spec or implementation plan and place them in the QA environment's dropbox for verification.

## Step 1: Locate Source Document

Search for the most recent spec or plan document:
- Check `docs/superpowers/specs/` for design specs
- Check `docs/superpowers/plans/` for implementation plans
- If multiple candidates exist, present them and ask the user to confirm which one

If no spec or plan is found, ask the user to provide the path or describe the feature to generate BDDs from conversation.

## Step 2: Read BDD Format Specification

Read the BDD format reference at `${CLAUDE_PLUGIN_ROOT}/shared/bdd-format.md` for the required file structure, frontmatter fields, and conventions.

## Step 3: Extract Testable Behaviors

Read the source document and identify:
- Explicit acceptance criteria
- User-facing behaviors described in the spec
- Edge cases and error conditions mentioned
- State transitions and data flows that are externally observable

Focus on **what the system should do**, not **how it does it**. Every scenario must be verifiable by someone who cannot see the source code.

## Step 4: Draft BDD File

Produce a `.feature.md` file following the format specification:

1. **Frontmatter**: Set all required fields:
   - `feature`: Clear, concise feature name
   - `source`: Path to the spec/plan document used
   - `priority`: Ask user or infer from spec context (default: `medium`)
   - `area`: Identify the domain area from the spec
   - `evidence-level`: Ask user or suggest based on feature criticality
2. **Optional fields**: Add `tags`, `acceptance-criteria`, and `notes` where valuable
3. **Scenarios**: Write Gherkin scenarios — implementation-agnostic, behavior-focused

Present the draft to the user for review.

## Step 5: User Review

Ask the user to review and adjust:
- Are the scenarios correct and complete?
- Are priority and evidence-level appropriate?
- Any missing edge cases or scenarios?
- Any notes the QA session should know?

Iterate until the user approves.

## Step 6: Drop in Dropbox

Write the finalized file to `qa/bdds/YYYY-MM-DD-<feature-slug>.feature.md`.

If the `qa/bdds/` directory does not exist, create it.

IMPORTANT: Do NOT read or modify any other files in `qa/`. The dev session's access is limited to writing BDD files into `qa/bdds/` only.

## Output

Confirm the file was written:
```
BDD file written to qa/bdds/<filename>.feature.md
  Feature: <name>
  Scenarios: <count>
  Priority: <level>
  Evidence: <level>

The QA session can pick this up with /c-a:verify.
```
```

- [ ] **Step 2: Validate frontmatter fields**

Check that the command file has `description` and `allowed-tools` in the YAML frontmatter.

- [ ] **Step 3: Commit**

```bash
git add commands/generate-bdds.md
git commit -m "feat: add /c-a:generate-bdds command for Session 1"
```

---

### Task 5: Session 1 Commands — brainstorm-with-bdds

**Files:**
- Create: `commands/brainstorm-with-bdds.md`

- [ ] **Step 1: Write brainstorm-with-bdds.md**

Create `commands/brainstorm-with-bdds.md`:

```markdown
---
description: Run superpowers brainstorming for a feature, then automatically generate BDD scenarios from the resulting spec
allowed-tools: Read, Write, Glob, Grep, AskUserQuestion, Skill
---

Combine feature brainstorming with BDD generation in a single flow. This command wraps the superpowers:brainstorming skill and follows it with BDD generation for the QA environment.

## Step 1: Invoke Brainstorming

Invoke the `superpowers:brainstorming` skill using the Skill tool. Follow its full workflow:
- Explore project context
- Ask clarifying questions
- Propose approaches
- Present design for approval
- Write and commit the design spec

Wait for the brainstorming skill to complete fully — including the spec being written and approved by the user.

## Step 2: Transition to BDD Generation

After the spec is written and committed, inform the user:

"Design spec complete. Now generating BDD scenarios for the QA environment."

## Step 3: Generate BDDs

Follow the same process as `/c-a:generate-bdds`:

1. Read the spec that was just produced by the brainstorming session
2. Read the BDD format reference at `${CLAUDE_PLUGIN_ROOT}/shared/bdd-format.md`
3. Extract testable behaviors from the spec
4. Draft the BDD file with frontmatter and Gherkin scenarios
5. Present to the user for review
6. Write the approved file to `qa/bdds/YYYY-MM-DD-<feature-slug>.feature.md`

IMPORTANT: Do NOT read or modify any files in `qa/` other than writing to `qa/bdds/`.

## Step 4: Offer Next Steps

After the BDD file is written, offer:
- "Continue to implementation planning? (invokes superpowers:writing-plans)"
- "Done for now — the QA session can pick up these BDDs with /c-a:verify"

## Note

This command deliberately does NOT skip the brainstorming skill's approval gates. The user must approve the design spec before BDD generation begins. BDDs are derived from the approved spec, not from intermediate brainstorming notes.
```

- [ ] **Step 2: Commit**

```bash
git add commands/brainstorm-with-bdds.md
git commit -m "feat: add /c-a:brainstorm-with-bdds command for Session 1"
```

---

### Task 6: Session 2 Skill — onboard

**Files:**
- Create: `skills/onboard/SKILL.md`
- Create: `skills/onboard/references/interview-guide.md`

- [ ] **Step 1: Write SKILL.md**

Create `skills/onboard/SKILL.md`:

```markdown
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
```

- [ ] **Step 2: Write interview-guide.md**

Create `skills/onboard/references/interview-guide.md`:

```markdown
# Onboarding Interview Guide

## Question Flow

The interview adapts based on answers. Not all questions apply to every project.
Ask one question at a time. Use multiple choice when possible.

### Q1: System Type

"What kind of system are we going to be testing?"
- (a) Web application (browser-based UI)
- (b) REST/GraphQL API (no UI, or API-first)
- (c) Desktop application
- (d) Mobile application
- (e) Game (e.g., Unity, Godot, Unreal)
- (f) CLI tool or library
- (g) Something else (describe it)

**Adaptation:** Answer determines which follow-up questions to ask and what
interaction approaches to suggest.

### Q2: Access Method

Based on system type:
- **Web app**: "What URL can I access it at? Is there a local dev server command?"
- **API**: "What's the base URL? Is there an API spec or docs URL?"
- **Desktop**: "How do I launch it? Is there an automation framework available?"
- **Game**: "What engine? How do I launch a test session?"
- **CLI**: "What's the command? How do I install/run it?"
- **Other**: "How would a tester interact with this system?"

### Q3: Interaction Layer

"Based on what you've described, here's how I think we can interact with the system:"

Present suggested tools based on system type and what Claude knows or can find
via web search. Examples:
- Web app → "Claude in Chrome for UI testing + direct API calls for backend verification"
- API only → "HTTP requests via Bash (curl) or a dedicated API testing tool"
- Godot game → "We may need an MCP server for Godot — let me search for options"
- Desktop → "Depends on the framework — let me check what automation tools exist for this"

Ask: "Does this approach work, or would you prefer something different?"

### Q4: Authentication

"Does the system require authentication to test? If so:"
- (a) Username/password login
- (b) API key or token
- (c) OAuth/SSO flow
- (d) No authentication needed
- (e) Multiple auth methods depending on the area

Follow up: "Can you provide test credentials, or do we need to set those up?"

### Q5: Environment Setup

"Is there anything I need to do before I can start testing?"
- Start a dev server or service
- Seed a database
- Configure environment variables
- Launch a companion process
- Nothing — it's always running

### Q6: System Map

"Give me a high-level map of the system's main areas or features. Just the big
categories — we'll explore details later."

This helps Claude create the initial knowledge graph structure. Don't push for
exhaustive detail — the graph grows through exploration and verification.

### Q7: Known Quirks (Optional)

"Anything I should know that might trip me up? Rate limits, flaky areas, things
that don't work in the test environment, etc."

### Exit Criteria

End the interview when:
- Claude knows what the system is and how to access it
- At least one interaction approach is agreed upon
- Auth is understood (or confirmed not needed)
- There's enough of a system map to create initial docs

Do NOT interview to exhaustion. Gaps are expected and will be filled through
`/c-a:explore` and `/c-a:verify` cycles. The onboarding just needs enough to
get started.
```

- [ ] **Step 3: Verify skill structure**

Run: `ls skills/onboard/`
Expected: `SKILL.md` and `references/` directory.

Run: `ls skills/onboard/references/`
Expected: `interview-guide.md`

- [ ] **Step 4: Commit**

```bash
git add skills/onboard/SKILL.md skills/onboard/references/interview-guide.md
git commit -m "feat: add /c-a:onboard skill with interview guide"
```

---

### Task 7: Session 2 Skill — verify

**Files:**
- Create: `skills/verify/SKILL.md`
- Create: `skills/verify/references/verification-guide.md`

- [ ] **Step 1: Write SKILL.md**

Create `skills/verify/SKILL.md`:

```markdown
---
name: verify
description: >
  This skill should be used when a QA session needs to verify BDD scenarios
  against a running system. Trigger phrases include "verify these BDDs",
  "test the new features", "run verification", "check the bdds", "verify
  against the system", "start QA verification", "what needs testing",
  and "run the BDD scenarios". Also activates when new .feature.md files
  appear in the bdds/ directory and the user asks to test them.
---

# Verify

## Overview

Ingest BDD scenario files from the `bdds/` dropbox, verify each scenario against
the running system using the configured interaction surface, produce a
verification report with evidence, check for regressions in related areas, and
update the internal knowledge graph with anything learned.

This skill is the core testing loop of claudity-assurance. It combines focused
verification (new BDDs) with regression awareness (previously verified behaviors
in the same area).

## When to Use

- New BDD files have been dropped in `bdds/` by the dev session
- The user asks to verify, test, or check scenarios
- After `/c-a:explore` discovers new behaviors worth verifying
- For periodic regression checks on previously verified areas

## When NOT to Use

- No BDD files exist and the user hasn't asked for regression-only testing
- The QA environment isn't onboarded yet — suggest `/c-a:onboard`
- The interaction surface isn't configured or isn't working — suggest `/c-a:reset` to troubleshoot

## Workflow

### Phase 1: Ingest BDDs

Read all `.feature.md` files in `bdds/`. Parse YAML frontmatter from each file.

If no new BDD files are found, ask the user:
- "No new BDDs in the dropbox. Would you like to run regression checks on a specific area, or explore the system?"

Sort BDDs by `priority` (high first, then medium, then low).

### Phase 2: Plan Verification

For each BDD file, cross-reference with the knowledge graph:

1. Read the `area` field — look for matching docs in the knowledge graph
2. Read the `tags` field — determine which interaction methods to use
3. Read `evidence-level` — plan evidence collection depth
4. Check `notes` for any constraints or gotchas

Build a verification plan. Present it briefly to the user:
"I have N scenarios across M areas. Starting with [highest priority]. Here's my approach: [brief summary]. Ready to begin?"

### Phase 3: Execute Verification

For each scenario in priority order:

1. **Set up preconditions** (the Given step) using the interaction surface
2. **Execute the action** (the When step)
3. **Check the outcome** (the Then step)
4. **Collect evidence** per the `evidence-level`:
   - `light`: Write a text note of what was observed
   - `medium`: Text note + capture screenshot(s) at key verification points
   - `heavy`: Text note + screenshots + record video/screen capture of the verification
5. **Record result**: pass or fail with details

**When stuck during verification:**
1. Check internal docs — has this interaction pattern been documented?
2. Try to figure it out through the interaction surface (probe, explore)
3. Ask the user a specific question: "How do I [specific action]?"
4. **Always** document the answer in the knowledge graph, regardless of source

Consult `references/verification-guide.md` for evidence collection patterns
and common verification strategies.

### Phase 4: Regression Check

After verifying the new BDDs, check for regressions:

1. Identify the `area` values from the new BDDs
2. Look through the knowledge graph for previously verified behaviors in those areas
3. Re-verify a relevant subset — focus on behaviors that are most likely to break
   given what changed (use the BDD scenarios as hints about what was modified)
4. Record regression results alongside the main verification

The regression scope should be proportional — not a full retest of everything,
but a focused check on areas adjacent to the changes.

### Phase 5: Produce Verification Document

Write the verification report to `results/YYYY-MM-DD-<feature-slug>-verification.md`.

The report should be lightweight and scannable:
- **Summary**: Total scenarios, pass/fail counts, key findings
- **Per-scenario results**: Scenario name, status (pass/fail), brief observation, evidence links
- **Regression results**: What was re-checked, any regressions found
- **Recommendations**: What needs to go back to the dev session for fixes (if anything)

Evidence files (screenshots, recordings) stored alongside the report or in a
subdirectory of `results/`.

### Phase 6: Summarize to User

Present a conversational summary — the user should understand the results
without reading the full document:

"Verified N scenarios for [feature]. M passed, L failed. [Brief note on failures if any]. Regression check on [area]: no issues found. Full report at results/[filename]."

The user can ask follow-up questions or review the full document if they want
more detail.

### Phase 7: Update Knowledge Graph

Fold everything learned during verification into the internal docs:
- New interaction patterns discovered
- System behaviors confirmed or contradicted
- Environment quirks encountered
- Updated regression baseline for the verified areas

Update the changelog with the verification event.

## Key Principles

- **Black-box only** — verify by interacting with the running system, never by reading code
- **Evidence proportional to risk** — let the evidence-level tag guide collection depth
- **Regression is part of verification** — don't just check the new stuff
- **Always learn** — every verification run should leave the knowledge graph richer
- **Summarize first, detail on demand** — respect the user's time
```

- [ ] **Step 2: Write verification-guide.md**

Create `skills/verify/references/verification-guide.md`:

```markdown
# Verification Guide

## Evidence Collection Patterns

### Light Evidence (text notes)

Record a brief observation for each scenario:

```
Scenario: Successful reset with valid email
Status: PASS
Observed: Submitted reset form → received confirmation page → email arrived
  in mailhog within 3s → followed link → set new password → logged in successfully
```

For failures:
```
Scenario: Expired reset link
Status: FAIL
Expected: Expiration message after 24 hours
Observed: Link still worked after 24h wait simulation — no expiration check detected
```

### Medium Evidence (text + screenshots)

Capture screenshots at key verification points:
- Before the action (precondition state)
- During the action (if multi-step)
- After the action (outcome state)

Name screenshots descriptively:
`results/2026-04-08-password-reset/01-reset-form.png`
`results/2026-04-08-password-reset/02-confirmation-page.png`
`results/2026-04-08-password-reset/03-email-received.png`

### Heavy Evidence (text + screenshots + video)

Record the entire verification flow as a video or GIF. Use whatever recording
capability is available through the interaction surface (e.g., Claude in Chrome
GIF recording, Playwright video, screen capture tools).

## Verification Strategies by Tag

### `ui-flow` tagged scenarios

- Use browser interaction (Claude in Chrome, Playwright, etc.)
- Verify visual elements are present and functional
- Check navigation flows end-to-end
- Screenshot at each major state transition

### `api-contract` tagged scenarios

- Make HTTP requests directly (curl, fetch, API tools)
- Verify response status codes, body structure, and values
- Check error responses match expected formats
- Log request/response pairs as evidence

### `data-integrity` tagged scenarios

- Verify through the interaction surface that data persists correctly
- Check that related data stays consistent after operations
- Test boundary values and edge cases
- May require multiple interaction methods (UI to create, API to verify)

### `state-transition` tagged scenarios

- Verify the system moves between states correctly
- Check that invalid transitions are rejected
- Verify side effects of state changes (notifications, logs, related records)

## Regression Strategies

### Selecting What to Re-check

When new BDDs target a specific area, re-check:
1. **Direct dependencies** — features that share data or state with the changed area
2. **Common workflows** — user flows that pass through the changed area
3. **Previously fragile behaviors** — anything documented in the knowledge graph as having failed before

### Regression Scope Rules

- **Small change (1-2 scenarios, single area)**: Re-check 3-5 related behaviors
- **Medium change (3-5 scenarios, 1-2 areas)**: Re-check core workflows through those areas
- **Large change (6+ scenarios, multiple areas)**: Broader regression, prioritize by risk

### Documenting Regression Results

Include in the verification report:
```
## Regression Check: auth area
Re-verified 4 previously passing scenarios:
- Login with valid credentials: PASS
- Login with invalid password: PASS
- Session timeout after inactivity: PASS
- Remember me functionality: PASS (new finding: cookie expires after 30 days, not 7 as previously documented — updated docs/auth.md)
```

Note: If regression re-verification uncovers something new about the system,
update the knowledge graph immediately.
```

- [ ] **Step 3: Verify skill structure**

Run: `ls skills/verify/`
Expected: `SKILL.md` and `references/` directory.

Run: `ls skills/verify/references/`
Expected: `verification-guide.md`

- [ ] **Step 4: Commit**

```bash
git add skills/verify/SKILL.md skills/verify/references/verification-guide.md
git commit -m "feat: add /c-a:verify skill with verification guide"
```

---

### Task 8: Session 2 Commands — explore

**Files:**
- Create: `commands/explore.md`

- [ ] **Step 1: Write explore.md**

Create `commands/explore.md`:

```markdown
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
```

- [ ] **Step 2: Commit**

```bash
git add commands/explore.md
git commit -m "feat: add /c-a:explore command for Session 2"
```

---

### Task 9: Session 2 Commands — reset

**Files:**
- Create: `commands/reset.md`

- [ ] **Step 1: Write reset.md**

Create `commands/reset.md`:

```markdown
---
description: Reset the QA environment — full re-onboard with archival, or troubleshoot and adapt the documentation approach
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion, Agent, WebSearch, Skill
---

Reset or repair the claudity-assurance QA environment. Presents two modes:
full re-onboard (archive and start fresh) or troubleshoot (diagnose and fix
issues with the current setup).

## Pre-Flight Check

Verify this is an initialized claudity-assurance QA environment. If not, suggest
`/c-a:onboard` instead.

## Step 1: Choose Mode

Present the two options:

"How would you like to reset?"

**(a) Full Re-onboard** — Archive current docs and start fresh with a new
interview. Use this when the project has changed significantly or the current
documentation approach isn't working at all.

**(b) Troubleshoot & Adapt** — Diagnose specific issues and make targeted
corrections. Use this when the QA environment mostly works but some aspect
needs fixing.

## Mode A: Full Re-onboard

1. **Archive current state**: Move the contents of `docs/` to `docs/_archive/YYYY-MM-DD/`. Preserve `results/` and `bdds/` as-is (they contain historical verification data).

2. **Reset CLAUDE.md**: Archive the current CLAUDE.md alongside the docs.

3. **Re-run onboarding**: Invoke the `/c-a:onboard` skill to conduct a fresh interview, write new docs, and reconfigure the interaction surface.

4. **Note in changelog**: Record the re-onboard event with a brief reason.

The archive is preserved for reference — Claude can consult it if the user
mentions something from the previous setup.

## Mode B: Troubleshoot & Adapt

1. **Diagnose**: Ask the user what isn't working:
   - "What's the issue? What did you expect vs. what happened?"
   - "Is the problem with how I interact with the system, what I test, or how I document?"

2. **Review together**: Based on the diagnosis, review the relevant parts:
   - **Interaction surface issues** → Read interaction surface docs together, test the tools, identify what's broken or misconfigured
   - **Documentation issues** → Review knowledge graph structure, identify stale/wrong/missing docs
   - **Testing approach issues** → Review verification patterns, discuss what should change
   - **Tool issues** → Check MCP server configs, helper scripts, test that tools work

3. **Make corrections**: Apply targeted fixes:
   - Update or rewrite specific docs
   - Reconfigure interaction surface
   - Add or remove MCP servers
   - Update CLAUDE.md pointers

4. **Verify the fix**: Test that the correction resolves the issue.

5. **Document the adaptation**: Update changelog with what was changed and why.

## Key Rules

- **Never delete results/** — historical verification data is valuable
- **Always archive before overwriting** — in re-onboard mode
- **Troubleshoot before re-onboarding** — Mode B is usually sufficient
- **Document the reason** — future sessions benefit from knowing why things changed
```

- [ ] **Step 2: Commit**

```bash
git add commands/reset.md
git commit -m "feat: add /c-a:reset command for Session 2"
```

---

### Task 10: README

**Files:**
- Create: `README.md`

- [ ] **Step 1: Write README.md**

Create `README.md`:

```markdown
# claudity-assurance

A self-learning QA plugin for [Claude Code](https://claude.ai/code). Builds institutional testing knowledge, verifies BDD scenarios, and guards against regressions — designed for solo developers who want independent verification of their work.

## How It Works

Claudity-assurance operates across two Claude Code sessions:

**Session 1 (Dev)** — Your normal development session. After brainstorming or implementing a feature, generate BDD scenarios that describe what the system should do, in plain behavioral terms. These get dropped into a shared directory.

**Session 2 (QA)** — A separate Claude session running in an isolated QA directory. It picks up BDD scenarios, tests them against the running system as a black box (never seeing source code), and builds a growing knowledge base about how to interact with and verify the system.

The QA session learns over time. It asks questions when stuck, documents every finding, and never asks the same question twice.

## Installation

Add this repository as a marketplace source in Claude Code, then install the plugin:

```
/plugin marketplace add https://github.com/look-itsaxiom/claudity-assurance.git
/plugin install claudity-assurance
```

Or install directly for development:

```bash
claude --plugin-dir /path/to/claudity-assurance
```

## Quick Start

### 1. Generate BDDs (Dev Session)

After brainstorming or implementing a feature:

```
/c-a:generate-bdds
```

Or combine brainstorming with BDD generation:

```
/c-a:brainstorm-with-bdds
```

### 2. Set Up the QA Environment

Create a `qa/` directory in your project, start a new Claude session there:

```bash
mkdir qa
cd qa
claude
```

Then run:

```
/c-a:onboard
```

### 3. Verify BDDs (QA Session)

When new BDD files arrive in `qa/bdds/`:

```
/c-a:verify
```

### 4. Explore the System

Build knowledge beyond specific BDDs:

```
/c-a:explore
```

## Commands

| Command | Session | Purpose |
|---|---|---|
| `/c-a:generate-bdds` | Dev | Generate BDD scenarios from a spec/plan |
| `/c-a:brainstorm-with-bdds` | Dev | Brainstorm a feature + generate BDDs |
| `/c-a:onboard` | QA | Set up a new QA environment (interview + scaffold) |
| `/c-a:verify` | QA | Verify BDD scenarios against the running system |
| `/c-a:explore` | QA | Exploratory testing to build knowledge |
| `/c-a:reset` | QA | Re-onboard or troubleshoot the QA environment |

## Directory Structure

```
your-project/
├── src/                    # Your code (Session 1 territory)
├── qa/                     # QA environment (Session 2 territory)
│   ├── CLAUDE.md           # QA operating instructions
│   ├── bdds/               # BDD dropbox (Session 1 writes here)
│   ├── docs/               # Knowledge graph (Claude-maintained)
│   ├── results/            # Verification reports + evidence
│   ├── tests/              # Generated test artifacts
│   └── changelog.md        # Activity log
└── ...
```

## Key Principles

- **Black-box testing** — The QA session never sees source code
- **Self-learning** — Every interaction grows the knowledge graph
- **Ask then document** — When stuck, ask the user, then write it down
- **Lightweight everything** — Small linked docs, not monoliths
- **System agnostic** — Works with web apps, APIs, games, desktop apps, CLIs, anything

## License

MIT — Chase Skibeness ([@look-itsaxiom](https://github.com/look-itsaxiom))
```

- [ ] **Step 2: Commit**

```bash
git add README.md
git commit -m "docs: add README with installation and usage guide"
```

---

### Task 11: Validate Plugin Structure

**Files:**
- None created — validation only

- [ ] **Step 1: Verify complete directory structure**

Run: `find . -type f -not -path './.git/*' | sort`

Expected:
```
./.claude-plugin/marketplace.json
./.claude-plugin/plugin.json
./README.md
./commands/brainstorm-with-bdds.md
./commands/explore.md
./commands/generate-bdds.md
./commands/reset.md
./docs/superpowers/plans/2026-04-08-claudity-assurance-implementation.md
./docs/superpowers/specs/2026-04-08-claudity-assurance-design.md
./hooks/hooks.json
./hooks/scripts/session-start.sh
./shared/bdd-format.md
./skills/onboard/SKILL.md
./skills/onboard/references/interview-guide.md
./skills/verify/SKILL.md
./skills/verify/references/verification-guide.md
```

- [ ] **Step 2: Validate all JSON files**

Run: `cat .claude-plugin/plugin.json | jq . && cat .claude-plugin/marketplace.json | jq . && cat hooks/hooks.json | jq .`
Expected: All three files parse as valid JSON.

- [ ] **Step 3: Verify SKILL.md frontmatter**

Run: `head -5 skills/onboard/SKILL.md && head -5 skills/verify/SKILL.md`
Expected: Both files start with `---` YAML frontmatter containing `name` and `description` fields.

- [ ] **Step 4: Verify command frontmatter**

Run: `head -3 commands/generate-bdds.md && head -3 commands/brainstorm-with-bdds.md && head -3 commands/explore.md && head -3 commands/reset.md`
Expected: All files start with `---` YAML frontmatter containing `description`.

- [ ] **Step 5: Verify hook script is executable**

Run: `ls -la hooks/scripts/session-start.sh`
Expected: Execute permission set.

- [ ] **Step 6: Run plugin validator if available**

Use the plugin-validator agent to check the complete plugin structure.

---

### Task 12: Push to GitHub

**Files:**
- None created

- [ ] **Step 1: Verify GitHub remote**

Run: `git remote -v`
Expected: `origin` points to `https://github.com/look-itsaxiom/claudity-assurance.git`

- [ ] **Step 2: Verify correct GitHub account is active**

Run: `gh auth status`
Expected: `look-itsaxiom` is the active account.

- [ ] **Step 3: Push to remote**

Run: `git push -u origin main`
Expected: All commits pushed to `look-itsaxiom/claudity-assurance` on GitHub.

- [ ] **Step 4: Verify repository**

Run: `gh repo view look-itsaxiom/claudity-assurance --json name,description`
Expected: Repository accessible with correct metadata.
