---
name: pstack-scion-runtime
description: >-
  How pstack's host primitives (Task subagents, subagent_type, per-call model and effort,
  readonly, AskQuestion, /loop, /goal, the agent store, transcripts) map onto Scion. Read this
  before any other pstack skill whenever you run pstack inside Scion. Also read it whenever a pstack
  skill tells you to spawn a subagent, pick a model, ask the human, arm a loop, or read a transcript.
---

# pstack on Scion

pstack was written for Cursor. Its skills are portable, but they name Cursor primitives.
This skill is the translation table. When a pstack skill and this table disagree about
*mechanics*, this table wins. When they disagree about *judgment* (what to verify, when to
fan out, what a good brief contains), the pstack skill wins.

## 0. Skills are files. Read them directly.

Many pstack skills set `disable-model-invocation: true`, which hides them from some harness skill tools (such as Claude Code). pstack says "read the leaf skill": when a skill names another (**principle-fix-root-causes**, the **why** skill, `playbooks/feature.md`), open `$HOME/<skills_dir>/<name>/SKILL.md` (`skills_dir` is `.claude/skills`, `.codex/skills`, `.gemini/skills`, etc.; `ls -d $HOME/.*/skills/*/`). Relative paths (`references/...`, `playbooks/...`, `scripts/...`) resolve against that skill's directory. `setup-pstack`, `automate-me`, and `poteto-help` ship only on `pstack-lead` (workers/reviewers flag the lead in `REPORT` instead of searching for them); when a reviewer skill cites **poteto-mode**'s Subagents effort rules without shipping `poteto-mode`, use §1. On workspace-sandboxed harnesses (`gemini-cli`), where `read_file`/`write_file`/`replace` reject paths outside `/workspace`, read `$HOME/<skills_dir>/...` and `/scion-volumes/...` via shell commands (`cat`, `sed -n`, Python/Node; §1, §4).

## 1. Two delegation tiers

pstack says "spawn a subagent" (`Task` with `subagent_type`, `model`, `run_in_background`).
On Scion, pick one of two tiers.

| Tier | Mechanism | Use when |
|---|---|---|
| **In-harness subagent** | Your harness's native subagent tool (e.g. Claude Code's Agent tool), passing its effort/model-tier parameter when supported; if none exists, run inline. | Read-only exploration, slicing a corpus, drafting in one turn where model diversity is not the point (`how` explorer, `recall` slices, cheap `swarm` coverage slices). |
| **Scion agent** | `scion start <name> --type <template> --role <role> --harness-config <h> [--model <m>] "<pointer-task>"` | Any of: (a) needs a **different model family** (`interrogate` reviewers, `arena` runners, `architect` runners, `arena` cross-judge, a verifier differing from its worker, `show-me-your-work` trail review); (b) **writes code on its own branch**; (c) can **outlive your turn** (owners, babysitters, stackers, sub-coordinators). |

When unsure, use a Scion agent for writes and an in-harness subagent for reads. Every Scion spawn costs a container boot, skill provisioning, and a broker slot, so skip container spawns on provably empty scopes (e.g. zero added comments/suppressions before `no-comments`).

### subagent_type → template

| pstack `subagent_type` | Scion template | Default `--role` |
|---|---|---|
| `poteto-agent` (code delegates, owners, stackers, babysitters, ad-hoc helpers) | `pstack-agent` | `baseline` for leaf workers; `full` only when the brief assigns spawning child Scion agents |
| `generalPurpose` with `readonly: true` (reviewers, judges, explainers, verifiers) | `pstack-reviewer` | `baseline` |
| `generalPurpose` that writes (arena candidates, swarm workers that produce branches) | `pstack-agent` | `baseline` |
| `comment-sicko` / `Comment Sicko` | `pstack-comment-sicko` | `baseline` |
| sub-coordinator | `pstack-lead`, with a track brief (honor an explicit human-mandated track split even below ~10 workers, recording it in `notes.md`/`goal.md`) | `full` (required for `project:agent:create` and `project:agent:lifecycle`; must pass `--role baseline` to leaf children) |

### model slug & effort → harness-config + model

