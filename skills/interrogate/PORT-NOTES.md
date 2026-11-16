# interrogate: port notes

Upstream: `upstream/pstack-bf0c7cd/skills/interrogate/` (single-file execution-proven rewrite in v0.15.42; `references/` removed upstream).

## Changed
- Frontmatter: dropped `disable-model-invocation: true` (the lead routes by name per **pstack-scion-runtime** §5).
- Fan out:
  - `interrogate reviewers` in `pstack-models.mdc` became `panels.interrogate` in `pstack-models.yaml` (**pstack-scion-runtime** §3).
  - Uncommitted scope handoff: instead of copying uncommitted changes into sibling worktrees, push an ephemeral `wip/<slug>` branch or write `git diff HEAD --binary > <store>/<program>/scope.patch` so each adversary applies it in its own container clone (**pstack-scion-runtime** §1).
  - `generalPurpose` became `pstack-reviewer` Scion agents (**pstack-scion-runtime** §1: ephemeral local repro/test runs inside `/workspace` are permitted to prove findings, while pushing refs, mutating PRs, and editing shared store files other than the assigned `inbox/` file remain forbidden).
- Brief: "Keep repros in your own worktree" became "Keep repros in your own clone, never pushed".
