---
name: pstack-scion-runtime
description: >-
  How pstack's host primitives (Task subagents, subagent_type, per-call model, readonly,
  AskQuestion, /loop, the agent store, transcripts) map onto Scion. Read this
  before any other pstack skill whenever you run pstack inside Scion. Also read it whenever a pstack
  skill tells you to spawn a subagent, pick a model, ask the human, arm a loop, or read a transcript.
---

# pstack on Scion

pstack was written for Cursor. Its skills are portable, but they name Cursor primitives.
This skill is the translation table. When a pstack skill and this table disagree about
*mechanics*, this table wins. When they disagree about *judgment* (what to verify, when to
fan out, what a good brief contains), the pstack skill wins.

## 0. Skills are files. Read them directly.

Many pstack skills carry `disable-model-invocation: true`. On some harnesses (Claude Code, for one) that
hides the skill from the model's skill tool. pstack never depended on that tool anyway: it says
"read the leaf skill". So when a pstack skill names another skill (**principle-fix-root-causes**,
the **how** skill, `playbooks/feature.md`), open its file:
`$HOME/<skills_dir>/<name>/SKILL.md`. `skills_dir` is `.claude/skills`, `.codex/skills`,
`.gemini/skills`, and so on. `ls -d $HOME/.*/skills/*/` finds it. Relative paths inside a skill
(`references/...`, `playbooks/...`, `scripts/...`) resolve against that skill's directory.

## 1. Two delegation tiers

pstack says "spawn a subagent" (`Task` with `subagent_type`, `model`, `run_in_background`).
On Scion, pick one of two tiers.

| Tier | Mechanism | Use when |
|---|---|---|
| **In-harness subagent** | Your harness's own subagent tool (for example Claude Code's Agent tool). If your harness has none, do the step inline. | Read-only exploration, slicing a corpus, drafting. Model diversity is not the point, and the result comes back in one turn. Examples: `how` explorers, `recall` slices, `swarm` coverage slices on cheap units. |
| **Scion agent** | `scion start <name> --type <template> --harness-config <h> [--model <m>] "<brief>"` | Any of these is true: (a) the step needs a **different model family** (interrogate reviewers, arena runners, architect runners, the arena cross-judge, a verifier that must differ from its worker, the show-me-your-work trail review); (b) the step **writes code on its own branch**; (c) the step can **outlive your turn** (owners, babysitters, stackers, sub-coordinators). |

If you are unsure, use a Scion agent for anything that writes, and an in-harness subagent for anything that only reads.

### subagent_type → template

| pstack `subagent_type` | Scion template |
|---|---|
| `poteto-agent` (code delegates, owners, stackers, babysitters, ad-hoc helpers) | `pstack-agent` |
| `generalPurpose` with `readonly: true` (reviewers, judges, explainers, investigators, verifiers) | `pstack-reviewer` |
| `generalPurpose` that writes (arena candidates, swarm workers that produce artifacts) | `pstack-agent` |
| `Comment Sicko` | `pstack-comment-sicko` |
| sub-coordinator | `pstack-lead`, with a track brief |

### model slug → harness-config + model

