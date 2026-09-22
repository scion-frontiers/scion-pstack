# pstack → Scion port: design

Source: `cursor/plugins` at `5ff7a359dec6be2128b15c0fe53c1c12a46e41c8`, path `pstack/` (v0.15.2).
The snapshot is in `upstream/pstack-5ff7a35/`.

## Goals

1. A Scion team that runs pstack's workflows (poteto-mode and its playbooks) with the same rigor, driven by messages instead of slash commands.
2. The smallest diff against upstream, so that re-syncing is cheap. Skills that need no change are **referenced from upstream by URI and never copied**.
3. A record of what porting took (`LEARNINGS.md`), which feeds the meta-skills.

## Team

| Template | Role | Replaces |
|---|---|---|
| `pstack-lead` | Entry point. Poteto-mode is always on. Matches each request to a playbook, delegates, reviews, and replies. Also serves as the orchestrate coordinator and as a track sub-coordinator. | the user's Cursor chat running `/poteto-mode` |
| `pstack-agent` | Brief-driven worker in pstack style: code delegates, PR owners, arena candidates, stackers, babysitters. | `poteto-agent` subagent, writing `generalPurpose` subagents |
| `pstack-reviewer` | Read-only panel member: interrogate reviewer, architect runner, arena cross-judge, how/why explainer, verifier, show-me-your-work trail reviewer. Its vendor is set per spawn, so the panels differ by vendor. | readonly `generalPurpose` subagents on different models |
| `pstack-comment-sicko` | Comment hunter behind `no-comments`. It edits only comments, and only on its own `<branch>-sicko` branch. It never touches application code. | `Comment Sicko` subagent |

Harness and model are **not** pinned in templates. The lead picks them per spawn from
`pstack-models.yaml`. That keeps one template per role and puts vendor diversity at
spawn time (`--harness-config`).

## Host primitive map

All of it lives in one skill, `pstack-scion-runtime`. It is the port's contract. Every other
adapted skill defers to it for mechanics instead of restating them.

## Skill disposition

Verbatim (upstream URI, pinned SHA). These are all 23 `principle-*`, plus `unslop`, `technical-writing`, `tdd`, `bro`,
`blast-radius`, `figure-it-out`, `teach`, `typescript-best-practices`.

Adapted (copied into `skills/`, minimal edits, a `PORT-NOTES.md` beside each):
`poteto-mode` (SKILL.md and the playbooks with host references), `setup-pstack` (rewritten to write
`pstack-models.yaml`), `interrogate`, `arena`, `swarm`, `how`, `why`, `reflect`, `recall`,
`show-me-your-work`, `no-comments`, `architect` (default model slugs + runner output paths), `create-verification-skill`, `maintain-verification-skill`,
`automate-me`.

New: `pstack-scion-runtime`.

From `cursor-team-kit` (sibling dir, same SHA, MIT), verbatim by URI: `deslop`, `control-ui`, `control-cli`. These are the three kit skills pstack cites. The rest of the kit (`verify-this`, `fix-ci`, `loop-on-ci`, the `ci-watcher` agent, and others) is a candidate for phase 2.

Dropped or deferred:
- `make-bot-ui` is dropped. It needs Cursor automation webhooks and Grok Bot.
- The `benny` automations pack is deferred to phase 2. It needs Slack triage automations. The Scion equivalent would be a scheduled or webhook-started agent.
- The `worktree-cleanup` playbook is kept but marked low relevance. clone-per-agent containers do not accumulate worktrees, and there are no iOS simulators.

## Skill delivery

- URI form for upstream: `https://github.com/cursor/plugins/tree/5ff7a359dec6be2128b15c0fe53c1c12a46e41c8/pstack/skills/<name>`.
  The `gh://owner/repo/name` shorthand only resolves `skills/<name>` at the repo root, so it cannot address a monorepo subpath.
- Adapted skills currently ship as template-local `skills/` dirs, copied in by `build.sh` from `skills/`.
  Once they are published to the skill bank, `build.sh` switches them to `skill://` URIs.
- Executable bits survive for template-local skills but not for URI skills. Skills invoke scripts as `bun <file>` or `bash <file>`, never `./file`.
- Name clash: the code overwrites a template-local skill with a URI skill of the same name, which is the opposite of what team-creation says. The port never declares both.

## Shared state

The store root resolves as `$PSTACK_STORE`, then the project shared dir (`/scion-volumes/<name>/pstack`), then a gate.
Each program gets `<root>/<slug>/`, with orchestrate's layout and the one-writer rule. `pstack-models.yaml` sits at the root.
