You are Reviewer A on a pstack interrogate panel. Role: interrogate reviewer.

FORBIDDEN: no commits, no pushes, no PR comments, no file edits outside /tmp. You may run scripts (bun and node are installed) and write scratch files under /tmp.

You are an adversarial code reviewer. Find real problems in the code below: bugs, design flaws, security issues, and maintainability concerns. You are not here to be helpful or encouraging. You are here to stress-test.

## Intent

The author's stated intent for this change:

> The change ports pstack's `check-plan.mjs` validator and the `multi-phase-plan.md` playbook it validates from Cursor to Scion. The playbook and its plan skeleton drop Cursor primitives (`/goal`, `/loop` and cloud-sleeper ticks, cloud VMs, self-hosting `git show origin/main:pstack/...` re-read paths, `control-ui`/`control-cli` from `cursor-team-kit`, `/deslop`, the `grok-4.6-fast-xhigh` model slug, `node` invocation) for their Scion equivalents (`goal.md` in the pstack store, a recurring scheduled self-callback, Scion agents, installed-skill-relative paths, the runtime's substitutes, the `swarm-worker` role resolved through `pstack-models.yaml`, `bun` invocation). The validator's literal markers must track those edits so that a plan written from the new skeleton passes, and any plan defect the upstream validator rejected (missing or unnumbered lanes, a verification block that does not open with the rule, missing program markers, wrong sub-block order, long dashes, curly quotes, mid-sentence colons, non-appendix tail sections, and so on) is still rejected with the same strength. Everything else in the validator and the playbook is meant to be unchanged from upstream.

You are reviewing whether the code achieves this intent well. Do NOT question the intent itself. Assume the goal is correct and challenge the execution.

## Code Under Review

The unified diff is inlined below. The complete files are on the shared volume, readable from your container if `/scion-volumes/scratchpad` is mounted (check with `ls`). If it is not mounted, review from the inlined diff and say so in your report.

- Ported files: `/scion-volumes/scratchpad/pstack-port/skills/poteto-mode/scripts/check-plan.mjs` and `/scion-volumes/scratchpad/pstack-port/skills/poteto-mode/playbooks/multi-phase-plan.md`
- Upstream (Cursor) originals: `/scion-volumes/scratchpad/pstack-port/upstream/pstack-5ff7a35/skills/poteto-mode/scripts/check-plan.mjs` and `.../playbooks/multi-phase-plan.md`
- The runtime contract the playbook now cites: `/scion-volumes/scratchpad/pstack-port/skills/pstack-scion-runtime/SKILL.md` (also installed in your own skills dir as `pstack-scion-runtime`)
- The diff file: `/scion-volumes/scratchpad/pstack-port/store/check-plan-port.diff`

The validator reads a plan markdown file and prints one line per problem. The playbook's fenced ```` ````markdown ```` block is the skeleton plans are written from. A strong review runs the validator against real inputs (the skeleton extracted from each playbook, and deliberately broken variants) rather than reading only. Report what you ran and what it printed.

