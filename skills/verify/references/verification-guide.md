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