pstack names a model per role (`claude-opus-5-5-xhigh`, `claude-fable-5-2-max`, `gemini-4-carbon-high`, etc.) and adjusts reasoning effort and speed per job. On Scion a role maps to a **harness-config** (vendor CLI) plus an optional **model** (`small|medium|large|extra-large` or explicit ID) from `pstack-models.yaml` (§3). Never guess a harness-config name; use `scion harness-config list`.

"Different model family" means a **different resolved model family** (`anthropic`, `openai`, `google`, `xai`, ...; §3), not merely a different `harness-config` name or model size; fall back to distinct `harness-config` names only when family is unknown.

When matching reasoning effort and fast/standard speed to the job:
- **Tier 1 (in-harness subagent):** Pass the harness's native effort or speed parameter when supported.
- **Tier 2 (`scion start`):** Keep the role's `harness-config` and model family so panels stay diverse, mapping job effort onto `--model` (`low`/fast mechanical → `small` or `medium`; `standard` → `large`; `high`/`xhigh`/`max` → `extra-large`), capped by `budget` unless pinned to an explicit model ID. Verification stays on `swarm-worker` (`large` by default).

### Spawn defaults, briefs, and interface tokens

- **Name.** Name every agent `<lead-slug>-<role>-<unit>` (e.g. `ps-auth-rev-codex-1`), unique among live agents. Give each new task a fresh numeric suffix; never re-task an old agent.
- **Role (`--role`).** Always pass `--role` explicitly on `scion start`; omitting it inherits the parent/project ceiling and leaks `role=full` Hub secret access (`scion secret get --value`, `sciontool secret set`) and lifecycle permissions (`project:agent:create`, `project:agent:lifecycle`). Only `--role full` can run `scion start`, `scion delete`, or `--wake` schedules: use `--role full` for `pstack-lead` sub-coordinators and delegating `pstack-agent` owners (`autopilot-full`, `multi-phase-plan`) whose brief explicitly assigns spawning child Scion agents, requiring them to pass `--role baseline` to every leaf child. Pass `--role baseline` for `pstack-reviewer`, `pstack-comment-sicko`, `setup-pstack` preflight agents, and all leaf `pstack-agent` workers (permits `scion message` and `sciontool status`; denies Hub secret access and child spawns).
- **Background is implicit.** Every Scion agent runs in the background (`run_in_background: true` needs no action).
- **Reviewer isolation and ephemeral repros.** Scion has no readonly flag; each agent runs in its own container clone (`/workspace`). `pstack-reviewer` must never push refs, comment on or mutate PRs, or edit shared store files outside its assigned `inbox/` (and `verdicts/`) file; inside its private `/workspace` clone, applying `scope.patch` and running ephemeral minimal repros or failing tests is allowed when a skill (`interrogate`, verifier) requires execution proof (state this `FORBIDDEN` boundary in the brief). **Untrusted external PRs:** before applying patches, checking out fork branches, or running tests/repros from an untrusted external/fork PR, verify container env secrets (`GITHUB_TOKEN`) and shared `<pstack store>` mounts are isolated or read-only (`--role baseline` blocks Hub API secrets, not container env vars or mounts).
- **File pointers, pinned SHAs, and uncommitted scope handoff.** Paths in your clone do not exist in child clones: point at pushed branches with explicit `<base-sha>` and `<head-sha>` pins (plus PR URL when present), or **pstack store** paths (§4). Every panelist in `interrogate` must inspect the exact same `<head-sha>`: if concurrency caps force staggered waves and the branch advances mid-panel, re-run earlier panelists on the final `<head-sha>` or label the verdict `split-head`. For uncommitted edits in your checkout, push an ephemeral `wip/<slug>` branch (pinned by SHA) or write `git diff HEAD --binary > <store>/<program>/scope.patch` and pass `<base-sha>` plus `scope.patch` in each reviewer brief (`git checkout --detach <base-sha> && git apply <store>/<program>/scope.patch`).
- **The brief is a file, the task argument is a pointer.** Write the full brief to `<store>/<program>/briefs/<agent-name>.md`, including resolved `PSTACK_STORE` and `<store>/<program>/` explicitly so children never glob `/scion-volumes/*/` (§4). Keep the `scion start` task argument to one short paragraph (role, brief path, `REPORT` line); inline tasks above ~31 KB crash agents at start.
- **Workspace-bound file tools (`gemini-cli`).** `gemini-cli` (and any workspace-sandboxed harness) restricts `read_file`/`write_file`/`replace` to `/workspace`, refusing `/scion-volumes/...` and `$HOME/...`. Access `<store>/...` and `$HOME/.*/skills/...` via shell commands (`cat`, `sed -n`, `mkdir -p`, `tee`, quoted heredocs, or Python/Node file I/O when shell guards reject backticks/heredocs). Stage temporary drafts in `/tmp` if needed, **never** in `/workspace` (collides across agents on `SCION_WORKSPACE_MODE=shared-plain` and pollutes checkouts). Note this in `gemini-cli` child briefs, and on `SCION_WORKSPACE_MODE=shared-plain` run a post-wave `/workspace` hygiene check (`ls -la /workspace`, `git status --short`) to quarantine stray files.
- **Brief checklist.** Size the brief to the unit (collapse to a short paragraph for a trivial unit), covering: `PSTACK_STORE` (plus `<store>/<program>/`), `GOAL`, `SCOPE`, `CONTEXT`, `ACCEPTANCE`, `VERIFY`, `TIMEBOX`, `FORBIDDEN`, `REPORT`, and `STANDING` (a pointer to `notes.md` in the store, or inline constraints).
- **The brief carries the report channel.** End every brief with: "When done, write your REPORT block to `<store>/<program>/inbox/<your-agent-name>.md`, send it to `@<lead-agent-name>` with `scion message`, then signal task completion." The inbox file is the primary artifact, and the message is the wake-up.
  - **Worker `REPORT` required items:** `status`, `branch`, `head SHA`, `PR URLs`, `verdict`, **per-`ACCEPTANCE` and per-`VERIFY` proof** (for each `ACCEPTANCE` and `VERIFY` line in the brief: exact command run, numeric exit code, and key literal output lines proving it; checkboxes, unbacked prose claims, and `"simulated"` runs are forbidden; test-first / **tdd** units must quote both the initial failing behavioral run and the passing run), `deviations` (backed by command or `file:line` evidence), and `follow-ups`.
  - **Verifier verdict tokens:** When verifying a PR or branch head, also write `<store>/<program>/verdicts/<pr-or-unit>-<sha7>-<agent-name>.md` using one of: `live-ui-verified | live-cli-verified | unit-test-verified | type-check-only | verifier-blocked | verifier-failed`. `verifier-blocked` is never a pass. CI green is an input, not a verdict.