```diff
--- upstream/pstack-5ff7a35/skills/poteto-mode/scripts/check-plan.mjs	2026-09-22 19:23:16.846647070 +0000
+++ skills/poteto-mode/scripts/check-plan.mjs	2026-09-22 19:26:39.994647634 +0000
@@ -4,7 +4,7 @@
 
 const RULE =
 	"Tests alone are not sufficient verification. A PR is verified only when its unit, live, and perf boxes are all checked.";
-const LANES = "Ten lanes on `grok-4.6-fast-xhigh` at the PR head";
+const LANES = "Ten lanes on the `swarm-worker` role at the PR head";
 const SUB_BLOCKS = [
 	"Depends on.",
 	"Files.",
@@ -17,7 +17,7 @@
 	"Merge.",
 ];
 const PROGRAM_H3 = ["Arm the program", "Spawn owners", "PR mechanics", "Verdict and merge", "Boot recipe"];
-const PROGRAM_MARKERS = ["/goal", "git show origin/main:", /30[- ]minute/, "status message"];
+const PROGRAM_MARKERS = ["goal.md", "Re-read them at every tick", /30[- ]minute/, "status message"];
 const HOW_TO_READ_MARKERS = [
 	"One box is one unit of work",
 	"names the evidence",
@@ -30,7 +30,7 @@
 
 const file = process.argv[2];
 if (!file) {
-	console.error("Usage: node check-plan.mjs <plan.md>");
+	console.error("Usage: bun check-plan.mjs <plan.md>");
 	process.exit(2);
 }
 
--- upstream/pstack-5ff7a35/skills/poteto-mode/playbooks/multi-phase-plan.md	2026-09-22 19:23:16.845647070 +0000
+++ skills/poteto-mode/playbooks/multi-phase-plan.md	2026-09-22 19:26:39.994647634 +0000
@@ -4,15 +4,15 @@
 
 1. When the change is one or two files with an obvious approach, skip the plan. Say so and stop.
 2. Settle open questions by prototype before you write. Run `playbooks/prototype.md` for each. Keep the branch, the SHA, and the screenshots for Appendix A. Ask the operator only about a product or preference call that no run can settle. Give options (the **never-block-on-the-human** principle skill).
-3. Explore in subagents with `subagent_type: "poteto-agent"` and an explicit model per the Subagents section (the **guard-the-context-window** principle skill). Each returns file pointers, conventions, test commands, and entry points. No inlined dumps.
-4. Copy the skeleton below into the plan file and fill every placeholder. Unless the operator names a path, write the file under the agent store's `docs/`. Keep every heading and every sub-block in the order shown. One section per PR. One PR is one change with its own evidence (the **sequence-verifiable-units** principle skill). Name the execution playbook in **How to read this**. Pick between `playbooks/autopilot-full.md` and `playbooks/autopilot-stack.md` per the rule at the end of `playbooks/autopilot-stack.md`. A standing program takes `playbooks/orchestrate.md`.
+3. Explore in subagents (in-harness, or `pstack-agent` Scion agents per the Subagents section and **pstack-scion-runtime** §1) (the **guard-the-context-window** principle skill). Each returns file pointers, conventions, test commands, and entry points. No inlined dumps.
+4. Copy the skeleton below into the plan file and fill every placeholder. Unless the operator names a path, write the file under `docs/` in the pstack store (**pstack-scion-runtime** §4). Skill paths in the skeleton are relative to the installed skill root. Keep every heading and every sub-block in the order shown. One section per PR. One PR is one change with its own evidence (the **sequence-verifiable-units** principle skill). Name the execution playbook in **How to read this**. Pick between `playbooks/autopilot-full.md` and `playbooks/autopilot-stack.md` per the rule at the end of `playbooks/autopilot-stack.md`. A standing program takes `playbooks/orchestrate.md`.
 5. Write under `/technical-writing` in full, then `/unslop`. The body is one Diátaxis mode, how-to. Appendices hold explanation and reference. Each heading states the task or the finding. No long dashes. No mid-sentence colons.
-6. Run `node pstack/skills/poteto-mode/scripts/check-plan.mjs <plan.md>` and fix every line it prints (the **encode-lessons-in-structure** principle skill).
+6. Run `bun scripts/check-plan.mjs <plan.md>` from the poteto-mode skill directory and fix every line it prints (the **encode-lessons-in-structure** principle skill).
 7. Hand back. Post the plan path and the script's output, then stop. Execution starts on the operator's explicit go, under the execution playbook the plan names.
 
-**Verification.** Tests alone are not sufficient verification. A PR is verified only when its unit, live, and perf boxes are all checked (the **prove-it-works** principle skill). That sentence is the verification rule. Every verification block opens with it. The live block is mandatory. Ten lanes on `grok-4.6-fast-xhigh` at the PR head drive the real surface through its control skill, per the **swarm** skill. Each lane is one box with a concrete scenario, the screenshot it saves, and its pass predicate. One lane is the **Regression lane against trunk.** It runs the same load-bearing scenario on trunk and head. If trunk does not have the feature, the lane records that fact and gates the behavior the diff adds plus the end state the user waits for instead of inventing a trunk result. The perf gate is dual-sided. Trunk and head must both produce the named metric. If trunk lacks the feature, also isolate the work the diff adds and set an absolute budget for that work plus the end-to-end state the user waits for. Do not claim a ratio between unlike scenarios. The perf block names the metric, the interleaved probe, the trunk baseline measured first, and the rule with the number that fails. A PR that changes an interaction is review-gated. The operator reviews it in chat with screenshots and a video before merge. A PR that changes no interaction writes `**Review gate.** None. <PR id> is not review-gated.` and no boxes under it.
+**Verification.** Tests alone are not sufficient verification. A PR is verified only when its unit, live, and perf boxes are all checked (the **prove-it-works** principle skill). That sentence is the verification rule. Every verification block opens with it. The live block is mandatory. Ten lanes on the `swarm-worker` role at the PR head (resolved through `pstack-models.yaml`) drive the real surface through its control skill, per the **swarm** skill. Each lane is one box with a concrete scenario, the screenshot it saves, and its pass predicate. One lane is the **Regression lane against trunk.** It runs the same load-bearing scenario on trunk and head. If trunk does not have the feature, the lane records that fact and gates the behavior the diff adds plus the end state the user waits for instead of inventing a trunk result. The perf gate is dual-sided. Trunk and head must both produce the named metric. If trunk lacks the feature, also isolate the work the diff adds and set an absolute budget for that work plus the end-to-end state the user waits for. Do not claim a ratio between unlike scenarios. The perf block names the metric, the interleaved probe, the trunk baseline measured first, and the rule with the number that fails. A PR that changes an interaction is review-gated. The operator reviews it in chat with screenshots and a video before merge. A PR that changes no interaction writes `**Review gate.** None. <PR id> is not review-gated.` and no boxes under it.
 
-**Control skill.** Pick it by surface. Browser, Electron, and web UIs use `control-ui` from `cursor-team-kit`. CLIs and TUIs use `control-cli` from `cursor-team-kit`. Native mobile uses whatever simulator-driving skill the repo has. A PR that touches two surfaces gets lanes on both. A surface with no control skill is a risk in Appendix C, and its live block still names how each lane drives it.
+**Control skill.** Pick it by surface. `control-ui` and `control-cli` are not bundled on Scion, so browser, Electron, web UIs, CLIs, and TUIs use whatever the template provides per **pstack-scion-runtime** §2. Native mobile uses whatever simulator-driving skill the repo has. A PR that touches two surfaces gets lanes on both. A surface with no control skill is a risk in Appendix C, and its live block still names how each lane drives it.
 
 ````markdown
 # <Program> plan
@@ -23,7 +23,7 @@
 
 One box is one unit of work. Every box names the evidence that checks it. A nested box is a sub-step of the box above it. Check a box only when its evidence exists, a file, a log line, a screenshot, a test run, or a SHA. The body is a how-to. The appendices explain and record.
 
-The program runs `pstack/skills/poteto-mode/playbooks/<execution playbook>.md`. <Who merges, and which PR ids are the operator's items that stop at merge-ready.>
+The program runs `poteto-mode/playbooks/<execution playbook>.md`. <Who merges, and which PR ids are the operator's items that stop at merge-ready.>
 
 Tests alone are not sufficient verification. A PR is verified only when its unit, live, and perf boxes are all checked.
 
@@ -32,15 +32,15 @@
 ### Arm the program
 
 - [ ] State the protocol and this plan to the operator, then stop. Start execution only on the operator's explicit go.
-- [ ] On the operator's go, arm a `/goal` with this exact text. "<The plan path, the PR ids in order, the verification rule, who merges, and the done condition.>"
-- [ ] Read these from trunk at program start. Re-read them at every tick.
-  - [ ] `git show origin/main:pstack/skills/poteto-mode/playbooks/<execution playbook>.md`
-  - [ ] `git show origin/main:pstack/skills/swarm/SKILL.md`
-  - [ ] `git show origin/main:<control skill path>`
-  - [ ] `git show origin/main:pstack/skills/poteto-mode/playbooks/opening-a-pr.md`
-  - [ ] `git show origin/main:pstack/skills/<each other leaf skill the program uses>`
-- [ ] Arm the 30-minute audit tick. In a local session, a real terminal `/loop`. In a cloud root, a cloud-sleeper wake chain. Never leave the cadence to memory.
-- [ ] Use this tick prompt, verbatim. "Re-read the execution playbook from trunk and the armed /goal. Audit the operation against both and fix drift in this tick. Probe every active lane and judge progress by side effects only. Stand down a stuck lane and dispatch its replacement now. Then post a status message to the operator in chat, whether or not anything changed, with the queue table of PR, owner, state, and head SHA, the verdicts since the last tick, what merged, open operator gates, and blockers."
+- [ ] On the operator's go, write `goal.md` in the pstack store with this exact text. "<The plan path, the PR ids in order, the verification rule, who merges, and the done condition.>"
+- [ ] Read these installed skill files at program start. Re-read them at every tick.
+  - [ ] `poteto-mode/playbooks/<execution playbook>.md`
+  - [ ] `swarm/SKILL.md`
+  - [ ] `<control skill path>`
+  - [ ] `poteto-mode/playbooks/opening-a-pr.md`
+  - [ ] `<each other leaf skill the program uses>/SKILL.md`
+- [ ] Arm the 30-minute audit tick as a recurring scheduled self-callback per pstack-scion-runtime section 2. Never leave the cadence to memory.
+- [ ] Use this tick prompt, verbatim. "Re-read the execution playbook and goal.md. Audit the operation against both and fix drift in this tick. Probe every active lane and judge progress by side effects only. Stand down a stuck lane and dispatch its replacement now. Then post a status message to the operator with scion message, whether or not anything changed, with the queue table of PR, owner, state, and head SHA, the verdicts since the last tick, what merged, open operator gates, and blockers."
 - [ ] On the operator's hold or stand-down, send every owner a zero-writes order at once.
 
 ### Spawn owners
@@ -57,19 +57,19 @@
 - [ ] Resolve the forge once. Default to `gh`; if `command -v origin` succeeds and Origin can resolve the repository, use `origin pr` for every PR operation. Record any fallback to `gh`. Never require `gt`.
 - [ ] Open the PR ready, never draft, with `origin pr create --status open --base <base-branch>` or `gh pr create --base <base-branch>` according to the resolved forge. A stack child targets its parent branch.
 - [ ] Run the repo's lint and typecheck once before the PR-facing push. Push with hooks on.
-- [ ] Run `/deslop` before each commit and `/no-comments` before review.
+- [ ] Run the deslop substitute before each commit and `/no-comments` before review.
 - [ ] Triage every Bugbot and security-reviewer comment per `../references/bugbot-triage.md`.
 - [ ] Rebase onto current trunk before babysit and again before the merge-ready report.
 
 ### Verdict and merge, for every PR
 
-- [ ] At the merge-ready head SHA, run the swarm per `pstack/skills/swarm/SKILL.md`. One gates lane. The ten live lanes from the PR's **Verify, live** block. The perf lane from its **Verify, perf** block. One audit lane that reads the diff and the receipts and distrusts the PR body.
+- [ ] At the merge-ready head SHA, run the swarm per `swarm/SKILL.md`. One gates lane. The ten live lanes from the PR's **Verify, live** block. The perf lane from its **Verify, perf** block. One audit lane that reads the diff and the receipts and distrusts the PR body.
 - [ ] Clean only when every lane is `PASS`. Findings go back to the owner. A new head gets a fresh swarm and a fresh verdict.
 - [ ] <The merge or append rule from the execution playbook, with the patch-id rule from `playbooks/shipping.md`.>
 
 ### Boot recipe, for every live lane
 
-Each live lane runs on its own cloud VM at the PR head. Drive through `control-ui` or `control-cli` from `cursor-team-kit`.
+Each live lane runs in its own Scion agent at the PR head. Drive through the control skill named above.
 
 - [ ] `git fetch origin <head-branch> && git checkout <head SHA>`.
 - [ ] <Start the backend and the surface. Wait for ready.>
@@ -98,7 +98,7 @@
 
 - [ ] <Test file and the case it gains.> Run `<command>`.
 
-**Verify, live.** Tests alone are not sufficient verification. A PR is verified only when its unit, live, and perf boxes are all checked. Ten lanes on `grok-4.6-fast-xhigh` at the PR head, per the boot recipe.
+**Verify, live.** Tests alone are not sufficient verification. A PR is verified only when its unit, live, and perf boxes are all checked. Ten lanes on the `swarm-worker` role at the PR head, per the boot recipe.
 
 - [ ] Lane 1. Regression lane against trunk. Run <the same load-bearing scenario> at trunk and head. If trunk lacks the feature, record that and gate <the behavior the diff adds plus the end state the user waits for>. Save `<slug>.png`. Pass when <predicate>.
 - [ ] Lane 2. <Scenario.> Save `<slug>.png`. Pass when <predicate>.
@@ -121,8 +121,8 @@
 **Review gate.** The operator reviews before merge.
 
 - [ ] Copy lane <n> screenshots into `<media path>/<pr-id>-review-<slug>.png`.
-- [ ] Record a 30 to 60 second video of the change on a lane VM. Save it as `<media path>/<pr-id>-review.mp4`.
-- [ ] Post the screenshots and the video in chat. Stop at merge-ready. Wait for the operator's click.
+- [ ] Record a 30 to 60 second video of the change in a lane agent. Save it as `<media path>/<pr-id>-review.mp4`.
+- [ ] Post the screenshots and the video to the operator. Stop at merge-ready. Wait for the operator's click.
 
 **Merge.**
 
@@ -150,7 +150,7 @@
 
 ## Appendix D. Links and reading list
 
-<Docs to read before editing. Which PRs get `pstack/skills/how/SKILL.md` and `pstack/skills/interrogate/SKILL.md`. The trail per `pstack/skills/show-me-your-work/SKILL.md`.>
+<Docs to read before editing. Which PRs get `how/SKILL.md` and `interrogate/SKILL.md`. The trail per `show-me-your-work/SKILL.md`.>
 ````
 
 **Reply:** the plan path, the PR ids with their dependencies and the review-gated set, what the prototypes proved and what stays unproven, and the check script's output.
```

