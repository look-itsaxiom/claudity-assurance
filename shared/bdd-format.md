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

```markdown
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
```

## Conventions

- Scenarios are **implementation-agnostic** — no CSS selectors, API endpoint paths, framework references, or code snippets
- Testing approach hints belong in frontmatter `tags`, not inline Gherkin tags
- One feature per file, scoped to match a single plan or spec document
- The `source` field is for traceability only — the QA session operates in isolation and never reads files at that path
- The `area` field should match terms the QA session uses in its knowledge graph so it can cross-reference during regression checks

## Example

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

  Scenario: Expired reset link
    Given a user has requested a password reset
    When they follow the reset link after 24 hours
    Then they see an expiration message
    And are prompted to request a new link
```
