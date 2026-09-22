# architect: port notes

Upstream: `pstack/skills/architect` at 5ff7a35. DESIGN.md listed architect as verbatim, pending this check. The check found two host-specific lines, so architect moves to **adapted**.

## Changed
- Frontmatter: dropped `disable-model-invocation: true` (explicit-invocation intent; the lead routes by name).
- Phase B: the four default model slugs became `panels.architect` in `pstack-models.yaml` (default panel in runtime §3), used in place of arena's `panels.arena`. Everything else defers to the arena skill, which owns the fan-out mechanics. **Tier: runners are `pstack-agent` Scion agents (via arena), and the cross-judge is a `pstack-reviewer` Scion agent.**
- `references/runner-prompt.md`: "git worktree when available, otherwise a per-runner subdirectory under the sketch dir" became "own Scion agent in its own clone, output on its own branch or store dir, as arena assigns". A sketch-dir subdirectory in the parent's clone is unreachable from another container.
- All other text is verbatim. Phase A delegates to `how`/`why`, and Phase C's checkpoint is a plain "pause for sign-off", which the runtime's ask rule covers.

## Open questions
- Runner prompts are passed "through" as files. The arena brief must inline `runner-prompt.md` and `rationale-template.md`, or point at the skill path in the runner's own template. That only works if `pstack-agent` ships the architect skill. Confirm in the template.
