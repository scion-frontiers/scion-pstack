# architect: port notes

Upstream: `upstream/pstack-bf0c7cd/skills/architect/` (v0.15.42). `references/design-red-flags.md` and `references/rationale-template.md` are verbatim.

## Changed
- Frontmatter: dropped `disable-model-invocation: true` (the lead routes by name per **pstack-scion-runtime** §5).
- Phase B: `architect runners` in `pstack-models.mdc` became `panels.architect` in `pstack-models.yaml` (resolving missing-file `[inherit, inherit, inherit]` and missing-key fallbacks per **pstack-scion-runtime** §3), delegating fallback rules to `arena` Phase A, and overriding `arena` Phase B to spawn `pstack-reviewer` Scion agents (`--role baseline`, read-only, no branch pushes) writing candidate design packages solely to `<store>/<program-slug>/arena-<slug>/candidate-<n>/` (with broker concurrency-cap fallback per **pstack-scion-runtime** §1). Upstream judgment in `SKILL.md` is preserved unchanged.
- `references/runner-prompt.md`: "git worktree when available, otherwise a per-runner subdirectory under the sketch dir" became read-only `pstack-reviewer` Scion agents (`--role baseline`) writing candidate design packages solely to `<store>/<program-slug>/arena-<slug>/candidate-<n>/` (plus `inbox/<your-agent-name>.md`) with no pushed branches or refs.
