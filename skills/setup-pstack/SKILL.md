---
name: setup-pstack
description: Configure which harness-config and model pstack uses per role and at what budget. Detects your available harness-configs and writes pstack-models.yaml in the pstack store, which overrides the skill defaults. Use for /setup-pstack, "configure pstack models", "pstack budget", or changing pstack's model choices.
---

# Setup pstack

Write `pstack-models.yaml` at the pstack store root, the file that sets pstack's harness-config and model per role. Resolve the store root and read the schema in the **pstack-scion-runtime** skill (sections 3 and 4).

## Steps

### 1. Detect available harness-configs

Run `scion harness-config list`. Its `NAME` column is the only dependable source of harness names. Each harness-config maps the aliases `small`, `medium`, `large`, and `extra-large` to its own vendor's models (`model_aliases` in its `config.yaml`; `scion harness-config pull <name> --to /tmp/hc/<name>` fetches it when you need the concrete IDs). If the command fails, ask the user to paste the names they have. Never write a harness name you have not confirmed is available. The value `inherit` is always valid even though it is not a detected name.

### 1b. Preflight: which ones actually start

A listed harness-config can still fail at start (expired auth, missing image, a crash at boot). The port trial found 7 of 8 listed vendors unrunnable. For each detected name, start one throwaway agent with a trivial task:

`scion start setup-preflight-<name> --type pstack-reviewer --harness-config <name> "Reply with the single word ok to @<your-agent-name> with scion message, then signal task completion."`

Start them all at once, then run `sciontool status blocked "setup-pstack preflight"`. After about five minutes, or once every result is in, check `scion list`. A name is **runnable** when its agent sent `ok` or reached `COMPLETED`. It has **failed** when the agent errored, exited, or sits on an interactive auth prompt (`scion look <agent>` once). Delete every preflight agent. The detected set for the steps below is the runnable set. Record the failed names and their reasons in the file's header comment (step 5), so later runs and the runtime's substitution rule know what was tried.

### 2. Load current state

The default role mapping is the file shape shown in step 5 below. If `<store-root>/pstack-models.yaml` already exists, read it and treat its `budget` key and its role values as the current choices. Otherwise start from those defaults.

### 3. Budget, map, and confirm

**(a) Ask for a budget.** Ask with the runtime's ask_user pattern (section 2). Offer these four options with these exact labels, and name the current budget when the file records one.

- `unlimited — keep max` (model alias `extra-large`)
- `large` (model alias `large`)
- `medium` (model alias `medium`)
- `small` (model alias `small`)

**(b) Apply it.** Build the working table from the skill defaults, and on a re-run keep any role you changed by harness, list, or `inherit`. The budget sets the `model` alias of every role and every panel entry: `unlimited` → `extra-large`, `large` → `large`, `medium` → `medium`, `small` → `small`. An entry pinned to an explicit model ID (not an alias) keeps it. `inherit` does not change. Panel entries written as bare harness names become `{harness: <h>, model: <alias>}` when the budget is not `unlimited`.

**(c) Show the roles and confirm.** Show every role with its harness and model, marking any harness not in the detected set as needing a choice. Ask whether to accept as-is or change specific roles, offering the detected harness-configs plus `inherit` (the role runs on the caller's own harness and model) as the options. Use the same ask_user pattern. For panel roles (arena runners, architect runners, interrogate reviewers) the value is a list, and one agent runs per entry, so the list length sets the count. Keep panel entries on distinct vendors, since the panel exists for model diversity. `cross-judge` is also a list, but Arena selects one value from it whose vendor differs from the caller's when possible. `swarm-worker` is the default for every worker unless a race or comparison assigns another harness per arm.

### 4. Validate

Every harness name written must be in the runnable set from step 1b. `inherit` always passes. Every `model` is one of the four aliases or an explicit ID the user supplied. If a chosen harness is not available, stop and ask again.

### 5. Write the file

Write `<store-root>/pstack-models.yaml` with a `budget` key holding the chosen label, and one key per role, using the role names from the runtime's section 3. Overwrite the whole file so re-runs stay idempotent. Shape (defaults, budget `unlimited`):

```yaml
# pstack-models.yaml. One key per role. Delete a key to fall back to the default.
# harness: a scion harness-config name. model: alias (small|medium|large|extra-large) or explicit ID.
# "inherit" means run the role on the caller's own harness and model (omit --harness-config/--model).
# preflight <date>: runnable [<names>]; failed [<name>: <reason>, ...]
budget: unlimited
roles:
  code:            {harness: grok-build, model: extra-large}   # feature, refactoring, bug-fix, perf, hillclimb delegates
  hardest:         {harness: claude, model: extra-large}       # cross-cutting design, gnarly concurrency
  judgment:        {harness: claude, model: extra-large}       # prose, judgment, synthesizers, explainers
  how-explorer:    inherit
  why-investigator: inherit
  reflect-tooling: {harness: codex, model: extra-large}
  swarm-worker:    {harness: grok-build, model: extra-large}
panels:            # one agent per entry; list length sets the fan-out
  interrogate: [claude, codex, gemini, grok-build]
  architect:   [claude, codex, gemini, grok-build]
  arena:       [claude, codex, gemini, grok-build]
  cross-judge: [claude, codex, gemini, grok-build]   # pick one whose vendor differs from the caller's
```

### 6. Confirm

Tell the user the file was written, its path, and that it applies to every agent spawned from now on (agents already running keep the harness they started with). Re-running this skill updates it.

### 7. Offer a verification skill (optional)

Check whether the project has a way to drive the real app for proof (a `verify-*` skill, or an existing harness). If not, offer once: "want a project-local verification skill, so agents can drive the app the way a user does and prove changes work? I can generate one with create-verification-skill." On yes, run the **create-verification-skill** skill. On no, move on without pushing.
