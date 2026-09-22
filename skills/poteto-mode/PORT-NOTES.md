# poteto-mode port notes

Source: `upstream/pstack-5ff7a35/skills/poteto-mode/` (pstack v0.15.2). Mechanics defer to **pstack-scion-runtime**. Judgment, voice, and structure are unchanged.
Unchanged files: `references/bugbot-triage.md`, `playbooks/{investigation,prototype,refactoring,runtime-forensics,trace-forensics}.md`, all of `scripts/orch/`, `scripts/watch-pr/`, `scripts/bootstrap.ts`, `scripts/worktree-audit.sh`, `package.json`, `bun.lock`.

## SKILL.md

- Frontmatter. `name: Poteto Mode` became `poteto-mode` (kebab-case, matches the dir). Dropped Cursor-only keys. Their intent:
  - `disable-model-invocation: true`. Fire only on explicit `/poteto-mode`. On Scion the `pstack-lead` template makes poteto-mode always on, gated by the reminder rule below (runtime §5).
  - `mode: true`. A persistent chat mode. The lead template's system prompt carries that.
  - `icon: crown`, `color: yellow`. UI only. No Scion equivalent.
  - `reminder: New task? Playbook match or rigor needed -> apply /poteto-mode. Casual turn or user opts out -> don't.` Belongs in the `pstack-lead` system prompt. Runtime §5 already restates it.
- Added the "read **pstack-scion-runtime** first" line under the H1.
- Non-negotiables. `AskQuestion` became "ask the human (runtime §2)". `create-skill` became the Authoring a skill playbook. `deslop` and `control-ui`/`control-cli` point at the runtime §2 substitutes. The built-in babysit disclaimer became "the only babysit on Scion". `/loop until X` became "loop until X" (a trigger phrase, not a command).
- Subagents. `subagent_type: "poteto-agent"` became the `pstack-agent` template, with the tier chosen per runtime §1. The Task defaults became a pointer to runtime §1 spawn defaults. Model slugs became `pstack-models.yaml` roles: `code` (was `grok-4.6-fast-xhigh`), `judgment` (was `claude-fable-5-1-thinking-max` for prose), `hardest` (was the same Claude slug for the hardest changes). `inherit-parent`/`auto` became `inherit`. "A second opinion is a different model" became "a different model family (harness-config vendor)".
- Playbook index. The Orchestrate coordinator is `pstack-lead`. Session pickup sources are trail file, agent name, or branch (no cloud-agent URL). The Pause trigger "a Cursor restart" became "the lead being stopped or replaced".

## playbooks