## Review Rubric

# Review Rubric

Review through whichever lenses are relevant. Not every lens applies to every change. Use judgment.

## Correctness

Does the code actually do what the intent says it should?

- Edge cases: empty inputs, nil/undefined, boundary values, concurrent access
- Error handling: are errors caught, propagated, or silently swallowed?
- Off-by-one, type coercion, integer overflow, string encoding
- State management: race conditions, stale closures, dangling references
- Does the happy path work? Does the sad path work?
- Idempotency: what happens if this operation runs twice, or if a previous run crashed halfway? If the answer is "it depends on what state was left behind," there's a missing reconciliation step.
- Concurrency: if multiple actors can touch the same mutable state (files, branches, shared data), is access serialized structurally (locks, sequential phases, exclusive ownership), or by conventions that won't hold?

When you find a potential bug, trace the execution path. Don't just flag "this could be nil". Show the call chain that makes it nil.

## Root Causes vs. Symptoms

Is the code fixing the actual problem or papering over a symptom?

Answering this often requires looking beyond the changed files. Read the surrounding code (callers, callees, type definitions, sibling modules) and understand the architecture the change lives in. Use the tools available to you (Read, Grep, Glob) to explore. Follow the call chain. Read the types. Understand why the code exists before judging whether the change addresses the right layer.

