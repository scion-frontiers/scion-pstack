---
name: setup-pstack
description: Configure which harness-config and model pstack uses per role and at what budget. Detects your available harness-configs and writes pstack-models.yaml in the pstack store, which overrides the skill defaults. Use for /setup-pstack, "configure pstack models", "pstack budget", or changing pstack's model choices.
---

# Setup pstack

Write `pstack-models.yaml` at the pstack store root, the file that sets pstack's harness-config and model per role. Resolve the store root and read the schema in the **pstack-scion-runtime** skill (sections 3 and 4).

## Steps

### 1. Detect available harness-configs

Run `scion harness-config list`. Its `NAME` column is the only dependable source of harness names. Each harness-config maps the aliases `small`, `medium`, `large`, and `extra-large` to its own vendor's models (`model_aliases` in its `config.yaml`; `scion harness-config pull <name> --to <scratch-dir>/hc/<name>` fetches it when you need the concrete IDs). If the command fails, ask the user to paste the names they have. Never write a harness name you have not confirmed is available. The value `inherit` is always valid even though it is not a detected name.

### 1b. Preflight: which ones actually start

A listed harness-config can still fail at start (expired auth, missing image, a crash at boot). For each detected name, start one throwaway agent with a trivial task:

`scion start setup-preflight-<name> --type pstack-reviewer --harness-config <name> "Reply with the single word ok to @<your-agent-name> with scion message, then signal task completion."`

Start them all at once, then run `sciontool status blocked "setup-pstack preflight"`. After about five minutes, or once every result is in, check `scion list`. A name is **runnable** when its agent sent `ok` or reached `COMPLETED`. It has **failed** when the agent errored, exited, or sits on an interactive auth prompt (`scion look <agent>` once). Delete every preflight agent. The detected set for the steps below is the runnable set. Record the failed names and their reasons in the file's header comment (step 5), so later runs and the runtime's substitution rule know what was tried.

### 2. Load current state

The default role mapping is the file shape shown in step 5 below (`# defaults: 2`). If `<store-root>/pstack-models.yaml` already exists, read it and treat its `budget` key and its role values as the current choices. Otherwise start from those defaults. Any role key not in step 5 (such as `how-explorer`, `how-explainer`, `why-investigator`, or `why-synthesizer`) is from a retired `# defaults: 1` role; drop it and record it to show in step 3(c).

A file without `# defaults: 2` comes from an older setup whose defaults used `grok-*` (`grok-build`). Before step 3, replace legacy defaults:
- A `grok-*` harness in `code`, `reflect-tooling`, or `swarm-worker` takes that role's step 5 default.
- In a panel role (`interrogate`, `architect`, `arena`, `cross-judge`), the 4-seat `# defaults: 1` default list `[claude, codex, gemini, grok-build]` (or any `grok-*` default entry) takes the 3-seat step 5 list `[claude, codex, gemini]` (dropping `grok-*` entries from custom lists or substituting a runnable vendor).

Every other value is the user's choice and stays, including `inherit`. Tell the user which values you replaced.

### 3. Budget, map, and confirm

**(a) Ask for a budget.** Ask with the runtime's ask_user pattern (section 2). Offer these four options with these exact labels, and name the current budget when the file records one. With no file, say that `unlimited` matches the skill defaults.

- `unlimited — max reasoning` (role defaults: `extra-large`, `swarm-worker` at `large`)
- `large — xhigh reasoning` (caps `extra-large` roles and panels at `large`)
- `medium — high reasoning` (caps roles and panels at `medium`)
- `small — medium reasoning` (caps roles and panels at `small`)

**(b) Apply it.** Build the working table from the step 5 defaults, and on a re-run keep any role you changed by harness, list, or `inherit` (and keep `reflect-judgment: judgment` unless explicitly overridden). `unlimited` keeps the step 5 model aliases (`extra-large` for primary roles and panels, `large` for `swarm-worker`); `large`, `medium`, and `small` cap every role and panel entry at `large`, `medium`, and `small` respectively. An entry pinned to an explicit model ID (not an alias) keeps it. `inherit` does not change. Panel entries written as bare harness names become `{harness: <h>, model: <alias>}` when the budget is not `unlimited`.

**(c) Show the roles and confirm.** Show every role with its harness and model, marking any harness not in the runnable set as needing a choice, and list any retired keys step 2 dropped. Ask whether to accept as-is or change specific roles, offering the runnable harness-configs plus `inherit` (the role runs on the caller's own harness and model) as the options. Use the same ask_user pattern. For panel roles (`arena`, `architect`, `interrogate`) the value is a list, and one agent runs per entry, `inherit` included, so the list length sets the fan-out. Keep panel entries on distinct vendors, since panels exist for model diversity. `cross-judge` is also a list, ordered by preference; Arena picks one runnable entry whose vendor differs from the caller's (`inherit` never judges). `swarm-worker` is the default for every worker unless a race or comparison assigns another harness per arm.

### 4. Validate

Every harness name written must be in the runnable set from step 1b. `inherit` (and `reflect-judgment: judgment`) always passes. Every `model` is one of the four aliases or an explicit ID the user supplied. If a chosen harness is not available, stop and ask again.

### 5. Write the file

Write `<store-root>/pstack-models.yaml` with the `# defaults: 2` marker, the preflight header, a `budget` key holding the chosen label (`unlimited`, `large`, `medium`, or `small`), and the `roles` and `panels` maps using the keys from **pstack-scion-runtime** §3. Overwrite the whole file so re-runs stay idempotent. Shape (defaults, budget `unlimited`):

```yaml
# pstack-models.yaml. One key per role. Delete a key to fall back to the default.
# harness: a scion harness-config name. model: alias (small|medium|large|extra-large) or explicit ID.
# "inherit" means run the role on the caller's own harness and model (omit --harness-config/--model).
# defaults: 2
# preflight <date>: runnable [<names>]; failed [<name>: <reason>, ...]
budget: unlimited
roles:
  code:             {harness: claude, model: extra-large}   # feature, refactoring, bug-fix, perf, hillclimb delegates
  hardest:          {harness: claude, model: extra-large}   # cross-cutting design, gnarly concurrency
  judgment:         {harness: claude, model: extra-large}   # prose, judgment, synthesizers, arena-picker
  reflect-judgment: judgment
  reflect-tooling:  {harness: codex, model: extra-large}
  swarm-worker:     {harness: claude, model: large}
panels:             # one agent per entry; list length sets the fan-out (3-vendor default in defaults: 2)
  interrogate: [claude, codex, gemini]
  architect:   [claude, codex, gemini]
  arena:       [claude, codex, gemini]
  cross-judge: [claude, codex, gemini]   # pick one whose vendor differs from the caller's
```

### 6. Confirm

Tell the user the file was written, its path, and that it applies to every agent spawned from now on (agents already running keep the harness they started with). Re-running this skill updates it.

### 7. Offer a verification skill (optional)

Check whether the project has a way to drive the real app for proof (a `verify-*` skill, or an existing harness). If not, offer once: "want a project-local verification skill, so agents can drive the app the way a user does and prove changes work? I can generate one with create-verification-skill." On yes, run the **create-verification-skill** skill. On no, move on without pushing.

### 8. Offer a formal verification skill (optional)

Check whether the project already has a formal verification skill (a project skill that runs a model checker, a proof, or another verifier against the code). If not, offer once: "want a formal verification skill, so agents can prove a key property of your code holds in every case in scope, not only the cases tests reach? I can generate one with create-formal-verification-skill." On yes, run the **create-formal-verification-skill** skill. On no, move on without pushing.
