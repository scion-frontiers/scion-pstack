# pstack → Scion port: design

Source: `cursor/plugins` at `bf0c7cd80abdbf7fe47b634978a7d1b4071f71a7`, path `pstack/` (v0.15.42).
The snapshots are in `upstream/pstack-bf0c7cd/` and `upstream/cursor-team-kit-bf0c7cd/`.

## Goals

1. A Scion team that runs pstack's workflows (poteto-mode and its playbooks) with the same rigor, driven by messages instead of slash commands.
2. The smallest diff against upstream, so that re-syncing is cheap. Skills that need no change are **referenced from upstream by URI and never copied**.
3. A record of what porting took (`LEARNINGS.md`), which feeds the meta-skills.

## Team

| Template | Role | Replaces |
|---|---|---|
| `pstack-lead` | Entry point. Poteto-mode is always on. Matches each request to a playbook, delegates, reviews, and replies. Also serves as the orchestrate coordinator and as a track sub-coordinator. | the user's Cursor chat running `/poteto-mode` |
| `pstack-agent` | Brief-driven worker in pstack style: code delegates, PR owners, arena candidates, stackers, babysitters. | `poteto-agent` subagent, writing `generalPurpose` subagents |
| `pstack-reviewer` | Read-only panel member: interrogate adversary, architect runner, arena cross-judge, verifier, show-me-your-work trail reviewer. It may apply `scope.patch` and run ephemeral repros or tests inside its private container clone, never pushing refs, mutating PRs, or writing shared store files outside its own `inbox/` or `verdicts/` file. Its vendor is set per spawn, so panels differ by vendor. | readonly `generalPurpose` subagents on different models |
| `pstack-comment-sicko` | Comment hunter behind `no-comments`. It edits only comments, and only on its own `<branch>-sicko` branch. It never touches application code. | `Comment Sicko` subagent |

Harness and model are **not** pinned in templates. The lead picks them per spawn from
`pstack-models.yaml` (`# defaults: 2`, 3-vendor default panels `[claude, codex, gemini]`). That keeps one template per role and puts vendor diversity at spawn time (`--harness-config`).

## Host primitive map

All of it lives in one skill, `pstack-scion-runtime`. It is the port's contract. Every other
adapted skill defers to it for mechanics instead of restating them, including runtime prerequisites
and trust boundaries for verbatim tool-bearing skills (`statechart`).

## Skill disposition

Verbatim (upstream URI, pinned SHA — 38 of 58 upstream pstack skills): all 24 `principle-*`, plus
`benchmark-checklist`, `blast-radius`, `bro`, `correct`, `figure-it-out`, `in-your-own-words`,
`sharpen`, `statechart`, `tdd`, `teach`, `technical-writing`, `typescript-best-practices`,
`unslop`, `why`.

Adapted (copied into `skills/`, minimal edits, a `PORT-NOTES.md` beside each — 18 skills):
`poteto-mode` (`SKILL.md`, the playbooks with host references, and `scripts/check-plan.*`),
`setup-pstack` (rewritten to preflight harnesses and write `pstack-models.yaml`), `interrogate`,
`arena`, `swarm`, `how`, `reflect`, `recall`, `show-me-your-work`, `no-comments`,
`architect` (default panel + runner output paths), `create-verification-skill`,
`maintain-verification-skill`, `create-formal-verification-skill`,
`maintain-formal-verification-skill`, `automate-me`, `ketchup`, `poteto-help`.

New: `pstack-scion-runtime`.

From `cursor-team-kit` (sibling dir, same SHA, MIT), verbatim by URI: `deslop`, `control-ui`, `control-cli`. These are the three kit skills pstack cites. The rest of the kit (`verify-this`, `fix-ci`, `loop-on-ci`, the `ci-watcher` agent, and others) is a candidate for phase 2.

Dropped or deferred:
- `make-bot-ui` is dropped. It needs Cursor automation webhooks and Grok Bot.
- `ketchup-video` is dropped. It requires a local TTS and `ffmpeg` slide-video pipeline not provisioned in Scion agent containers (`ketchup` covers async catch-ups via Markdown, Mermaid, and shared artifacts).
- The `benny` automations pack is deferred to phase 2. It needs Slack triage automations. The Scion equivalent would be a scheduled or webhook-started agent.
- The `worktree-cleanup` playbook is kept but marked low relevance. clone-per-agent containers do not accumulate worktrees, and there are no iOS simulators.

## Skill delivery

- URI form for upstream: `https://github.com/cursor/plugins/tree/bf0c7cd80abdbf7fe47b634978a7d1b4071f71a7/pstack/skills/<name>` (and `/cursor-team-kit/skills/<name>`).
  The `gh://owner/repo/name` shorthand only resolves `skills/<name>` at the repo root, so it cannot address a monorepo subpath.
- Adapted skills are referenced as `gh://scion-frontiers/scion-pstack/<name>`, which works because `skills/` sits at this repo's root. The layout matches `scion-frontiers/agent-team`.
- Scion's GitHub skill resolvers recurse into subdirectories (`v0.3.26+`), so `templates/<role>/` commits only `agents.md` and pure-URI `scion-agent.yaml` files with no committed `templates/<role>/skills/` copies.
- `build.sh` generates `templates/*/scion-agent.yaml`. `build.sh --bundle DIR` writes self-contained offline templates with every skill copied locally (excluding `PORT-NOTES.md`, `node_modules`, and `scripts/test`), and `build.sh --check` validates both `templates/*/scion-agent.yaml` and a full `--bundle` pass.
- Executable bits are lost for URI skills. Skills invoke scripts as `bun <file>`, `node <file>`, or `bash <file>`, never `./file`.
- Name clash: the code overwrites a local skill with a URI skill of the same name, which is the opposite of what team-creation says. The port never declares both.

## Shared state

The store root resolves as `$PSTACK_STORE`, then the project shared dir (`/scion-volumes/<name>/pstack`), then a gate.
Each program gets `<root>/<slug>/`, with `notes.md` as the coordinator's one-writer tracker alongside `decisions.tsv`, `goal.md`, `resume.md`, `briefs/`, `inbox/`, and `verdicts/`. `pstack-models.yaml` sits at `<root>/pstack-models.yaml`.