### Completion (replaces the Task completion notification)

- Completion arrives via a state-change notification, the worker's `REPORT` message, and its `inbox/` file. Treat either `REPORT` or `COMPLETED` as the wake-up, then read `inbox/`. If both are missing, check `scion look <name> --full --plain` once before calling the worker failed.
- While waiting, run `sciontool status blocked "<what you are waiting on>"` and end your turn. Never poll, sleep, or `scion look` in a loop.
- Never message a silent worker as a probe (messaging wakes idle agents). Probe read-only: `scion list`, pushed branch, `inbox/` or `verdicts/`, and `scion look <name> --full --plain` once. If `scion list` shows `waiting_for_input` (or `agent.input-needed` arrives) without a task question in `scion message`, check `scion look <name> --full --plain` once: if the child sits on an interactive login/auth prompt (`login`, `setup-token`, `auth login`, `"started without credentials"`, device-auth URL), shell drop, or startup serialization error, `scion delete <name>`, mark that `harness-config` unavailable for the session (§3), and respawn on a runnable substitute.
- Prefer `scion look <name> --full --plain` while the container exists; `scion logs` can return 403 or 404 on hosted brokers even for healthy completed agents, so never treat a `scion logs` error alone as crash evidence. A start crash leaves no `inbox/` file, error state in `scion list`, and empty/failed `scion look`. Retry once with a pointer-only task; on a second crash, mark that `harness-config` unavailable (§3).

### Getting the result back

