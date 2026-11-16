# architect: port notes

Upstream: `upstream/pstack-bf0c7cd/skills/architect/` (v0.15.42). `references/design-red-flags.md` and `references/rationale-template.md` are verbatim.

## Changed
- Frontmatter: dropped `disable-model-invocation: true` (the lead routes by name per **pstack-scion-runtime** §5).
- Phase B: `architect runners` in `pstack-models.mdc` became `panels.architect` in `pstack-models.yaml` (resolving missing-file `[inherit, inherit, inherit]` and missing-key fallbacks per **pstack-scion-runtime** §3), delegating fallback rules to `arena` Phase A.
- `references/runner-prompt.md`: "git worktree when available, otherwise a per-runner subdirectory under the sketch dir" became "its own Scion agent in its own clone, and its output path is its own pushed branch or pstack-store dir, as the arena skill assigns".