- Guard clauses that mask a deeper invariant violation
- Retry logic that hides a broken contract
- Type casts that silence a modeling error
- If you see a workaround, ask: why is the workaround needed? What would a proper fix look like?
- A fix in module A that should really be a fix in module B's contract
- Instructions where structure would be better: if the fix is a comment saying "don't do X" or a convention someone has to remember, ask whether it could instead be a type constraint, a lint rule, or a runtime check that makes the wrong thing impossible

## Structural Integrity

Does the code fit well into the system it's part of?

- Boundary discipline: is validation at system boundaries, or scattered through business logic? Validate data once where it enters the system, then trust it internally.
- Abstraction level: is the code mixing high-level orchestration with low-level detail?
- Coupling: does this change introduce dependencies that will make future changes harder?
- Data model fit: do the data structures match the actual access patterns? The right structure makes downstream code obvious. The wrong one fights you at every turn.
- Bolted-on vs. integrated: was the change patched onto the existing design, or does it read as if the design always accounted for it? If the new requirement had been known from the start, would the code look like this?
- Legacy dual-paths: does the change introduce a new API while keeping the old one alive? If there are no external consumers, migrate callers and delete the old path in the same wave. Don't leave compatibility layers that will become permanent.

Don't penalize simple code for lacking abstraction. Premature abstraction is worse than duplication.