A worker's product lives on a pushed branch or in the pstack store, never only in its container.
Review every code delegate's diff (`git fetch origin <branch> && git diff <base>...origin/<branch>`), check that its `REPORT` supplies per-`ACCEPTANCE`/`VERIFY` command + exit code + key literal output lines (rejecting checkboxes or `"simulated"` runs), and **re-run at least the brief's `VERIFY` commands locally** in your checkout or a clean detached checkout of `origin/<branch>` (or via an independent `pstack-reviewer` verifier when your container lacks the required service/mount, §2) before accepting a remote worker's `REPORT`. "You own every subagent's work" still applies.

## 2. Other primitives

| pstack / Cursor | Scion |
|---|---|
| `AskQuestion` (structured multi-choice) | `sciontool status ask_user "<question>"`, then `scion message` the human (or use `--choices-file` when appropriate) with clear options, your recommendation, and the default you will take if there is no answer. Poteto-mode's rule still governs *whether* to ask. |
| `/loop`, "arm a wake chain", "cloud-sleeper", "watcher subagent that wakes you" | For an agent event: `sciontool status blocked` and wait for the notification. For an external event (CI, a merge, a ref advancing) watched from inside your container (for example `watch-pr`), run the watcher as a background shell command (which wakes you on exit) backed by a **one-shot** self-callback via `scion schedule create --in <d> --agent <self> --message "..."`, then `sciontool status blocked`; cancel any pending one-shot callback with `scion schedule cancel <id>` on early wake, stand-down, or program close. For a **recurring** cadence (such as `/loop 1h`), create a cron schedule via `scion schedule create-recurring --name <unique-name> --cron "<5-field>" --agent <self> --message "..."` and remove it with `scion schedule delete <id>` on stand-down and program close. Record every `<id>` and kind (`one-shot` vs `recurring`) in `notes.md`; never call `delete` on a one-shot event or `cancel` on a recurring schedule (see `scion-scheduler`). |
| `/goal` | Write the full objective to `<store>/<program>/goal.md` (§4) and re-read it at every audit tick. |
| `environment: "cloud"` / `"local"` | Not applicable. Every agent is a container in its own clone, so remote worker `REPORT`s require per-`ACCEPTANCE`/`VERIFY` command + exit code + key literal output lines and local lead `VERIFY` re-execution (§1). "Needs this machine" becomes "needs a template service, mount, or secret" (delegate verification to a matching `pstack-reviewer` container or flag a gate if missing). |
| `cloud_base_branch` | Put the base branch in the brief. The worker runs `git fetch origin <branch> && git checkout -B <work-branch> origin/<branch>`. |
| "the Cursor dashboard", "cloud agent status" | `scion list`, `scion look <name> --full --plain` (`waiting_for_input` with no `scion message` question: inspect `scion look` once for auth/startup failure, `scion delete <name>`, and mark the harness unavailable; §1, §3). |
| "After a Cursor restart" | After the lead is resumed or replaced. Workers are separate containers and survive it. Reattach by agent name, branch, and PR. |
| `agent-transcripts/` (your own chat history) | No shared transcript store exists. Use in order: (0) your harness's readable local session log (e.g. `~/.claude/projects/*/*.jsonl`; own container only); (1) `decisions.tsv` (`show-me-your-work`) and `notes.md`; (2) `scion conversation` history; (3) `scion look <agent> --full --plain` while the container exists (prefer over `scion logs <agent>`, which can return 403/404 on hosted brokers). State which source you used. |
| `mcps/` directory, "available MCPs" | The MCP servers your harness lists. Template `mcp_servers` adds more. |
| Cursor built-in `create-skill` | The authoring-a-skill playbook plus the agentskills.io format: `SKILL.md` with `name` and `description` frontmatter. |
| Cursor built-in `/babysit` | Not present. The babysit playbook is the only babysit. |
| `cursor-team-kit` `deslop` (`/deslop`) | The `deslop` skill, installed verbatim from cursor-team-kit. Read it as a file (§0) and run it over the diff against the base branch. |
| `cursor-team-kit` `control-ui` / `control-cli` | Installed verbatim from cursor-team-kit (`verify-this`, cited in `control-ui`, is not installed on Scion; use project `verify-*` skills from `create-verification-skill`). Standard Scion images ship `/usr/bin/chromium` and Node `v24+` without `playwright`/`playwright-core`: if the repo does not depend on `playwright`, do not edit `package.json`; install `playwright-core` into `/tmp/pw` (`npm install --no-save --prefix /tmp/pw playwright-core`, `executablePath: "/usr/bin/chromium"`, `args: ["--no-sandbox"]`, registry required) or run `/usr/bin/chromium --headless --no-sandbox --remote-debugging-port=9222` and drive CDP via Node 24's global `fetch` + `WebSocket`. If `/usr/bin/chromium` (or `tmux` / PTY for `control-cli`) is absent, setup fails, or the surface is unreachable, report `verifier-blocked` (or `live-cli-verified` / `live-ui-verified` on pass), never a silent pass. Save screenshots/traces to the store or branch, not `/tmp` (§1). |
| `~/.cursor/rules/pstack-models.mdc` | `pstack-models.yaml` in the pstack store (§3). |
| `.cursor/skills/<name>/` (project-local skill output) | `.scion/skills/<name>/` in the repo. Scion never auto-loads skills from `/workspace` at start: copy into `.scion/templates/<role>/skills/<name>/` and run `scion templates sync <role>`, publish it, or add its `https://github.com/<owner>/<repo>/tree/<ref>/.scion/skills/<name>` URI to `scion-agent.yaml`. |
| Installed plugin cache (`~/.cursor/plugins/cache/...`, `~/.claude/plugins/cache/...`) | Skills under `$HOME/.*/skills/` are read-only provisioned copies. `reflect` and skill-maintenance edits target the source checkout (`.scion/skills/`, `.scion/templates/`, or `scion-pstack`), never `$HOME/.*/skills/`. |
| `ketchup` visuals & >2000-char waiting lists | Scion human messages cap at 2000 Unicode chars and cannot open container-local paths. Save screenshots, diagrams, or >2000-char waiting sheets under `/scion-volumes/...` (`<store>/<program>/`) or via `scion artifact publish` (`scion://artifact/<id>`), placing plain-text `scion://artifact/<id>` and `/scion-volumes/...` refs outside backticks in `scion message` so web chat links previews. (`ketchup-video` and `/visualize` are not installed on Scion.) |
| `statechart` (`/statechart`) | Invoke via `node <statechart-skill-dir>/scripts/statechart.ts` (or `bash <statechart-skill-dir>/scripts/statechart`). Pure JS `--view` runs on preinstalled Node `v24+`; TLA+ SANY/TLC (`run.ts`) needs `java` and `tla2tools.jar` (`mise` is absent: check `command -v java` upfront and report `verifier-blocked` rather than ad-hoc binary installs or hanging). Pass `--out <store>/<program>/statecharts/` instead of `/tmp` for shared outputs. **Security boundary:** `--view <module.mjs>` executes JS/TS via `import()`, and omitting `--view` when Java + `tla2tools.jar` exist still runs `tlc2.TLC` with `-DTLA-Library=<spec-dir>` (Java module override vector) and no timeout; never run `statechart` (with or without `--view`) on untrusted external/fork PRs unless container secrets (`GITHUB_TOKEN`) and `<pstack store>` mounts are isolated/read-only and an external timeout (`timeout 120s`) wraps the run. |
| `gt` (Graphite) | Optional. Use it only if installed and the program's standing orders in `notes.md` name a stacker; always pass `--no-interactive` so `gt log` never hangs on interactive trunk setup, and never call `gt submit` without a configured remote PR host. Otherwise use plain `git` plus `gh` (or `origin`). |
| No PR host / bare git `origin` (`/scion-volumes/.../repo.git`) | When `origin` is a local or shared-volume bare git repo with neither GitHub (`gh`) nor Origin (`origin pr`): a **"PR"** maps to a pushed branch + exact `<head-sha>` + a unit review record at `<store>/<program>/reviews/<unit>.md`; verifier verdicts go to `<store>/<program>/verdicts/<unit>-<sha7>-<agent-name>.md`; `interrogate` reviews `git diff <base-sha>...<head-sha>` fetched from `origin`; `babysit` and `watch-pr` are N/A (run repo checks directly in worker and verifier containers); and landing is `git merge --no-ff` onto trunk by the coordinator after an independent `pstack-reviewer` pass at `<head-sha>`, re-running checks on merged trunk before pushing `origin`. |