pstack names a model per role (`grok-4.6-fast-xhigh`, `claude-fable-5-1-thinking-max`, and so on).
On Scion a role maps to a **harness-config** (which vendor's agent CLI runs) plus an optional
**model** (alias `small|medium|large|extra-large` or an explicit ID). Resolve roles from
`pstack-models.yaml` (section 3). Never guess a harness-config name. The list of valid names comes from
`scion harness-config list`.

"Different model family" means a **different harness-config vendor** (claude, codex, gemini,
grok-build, ...), not a different size within one vendor.

### Spawn defaults (replaces pstack's "Defaults for every Task call")

- **Name.** Name every agent `<lead-slug>-<role>-<unit>`, for example `ps-auth-rev-codex-1`. Names must be unique among live agents. A new task gets a fresh name with a numeric suffix. Never re-task an old agent.
- **Background is implicit.** Every Scion agent runs in the background. pstack's `run_in_background: true` needs no action.
- **Readonly is a brief clause, not a flag.** Scion has no readonly switch. For a `pstack-reviewer`, put `FORBIDDEN: no commits, no pushes, no file edits outside /tmp and your own inbox file` in the brief. The template repeats the rule.
- **File pointers, not inlined context.** Workers run in their own clone, so a path in *your* clone means nothing to them. Point at one of these: pushed branches and SHAs, PR URLs, or files in the **pstack store** (section 4).
- **The brief is a file, the task argument is a pointer.** Write the full brief to `<store>/<program>/briefs/<agent-name>.md`. The `scion start` task argument is one short paragraph: role, the brief path, and the REPORT line. Never inline a diff or a long brief into the task argument. A 31 KB inline task crashed 5 of 5 agents in the port trial, while pointer tasks on the same harness survived.
- **The brief carries the report channel.** End every brief with this: "When done, write your REPORT block to `<store>/<program>/inbox/<your-agent-name>.md`, send it to `@<lead-agent-name>` with `scion message`, then signal task completion." The inbox file is the primary artifact, and the message is the wake-up. Messages have been lost in practice.

### Completion (replaces the Task completion notification)

- A Scion worker's completion arrives in three ways: a state-change notification, the worker's REPORT message, and its inbox file. Treat either the REPORT message or a `COMPLETED` notification as the wake-up, then read the inbox file. If there is no inbox file and no message, recover the report once with `scion look <name> --full --plain` before you call the worker failed.
- While you wait, run `sciontool status blocked "<what you are waiting on>"` and end your turn. Do not poll, sleep, or `scion look` in a loop.
- A worker that goes silent does not get resumed as a probe (pstack's orchestrate rule still holds). Probe read-only instead: `scion list`, its pushed branch, its inbox file, its ledger row, `scion look <name>` once.
- A worker that crashes at start leaves no trace: `scion logs` may return 403, and `scion look` fails once the container is gone. Retry once with a pointer-only task. On a second crash, treat that harness-config as unavailable (section 3) and move on.

### Getting the result back

A worker's product lives on a pushed branch or in the pstack store, never only in its container.
Review a code delegate's diff with `git fetch origin <branch> && git diff <base>...origin/<branch>`.
"You own every subagent's work" still applies. Read the diff yourself.

## 2. Other primitives

| pstack / Cursor | Scion |
|---|---|
| `AskQuestion` (structured multi-choice) | `sciontool status ask_user "<question>"`, then `scion message` the human with numbered options, your recommendation, and the default you will take if there is no answer. Poteto-mode's rule still governs *whether* to ask. |
| `/loop`, "arm a wake chain", "cloud-sleeper", "watcher subagent that wakes you" | For an agent event: `sciontool status blocked` and wait for the notification. For an external event (CI, a merge, a ref advancing) you can watch from inside your container (for example `watch-pr`), run the watcher as a background shell command in your own harness, which wakes you when it exits. Always back it with a `scion schedule create` self-callback at the heartbeat interval, then `sciontool status blocked`. See the scion-scheduler skill. Unlike `/loop`, a recurring schedule outlives your session. Record its ID in the program's `status.md` and `scion schedule delete` it on stand-down and at program close. |
| `environment: "cloud"` / `"local"` | Not applicable. Every agent is a container in its own clone. "Needs this machine" becomes "needs a template service, mount, or secret". Flag it as a gate if the template does not have one. |
| `cloud_base_branch` | Put the base branch in the brief. The worker runs `git fetch origin <branch> && git checkout -B <work-branch> origin/<branch>`. |
| "the Cursor dashboard", "cloud agent status" | `scion list`, `scion look <name>` |
| "After a Cursor restart" | After the lead is resumed or replaced. Workers are separate containers and survive it. Reattach by agent name, branch, and PR. |
| `agent-transcripts/` (your own chat history) | No shared transcript store exists. Use these, in order. (0) Your own harness's local session log, if it has one you can read (for example Claude Code's `~/.claude/projects/*/*.jsonl`); it only covers your own container. (1) The trail file you wrote (show-me-your-work `decisions.tsv`). (2) `scion conversation` history for messages. (3) `scion logs <agent>` and `scion look <agent>` for another agent's output. State in your reply which source you used. |
| `mcps/` directory, "available MCPs" | The MCP servers your harness lists. Template `mcp_servers` adds more. |
| Cursor built-in `create-skill` | The authoring-a-skill playbook plus the agentskills.io format: `SKILL.md` with `name` and `description` frontmatter. |
| Cursor built-in `/babysit` | Not present. The babysit playbook is the only babysit. |
| `cursor-team-kit` `deslop` (`/deslop`) | The `deslop` skill, installed verbatim from cursor-team-kit. Read it as a file (§0) and run it over the diff against the base branch. |
| `cursor-team-kit` `control-ui` / `control-cli` | The `control-ui` and `control-cli` skills, installed verbatim from cursor-team-kit. They build their harness inside your container: Playwright or CDP for UIs, tmux or a PTY script for CLIs. If the image lacks a browser or tmux and you cannot install one, or the surface needs something the container cannot reach, the verdict is `verifier-blocked`, not a pass. Screenshots and traces go to the pstack store or a pushed branch, not `/tmp` (see §1, Getting the result back). |
| `~/.cursor/rules/pstack-models.mdc` | `pstack-models.yaml` in the pstack store (section 3) |
| `.cursor/skills/<name>/` (project-local skill output) | `.scion/skills/<name>/` in the repo. Propose publishing it once it is stable. |
| `gt` (Graphite) | Optional. Use it if it is installed and the program's standing orders name a stacker. Otherwise use plain git plus `gh`. The pstack stack-safety rules stay the same. |

## 3. pstack-models.yaml

pstack's per-role model table, restated as harness-configs. `setup-pstack` writes it. Every
pstack skill that says "your configured X model" reads it. If the file is absent, the defaults
below apply. Listed is not the same as runnable. A harness-config can be listed and still fail at start (auth, missing image, crash). `setup-pstack` preflights every entry and records the result. When a harness-config is unlisted or known not to start, pick the nearest runnable one from another vendor for panel roles, or the same vendor for single roles. Note the substitution in your reply.

**Degraded diversity.** When a panel collapses to fewer vendors than it lists (in the worst case, one), still run it at the listed fan-out, varying model size where you can. Label the reviewers by the vendor that actually ran. State in the verdict, above the findings, that the panel was N-vendor, so agreement is weaker evidence. Prefer an independent non-model lever, such as a test corpus, a mutation run, or a benchmark, to make up for the lost diversity.

```yaml
# pstack-models.yaml. One key per role. Delete a key to fall back to the default.
# harness: a scion harness-config name. model: alias (small|medium|large|extra-large) or explicit ID.
# "inherit" means run the role on the caller's own harness and model (omit --harness-config/--model).
budget: unlimited
roles:
  code:            {harness: grok-build, model: extra-large}   # feature, refactoring, bug-fix, perf, hillclimb delegates
  hardest:         {harness: claude, model: extra-large}       # cross-cutting design, gnarly concurrency
  judgment:        {harness: claude, model: extra-large}       # prose, judgment, synthesizers, explainers
  how-explorer:    inherit
  why-investigator: inherit
  how-explainer:   judgment      # a role name as value = alias to that role
  why-synthesizer: judgment
  reflect-judgment: judgment
  reflect-tooling: {harness: codex, model: extra-large}
  swarm-worker:    {harness: grok-build, model: extra-large}
panels:            # one agent per entry; list length sets the fan-out
  interrogate: [claude, codex, gemini, grok-build]
  architect:   [claude, codex, gemini, grok-build]
  arena:       [claude, codex, gemini, grok-build]
  cross-judge: [claude, codex, gemini, grok-build]   # pick one whose vendor differs from the caller's
```

A missing role falls back to `judgment` (prose, synthesis, explanation) or `code` (anything that writes code). `budget` is a record of what `setup-pstack` applied; skills do not read it.

Panel entries are harness-config names and run at `model: extra-large` unless the entry is written
as `{harness: <h>, model: <m>}`.

## 4. The pstack store

pstack's orchestrate playbook and show-me-your-work keep state in "the current agent's store".
On Scion that store must be readable by every agent on the program, so it lives on a
**project shared directory**, not in your clone.

- Resolve the root once at task start. First, if `$PSTACK_STORE` is set, use it. Second, use a mounted shared dir with `pstack/` appended: `ls -d /scion-volumes/*/` (or `.scion-volumes/*/`), where a dir named `scratchpad` wins. Check the mount itself. `scion shared-dir list` can report none while a volume is mounted and writable. Otherwise there is no shared store, so write a gate asking the human to create one (`scion shared-dir create <name>`). Until then, keep the store in your clone and inline everything into briefs.
- Layout: `<root>/pstack-models.yaml`, and `<root>/<program-slug>/` for each program (ad-hoc runs outside a program use `adhoc-<yyyymmdd>-<topic>`) (orchestrate's `preferences.md`, `units.tsv`, `ledger.tsv`, `inbox/`, `gates.md`, `decisions.tsv`, `status.md`, and `briefs/`; `goal.md` replaces Cursor's `/goal`; pause-safely resume notes go in `resume.md`; plan documents go in `docs/`). Program files never sit at the store root, because two programs would collide there.
- The store follows orchestrate's one-writer rule: every file has exactly one writer. Workers write their own report files under `inbox/`. Only the lead writes the tables.
- Keep the store out of commits and out of cleanup.
- Locks: `orch.ts` detects a stale lock by PID, and a PID is only meaningful inside one container. A lock held by another container can look dead or alive. Only the lead writes the tables, so contention should not happen. If a lock is stale, recover with `--force`.

## 5. Human surface

- The human talks to the lead through Scion messages, and your terminal output is not visible to them. Every pstack "Reply" is sent as a `scion message` to the conversation the request came from. Messages to humans cap at 2000 characters. Put the long form in the store and send a pointer.
- pstack's slash commands do not exist. When the human names a skill ("interrogate this", "arena it", "/how does X work"), route to that skill as if it had been invoked. Treat poteto-mode as always on for the lead, and apply its "Casual turn or user opts out → don't" rule.
- Before ending any turn, signal state: `task_completed` when the request is done, `blocked` while waiting on agents or schedules, and `ask_user` before a question.
