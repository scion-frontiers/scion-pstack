# poteto-mode port notes

Source: `upstream/pstack-bf0c7cd/skills/poteto-mode/` (pstack v0.15.42). Mechanics defer to **pstack-scion-runtime**. Judgment, voice, and structure are unchanged.
Unchanged files: `references/bugbot-triage.md`, `playbooks/{investigation,prototype,runtime-forensics,trace-forensics}.md`, `scripts/watch-pr/*`, `scripts/bootstrap.ts`, `scripts/worktree-audit.sh`, `scripts/package.json`, `scripts/bun.lock`.

## SKILL.md

- Frontmatter: `name: Poteto Mode` became `poteto-mode` (kebab-case, matches the dir). Dropped Cursor-only keys (`disable-model-invocation`, `mode`, `icon`, `color`, `reminder`), whose persistent-mode and casual-turn rules live in `pstack-lead` and **pstack-scion-runtime** §5.
- Added the "read **pstack-scion-runtime** first" line under the H1.
- Non-negotiables: `AskQuestion` became "ask the human (runtime §2)". `create-skill` became the Authoring a skill playbook. `deslop`, `control-ui`, and `control-cli` from `cursor-team-kit` remain verbatim (installed on Scion). The built-in babysit disclaimer became "the only babysit on Scion". `/loop until X` became "loop until X".
- Subagents: `subagent_type: "poteto-agent"` became `pstack-agent`, tiered per runtime §1. Per-job reasoning effort and speed map via runtime §1. Model slugs (`claude-opus-5-5-xhigh`, `claude-fable-5-2-max`) became `pstack-models.yaml` roles (`code`, `judgment`, `hardest`). "A second opinion is a different model" became "a different model family (harness-config vendor)".
- Playbook index: Orchestrate coordinator is `pstack-lead`. Session pickup sources use trail file, `notes.md`, agent name, or branch. Pause trigger "a Cursor restart" became "the lead being stopped or replaced".

## playbooks

- `orchestrate.md`: Rebased onto upstream's 25-line `notes.md` contract (`scripts/orch/*` deleted upstream). Coordinator is `pstack-lead`, sub-coordinators are `pstack-lead`, workers/verifiers map via runtime §1 (`briefs/`, `inbox/`, `verdicts/`), and `notes.md` lives in `<store>/<project-slug>/notes.md` (runtime §4).
- `multi-phase-plan.md`: Rebased onto upstream's streamlined skeleton (`goal.md` dropped from `### Arm the program`, 1-hour audit tick, `status message`). Plan path uses `docs/` in the pstack store, lanes use `swarm-worker` (`pstack-reviewer`), `git show origin/main:pstack/skills/...` became installed-skill-relative paths, and `/loop 1h` became a 1-hour recurring scheduled self-callback recorded in `notes.md`.
- `autonomous-run.md`: `/loop` wake points at runtime §2; `AskQuestion` became "ask the human".
- `autopilot-full.md`: "Cursor cloud agent" became `pstack-agent` Scion agent; store points at runtime §4; `/loop 1h` became a 1-hour recurring scheduled self-callback recorded in `notes.md` plus `goal.md` in the store; `deslop`, `control-ui`/`control-cli`, and `ketchup` stay verbatim.
- `autopilot-stack.md`: Rebased onto upstream's 7-line delta over `autopilot-full.md`; "loop tick" became "scheduled audit tick (**pstack-scion-runtime** §2)".
- `babysit.md`: Built-in babysit disclaimer shortened; `watch-pr` runs via `bun scripts/watch-pr/watch-pr`; `/loop` dynamic mode became the runtime §2 background watcher + scheduled heartbeat.
- `shipping.md`: Per-PR "Cursor cloud agent" verifier became `pstack-reviewer` Scion agent recording verdicts in `verdicts/` (runtime §1); `watch-pr` runs via `bun` on the runtime §2 wake mechanism.
- `opening-a-pr.md`: Worktree paragraph notes in-harness subagents inherit it while Scion agents get a pushed branch, and `Task` calls became "writers". All other sections (`deslop`, STE titles/descriptions, forge, stacks, readiness, babysit) match upstream verbatim.
- `eval.md`: `agent-transcripts/` became `scion logs` / `scion look` on spawned candidates (runtime §2).
- `session-pickup.md`: Trail lookup uses store `notes.md`/trail file, Scion history (runtime §2), or pushed branch.
- `pause-safely.md`: Nested subagent cancel scoped to in-harness subagents while running Scion agent names go in `<store>/<slug>/resume.md` (runtime §4, avoiding `/tmp`).
- `authoring-a-skill.md`: `create-skill` became agentskills.io `SKILL.md` format + `.scion/skills/<name>/` (runtime §2).
- `bug-fix.md`, `feature.md`, `perf-issue.md`, `refactoring.md`, `hillclimb.md`: Per-playbook model defaults (`claude-opus-5-5-xhigh`) became the `code` role from `pstack-models.yaml` (runtime §3). `bug-fix.md` `/loop` became runtime §2 scheduled self-callback. `hillclimb.md` parallel worktrees became `pstack-agent` branches.
- `visual-parity.md`: `` `/loop` per component `` became "Loop per component (**pstack-scion-runtime** §2)".
- `worktree-cleanup.md`: Added one-sentence Scion relevance note and `bash scripts/worktree-audit.sh [-b <pr-base-ref>] [repo-path]`.

## scripts

- `check-plan.mjs`: Tracks the two ported skeleton changes (`swarm-worker` role in `LANES`; installed-skill re-read item `/^ {2}- \[[ x]\] \`swarm\/SKILL\.md\`$/m`, `"1-hour audit tick"`, and `"status message"` in `PROGRAM_MARKERS`).
- `check-plan.test.ts`: Merged upstream negative-marker suite with Scion negative tests for re-read item, audit tick, and status message (14 tests total).