## 3. pstack-models.yaml

pstack's per-role model table (`# defaults: 2`), restated as harness-configs and resolved model families. `setup-pstack` preflights harnesses and writes `<store>/pstack-models.yaml`. Every pstack skill that says "your configured X model" reads it.

**When `<store>/pstack-models.yaml` is missing (`inherit` fallback).** Never spawn unpreflighted harnesses: until `setup-pstack` writes `<store>/pstack-models.yaml`, default every role (`code`, `hardest`, `judgment`, `reflect-judgment`, `reflect-tooling`, `swarm-worker`) to `inherit` (omit `--harness-config` and `--model`) and every 3-seat panel (`interrogate`, `architect`, `arena`, `cross-judge`) to `[inherit, inherit, inherit]`. Panels keep 3-agent fan-out on `inherit` and flag 1-family (1-vendor) degraded diversity above findings; `arena` Phase C skips `cross-judge` with notice (`inherit` shares the caller's family); `show-me-your-work` runs its trail `pstack-reviewer` on `inherit` with a 1-family note in `Attention`. Suggest `setup-pstack` once per project (or once per session if missing or lacking `# defaults: 2`), without blocking. Retired `# defaults: 1` keys (`how-explorer`, `how-explainer`, `why-investigator`, `why-synthesizer`) are ignored at runtime and pruned when `setup-pstack` re-runs.

Listed is not runnable: a harness-config can fail at start (auth prompt in `waiting_for_input`, missing image, crash). `setup-pstack` preflights each entry and records its resolved model `family` (`anthropic`, `openai`, `google`, `xai`, ...) from `config.yaml` `model_aliases`/`model` in `families:` (or `{harness, model, family}` when an explicit model ID changes a multi-provider harness's family, e.g. `opencode` on Claude vs Gemini). Without `families`, infer family by model ID prefix (`claude-*` → `anthropic`, `gpt-*`/`o1*`/`o3*`/`o4*` → `openai`, `gemini-*` → `google`, `grok-*` → `xai`), falling back to distinct `harness-config` names only when unknown. If a configured harness is unlisted or unavailable, substitute a runnable entry from `pstack-models.yaml` of another family for panel/cross-review roles, or the same family (else `inherit`) for single roles, noting the substitution.

**Degraded diversity.** Count panel diversity by distinct resolved **model families**, not `harness-config` names (`gemini-cli` + `antigravity` on Gemini = 1 family; `claude` + `opencode` on Claude = 1 family). When a panel collapses to fewer families (including 1 under `inherit`), keep the listed fan-out, varying model size where possible; label reviewers by harness-config and family, state N-family (N-vendor) above findings, and compensate with an independent non-model check (test corpus, mutation run, benchmark).

```yaml
# pstack-models.yaml
# defaults: 2
# preflight <date>: runnable [<name> (<family>/<model>), ...]; failed [<name>: <reason>, ...]
budget: unlimited
families:           # resolved model family per runnable harness-config (from config.yaml model_aliases)
  claude: anthropic
  codex:  openai
  gemini: google
roles:
  code:             {harness: claude, model: extra-large}   # feature, refactoring, bug-fix, perf, hillclimb delegates
  hardest:          {harness: claude, model: extra-large}   # cross-cutting design, gnarly concurrency
  judgment:         {harness: claude, model: extra-large}   # prose, judgment, synthesizers, arena-picker
  reflect-judgment: judgment
  reflect-tooling:  {harness: codex, model: extra-large}
  swarm-worker:     {harness: claude, model: large}
panels:             # one agent per entry, at most one per model family when available (3-family target in defaults: 2)
  interrogate: [claude, codex, gemini]
  architect:   [claude, codex, gemini]
  arena:       [claude, codex, gemini]
  cross-judge: [claude, codex, gemini]   # pick one whose model family differs from the caller's
```

Inside an existing `pstack-models.yaml`, a missing role key falls back to `judgment` (prose, synthesis, explanation), `code` (code writers), or the `# defaults: 2` target above when its harness is in the file's runnable set (else `inherit`). `budget` caps per-job `--model` effort overrides unless pinned to an explicit model ID. Panel entries run at `model: extra-large` unless written as `{harness: <h>, model: <m>}` (or `{harness: <h>, model: <m>, family: <f>}`).

## 4. The pstack store

pstack's orchestrate, autopilot, and `show-me-your-work` playbooks keep state in "the Project store" / "the current agent's store". On Scion it must be readable across every agent on the program, so it lives on a **project shared directory**, not in your clone.

- **Canonical default:** store root = `$PSTACK_STORE`, else `/scion-volumes/scratchpad/pstack`, program dir `<store>/<program-slug>/`.
- Resolve once at task start: (1) `$PSTACK_STORE` if set; (2) a mounted writable shared dir with `pstack/` appended (`ls -d /scion-volumes/*/` or `.scion-volumes/*/`, where `scratchpad` wins; `mkdir -p <store>` on first use, checking the mount directly since `scion shared-dir list` can report none while mounted); (3) else ask the human to mount `scratchpad` or set `PSTACK_STORE`, keeping state in your clone and inlining context into briefs until then. Pass resolved `PSTACK_STORE` and `<store>/<program-slug>/` explicitly in every child brief (§1).
- **Shell I/O for `/scion-volumes/...` (`gemini-cli`).** Shared store paths sit outside `/workspace`: workspace-sandboxed harnesses (`gemini-cli`) must read/write `<store>/...` via shell commands (`cat`, `sed -n`, `mkdir -p`, `tee`, quoted heredocs, or Python/Node), staging temporary drafts in `/tmp` if needed and **never** in `/workspace` (§1).
- Layout: `<root>/pstack-models.yaml`, and `<root>/<program-slug>/` per program (`adhoc-<yyyymmdd>-<topic>` outside a program; never place program files at `<root>/`):
  - `notes.md`: single-writer coordinator tracker (`pstack-lead`), standing orders, open gates, and active schedule IDs + kinds (`one-shot` vs `recurring`, matching `orchestrate.md`).
  - `goal.md`: durable program objective where autopilot playbooks arm `/goal`.
  - `resume.md`: `pause-safely` checkpoint note.
  - `decisions.tsv`: `show-me-your-work` trail.
  - `docs/`: multi-phase plans and design artifacts.
  - `briefs/<agent-name>.md`: worker or reviewer brief written before `scion start` (>31 KB task-arg crash guard).
  - `inbox/<agent-name>.md`: child's primary durable `REPORT` file (single writer per child; never bulk-deleted). For `pstack-agent` workers, it must record per-`ACCEPTANCE`/`VERIFY` command + exit code + key literal output lines (checkboxes and `"simulated"` runs are forbidden), and `pstack-lead` re-runs at least `VERIFY` before accepting it (§1).
  - `verdicts/<pr-or-unit>-<sha7>-<agent-name>.md`: verifier verdict records keyed by PR (or unit ID on bare-git `origin`) + head SHA so concurrent verifiers never collide.
  - `reviews/<unit>.md`: unit review record (branch, head SHA, lead `VERIFY` re-run output, verdict links) when `origin` has no PR host (§2).
  - `scope.patch`: optional `git diff HEAD --binary` patch written when running `interrogate` on uncommitted changes.
- Every file has one writer: only the coordinator writes `notes.md`, `goal.md`, and `reviews/<unit>.md`, and each child writes only its own `inbox/<agent-name>.md` (and `verdicts/<pr-or-unit>-<sha7>-<agent-name>.md`).
- Keep the store out of commits and out of cleanup.

## 5. Human surface

- The human talks to the lead through Scion messages, and your terminal output is not visible to them. Every pstack "Reply" is sent as a `scion message` to the conversation the request came from. Messages to humans cap at 2000 characters. Put the long form in the store (or publish an artifact) and send a plain-text pointer.
- pstack's slash commands do not exist. When the human names a skill ("interrogate this", "arena it", "/how does X work", "/ketchup"), route to that skill as if it had been invoked. Treat poteto-mode as always on for the lead, and apply its "Casual turn or user opts out → don't" rule.
- Before ending any turn, signal state: `task_completed` when the request is done, `blocked` while waiting on agents or schedules, `idle` when standing by between requests, and `ask_user` before a question.
