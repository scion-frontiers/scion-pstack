# interrogate: port notes

Upstream: `upstream/pstack-bf0c7cd/skills/interrogate/` (single-file execution-proven rewrite in v0.15.42; `references/` removed upstream).

## Changed
- Frontmatter: dropped `disable-model-invocation: true` (the lead routes by name per **pstack-scion-runtime** §5).
- Fan out:
  - `interrogate reviewers` in `pstack-models.mdc` became `panels.interrogate` in `pstack-models.yaml` (**pstack-scion-runtime** §3).
  - Scope pinning & uncommitted handoff: pin exact `<base-sha>` and `<head-sha>` across every panelist brief (re-running on the final head or labeling `split-head` if concurrency-capped sequential waves diverge), and for uncommitted edits push an ephemeral `wip/<slug>` branch or write `git diff HEAD --binary > <store>/<program>/scope.patch` instead of copying into sibling worktrees (**pstack-scion-runtime** §1).
  - `generalPurpose` became `pstack-reviewer` Scion agents started with `--role baseline` (**pstack-scion-runtime** §1: ephemeral local repro/test runs inside `/workspace` are permitted to prove findings once container secret/store isolation is verified on untrusted external PRs, while pushing refs, mutating PRs, and editing shared store files other than the assigned `inbox/` file remain forbidden).
- Brief: "Keep repros in your own worktree" became "Keep repros in your own clone, never pushed".
