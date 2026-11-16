# arena: port notes

Upstream: `upstream/pstack-bf0c7cd/skills/arena/` (v0.15.42).

## Changed
- Frontmatter: dropped `disable-model-invocation: true` (the lead routes by name per **pstack-scion-runtime** §5).
- Phase A step 3: `arena runners` in `~/.cursor/rules/pstack-models.mdc` became `panels.arena` in `pstack-models.yaml` (default `[claude, codex, gemini]` in **pstack-scion-runtime** §3), with Scion preflight substitution and degraded-diversity reporting.
- Phase A step 4: worktree / `/tmp/arena-<slug>/candidate-<n>/` became each candidate's own pushed branch (`arena-<slug>-c<n>`) or `<store>/<program-slug>/arena-<slug>/candidate-<n>/` in the pstack store.
- Phase B: `run_in_background: true` subagents became `pstack-agent` Scion agents reporting via `inbox/` + `scion message` (**pstack-scion-runtime** §1).
- Phase C: `arena cross-judge pool` became `panels.cross-judge`, spawning a `pstack-reviewer` Scion agent from a vendor other than the parent's (preserving upstream's skip-with-notice fallback if no other vendor is runnable).
