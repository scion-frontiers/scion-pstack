# how: port notes

Upstream: `pstack/skills/how` at 5ff7a35. References are verbatim. They name Read/Grep/Glob, which are generic enough.

## Changed
- Frontmatter: dropped `disable-model-invocation: true` (explicit-invocation intent; the lead routes by name).
- Explorers: **Tier: in-harness subagents** (read-only, single family, return in one turn). **Fallback: `pstack-reviewer` Scion agents** when `roles.how-explorer` names another harness. The model is `roles.how-explorer` (default `inherit`), not `grok-4.6-fast-xhigh`.
- Explainer and synthesizer: the upstream "how-explainer" role maps to `roles.judgment`, because the runtime yaml has no separate key. **Tier: in-harness when `roles.judgment` is the caller's harness, otherwise a `pstack-reviewer` Scion agent.** A Scion explainer needs the branch and SHA, and long explorer findings go through the store.
- `readonly: true` became a brief clause for Scion agents. In-harness subagents keep whatever read-only mode the harness has.

## Not ported cleanly
- A mixed tier (in-harness explorers feeding a Scion-agent explainer) is possible and costs a store round-trip. It is acceptable, but it is less clean than upstream's all-in-process flow.

## Open questions
- Should `pstack-models.yaml` grow a `how-explainer` key so it can differ from `judgment`, as upstream allowed?
