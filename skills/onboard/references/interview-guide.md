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
