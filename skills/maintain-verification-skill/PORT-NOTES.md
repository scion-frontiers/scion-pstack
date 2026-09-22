# maintain-verification-skill: port notes

Upstream: `pstack/skills/maintain-verification-skill` at 5ff7a35.

## Changed
- Dropped `disable-model-invocation: true`; routed by name (runtime §5).
- Target location `.cursor/skills/verify-*/` → `.scion/skills/verify-*/` in the repo, or the delivered copy in the agent's skills dir.
- Source wave: "read-only subagent" → read-only in-harness subagent (runtime §1). Same model family is fine; no diversity needed.
- Ship: edit the repo source, not a delivered copy; note in the PR that template-local copies need a refresh.
- Run notes: scratch location → pstack store when there is one.
- `/create-verification-skill` → the skill by name.

## Unresolved
- If the verify skill was delivered by copying into templates, the copies drift from the repo source after this PR. Injected-by-URI delivery (see create-verification-skill PORT-NOTES) avoids that.
- A periodic cadence would be a `scion schedule` recurring event on the lead; not added (upstream: "suggest a cadence only if they ask").
