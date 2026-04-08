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
