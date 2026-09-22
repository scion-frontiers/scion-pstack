# swarm: port notes

Upstream: `pstack/skills/swarm` at 5ff7a35.

## Changed
- Frontmatter: dropped `disable-model-invocation: true` (explicit-invocation intent; the lead routes by name).
- "cloud workers" and "cloud concurrency limit" lost the word "cloud". Every Scion agent is a container.
- Worker model: `swarm workers` in the Cursor rule became `roles.swarm-worker` in `pstack-models.yaml`. Race arms name a harness-config each.
- Fan out: `subagent_type` / `environment` / `run_in_background` became tiers. **Default tier: Scion agent** (`pstack-agent` if it writes, `pstack-reviewer` if it only reads). **In-harness subagents are allowed** only for read-only coverage slices on cheap units when the role resolves to the caller's own harness. **Model races: always Scion agents.** `environment: "local"` became "needs a template service, mount, or secret, otherwise a gate". `cloud_base_branch` became the base branch in the brief.
- Writable outputs: own branch or own `inbox/` file in the store (no shared `/tmp`).
- Reports: PASS/ISSUES/BLOCKED sent as a REPORT message. The final "in-chat report" became a reply per runtime §5 (a message capped at 2000 characters, with the long form in the store).

## Not ported cleanly
- The default `swarm-worker` is `grok-build`. When the lead runs on another vendor, even cheap read-only slices become containers. That makes big-N coverage swarms expensive. Consider `inherit` as the default for coverage swarms.

## Open questions
- Is there a Scion concurrency cap the lead should respect when N is large? Upstream separated N from the cloud limit. Scion's limit, if any, isn't documented in the runtime.
