# Claudity-Assurance Design Spec

## Identity

- **Name:** claudity-assurance
- **Alias prefix:** c-a:
- **Repository:** [look-itsaxiom/claudity-assurance](https://github.com/look-itsaxiom/claudity-assurance)
- **Author:** Chase Skibeness (look-itsaxiom)
- **License:** MIT
- **Target user:** Solo developers who want to harden verification of local changes without a dedicated QA team

## Purpose

A two-session Claude Code plugin that creates a self-learning QA environment. It builds institutional knowledge about a project over time, verifies behavioral specifications (BDDs), and guards against regressions — all from an isolated directory that never sees source code.

### What it is

- A two-session plugin — lightweight presence in the dev session (Session 1), full presence in the QA session (Session 2)
- A self-learning QA environment that builds institutional knowledge about a project over time
- A regression guardian that accumulates verified behaviors and watches for breakage
- Agnostic about the system under test — works with web apps, APIs, games, desktop apps, CLIs, or anything else

### What it is NOT

- Not a replacement for dedicated QA team tooling (e.g., tapcheck-qa for ADO-integrated workflows)
- Not a test framework — it uses whatever testing tools are available
- Not a CI/CD tool — it's interactive and conversational, designed for local dev loops

### Phase 2 (future, not designed)

- Single-session mode via Agent Teams or subagents — a "lite" version that runs both dev and QA roles from one Claude session

---

## Session Boundary Model

### Session 1 (Dev Session)

- Can read/write anywhere in `project-dir/` except inside `project-dir/qa/` (with one exception below)
- Can **only write** to `project-dir/qa/bdds/` — drop BDD files, nothing else
- Cannot read from `qa/docs/`, `qa/results/`, `qa/tests/`, `qa/CLAUDE.md`, or `qa/changelog.md`
- Boundaries enforced via project CLAUDE.md instructions + SessionStart hook nudge

### Session 2 (QA Session)

- Operates **entirely** within `project-dir/qa/`
- **Never** reads source code, implementation files, config files, or anything outside `qa/`
- **Never** looks at specs, plans, or implementation docs from Session 1
- Only inputs: its own internal docs (`qa/docs/`), incoming BDDs (`qa/bdds/`), and direct interaction with the running system
- Tests the system as a **black box** — all understanding comes from onboarding, exploration, and accumulated documentation
- When stuck: ask the user, then document the answer — never read code to figure it out

### Session 2 Startup Validation

Before any skill can run, the SessionStart hook validates the environment:

| State | Action |
|---|---|
| Code files detected (package.json, src/, *.csproj, etc.) | **Block.** Instruct user to create an isolated QA directory or reuse an existing one. |
| Empty directory, no code | **Allow.** Suggest `/c-a:onboard`. |
| Initialized claudity-assurance directory | **Allow.** Normal operation. |
| Partially initialized (some skeleton, missing pieces) | **Allow with warning.** Suggest `/c-a:reset` to repair. |

---

## Component Map

### Session 1 (Dev Session) — Lightweight Surface

| Component | Type | Purpose |
|---|---|---|
| SessionStart hook | Hook | Light nudge: after brainstorming or planning, consider `/c-a:generate-bdds` |
| `/c-a:generate-bdds` | Command | Read spec/plan doc, produce BDD file with frontmatter, drop in `qa/bdds/` |
| `/c-a:brainstorm-with-bdds` | Command | Wrap superpowers brainstorming, flow into BDD generation |

### Session 2 (QA Session) — Full Surface

| Component | Type | Purpose |
|---|---|---|
| SessionStart hook | Hook | Validate environment, establish QA role, point to CLAUDE.md |
| `/c-a:onboard` | Skill | New project interview, scaffold directory, write CLAUDE.md + initial docs |
| `/c-a:verify` | Skill | Ingest BDDs, test against interaction surface, verification doc, update docs |
| `/c-a:explore` | Command | Ad-hoc exploratory testing, build knowledge outside of specific BDDs |
| `/c-a:reset` | Command | Two modes: full re-onboard OR troubleshoot/adapt documentation approach |

### Single SessionStart Hook

One hook script detects context at runtime:
- If claudity-assurance markers found (`CLAUDE.md` with c-a markers, `bdds/`, `docs/`) → **QA mode**: validate environment, establish QA role, enforce boundaries
- If no markers → **Dev mode**: light nudge about BDD generation after brainstorming/planning

---

## BDD Format Specification

BDD files use Gherkin syntax with YAML frontmatter. One file per plan/spec scope, dropped into `qa/bdds/`.

**File naming:** `YYYY-MM-DD-<feature-slug>.feature.md`

### Frontmatter Fields

| Field | Required | Purpose |
|---|---|---|
| `feature` | Yes | Human-readable feature name |
| `source` | Yes | Path to the spec/plan that produced this BDD (traceability metadata only — Session 2 does not follow this path) |
| `priority` | Yes | QA session uses this to order verification work (high, medium, low) |
| `area` | Yes | Links to QA session's knowledge graph (e.g., maps to `docs/auth.md`) |
| `evidence-level` | Yes | Controls verification output depth |
| `tags` | No | Testing approach hints (ui-flow, api-contract, data-integrity, etc.) |
| `acceptance-criteria` | No | Explicit AC mapping for traceability |
| `notes` | No | Freeform context — environment quirks, constraints, gotchas |

### Evidence Levels

| Level | Output |
|---|---|
| `light` | Text notes ("saw X instead of Y") |
| `medium` | Text notes + screenshots |
| `heavy` | Text notes + screenshots + video/recording |

### Example

```markdown
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
```

### Conventions

- Scenarios stay implementation-agnostic — no CSS selectors, endpoint paths, or framework references
- Testing approach hints live in frontmatter `tags`, not inline Gherkin tags
- One feature per file, scoped to match a single plan/spec document

---

## Interaction Surface Layer

### Core Principle

The plugin defines *what* testing means (BDD verification, regression, knowledge building). The user and QA session together define *how* to interact with the system under test.

### Definition

The interaction surface is documented in the QA knowledge graph and describes:
- What tools/capabilities are available (browser, API, MCP servers, CLI, etc.)
- How to access the system (URLs, ports, auth flows, launch commands)
- What each tool is good for
- Setup steps if any

### Defining New Interaction Layers

During `/c-a:onboard` or `/c-a:explore`:

1. QA session asks: "What kind of system are we testing?"
2. Claude supplements with web search and environment detection to suggest interaction approaches
3. If existing Claude Code tools cover it (browser, Bash, API calls): document and proceed
4. If custom tooling is needed (e.g., Godot MCP server, desktop automation):
   - QA session works with user to identify or create the tooling
   - Configure MCP servers in the QA environment's `.mcp.json`
   - Install tools, write adapter scripts as needed
   - Test the interaction layer before relying on it
5. Document everything in the knowledge graph

### Examples

| System Type | Interaction Layer |
|---|---|
| SaaS web app | Claude in Chrome + REST API calls |
| Godot game | MCP server for Godot session control |
| Desktop app (Electron) | Browser DevTools + Playwright |
| CLI tool | Bash execution + output parsing |
| Mobile app | Device farm MCP or Appium |
| REST API only | Direct HTTP calls |

### Self-Mutation Scope

The QA session can modify its own environment:
- Edit `.mcp.json` within `qa/` to add MCP servers
- Create helper scripts in `qa/tests/` or `qa/scripts/`
- Update its own CLAUDE.md to reference new tools
- Document everything in the knowledge graph

---

## Workflow Details

### `/c-a:onboard` (New Project)

1. **Detect state** — Already initialized? Suggest `/c-a:verify` or `/c-a:explore` instead.
2. **Interview** — One question at a time, multiple choice when possible:
   - What kind of system? How is it accessed?
   - What testing tools are available? (Claude suggests based on web search + environment)
   - Auth flows or setup steps?
   - High-level feature map?
3. **Scaffold directory** — Create the skeleton (`bdds/`, `docs/`, `results/`, `tests/`, `changelog.md`, `CLAUDE.md`)
4. **Write initial docs** — Knowledge graph entries from the interview (interaction surface, system overview, etc.)
5. **Configure interaction layer** — Set up MCP servers or tools if needed. Test that they work.
6. **Seed BDDs (optional)** — Write a few initial BDDs with the user, run them as a smoke test.
7. **Update changelog**

### `/c-a:generate-bdds` (Session 1 — Dev)

1. **Find source** — Locate the most recent spec or plan doc. Confirm with user if ambiguous.
2. **Extract behaviors** — Read the spec, identify testable behaviors.
3. **Draft BDDs** — Produce Gherkin scenarios with frontmatter. Present for review.
4. **User reviews** — Adjust priority, evidence levels, tags, scenarios.
5. **Drop in dropbox** — Write the finalized `.feature.md` to `qa/bdds/`.

### `/c-a:brainstorm-with-bdds` (Session 1 — Dev)

1. Invoke `superpowers:brainstorming` — normal brainstorming flow.
2. On completion, flow into `/c-a:generate-bdds` — read the produced spec, generate BDDs.

### `/c-a:verify` (Session 2 — QA)

1. **Ingest BDDs** — Read new files from `qa/bdds/`. Parse frontmatter.
2. **Plan verification** — Order by priority, cross-reference with interaction surface docs.
3. **Execute verification** — For each scenario:
   - Verify using the interaction surface
   - Collect evidence per `evidence-level`
   - If stuck: check docs → try to figure it out → ask user → document finding
4. **Regression check** — Based on `area`, re-verify previously verified behaviors that could be affected.
5. **Produce verification doc** — Write to `qa/results/YYYY-MM-DD-<feature-slug>-verification.md` with summary, per-scenario detail, evidence, regression results, recommendations.
6. **Summarize conversationally** — Present the summary. User can dig into the doc for detail.
7. **Update internal docs** — Fold learnings into the knowledge graph.
8. **Update changelog**

### `/c-a:explore` (Session 2 — QA)

1. **User directs or Claude proposes** — Pick an area to explore.
2. **Interact with the system** — Use the interaction surface to discover behaviors, map flows.
3. **Document findings** — Update the knowledge graph.
4. **Optionally produce BDDs** — If exploration reveals testable behaviors, offer to write BDDs for the regression baseline.
5. **Update changelog**

### `/c-a:reset` (Session 2 — QA)

Two modes presented as a choice:

**Mode 1: Full Re-onboard**
- Archive current docs to `qa/docs/_archive/YYYY-MM-DD/`
- Re-run `/c-a:onboard` interview
- Start fresh, preserving archive for reference

**Mode 2: Troubleshoot & Adapt**
- Interactive diagnosis: what's not working? What did you expect?
- Review internal docs together — identify stale, wrong, or missing knowledge
- Review interaction surface — is tooling still appropriate?
- Make targeted corrections
- Document the adaptation in changelog

---

## Knowledge Graph & Documentation Model

### Principles

- **Small, linked documents** — Claude navigates by pointers, loads only what's relevant
- **No monoliths** — everything stays lightweight
- **Graph over hierarchy** — files link to each other, Claude decides the structure
- **Claude is the curator** — the plugin provides the skeleton, Claude fills and maintains everything

### Directory Skeleton (Enforced)

```
project-dir/qa/
├── CLAUDE.md          # How to operate + pointers (lean)
├── bdds/              # Incoming BDDs from Session 1
├── docs/              # Claude-maintained knowledge graph (free-form)
├── results/           # Verification outputs + evidence
├── tests/             # Generated test artifacts (optional)
└── changelog.md       # Lightweight event log
```

### CLAUDE.md

- Lean and instructional — how Claude should behave in this environment
- Pointers to key docs (not the docs themselves)
- Boundary rules (don't leave `qa/`, don't read code, ask then document)
- Interaction surface summary with links to details
- Updated by Claude as the environment evolves

### Knowledge Graph (`qa/docs/`)

- Claude creates and organizes files freely
- Files link to each other via markdown references
- Claude decides when to split, merge, or restructure
- No prescribed template — grows organically from onboarding, exploration, and verification

### Changelog (`qa/changelog.md`)

- Lightweight append-only log
- Date, event type, one-line summary
- Tracks: onboarding, verification runs, doc updates, interaction surface changes, resets

### The "Ask Then Document" Reflex

1. Encounter something unknown
2. Check internal docs — documented before?
3. If not: try to figure it out through the interaction surface
4. If still stuck: ask the user a specific question
5. **Always** update internal docs with the finding
6. Never ask the same question twice

---

## Plugin File Structure

```
claudity-assurance/
├── .claude-plugin/
│   ├── plugin.json
│   └── marketplace.json
├── commands/
│   ├── generate-bdds.md
│   ├── brainstorm-with-bdds.md
│   ├── explore.md
│   └── reset.md
├── skills/
│   ├── onboard/
│   │   ├── SKILL.md
│   │   └── references/
│   │       └── interview-guide.md
│   └── verify/
│       ├── SKILL.md
│       └── references/
│           └── verification-guide.md
├── hooks/
│   ├── hooks.json
│   └── scripts/
│       └── session-start.sh
├── shared/
│   └── bdd-format.md
└── README.md
```

### hooks.json

```json
{
  "description": "Claudity-assurance session detection and context injection",
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

### plugin.json

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

### marketplace.json

```json
{
  "$schema": "https://anthropic.com/claude-code/marketplace.schema.json",
  "name": "claudity-assurance",
  "version": "1.0.0",
  "description": "Self-learning QA plugin for Claude Code",
  "owner": { "name": "look-itsaxiom" },
  "plugins": [
    {
      "name": "claudity-assurance",
      "description": "A self-learning QA environment that builds institutional testing knowledge, verifies BDDs, and guards against regressions for solo developers",
      "source": "./",
      "category": "testing"
    }
  ]
}
```

---

## Distribution

- **Primary:** Repository serves as its own marketplace at `look-itsaxiom/claudity-assurance`
- **Future:** Submit to official Claude Code plugin directory once stable
- **Development:** Local install via `--plugin-dir ./claudity-assurance`

## Command Collision Check

All commands prefixed with `c-a:` — verified no collisions with Claude Code built-ins or any installed plugins.
