---
name: setup-pstack
description: Configure which harness-config and model pstack uses per role and at what budget. Detects your available harness-configs and writes pstack-models.yaml in the pstack store, which overrides the skill defaults. Use for /setup-pstack, "configure pstack models", "pstack budget", or changing pstack's model choices.
---

# Setup pstack

Write `pstack-models.yaml` at the pstack store root, the file that sets pstack's harness-config and model per role. Resolve the store root and read the schema in the **pstack-scion-runtime** skill (sections 3 and 4).

## Steps

### 0. Resolve and initialize the pstack store

Resolve `<store-root>` per **pstack-scion-runtime** §4 (canonical default: `$PSTACK_STORE`, else `/scion-volumes/scratchpad/pstack`, with each program's directory at `<store-root>/<program-slug>/`). Check mounted volumes directly (`ls -d /scion-volumes/*/` or `.scion-volumes/*/`, where `scratchpad` wins), because `scion shared-dir list` can report none while a volume is mounted and writable.

When `$PSTACK_STORE` is set or a writable `/scion-volumes/<mount>/` mount exists, create the store upfront (`mkdir -p <store-root>/.preflight/inbox && chmod 2775 <store-root> 2>/dev/null || true`) and write `ok` to `<store-root>/.preflight/probe.txt` so step 1b verifies cross-container read and write access from a spawned `pstack-reviewer`. If `$PSTACK_STORE` is unset and no writable shared volume is mounted, ask the user (**pstack-scion-runtime** §2 `ask_user`) to mount a project shared volume (such as `scratchpad`) or set `PSTACK_STORE` before multi-container runs, noting that a clone-local store is not shared across containers; skip the `.preflight/` child store check only if they choose a local setup for now.

### 1. Detect available harness-configs and model families

Run `scion harness-config list`. Its `NAME` column is the only dependable source of harness names. Pull each detected harness-config into `/tmp/pstack-hc/<name>` (`scion harness-config pull <name> --to /tmp/pstack-hc/<name>`, never inside `/workspace`) and read its `config.yaml` (`model_aliases` and default `model`) to resolve concrete IDs for `small`, `medium`, `large`, and `extra-large` plus its model `family` (`claude-*` → `anthropic`, `gpt-*` / `o1*` / `o3*` / `o4*` → `openai`, `gemini-*` → `google`, `grok-*` → `xai`, and so on; a multi-provider harness such as `opencode` takes the family of the model ID its alias resolves to). If `scion harness-config list` fails, ask the user to paste the names they have. Never write a harness name you have not confirmed is available. The value `inherit` is always valid even though it is not a detected name.

### 1b. Preflight: which ones actually start

A listed harness-config can still fail at start (expired auth, missing image, a crash at boot). Pick a unique agent prefix `<prefix>` (default `<your-agent-name>-pf` from `$SCION_AGENT_NAME` or `scion list`, honoring any prefix or batch size in the brief so project naming rules pass, and adding a short run suffix if a stale `<prefix>-*` agent exists). For each detected name, start one throwaway `pstack-reviewer` with explicit `--role baseline` (**pstack-scion-runtime** §1):

`scion start <prefix>-<name> --type pstack-reviewer --role baseline --harness-config <name> "Read <store-root>/.preflight/probe.txt, write ok to <store-root>/.preflight/inbox/<prefix>-<name>.md, reply with the single word ok to @<your-agent-name> with scion message, then signal task completion."`

(Omit the `.preflight/` read and write clause only when step 0 found no shared store.)

- **Template provisioning blocker (`skill_resolution_failed`).** If `scion start` fails with `skill_resolution_failed` (for example 404 on `gh://scion-frontiers/scion-pstack/...` or `secret "GH_SCION_FRONTIERS" not found in ProvisionCredentials`), stop preflight immediately instead of marking the harness unrunnable or launching remaining harnesses. That error blocks every template in the project because Hub skill resolution ignores user-scope secrets: tell the user to set `GH_SCION_FRONTIERS` at **project scope** (`scion hub secret set --project GH_SCION_FRONTIERS <PAT>`, or `sciontool secret set GH_SCION_FRONTIERS <PAT>` from a `--role full` agent) or re-sync templates from `bash build.sh --bundle DIR`.
- **Concurrency caps and non-zero `scion start` exits.** Launch all detected harnesses at once unless the brief sets a batch size. If `scion start` hits `429` / `quota_exceeded` (`max_agents_per_broker`), stop launching new ones, finish and `scion delete` the active batch, then test remaining harnesses in smaller batches (down to 1 at a time). Whenever `scion start` exits non-zero without `skill_resolution_failed` (such as `context deadline exceeded` or readiness exit `3`), still check `scion list` for `<prefix>-<name>`: if the Hub created the agent and it is running, keep waiting on it; otherwise record the start failure and `scion delete` any leaked container.
- **Check messages, store probe, and `scion list`.** Run `sciontool status blocked "setup-pstack preflight"` with a per-batch timeout of 3 to 5 minutes (optionally arming a one-shot `scion schedule create --in 5m` self-callback canceled via `scion schedule cancel <id>` once done, **pstack-scion-runtime** §2; never `sleep`-poll). Do not rely on `scion list` alone, because harnesses such as `opencode` can send `ok` and stay running without reaching `COMPLETED`. Check inbound `scion message` / `scion conversation` history for `ok`, `<store-root>/.preflight/inbox/<prefix>-<name>.md` (when using a shared store), and `scion list`. A name is **runnable** when its agent sent `ok` or reached `COMPLETED` cleanly. When step 0 initialized a shared store, confirm at least one runnable child wrote `<store-root>/.preflight/inbox/<prefix>-<name>.md`; if an agent sent `ok` by message while failing to read or write `<store-root>/.preflight/`, surface the shared-store mount or permission error before continuing. A name has **failed** when it timed out without `ok`, errored or exited, or sits in `waiting_for_input` on an interactive login/auth prompt or startup error (`scion look <prefix>-<name> --full --plain` once).

Delete every `<prefix>-*` preflight agent (`scion delete`, confirming zero remain in `scion list`), and remove `<store-root>/.preflight/` and `/tmp/pstack-hc`. The detected set for the steps below is the runnable set. Record runnable names (with `<family>/<model>`) and failed names (with reasons) in the file's header comment (step 5), so later runs and the runtime's substitution rule know what was tried.

### 2. Load current state

The default role mapping is the file shape shown in step 5 below (`# defaults: 2`). If `<store-root>/pstack-models.yaml` already exists, read it and treat its `budget` key and its role values as the current choices. Otherwise start from those defaults. Any role key not in step 5 (such as `how-explorer`, `how-explainer`, `why-investigator`, or `why-synthesizer`) is from a retired `# defaults: 1` role; drop it and record it to show in step 3(c).

A file without `# defaults: 2` comes from an older setup whose defaults used `grok-*` (`grok-build`). Before step 3, replace legacy defaults:
- A `grok-*` harness in `code`, `reflect-tooling`, or `swarm-worker` takes that role's step 5 default.
- In a panel role (`interrogate`, `architect`, `arena`, `cross-judge`), the 4-seat `# defaults: 1` default list `[claude, codex, gemini, grok-build]` (or any `grok-*` default entry) takes the 3-seat step 5 list `[claude, codex, gemini]` (dropping `grok-*` entries from custom lists or substituting a runnable harness from another model family).

Every other value is the user's choice and stays, including `inherit`. Tell the user which values you replaced.

### 3. Budget, map, and confirm

**(a) Ask for a budget.** Ask with the runtime's ask_user pattern (section 2). Offer these four options with these exact labels, and name the current budget when the file records one. With no file, say that `unlimited` matches the skill defaults.

- `unlimited — max reasoning` (role defaults: `extra-large`, `swarm-worker` at `large`)
- `large — xhigh reasoning` (caps `extra-large` roles and panels at `large`)
- `medium — high reasoning` (caps roles and panels at `medium`)
- `small — medium reasoning` (caps roles and panels at `small`)

**(b) Apply it.** Build the working table from the step 5 defaults (substituting runnable harnesses where a default is unrunnable, or `inherit` if none is runnable, and deduplicating default panel lists so each panel contains at most one runnable harness per resolved model `family`, falling back to distinct `harness-config` names only when family is unknown), and on a re-run keep any role you changed by harness, list, or `inherit` (and keep `reflect-judgment: judgment` unless explicitly overridden). `unlimited` keeps the step 5 model aliases (`extra-large` for primary roles and panels, `large` for `swarm-worker`); `large`, `medium`, and `small` cap every role and panel entry at `large`, `medium`, and `small` respectively. An entry pinned to an explicit model ID (not an alias) keeps it. `inherit` does not change. Panel entries written as bare harness names become `{harness: <h>, model: <alias>}` when the budget is not `unlimited`.

**(c) Show the roles and confirm.** Show every role with its harness, model, and resolved model `family` (noting when multiple runnable harnesses share one family, such as `gemini-cli` and `antigravity` on `google`, or `claude` and `opencode` on `anthropic`), marking any harness not in the runnable set as needing a choice, and list any retired keys step 2 dropped. Ask whether to accept as-is or change specific roles, offering the runnable harness-configs plus `inherit` (the role runs on the caller's own harness and model) as the options. Use the same ask_user pattern. For panel roles (`arena`, `architect`, `interrogate`) the value is a list, and one agent runs per entry, `inherit` included, so the list length sets the fan-out. Keep panel entries on distinct model families (at most one member per `family` by default), since panels exist for model-family diversity. `cross-judge` is also a list, ordered by preference; Arena picks one runnable entry whose model `family` differs from the caller's (`inherit` never judges). `swarm-worker` is the default for every worker unless a race or comparison assigns another harness per arm.

### 4. Validate

Every harness name written must be in the runnable set from step 1b. `inherit` (and `reflect-judgment: judgment`) always passes. Every `model` is one of the four aliases or an explicit ID the user supplied (if an explicit model ID changes a multi-provider harness's family, record `{harness: <h>, model: <m>, family: <f>}`). Warn if a panel contains two entries with the same resolved `family` so duplicate-family slots are only kept intentionally. If a chosen harness is not available, stop and ask again.

### 5. Write the file

Write `<store-root>/pstack-models.yaml` with the `# defaults: 2` marker, the preflight header, a `budget` key holding the chosen label (`unlimited`, `large`, `medium`, or `small`), a `families` map recording each runnable harness-config's resolved model family, and the `roles` and `panels` maps using the keys from **pstack-scion-runtime** §3. Overwrite the whole file so re-runs stay idempotent. Shape (defaults, budget `unlimited`):

```yaml
# pstack-models.yaml. One key per role. Delete a key to fall back to the default.
# harness: a scion harness-config name. model: alias (small|medium|large|extra-large) or explicit ID.
# "inherit" means run the role on the caller's own harness and model (omit --harness-config/--model).
# defaults: 2
# preflight <date>: runnable [<name> (<family>/<model>), ...]; failed [<name>: <reason>, ...]
budget: unlimited
families:           # resolved model family per runnable harness-config (from config.yaml model_aliases)
  claude: anthropic
  codex:  openai
  gemini: google
roles:
  code:             {harness: claude, model: extra-large}   # feature, refactoring, bug-fix, perf, hillclimb delegates
  hardest:          {harness: claude, model: extra-large}   # cross-cutting design, gnarly concurrency
  judgment:         {harness: claude, model: extra-large}   # prose, judgment, synthesizers, arena-picker
  reflect-judgment: judgment
  reflect-tooling:  {harness: codex, model: extra-large}
  swarm-worker:     {harness: claude, model: large}
panels:             # one agent per entry, at most one per model family when available (3-family target in defaults: 2)
  interrogate: [claude, codex, gemini]
  architect:   [claude, codex, gemini]
  arena:       [claude, codex, gemini]
  cross-judge: [claude, codex, gemini]   # pick one whose model family differs from the caller's
```

### 6. Confirm

Tell the user the file was written, its path, and that it applies to every agent spawned from now on (agents already running keep the harness they started with). Re-running this skill updates it.

### 7. Offer a verification skill (optional)

Check whether the project has a way to drive the real app for proof (a `verify-*` skill, or an existing harness). If not, offer once: "want a project-local verification skill, so agents can drive the app the way a user does and prove changes work? I can generate one with create-verification-skill." On yes, run the **create-verification-skill** skill. On no, move on without pushing.

### 8. Offer a formal verification skill (optional)

Check whether the project already has a formal verification skill (a project skill that runs a model checker, a proof, or another verifier against the code). If not, offer once: "want a formal verification skill, so agents can prove a key property of your code holds in every case in scope, not only the cases tests reach? I can generate one with create-formal-verification-skill." On yes, run the **create-formal-verification-skill** skill. On no, move on without pushing.