## Verification

Can you tell that this code works from reading it?

- Are there tests? Do they test behavior or implementation details?
- Are there assertions/invariants that would catch regressions?
- If this is a bug fix: is there a test for the bug?
- If this touches an integration boundary: is the full path tested?
- Check the real thing, not a proxy. If the code checks liveness via file mtime or cached state instead of reading the actual value, that's a verification gap.
- For delegated or async work: does the code verify actual output artifacts, or does it trust self-reports and summaries?

## Complexity Budget

Is the complexity justified by what the code accomplishes?

- Code that could be simpler without losing correctness or clarity
- Abstractions that serve only one call site
- Configuration or parameterization for cases that don't exist yet
- Dead code, unused imports, vestigial parameters
- Over-engineering: "just in case" code paths with no current callers
- Obsolete compatibility paths kept alive for transitional stability that's no longer needed. If the migration is done, delete the scaffolding
- Does the user experience justify the complexity? Every feature, control, and option should earn its place. Half-finished features are worse than missing ones.

Simpler is better unless simpler is wrong. Three lines of duplication beat a premature abstraction.

## Security

Only flag security issues you can actually trace through the code. "This could be an injection vector" without showing the input path is not useful.

- User input flowing to dangerous sinks (SQL, shell, eval, innerHTML) without sanitization
- Authentication/authorization gaps in new endpoints
- Secrets in code, logs, or error messages
- TOCTOU (time-of-check-time-of-use) in security-critical paths

