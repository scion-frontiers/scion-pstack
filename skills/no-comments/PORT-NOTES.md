# no-comments: port notes

Upstream: `upstream/pstack-bf0c7cd/skills/no-comments/` (v0.15.42).

## Changed
- Frontmatter: dropped `disable-model-invocation: true` (routed by name per **pstack-scion-runtime** §5).
- Scope: added a zero-comment pre-spawn fast-path scanning scoped/added lines for any comment or suppression syntax (including trailing inline comments: `//`, `/*`, `#`, `<!--`, `--`, `eslint-disable`, `@ts-ignore`, `@ts-expect-error`) so comment-free scopes report `0 deletions` without booting a container; otherwise commits and pushes the scope to a branch first and passes branch + SHA + base (+ file list).
- Step 1: `Task` with `subagent_type: "comment-sicko"` became a `pstack-comment-sicko` Scion agent (`--role baseline`), pushing `<branch>-sicko` only when edits are made and pushing no branch / no empty commit when `0` edits are made (reporting `0 deletions` plus any `MUST KILL` flags via `inbox/` + `scion message`).
- Step 2: inspects diff via `git fetch origin <its-branch> && git diff <scope-sha>...origin/<its-branch>` when `<its-branch>` was pushed (or audits the scoped code directly when `0` edits were made), taking accepted hunks onto the caller's branch and rerunning on a fresh agent when rejected.
