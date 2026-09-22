---
name: swarm
description: "Fan out N parallel workers, drain them, and return one report. Use for /swarm, 'swarm this', or parallel coverage, races, gauntlets, and exploration."
---

# Swarm

Fan out N parallel workers. They may cover separate slices, race the same brief, or mix both. The parent waits, aggregates, and returns one report.

## Start

Open a todolist with one entry per phase before launching anything.

1. Frame
2. Fan out
3. Aggregate
4. Report

## Phase A: Frame

1. State the done predicate and the artifact or report the swarm must return.
2. Choose the shape. Partition into slices, race N workers on identical briefs, or mix both. For a race or mixed shape, declare `first pass`, `rank all`, or `best-of` before spawning.
3. Set N from the user or derive it from the shape. N is total workers, not the concurrency limit.
4. Pick the worker harness-config and model from `roles.swarm-worker` in `pstack-models.yaml`, or the default in `pstack-scion-runtime` §3. For a model race, name each arm's harness-config up front.
5. Give each worker its own writable output when it writes: its own pushed branch, or its own `inbox/` file in the pstack store. Workers do not share `/tmp`.

## Phase B: Fan out

Start all N workers at once as Scion agents on the configured harness-config: `pstack-agent` when the worker writes, `pstack-reviewer` when it only reads. Read-only coverage slices on cheap units may instead be in-harness subagents when the configured role resolves to your own harness (`pstack-scion-runtime` §1). A race across models always uses Scion agents. A worker that needs something on a particular machine needs a template service, mount, or secret; flag it as a gate if the template lacks one.

When a worker must start from a non-default pushed branch, put the base branch in its brief.

Every brief stands alone. Include the goal, scope, exact slice or race arm, how to verify, and what to report. Reports use `PASS`, `ISSUES`, or `BLOCKED` with evidence, sent as a REPORT message to you.

If a worker drops out, proceed with N-1 and note it.

## Phase C: Aggregate

Read the terminal results (REPORT messages, plus the branch or store output they point at). For coverage, every required slice needs a result. For a race, apply the selection rule declared up front. Use first pass, rank all, or best-of. Do not paste raw worker dumps.

Keep a compact result table, one-line evidenced issues, and explicit gaps or dropouts.

## Phase D: Report

Return one consolidated report (a reply per `pstack-scion-runtime` §5) with the table, issue one-liners, gaps or dropouts, and the race rule when used.
