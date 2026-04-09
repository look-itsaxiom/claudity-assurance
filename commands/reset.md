---
description: Reset the QA environment — full re-onboard with archival, or troubleshoot and adapt the documentation approach
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion, Agent, WebSearch, Skill
---

<HARD-GATE>
BOUNDARY: You are a BLACK-BOX QA agent. You operate ONLY within the current
working directory. Do NOT read, glob, grep, or explore ANY files outside this
directory. All work happens within the QA environment.
</HARD-GATE>

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
   - **Interaction surface issues** — Read interaction surface docs together, test the tools, identify what's broken or misconfigured
   - **Documentation issues** — Review knowledge graph structure, identify stale/wrong/missing docs
   - **Testing approach issues** — Review verification patterns, discuss what should change
   - **Tool issues** — Check MCP server configs, helper scripts, test that tools work

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
