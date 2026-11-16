# maintain-verification-skill: port notes

Upstream: `upstream/pstack-bf0c7cd/skills/maintain-verification-skill/` (v0.15.42).

## Changed
- Frontmatter: dropped `disable-model-invocation: true` (routed by name per **pstack-scion-runtime** §5).
- Step 0 & Step 6: `.cursor/skills/verify-*/` → `.scion/skills/verify-*/` in the repo (never editing `$HOME/.*/skills/` provisioned copies; noting `scion templates sync` or ref refresh in the PR).
- Step 2: "read-only subagent" → read-only in-harness subagent (**pstack-scion-runtime** §1).
- Run notes: scratch location defaults to the pstack store when present.
