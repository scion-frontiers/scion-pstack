# arena: port notes

Upstream: `upstream/pstack-bf0c7cd/skills/arena/` (v0.15.42).

## Changed
- Frontmatter: dropped `disable-model-invocation: true` (the lead routes by name per **pstack-scion-runtime** §5).
- Phase A step 3: `arena runners` in `~/.cursor/rules/pstack-models.mdc` became `panels.arena` in `pstack-models.yaml` (resolving missing-file `[inherit, inherit, inherit]` and missing-key fallbacks per **pstack-scion-runtime** §3), with resolved model-family substitution and N-family degraded-diversity reporting.
- Phase A step 4: worktree / `/tmp/arena-<slug>/candidate-<n>/` became each candidate's own pushed branch (`arena-<slug>-c<n>`) or `<store>/<program-slug>/arena-<slug>/candidate-<n>/` in the pstack store.
- Phase B: `run_in_background: true` subagents became `pstack-agent` Scion agents (`--role baseline`) for code/branch implementations, or `pstack-reviewer` Scion agents (`--role baseline`, store-only, no pushed branches) when overridden by `architect` Phase B, reporting via `inbox/` + `scion message` (**pstack-scion-runtime** §1).
- Phase C: `arena cross-judge pool` became `panels.cross-judge`, spawning a `pstack-reviewer` Scion agent from a resolved model family other than the parent's among runnable entries in `pstack-models.yaml` (never spawning unpreflighted harnesses when `pstack-models.yaml` is missing or single-family, and skipping the separate judge with a `single-judge` label when no other model family runs or a broker concurrency cap precludes it per **pstack-scion-runtime** §1).
