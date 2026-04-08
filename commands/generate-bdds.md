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
