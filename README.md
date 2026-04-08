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
