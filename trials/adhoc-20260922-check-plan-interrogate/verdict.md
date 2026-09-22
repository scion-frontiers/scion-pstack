# Interrogate verdict. check-plan.mjs and multi-phase-plan.md port

Lead: pstack-trial-lead (claude, claude-fable-5-1). Date 2026-09-22.
Scope: `store/check-plan-port.diff` (138 lines, two files). Confirmed byte-identical to the diff between `upstream/pstack-5ff7a35/skills/poteto-mode/` and `skills/poteto-mode/` for those two files (measured with `diff`).

## Intent

> The change ports pstack's `check-plan.mjs` validator and the `multi-phase-plan.md` playbook it validates from Cursor to Scion. The playbook and its plan skeleton drop Cursor primitives (`/goal`, `/loop` and cloud-sleeper ticks, cloud VMs, self-hosting `git show origin/main:pstack/...` re-read paths, `control-ui`/`control-cli` from `cursor-team-kit`, `/deslop`, the `grok-4.6-fast-xhigh` model slug, `node` invocation) for their Scion equivalents (`goal.md` in the pstack store, a recurring scheduled self-callback, Scion agents, installed-skill-relative paths, the runtime's substitutes, the `swarm-worker` role resolved through `pstack-models.yaml`, `bun` invocation). The validator's literal markers must track those edits so that a plan written from the new skeleton passes, and any plan defect the upstream validator rejected is still rejected with the same strength. Everything else in the validator and the playbook is meant to be unchanged from upstream.

## Reviewers

- Reviewer A: `claude`, extra-large (`ptl-rev-a-claude-2`). 5 findings. Report recovered from `scion look --full` scrollback (`inbox/reviewer-A-claude-scrollback.txt`); its `scion message` to the lead never arrived.
- Reviewer B: `claude`, large (`ptl-rev-b-claude-large-1`). 5 findings. Report arrived as a Scion message (`inbox/reviewer-B-report.md`). Same vendor as A, so a second read, not a second family.
- Lead's own lever: `corpus.sh`. 25 defect mutations applied to both skeletons, each run through its own validator, outputs normalised and diffed. Results in `corpus.tsv`.
- Panel substitutions attempted and failed, all measured from `scion list` or `scion look`: grok-build (crashes at start, with and without `--model`), codex (refresh token already used), gemini (no auth method configured, interactive prompt), copilot (authorization error, and runs claude-opus anyway), opencode (PAT rejected, routes to Claude Sonnet via Copilot anyway), hermes (exit 2 at start), muse-code (image `scion-muse-code:latest` not found). The configured default panel `[claude, codex, gemini, grok-build]` is therefore claude-only in this project. This verdict has one model family behind it.

## Measured baseline

- Ported skeleton through ported validator: 0 problems. Upstream skeleton through upstream validator: 0 problems. Cross pairs fail only on the swapped markers (3 problems one way, 2 the other). `node` and `bun` both run the ported script with exit 0.
- Corpus: 22 of 25 mutations rejected identically by both validators (same message text modulo the swapped marker strings). `lanes-wrong-role` is a sed artifact (my swap applied twice). The two real divergences are below.

## Act On

1. **The `"Re-read them at every tick"` marker is a no-op that drops a check upstream had.** Raised by Reviewer A, Reviewer B, and the lead's corpus, three independent runs, same measurement. Upstream's `"git show origin/main:"` marker required the plan to list the files it re-reads. The replacement sentence already existed in the upstream skeleton, so the port did not add a marker, it removed one. Measured: deleting the five nested re-read boxes passes the ported validator (0 problems) and fails upstream (`no-reread-list` row). That contradicts the intent's "same strength". Fix, tested in `/tmp/cp/check-plan-fixed.mjs`: replace the string with a RegExp on the nested list, for example `/^ {2}- \[[ x]\] `swarm\/SKILL\.md`$/m`. With that one line the fixed validator matches upstream's exit code on every corpus row, accepts the clean ported skeleton, and rejects the deleted list. `PROGRAM_MARKERS` already accepts RegExp entries. Reviewer B's alternative is structural: require an indented box right after the box containing the re-read sentence. Either works; the RegExp is one line. While there, tighten the `goal.md` marker the same way. Reviewer B measured that reverting the arming box to Cursor's `arm a /goal` still passes, because the tick prompt also says `goal.md`. Matching `write \`goal.md\`` instead pins the arming step. Upstream's `/goal` had the identical double hit, so that half is a missed improvement, not a regression. Add the `no-reread-list` and `stalegoal` mutations as negative fixtures (`corpus.sh` is a starting point), since PORT-NOTES.md:37 records only the two happy-path runs. Optional: give RegExp markers a label so the failure line reads better than the regex source.

