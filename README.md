# claudity-assurance

A self-learning QA plugin for [Claude Code](https://claude.ai/code) that gives solo developers an independent verification layer for their work.

It operates as a **black-box tester** — it never sees your source code. Instead, it builds its own knowledge about your system through interviews, exploration, and testing, then verifies behavioral specifications (BDDs) against the running system. Over time, it accumulates institutional QA knowledge that gets better with every session.

## The Problem

When you're a solo developer, you're writing code and testing it yourself. That means your tests are biased by your knowledge of the implementation — you test what you *built*, not what the system *should do*. Bugs hide in the gap between those two things.

Claudity-assurance fills that gap by creating a QA session that:
- Doesn't know how your code works (by design)
- Tests behavior, not implementation
- Remembers what it's verified before and watches for regressions
- Learns how to interact with your system and never asks the same question twice

## How It Works

Claudity-assurance operates across **two Claude Code sessions**:

```
Session 1 (Dev)                          Session 2 (QA)
─────────────────                        ────────────────
Your normal dev work                     Isolated QA directory
  │                                        │
  ├─ Brainstorm features                   ├─ Onboard: interview about the system
  ├─ Write specs & plans                   ├─ Build interaction surface (browser, API, etc.)
  ├─ Implement code                        ├─ Verify BDDs against running system
  ├─ Generate BDDs ──── qa/bdds/ ─────────>├─ Produce verification reports
  │                                        ├─ Run regression checks
  │                                        ├─ Update knowledge graph
  │               ◄── results/ ────────────├─ Evidence (screenshots, logs, notes)
  └─ Fix failures                          └─ Get smarter every session
```

**Session 1 (Dev)** — Your normal development session. After brainstorming or implementing a feature, generate BDD scenarios that describe what the system should do in plain behavioral terms. These get dropped into a shared `qa/bdds/` directory.

**Session 2 (QA)** — A separate Claude session running in an isolated QA directory. It picks up BDD scenarios, tests them against the running system as a black box, and builds a growing knowledge base about how to interact with and verify the system.

### The Boundary

The two sessions are deliberately isolated:

- **Session 1** can only *write* to `qa/bdds/` — it cannot read QA results or docs
- **Session 2** lives entirely inside `qa/` — it cannot read source code, specs, or implementation files
- The BDD dropbox (`qa/bdds/`) is the only shared artifact

This separation ensures the QA session tests *behavior*, not *implementation*.

## Installation

```
/plugin marketplace add https://github.com/look-itsaxiom/claudity-assurance.git
/plugin install claudity-assurance
```

Or for local development:

```bash
claude --plugin-dir /path/to/claudity-assurance
```

## Quick Start

### Scenario A: Existing Project

You have a project and want to add QA verification.

**1. Create the QA environment**

```bash
cd your-project
mkdir qa
cd qa
claude
```

```
/claudity-assurance:onboard
```

Claude will interview you about the system — what it is, how to access it, what tools to use for testing. It then scaffolds the QA directory and writes its initial knowledge docs.

**2. Generate BDDs from your dev session**

In a separate Claude session in your project root:

```
/claudity-assurance:generate-bdds
```

This reads your most recent spec or plan and produces behavioral scenarios in Gherkin format, dropping them in `qa/bdds/`.

**3. Verify in the QA session**

Back in the QA session:

```
/claudity-assurance:verify
```

Claude picks up the BDDs, tests each scenario against the running system, collects evidence, checks for regressions, and produces a verification report.

### Scenario B: New Project

Starting fresh with no code yet.

**1. Create the QA directory and onboard**

```bash
mkdir my-project/qa
cd my-project/qa
claude
```

```
/claudity-assurance:onboard
```

During onboarding, Claude will help you define initial BDD scenarios and test them — building its knowledge base from scratch.

**2. Brainstorm with BDDs**

In your dev session, use the combined workflow:

```
/claudity-assurance:brainstorm-with-bdds
```

This runs the full brainstorming process and automatically generates BDDs from the approved spec.

**3. Iterate**

Implement features in Session 1, generate BDDs, verify in Session 2. The QA session gets smarter each cycle.

## Commands

### Session 1 (Dev)

| Command | Purpose |
|---|---|
| `/c-a:generate-bdds` | Generate BDD scenarios from a spec or plan document |
| `/c-a:brainstorm-with-bdds` | Brainstorm a feature, then generate BDDs from the result |

### Session 2 (QA)

| Command | Purpose |
|---|---|
| `/c-a:onboard` | Set up a new QA environment through a collaborative interview |
| `/c-a:verify` | Verify BDD scenarios against the running system |
| `/c-a:explore` | Exploratory testing to discover and document system behaviors |
| `/c-a:reset` | Full re-onboard (with archival) or troubleshoot the current setup |

## BDD Format

BDD files use Gherkin syntax with YAML frontmatter for metadata:

```markdown
---
feature: Password Reset via Email
source: docs/specs/password-reset-design.md
priority: high
area: auth
evidence-level: medium
tags:
  - ui-flow
  - api-contract
notes: |
  Rate limiting: 3 attempts/hour/email.
---

Feature: Password Reset via Email

  Scenario: Successful reset with valid email
    Given a registered user with email "user@example.com"
    When they request a password reset
    And they follow the reset link from their email
    And they enter a new valid password
    Then they can sign in with the new password
```

Key frontmatter fields:
- **`priority`** — Orders verification work (high, medium, low)
- **`area`** — Links to the QA knowledge graph for regression checking
- **`evidence-level`** — Controls how much proof is collected: `light` (text notes), `medium` (+ screenshots), `heavy` (+ video)
- **`tags`** — Hints about testing approach (ui-flow, api-contract, data-integrity, etc.)

See [`shared/bdd-format.md`](shared/bdd-format.md) for the full specification.

## The Knowledge Graph

The QA session maintains its own documentation inside `qa/docs/` — a graph of small, linked markdown files that grows over time. This is *not* a static test suite. It's a living knowledge base about:

- How to interact with the system (URLs, APIs, auth flows, tools)
- What behaviors have been verified
- What tends to break together
- Environment quirks and gotchas

Claude decides how to organize these docs. The plugin enforces the directory skeleton but lets Claude curate the contents:

```
qa/
├── CLAUDE.md              # Operating instructions + pointers (lean)
├── bdds/                  # Incoming BDDs from dev session
├── docs/                  # Knowledge graph (Claude-maintained, free-form)
├── results/               # Verification reports + evidence
├── tests/                 # Generated test artifacts
└── changelog.md           # Lightweight event log
```

### The "Ask Then Document" Reflex

When the QA session encounters something it doesn't know:

1. Check internal docs — has this been documented before?
2. Try to figure it out through the interaction surface (probe the UI, test the API)
3. If still stuck — ask the user
4. **Always** write down the answer
5. Never ask the same question twice

## Interaction Surface

The plugin is agnostic about *how* it tests. During onboarding, you and Claude define the interaction layer together:

| System Type | Typical Interaction Layer |
|---|---|
| Web app | Claude in Chrome + REST API calls |
| REST API | HTTP requests via curl or API tools |
| Game (Godot, Unity) | MCP server for engine interaction |
| Desktop app | Automation tools (Playwright, etc.) |
| CLI tool | Bash execution + output parsing |
| Mobile app | Device farm MCP or Appium |

The QA session can configure MCP servers, write helper scripts, and adapt its tooling — all within the `qa/` directory. If it needs a new interaction capability, it works with you to set it up and documents it in the knowledge graph.

## Design Principles

- **Black-box testing** — The QA session never sees source code. All understanding comes from interviews, exploration, and direct interaction with the running system.
- **Self-learning** — Every verification run, every exploration session, every user answer feeds back into the knowledge graph. The QA session compounds in value over time.
- **Lightweight everything** — Small linked documents, not monoliths. The knowledge graph is navigated by pointers, not loaded wholesale.
- **Regression awareness** — Verification isn't just checking new BDDs. The QA session also re-verifies previously passing behaviors in affected areas.
- **System agnostic** — Works with anything Claude Code can interact with. The testing approach is defined at runtime, not baked into the plugin.

## Roadmap

- **Phase 1 (current)** — Two-session model with manual BDD handoff
- **Phase 2** — Single-session mode via Agent Teams or subagents for a lighter workflow

## License

MIT — [Chase Skibeness](https://github.com/look-itsaxiom)
