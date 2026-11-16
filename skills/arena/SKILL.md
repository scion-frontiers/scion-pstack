---
name: arena
description: "Spawn N parallel candidates at the same task, pick a base, graft the strongest parts of the losers into it. Use for /arena, 'arena this', 'throw it in the arena', or when one attempt at a non-trivial artifact would lock in the wrong shape."
---

# Arena

Open a todolist with one entry per phase (Frame, Fan out, Cross-judge, Pick, Graft, Verify) before launching anything.

## Phase A: Frame

Every candidate gets the same prompt, so the prompt is the contract.

1. State the artifact each candidate is producing.
2. Derive the rubric, 3-6 concrete gradeable criteria for what success looks like on *this* task. It is the picker's tool in Phase D. Candidates only see the task.
3. Pick the runners. Use `panels.arena` in `pstack-models.yaml`, resolving missing-file (`[inherit, inherit, inherit]`, flagging 1-family degraded diversity) and missing-key fallbacks per **pstack-scion-runtime** §3 so unpreflighted harnesses are never spawned. An `inherit` entry means the parent's own harness and model (omit `--harness-config` and `--model`). If a configured harness-config is unlisted or unavailable, substitute per **pstack-scion-runtime** §3 (a runnable entry from another resolved model family, noting N-family degraded diversity when fewer model families remain; fall back to distinct `harness-config` names only when model family is unknown). If dropped seats leave fewer than two runners, add runners on a remaining runnable model family (or `inherit` when none remain) until there are two, or one when the list has one entry, and say so. Spawn more runners when the arena covers multiple design directions. Use the same harness-config N times when the work is generation-bound rather than judgment-sensitive. Pick each runner's reasoning level per the Subagents section of the **poteto-mode** skill (**pstack-scion-runtime** §1).
4. Give each candidate its own output location (**pstack-scion-runtime** §1): runners run in isolated clones and do not share `/tmp`, so code goes on each candidate's own pushed branch (`arena-<slug>-c<n>`) and other artifacts go to `<store>/<program-slug>/arena-<slug>/candidate-<n>/` in the pstack store, per the **separate-before-serializing-shared-state** principle skill.

## Phase B: Fan out

Start all N runners at once as `pstack-agent` Scion agents (`--role baseline`) for code/branch implementations, or as `pstack-reviewer` Scion agents (`--role baseline`, read-only, writing solely to `<store>/<program-slug>/arena-<slug>/candidate-<n>/` with no pushed branch) when overridden by **architect** Phase B (**pstack-scion-runtime** §1; under broker concurrency caps, stagger waves per §1). Give each runner a brief containing the task, the pointer to the shared grounding (pushed branch or store path), its own output path, the base branch (or `<head-sha>` pin for read-only store runners), instructions to produce the artifact and a short rationale naming the alternatives it considered and what it rejected, and the `REPORT` channel.

If a candidate produces no output, proceed with N-1 and note the dropout.

## Phase C: Cross-judge

After all Phase B candidates complete, choose one entry from `panels.cross-judge` in `pstack-models.yaml`, resolving missing-file (`[inherit, inherit, inherit]`) and missing-key fallbacks per **pstack-scion-runtime** §3. Spawn one `pstack-reviewer` Scion agent (**pstack-scion-runtime** §1). The judge is never from the parent's resolved model family (**pstack-scion-runtime** §3; fall back to distinct `harness-config` names only when model family is unknown): try only runnable entries from another model family, in pool order (`inherit` shares the parent's model family, so it never judges). If no entry in `panels.cross-judge` from another model family runs, try any other runnable entry recorded in `pstack-models.yaml` from another model family (never spawn unpreflighted harnesses when `pstack-models.yaml` is missing or marked them failed). If none exists or runs (or a broker concurrency cap precludes a separate judge per **pstack-scion-runtime** §1), skip the judge, pick the base alone in Phase D, and say so (labeling the synthesis `single-judge`). If you cannot determine the parent's model family or harness, try runnable pool entries in pool order and say that the family check did not run. The judge sees the rubric and the candidates by branch or store-path label, scores each criterion, and recommends a base with rationale. It runs in parallel with your reading in Phase D. Don't spawn it while candidates are still writing.

## Phase D: Pick a base

Read every candidate end to end before picking. Score each against the rubric criterion by criterion, not on holistic feel, and compare with the cross-judge when Phase C ran one. Agreement on the base confirms the pick. Disagreement means one of you is biased or the rubric was ambiguous. Read both rationales before deciding.

Pick the base a future maintainer can extend most easily without breaking invariants. When two feel tied, prefer the cleaner boundary or smaller API, per the Laziness Protocol.

## Phase E: Graft

Walk each losing candidate once more for what is worth porting into the base, usually one or two things per candidate, not most of it. Fold each graft in by hand, per the **redesign-from-first-principles** principle skill, so the result stays coherent under one mental model. Don't paste mechanically.

If the candidates converge on one shape, that is strong agreement. Note it and ship the consensus shape. No graft is needed. If they wildly diverge, Phase A was under-specified. Reframe and re-run rather than averaging the divergence.

## Phase F: Verify

Verify the synthesized artifact like any other output, per the **prove-it-works** principle skill. If verification finds a problem the arena missed, either Phase A was wrong (re-frame and re-run) or a candidate caught it and you missed the graft (go back to Phase E). Don't paper over it.

## Outputs

One synthesized artifact, with a short synthesis note alongside naming the base and why, the cross-judge's verdict or that Phase C skipped the judge, each graft with its source candidate, what was rejected and why, any convergence or dropouts, and the verification result.