2. **Boot recipe still saves lane screenshots to container-local `/tmp`.** Reviewer A. `multi-phase-plan.md:77` says `Save every screenshot to /tmp/swarm-<pr-id>/worker-<n>/<slug>.png and return the paths with the report`. Line 72 was ported to "its own Scion agent", line 77 was not. The port's own `swarm/SKILL.md:25` says workers do not share `/tmp` and write to their own `inbox/` file in the pstack store. The review-gate copy step (line 123) then has no source once the lane agent exits. Fix: point line 77 at `<pstack store>/<program>/inbox/<pr-id>/worker-<n>/<slug>.png` (or a pushed branch) and make line 123 copy from there. No validator change needed; nothing checks the path.

## Consider

3. **The recurring self-callback has no lifecycle.** Reviewer A. Cursor's `/loop` died with the session. `scion schedule` recurring events persist until deleted (scion-scheduler skill, "Lifecycle management"). The skeleton arms the tick (line 42) but neither "On the operator's hold or stand-down" (line 44) nor "Close the program" deletes it. Grep over the ported playbooks and runtime finds no delete or cancel step for schedules (measured, 0 hits). Tradeoff: adding a box to Close the program is one line and costs nothing, but the same gap exists in autopilot-full and autopilot-stack, so the right fix may be one sentence in runtime §2 plus one box here. Not blocking this diff because the tick's failure mode is noise (a status message to a finished program), not data loss.

4. **"Skill paths in the skeleton are relative to the installed skill root" is ambiguous and partly false.** Lead. Step 4 adds that sentence. In the skeleton, `poteto-mode/playbooks/<execution playbook>.md` and `swarm/SKILL.md` are relative to the skills directory, `playbooks/shipping.md` is relative to the poteto-mode directory, and `../references/bugbot-triage.md` is relative to the playbooks directory. Two of those three conventions predate the port, but the new sentence claims one convention for all of them. Tradeoff: normalising every path to one convention touches lines upstream did not touch and widens the re-sync diff. Cheapest fix is to reword the sentence ("paths that start with a skill name are relative to the skills directory, per runtime §0").

5. **`goal.md` and `docs/` locations disagree with runtime §4.** Reviewer B. §4 puts `goal.md` under `<root>/<program-slug>/` and lists no `docs/`. The skeleton says "write `goal.md` in the pstack store" and step 4 says "under `docs/` in the pstack store", which both read as the root, so two concurrent programs would collide on `<root>/goal.md`. Tradeoff: fixing the playbook is two phrases; fixing §4 to list `docs/` is one line in the runtime. Do both, they are cheap, but neither blocks this diff.

## Noted

6. Shebang still says `#!/usr/bin/env node` while the usage string and playbook say `bun`. Reviewers A and B. Both runtimes execute it (measured). Reviewer B adds that step 6 ("from the poteto-mode skill directory") plus a plan that lives in the store means `<plan.md>` must be absolute, and the step does not say so.
7. "The deslop substitute" in PR mechanics names no pointer. Reviewer B. Runtime §2 defines it. Add "per pstack-scion-runtime section 2".
8. Line 42 writes "pstack-scion-runtime section 2" where the rest of the file writes "§2". Lead.
9. The `goal.md` marker is a substring check, so a plan that mentions `goal.md` only in the tick prompt still passes. Upstream's `/goal` had the identical weakness (measured, `no-goal` row: 0 problems on both). Not a port regression.
10. Leftovers outside this diff. Reviewer A and lead. `playbooks/refactoring.md:11` still names `grok-4.6-fast-xhigh`; `playbooks/bug-fix.md:8` still says "Drive a long or stubborn hunt with Cursor's `/loop` command". Out of scope for this diff, in scope for the port.