- `orchestrate.md`. Coordinator is `pstack-lead`. Sub-coordinator is `pstack-lead` with a track brief (the "nesting depth 3 / full Task schema" note is gone). Workers are `pstack-agent`, verifiers `pstack-reviewer`. The cloud/local split is gone, and "needs this machine" became "needs a template service, mount, or secret, else a gate". Store is `<pstack store>/<project-slug>/` on the shared dir (runtime §4), not `orchestrate/<slug>/` in the agent store. `orch` runs as `bun <skill dir>/scripts/orch/orch.ts --store ...` or with `ORCH_STORE`. Completion event is the REPORT message. The Cursor dashboard became `scion list` and one `scion look`. "After a Cursor restart" became "after the lead is resumed or replaced". "Restacks run in cloud / laptop" became "in the stacker's agent". VM became container.
- `autonomous-run.md`. `/loop` wake points at runtime §2. The `AskQuestion` ban became "ask the human".
- `autopilot-full.md`, `autopilot-stack.md`. "Cursor cloud agent per PR" became a `pstack-agent` Scion agent. The deslop and control skills point at runtime §2. The local `/loop` vs cloud-sleeper tick became a recurring scheduled self-callback. `/goal` became `goal.md` in the pstack store. The "re-read from trunk with `git show origin/main:pstack/...`" step became a re-read of the installed playbook file, because the target repo does not contain pstack.
- `babysit.md`. The built-in babysit disclaimer is dropped. `watch-pr` runs through `bun`. `/loop` dynamic mode became the runtime §2 wake: the watcher as a background shell command whose exit wakes you, plus a scheduled heartbeat.
- `shipping.md`. The per-PR "Cursor cloud agent" verifier became a `pstack-reviewer` Scion agent. The control skill points at runtime §2. `watch-pr` runs through `bun`. `/loop` became the runtime §2 wake.
- `opening-a-pr.md`. Worktree: in-harness subagents inherit it, and Scion agents get a pushed branch. `Task` calls became "writers". `/deslop` became the substitute. "Cloud-agent PR tools default to draft" became "some PR tools".
- `multi-phase-plan.md`. The explore step uses the Subagents tiers. The plan goes to `docs/` in the pstack store. `check-plan.mjs` runs with `bun`. Lanes run on the `swarm-worker` role, not `grok-4.6-fast-xhigh`. The control-skill paragraph points at runtime §2. In the skeleton, `/goal` became `goal.md`, `git show origin/main:pstack/skills/X` became installed-skill-relative paths, the `/loop` or cloud-sleeper tick became a scheduled self-callback, "cloud VM" became "Scion agent", and "chat" became `scion message` / "the operator".
- `eval.md`. The transcript read under `agent-transcripts/` became `scion logs` / `scion look` on the candidates you spawned.
- `session-pickup.md`. The trail source is a trail file, Scion history (runtime §2 order), or a pushed branch.
- `pause-safely.md`. Cancelling "nested subagents" now applies to in-harness subagents only, and live Scion agent names go in the resume note. The resume note goes to the pstack store for every trigger, not `/tmp`, because `/tmp` dies with the container and a replacement lead cannot read it.
- `authoring-a-skill.md`. `create-skill` became the agentskills.io format plus `.scion/skills/<name>/`.
- `bug-fix.md`, `feature.md`, `perf-issue.md`, `hillclimb.md`. The per-playbook model with a `grok-4.6-fast-xhigh` default became the `code` role. Hillclimb's parallel worktrees became `pstack-agent` agents on their own branches.
- `visual-parity.md`. `` `/loop` per component `` became "Loop per component" (an iteration, not a wake).
- `worktree-cleanup.md`. Added a one-sentence low-relevance note at the top. `bash scripts/worktree-audit.sh`. Everything else is left as is (the `.cursor/worktrees` example, transcript checks, `~/Library/Application Support/Cursor`), since it only applies on a long-lived host checkout.

## scripts

- `check-plan.mjs`. The skeleton markers it enforces had to track the playbook edits. `LANES` now expects the `swarm-worker` role, and `PROGRAM_MARKERS` now expects `goal.md` and "Re-read them at every tick" instead of `/goal` and `git show origin/main:`. The usage string says `bun`. Checked: the upstream skeleton against the upstream script, and the ported skeleton against the ported script, give identical output (0 problems).
- `orch/orch.ts` needed no change. It already takes `--store <dir>` / `ORCH_STORE` and hardcodes no Cursor path.
- `watch-pr/` needed no change. `github.ts` matches the `cursor` bot login and `CURSOR_AUTOMATION_ID` to recognize Bugbot comments on GitHub. That is a GitHub-side fact, not a host primitive.
- Tests. `bun install --frozen-lockfile` worked (network available), `bun test orch watch-pr` gave 52 pass / 0 fail, and `tsc --strict` on watch-pr was clean. `node_modules/` was removed afterwards.

## Could not port cleanly / open questions

- `bootstrap.ts` runs `bun install` into `scripts/node_modules` on first use. That needs network and a writable skill dir. For a URI-delivered (possibly read-only or cached) skill it may fail. Should `build.sh` pre-install, or should the image carry `commander`?
- The `orch` stale-lock check uses `process.kill(pid, 0)`, which is PID-namespace-local. On a shared dir across containers, a lock left by a crashed process in another container can look alive (pid collision) or dead. The one-writer rule (only the lead writes) makes contention rare, and `--force` recovers. A hostname in the lock file would fix it upstream.
- The babysit/shipping wake uses a background shell watcher. It depends on the harness having background shell commands that wake the agent on exit. Runtime §2 only names `scion schedule` + `blocked` for external events. Should runtime §2 bless the background-command pattern for `watch-pr`?
- `goal.md` is a new store file not listed in runtime §4's layout. Add it there, or fold it into `preferences.md`.
- Slash-command mentions (`/no-comments`, `/technical-writing`, `/unslop`) are left as is. Runtime §5 treats them as skill names.
- Orchestrate "resume" (an idle agent restarted by a message) maps loosely to `scion message` to a live agent. "Never resume to probe" still holds, but Scion does not distinguish resume from message.
