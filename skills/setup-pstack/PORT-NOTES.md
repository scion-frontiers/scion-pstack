# setup-pstack: port notes

Upstream: `upstream/pstack-bf0c7cd/skills/setup-pstack/` (v0.15.42, `# defaults: 2`). Mechanics rewritten for Scion harness-configs; step structure (0–8, adding step 0 shared-store initialization) and `# defaults: 2` migration kept.

## Changed
- Output: `~/.cursor/rules/pstack-models.mdc` → `<store-root>/pstack-models.yaml`, schema (`budget`, `families`, `roles`, `panels`) from **pstack-scion-runtime** §3 (`# defaults: 2`) and store root from §4.
- Step 0 store setup: resolves `$PSTACK_STORE` or writable `/scion-volumes/<mount>/pstack` (`scratchpad` preferred), runs `mkdir -p` upfront, and seeds `.preflight/probe.txt` so step 1b verifies cross-container store read/write from a spawned `pstack-reviewer`.
- Detection & preflight (steps 1 & 1b): `Task` model slugs → `scion harness-config list` + `scion harness-config pull` into `/tmp/pstack-hc` to resolve concrete model IDs and model `family` (`anthropic`, `openai`, `google`, `xai`, ...). Step 1b starts `<prefix>-<name>` (`<agent-name>-pf-<name>`) with `--role baseline`, distinguishes `skill_resolution_failed` (project-scope `GH_SCION_FRONTIERS` / `--bundle` blocker) from unrunnable harnesses, handles `429` broker concurrency caps and `context deadline exceeded` leaked containers, and checks `scion message` / `scion conversation` (`ok`), `.preflight/inbox/`, and `scion list`.
- Step 2 migration: drops retired `# defaults: 1` keys (`how-explorer`, `how-explainer`, `why-investigator`, `why-synthesizer`) and migrates legacy `grok-*` defaults to `# defaults: 2` (`claude` for `code`/`swarm-worker`, 3-seat `[claude, codex, gemini]` panels).
- Steps 3–5 model-family diversity & budget: deduplicates default panels by resolved model `family` (recording `families:` in `pstack-models.yaml`) and maps `unlimited | large | medium | small` onto Scion model size aliases (`extra-large`, `large`, `medium`, `small`), keeping `swarm-worker` at `large` under `unlimited` per runtime §3.
- `AskQuestion` → runtime `ask_user` pattern (§2); `inherit-parent`/`auto` → `inherit`.
- Steps 7 & 8: offer **create-verification-skill** and **create-formal-verification-skill** by skill name rather than slash invocation.