## Dismissed

- Leftover slash-command names (`/technical-writing`, `/unslop`, `/no-comments`) in the playbook. Reviewer B, part of its finding 5. Runtime §5 says a slash name routes to the skill of that name, and PORT-NOTES records the choice to leave them. Consistent with the port's contract, so not a defect.
- Nothing from Reviewer A is dismissed. Its finding 5 sits under Noted because it is correct and outside the diff.

## Agreement map

Two independent methods (Reviewer A's 17-variant run and the lead's 25-variant corpus) converged on the same single validator regression, with the same measurement (delete the nested re-read list, ported passes, upstream fails). That is the highest-signal item and it is also the only item that touches the stated intent. Everything else is playbook prose the validator does not check. Reviewer B added the `stalegoal` case (Cursor's `/goal` phrasing still passes) and the §4 layout mismatch, neither of which A or the lead raised. A and B disagree only on the fix shape for Act On 1 (regex versus structural). With one model family behind the panel, the absence of disagreement is weak evidence; the corpus is the independent check that does not depend on any model.

## Verdict

Not yet acceptable against the stated intent. One measured regression in the validator (Act On 1) with a one-line, tested fix; one Scion-correctness gap in the skeleton (Act On 2). Fix both, rerun `corpus.sh`, and the diff meets the intent as far as a single-vendor panel can tell.


## Principles applied

- **Build the Lever.** `corpus.sh` instead of reading the two validators side by side. It is the artifact that found the regression and the artifact that proves the fix.
- **Prove It Works.** Every claim above about accept or reject is a validator run, not a reading of the constants. Reviewer A's findings 2 to 5 were re-checked against the files before they were weighed.
- **Test Behavior, Not Implementation.** The corpus asserts on validator output for a mutated plan, not on the marker strings. A test that pinned `PROGRAM_MARKERS` would have passed this port.
- **Encode Lessons in Structure.** Act On 1 asks for the negative fixtures to be checked in next to the script, so the next marker edit cannot silently weaken it.

## Port friction

1. **The default interrogate panel is unrunnable here.** `scion harness-config list` shows 14 configs, and only `claude` can start a `pstack-reviewer` in this project. Seven attempts on six other vendors failed on auth, a missing image, or an immediate crash. `setup-pstack` and runtime §3 check names, not whether a config can start an agent. A preflight (`scion start` a trivial task per panel entry, once per project) belongs in setup-pstack, and interrogate needs a rule for "panel collapsed to one vendor" (I proceeded and labelled it; the skill is silent).
2. **A 31 KB brief in the `scion start` task argument crashed every harness.** Five of five agents with the inline brief died within a minute; two of two on the same harness with a one-paragraph pointer task lived (inferred cause, not proven, because the next item hides the evidence). Runtime §1 says "paste the text in only when it is small" with no number; interrogate step 1 says to "package the diff". Make the rule "brief goes in the store, task argument is a pointer", always.
3. **A crashed child is a black box.** `scion logs <child>` returns 403 for agents I started (LEARNINGS L40 again), and `scion look` fails once the container is gone. Nine crashes, zero stack traces.
4. **The REPORT channel is not reliable enough to be the completion event.** Reviewer A said "Report delivered to @pstack-trial-lead" and nothing arrived; Reviewer B's identical send did. I recovered A from `scion look --full --plain`. Reviewers should also write their report to `inbox/` in the store (the one-writer rule already permits it), and the lead should read the inbox file as the primary artifact.
5. **`scion shared-dir list` says "No shared directories configured" while `/scion-volumes/scratchpad` is mounted and writable.** Runtime §4's fallback would have raised a gate for a store that exists. `PSTACK_STORE` masked it this run.
6. **`scion template show` reveals nothing about mounts or skills**, so I could not tell in advance whether reviewers would see the shared volume. They did, but I had to add a "if unreadable, say so" clause to every brief.
7. **Small skill gaps.** Interrogate labels reviewers A to D by panel entry and says nothing about relabelling after a substitution. Poteto-mode's reply rules (no long dash, no mid-sentence colon) are easy to keep in a store file and hard to keep in a 2000-character message. The pstack-reviewer template has no `bun` guarantee; both reviewers happened to find it.
