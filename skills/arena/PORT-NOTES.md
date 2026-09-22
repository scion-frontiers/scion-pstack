# arena: port notes

Upstream: `pstack/skills/arena` at 5ff7a35.

## Changed
- Frontmatter: dropped `disable-model-invocation: true` (explicit-invocation intent; the lead routes by name per runtime §5).
- Runner selection: `arena runners` in `~/.cursor/rules/pstack-models.mdc` plus a slug list became `panels.arena` in `pstack-models.yaml`, with the runtime §3 default panel. "Same model N times" became "same harness-config N times".
- Output paths: the git worktree or `/tmp/arena-<slug>/candidate-<n>/` became the candidate's own pushed branch `arena-<slug>-c<n>` (code) or `<store>/<program-slug>/arena-<slug>/candidate-<n>/` (other artifacts). Each Scion agent is its own container and clone, so neither the parent's worktrees nor `/tmp` can be shared.
- Fan out: **Tier: Scion agent, `pstack-agent`**. Runners differ by vendor and write artifacts (runtime §1 (a) and (b)). `run_in_background` is implicit. The brief carries the base branch and the report line.
- Completion: a candidate counts as complete when its REPORT arrives *and* the artifact is on its branch or in its store dir. This follows the runtime's "verify artifacts, not self-reports".
- Cross-judge: **Tier: Scion agent, `pstack-reviewer`**, on one entry from `panels.cross-judge` whose vendor differs from the parent's. It reads the candidates by branch or store-path label.

## Not ported cleanly
- The parent's graft step now needs `git fetch` of N branches and a manual cross-branch merge by hand. That works, but it is heavier than reading sibling worktrees.
- Todolist: kept as-is. It assumes the harness has a todo tool. Most do.

## Open questions
- Branch naming: `arena-<slug>-c<n>` is new. Should it carry the lead-slug prefix used for agent names (runtime §1 "Name")?
- Cleanup of losing candidate branches is unspecified (upstream never had to delete worktrees either).
