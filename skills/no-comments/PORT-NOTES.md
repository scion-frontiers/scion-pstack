# no-comments: port notes

Upstream: `pstack/skills/no-comments` at 5ff7a35.

## Changed
- Dropped `disable-model-invocation: true`; routed by name (runtime §5).
- Scope: added one paragraph. The sicko runs in its own clone, so the caller commits (working tree included) and pushes the scope to a branch and passes branch + SHA + base (+ file list).
- Step 1: `Task` with `subagent_type: "Comment Sicko"` → spawn a `pstack-comment-sicko` Scion agent. It pushes its comment edits as one commit on its own branch and reports by message.
- Step 2: diff inspection via `git fetch` + `git diff <scope-sha>...origin/<its-branch>`. "Revert and rerun" → take only accepted hunks; the rerun is a fresh agent (runtime: never re-task an old agent).
- Slash phrasing (`/how`, `/why`, `/architect`, `/no-comments`) kept as upstream voice; runtime §5 says a named skill is routed to as if invoked.

## Unresolved
- DESIGN.md calls `pstack-comment-sicko` "read-only". Upstream Comment Sicko deletes comments ("I touch comments"), and no-comments inspects "its report and diff". This port needs the template to allow commit + push to its own branch (never to the scope branch). The template brief/instructions must say so; alternative is a report-only sicko that lists deletions and the caller applies them, which changes step 2's review model.
- Step 5 "wait for interactive approval" relies on the runtime's ask_user pattern; not restated.