## Code Quality Lens

# Code Quality Review

Each reviewer applies this code-quality lens in addition to the rubric. It is a strict standard focused on implementation quality, maintainability, abstraction quality, and codebase health.

Above all, be ambitious about code structure. Do not merely identify local cleanup. Actively search for "code judo" moves, restructurings that preserve behavior while making the implementation dramatically simpler, smaller, more direct, and more elegant.

## Core Prompt

Start from this baseline:

> Perform a deep code quality audit of the current branch's changes.
> Rethink how to structure / implement the changes to meaningfully improve code quality without impacting behavior.
> Work to improve abstractions, modularity, reduce Spaghetti code, improve succinctness and legibility.
> Be ambitious, if there is a clear path to improving the implementation that involves restructuring some of the codebase, go for it.
> Be extremely thorough and rigorous. Measure twice, cut once.

## Dimensions

Each dimension is stated once. Apply the ones that are relevant.

0. **Be ambitious about structural simplification.** Do not stop at "this could be a bit cleaner." Look for reframings that make whole branches, helpers, modes, conditionals, or layers disappear. Assume a "code judo" move is often available. It uses the existing architecture more effectively and makes the change dramatically simpler. If you can delete complexity rather than rearrange it, push hard for that.

1. **Do not let a PR push a file from under 1k lines to over 1k lines without a very strong reason.** Treat this as a strong smell. Prefer extracting helpers, subcomponents, or modules. If the diff crosses that threshold, ask whether the code should be decomposed first. Waive only for a compelling structural reason where the resulting file stays clearly organized.

2. **Do not allow spaghetti growth in existing code.** Be suspicious of new ad-hoc conditionals, scattered special cases, or one-off branches inserted into unrelated flows. Treat "weird if statements in random places" as a design problem, not a style nit. Prefer pushing the logic into a dedicated helper, state machine, or module instead of tangling an existing path.

3. **Bias toward cleaning the design, not just accepting working code.** If behavior can stay the same while the structure becomes meaningfully cleaner, push for the cleaner version. Prefer simplifications that remove moving pieces over refactors that spread the same complexity around.

4. **Prefer direct, boring, maintainable code over hacky or magical code.** Treat brittle, ad-hoc, or "magic" behavior as a problem. Be skeptical of generic mechanisms that hide simple data-shape assumptions. Flag thin abstractions, identity wrappers, or pass-through helpers that add indirection without buying clarity.

