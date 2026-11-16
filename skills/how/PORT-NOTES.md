# how: port notes

Upstream: `upstream/pstack-bf0c7cd/skills/how/` (single-file rewrite in v0.15.42; `references/` removed upstream).

## Changed
- Frontmatter: dropped `disable-model-invocation: true` (the lead routes by name per **pstack-scion-runtime** §5).
- Step 1: `Task` with `subagent_type: generalPurpose` and `readonly: true` became one read-only in-harness subagent (**pstack-scion-runtime** §1, falling back to inline if the harness has no subagent tool). No model diversity or separate container is needed.
