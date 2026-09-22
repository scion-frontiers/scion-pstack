# setup-pstack: port notes

Upstream: `pstack/skills/setup-pstack` at 5ff7a35. Mechanics rewritten, step structure (1-7) and judgment kept.

## Changed
- Output: `~/.cursor/rules/pstack-models.mdc` (always-applied rule) → `<store-root>/pstack-models.yaml`, schema from pstack-scion-runtime §3, root from §4. Whole-file overwrite kept for idempotency.
- Detection: "model slugs you can pass to Task" → `scion harness-config list` (NAME column). Aliases small/medium/large/extra-large come from each harness-config's `model_aliases`. `scion harness-config show` does not print them; `scion harness-config pull <name> --to <dir>` does (in its config.yaml).
- Budget: the effort-token ladder rewrite (max/xhigh/high/medium on slug suffixes) → one alias per budget: unlimited→extra-large, large→large, medium→medium, small→small. Explicit model IDs are left alone. Labels kept except the reasoning-effort suffixes, which no longer mean anything.
- `inherit-parent` / `auto` → `inherit` (the runtime's term).
- AskQuestion → the runtime's ask_user pattern (§2).
- Step 6: "applies to new sessions" → applies to agents spawned from now on.
- Step 7: `/create-verification-skill` slash invocation → run the skill by name.
- Added one line: keep panel entries on distinct vendors (the runtime defines model diversity as vendor diversity).
- Role labels follow the runtime's §3 keys (`code`, `hardest`, `judgment`, ...), not upstream's prose labels. Upstream's `how explainer`, `why synthesizer`, and `reflect judgment` roles fold into `judgment`.

## Unresolved
- Who reads the file: spawns only pick it up if the lead (and every skill that spawns) resolves roles from it. That lives in the runtime/lead template, not here.
- A `budget` of large/medium/small on a harness whose alias table lacks that size: the harness decides. Not validated here.
- `gemini` vs `gemini-cli` are both listed on the current hub. The default uses `gemini`; confirm which one the team wants.
