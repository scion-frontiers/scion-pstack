# setup-pstack: port notes

Upstream: `upstream/pstack-bf0c7cd/skills/setup-pstack/` (v0.15.42, `# defaults: 2`). Mechanics rewritten for Scion harness-configs; step structure (1–8) and `# defaults: 2` migration kept.

## Changed
- Output: `~/.cursor/rules/pstack-models.mdc` → `<store-root>/pstack-models.yaml`, schema from **pstack-scion-runtime** §3 (`# defaults: 2`) and store root from §4.
- Detection & preflight: `Task` model slugs → `scion harness-config list` plus step 1b throwaway `pstack-reviewer` preflight check.
- Step 2 migration: drops retired `# defaults: 1` keys (`how-explorer`, `how-explainer`, `why-investigator`, `why-synthesizer`) and migrates legacy `grok-*` defaults to `# defaults: 2` (`claude` for `code`/`swarm-worker`, 3-seat `[claude, codex, gemini]` panels).
- Budget: maps `unlimited | large | medium | small` onto Scion model size aliases (`extra-large`, `large`, `medium`, `small`), keeping `swarm-worker` at `large` under `unlimited` per runtime §3.
- `AskQuestion` → runtime `ask_user` pattern (§2); `inherit-parent`/`auto` → `inherit`.
- Steps 7 & 8: offer **create-verification-skill** and **create-formal-verification-skill** by skill name rather than slash invocation.
