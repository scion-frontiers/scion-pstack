# no-comments: port notes

Upstream: `upstream/pstack-bf0c7cd/skills/no-comments/` (v0.15.42).

## Changed
- Frontmatter: dropped `disable-model-invocation: true` (routed by name per **pstack-scion-runtime** §5).
- Scope: Comment Sicko runs in its own clone, so the caller commits and pushes the scope to a branch first and passes branch + SHA + base (+ file list).
- Step 1: `Task` with `subagent_type: "comment-sicko"` became a `pstack-comment-sicko` Scion agent pushing `<branch>-sicko` and reporting via `inbox/` + `scion message`.
- Step 2: inspects diff via `git fetch origin <its-branch> && git diff <scope-sha>...origin/<its-branch>`, taking accepted hunks onto the caller's branch and rerunning on a fresh agent when rejected.
