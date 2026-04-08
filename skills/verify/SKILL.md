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