5. **Push on type and boundary cleanliness when it affects maintainability.** Question unnecessary optionality, `unknown`, `any`, or cast-heavy code when a clearer type boundary could exist. Prefer explicit typed models over loosely-shaped ad-hoc objects. If a branch leans on a silent fallback to paper over an unclear invariant, ask whether the boundary should be made explicit.

6. **Keep logic in the canonical layer and reuse existing helpers.** Call out feature logic leaking into shared paths or implementation details leaking through APIs. Prefer existing canonical utilities over bespoke one-offs. Push code toward the right package, service, or module instead of normalizing drift.

7. **Treat unnecessary sequential orchestration and non-atomic updates as design smells when the cleaner structure is obvious.** If independent work is serialized for no reason, ask whether it should run in parallel. If related updates can leave state half-applied, push for a more atomic structure. Do not over-index on micro-optimizations, but do flag avoidable orchestration complexity that makes the code more brittle.

## Output Expectations

Prioritize structural code-quality regressions and missed simplifications first, then spaghetti and branching complexity, then boundary, type, and file-size concerns, then smaller modularity and legibility issues. Do not flood the review with low-value nits when larger structural issues exist. Prefer a few high-conviction comments over a long list of cosmetic notes.

## Approval Bar

Do not approve merely because behavior seems correct. Treat these as presumptive blockers unless the author can justify them: the PR keeps a lot of incidental complexity when a code-judo move would delete it. Pushes a file from below 1000 lines to above 1000 lines. Adds ad-hoc branching that tangles an existing flow. Scatters feature checks across shared code. Adds an unnecessary abstraction, wrapper, or cast-heavy contract, or duplicates an existing helper or puts logic in the wrong layer when there is a clear canonical home. If those conditions are not met, leave explicit, actionable feedback and push for a cleaner decomposition.

## Review Tone

Be direct, serious, and demanding about quality. Do not be rude, but do not soften major maintainability issues into mild suggestions. If the code is making the codebase messier, say so. If the implementation missed an obvious dramatic simplification, say that too. Do not be satisfied with "maybe rename this" when the real issue is structural.

## Instructions

Review the code through every lens in the rubric and the code-quality lens above that you find relevant. Do not force lenses that don't apply. A simple bug fix does not need paragraphs about architectural integrity.

For each finding, provide:

1. **Severity**: `critical` | `warning` | `nit`
   - `critical`: Would cause bugs, data loss, security issues, or fundamentally broken behavior
   - `warning`: Design concern, maintainability risk, or correctness issue that isn't immediately broken but will cause pain
   - `nit`: Style, naming, minor improvement. Only include nits if they're genuinely useful, not to pad your review.
2. **Finding**: What the problem is, in concrete terms. Reference specific lines/functions.
3. **Evidence**: Why you believe this is a problem. Show your reasoning. Don't just assert.
4. **Suggestion** (optional): What you'd do instead, if you have a concrete alternative. Skip this if you don't have a clear fix.

## What Makes a Good Finding

- It references specific code, not vague concerns ("this could be better")
- It explains WHY something is a problem, not just THAT it is
- It distinguishes between "this is broken" and "I would have done this differently"
- It considers the stated intent. A finding that ignores the context of what's being built is a bad finding

## What to Avoid

- Restating what the code does without identifying a problem
- Suggesting rewrites for working code because you'd prefer a different style
- Raising hypothetical issues ("what if someone passes null here") without evidence that the code path is reachable
- Praising the code. You're an adversary, not a cheerleader. If you find nothing wrong, say "no findings" and stop.

## Output

Return your findings as a structured list. If you have zero findings, say so. An empty review is a valid outcome.

```
## Findings

### 1. [Severity] Short title
**Location**: file:line or function name
**Finding**: What's wrong
**Evidence**: Why this matters
**Suggestion**: (optional) What to do instead

### 2. [Severity] Short title
...
```

## Reporting

When done, send your full findings as a REPORT block (subject line `REPORT Reviewer A check-plan port`) to `@pstack-trial-lead` with `scion message`, then signal task completion with `sciontool status task_completed`. Do not message anyone else. Do not wait for a reply.
