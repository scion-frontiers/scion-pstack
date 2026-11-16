---
name: interrogate
description: "Use for \"interrogate\", \"adversarial review\", \"multi-model review\", \"challenge this\", \"stress test this code\", \"find blind spots\", or \"tear this apart\". Adversaries try to break a change or design, and only findings proven by a run survive."
---

# Interrogate

Adversaries try to break a change or a design. A finding survives only when a run proves it. Report the findings. Do not apply fixes.

## Frame

The scope is what the user names. Otherwise it is the branch diff from its merge base with the base branch, through the working tree. State the intent with the **in-your-own-words** skill, from the user's message, the commits, and the PR description. Ask the user when the intent is unclear.

## Fan out

Run Phase A steps 3 and 4 and Phase B of the **arena** skill, with four changes. Read `panels.interrogate` in `pstack-models.yaml` in place of `panels.arena` (**pstack-scion-runtime** §3). Package the scope for isolated clones (**pstack-scion-runtime** §1): pin the pushed branch, exact `<base-sha>`, and exact `<head-sha>` (plus PR URL when present) in every adversary's brief so every panelist checks out `<head-sha>` and reviews the identical `<base-sha>...<head-sha>` diff; if broker concurrency caps force sequential waves and the branch advances mid-run, finish on the pinned `<head-sha>` or re-run earlier panelists on the final `<head-sha>` (otherwise label the verdict `split-head` with each panelist's reviewed SHA). When the scope has uncommitted changes, push an ephemeral `wip/<slug>` branch (pinned by SHA) or write `git diff HEAD --binary > <store>/<program>/scope.patch` against `<base-sha>` so each adversary applies it in its own clone. Spawn each adversary as a `pstack-reviewer` Scion agent with `--role baseline` (**pstack-scion-runtime** §1: never push refs, mutate PRs, or edit shared store files other than its assigned `inbox/` file; for untrusted external/fork PRs, verify container `GITHUB_TOKEN` and shared store isolation before running live repros). In place of the arena task and rationale, give each adversary the scope, the intent, and this brief:

> Break this change. Prove each finding with a run against the real code, such as a failing test, a repro script, or command output that shows the wrong behavior. For a design or plan, run a prototype or probe the current tree. Keep repros in your own clone, never pushed. Report each finding with a title, the exact command, the output it printed, and the output the intent requires. Leave out anything you did not run. That covers style, naming, structure, and risks that need a future change to matter. No findings is a valid result.

## Verify

Verify each finding per arena Phase F by rerunning its command. Keep a finding when the output shows the failure and the failure breaks the intent. Drop the rest. Merge findings that share a root cause.

Skip arena Phases C, D, and E. Adversaries find different failures, so the verdict keeps every verified finding, not one adversary's list.

## Output

- **Intent**: the restatement.
- **Findings**: for each verified finding, the command, its output, how it breaks the intent, and the adversaries that found it. Say "no verified findings" when none survive.
- **Dropped**: for each adversary, the count of dropped findings and why.
