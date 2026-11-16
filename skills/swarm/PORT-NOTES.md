# swarm: port notes

Upstream: `upstream/pstack-bf0c7cd/skills/swarm/` (v0.15.42).

## Changed
- Frontmatter: dropped `disable-model-invocation: true` (the lead routes by name per **pstack-scion-runtime** §5).
- Phase A step 3: `swarm workers` in `~/.cursor/rules/pstack-models.mdc` became `roles.swarm-worker` in `pstack-models.yaml` (resolving missing-file `inherit` and missing-key fallbacks per **pstack-scion-runtime** §3).
- Phase A step 4: writable outputs use each worker's own pushed branch or `inbox/` / `verdicts/` store file (no shared `/tmp`), keeping upstream's SHA and measurement-method recording contract verbatim.
- Phase B: `subagent_type` / `environment: "cloud" | "local"` / `cloud_base_branch` became `pstack-agent` / `pstack-reviewer` Scion agents (or in-harness subagents for cheap read-only coverage slices on the caller's own harness), template-service gates, base branch in the brief, and `inbox/` + `scion message` reporting.
- Phase D: "in-chat report" became a reply via `scion message` (**pstack-scion-runtime** §5).
