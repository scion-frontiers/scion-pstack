---
name: swarm
description: "Fan out N parallel workers, drain them, and return one report. Use for /swarm, 'swarm this', or parallel coverage, races, gauntlets, and exploration."
---

# Swarm

## Start

Open a todolist with one entry per phase before launching anything.

1. Frame
2. Fan out
3. Aggregate
4. Report

## Phase A: Frame

1. State the done predicate and the artifact or report the swarm must return.
2. Choose the shape. Partition into slices, race N workers on identical briefs, or mix both. For a race or mixed shape, declare `first pass`, `rank all`, or `best-of` before spawning.
3. Pick the worker harness-config and model from `roles.swarm-worker` in `pstack-models.yaml`, resolving missing-file (`inherit`) and missing-key fallbacks per **pstack-scion-runtime** §3 so unpreflighted harnesses are never spawned. For `inherit`, omit `--harness-config` and `--model` so the workers run on the parent harness and model. If a configured harness-config is unavailable, substitute per **pstack-scion-runtime** §3 and say so. For a model race, name each arm's runnable harness-config up front (preferring distinct resolved model families per **pstack-scion-runtime** §3). Pick each worker's reasoning level per the Subagents section of the **poteto-mode** skill (**pstack-scion-runtime** §1).
4. Give each worker its own writable output when it writes (its own pushed branch, or its own `inbox/` / `verdicts/` file in the pstack store; workers do not share `/tmp`). When workers verify or measure commits, each brief names the exact SHAs. A measurement brief also names the method (sample count, what one sample is, order). The worker records both in its result.

## Phase B: Fan out

Start all N workers at once on the step 3 configuration: `pstack-agent` Scion agents when the worker writes, `pstack-reviewer` Scion agents when it only reads (**pstack-scion-runtime** §1; read-only coverage slices on cheap units may use in-harness subagents when `roles.swarm-worker` resolves to your own harness, while model races always use Scion agents). A worker that needs access to a host-specific resource needs a template service, mount, or secret; flag it as a gate if the template lacks one.

When a worker must start from a non-default pushed branch, put the base branch in its brief (**pstack-scion-runtime** §2).

Every brief stands alone. Include the goal, scope, exact slice or race arm, how to verify, and what to report (via `inbox/` and `scion message` per **pstack-scion-runtime** §1). Reports use `PASS`, `ISSUES`, or `BLOCKED` with evidence. A worker that can prove a defect reports `ISSUES` and lists every issue it can prove, not only the first.

If a worker drops out, proceed with N-1 and note it.

## Phase C: Aggregate

Read the terminal results. Drop a result that does not record the SHAs and method its brief names, and respawn that worker once. After a second miss, record a gap. A gap does not count as a pass. For coverage, every required slice needs a result. For a race, apply the selection rule declared up front. Use first pass, rank all, or best-of. Do not paste raw worker dumps.

## Phase D: Report

Return one consolidated report (via `scion message` per **pstack-scion-runtime** §5) with a result table, issue one-liners, gaps or dropouts, and the race rule when used.
