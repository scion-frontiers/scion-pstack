# reflect: port notes

Upstream: `pstack/skills/reflect` at 5ff7a35.

## Changed
- Frontmatter: dropped `disable-model-invocation: true` (explicit-invocation intent; "when the user says reflect" stays in the description).
- Step 1: `agent-transcripts/` discovery (the three JSONL layouts and the first-line match) became the runtime §2 source order: trail file, `scion conversation`, `scion logs`/`look`. The assembled transcript plus digest goes to `<store>/<program-slug>/reflect/transcript.md` so that cross-container reviewers can read it. Upstream's privacy rule (don't glob `~/.cursor/projects/*/`) became "stay inside this session's conversation and agents". Upstream's digest fallback is kept.
- Step 2: three `Task` calls with model slugs became roles (`roles.judgment` for Judgment and Divergent, `roles.reflect-tooling` for Tooling). **Tier per lens: a Scion agent (`pstack-reviewer`) when the lens's harness differs from the caller's, otherwise in-harness is allowed.** With the defaults, Tooling (codex) is always a Scion agent. Results come back as a REPORT message.
- Step 3: the synthesizer is on `roles.judgment`, with the same tier rule. The `readonly: false` MCP rationale became "writes nothing, keeps MCP access".
- Step 5: the approval ask goes through the runtime §2 (`AskQuestion` row) and §5. Cursor's built-in `create-skill` became poteto-mode's authoring-a-skill playbook. The `new skill via create-skill:` routing label is kept verbatim, because `references/synthesizer.md` emits it.
- Step 6: added a "Transcript source" line (the runtime requires stating which source was used).
- References (`judgment-`, `tooling-`, `divergent-reviewer.md`): the "was the skill used" detection named `.cursor/skills/`, `~/.cursor/plugins/`, and `Task` prompts. These became template skills, `.scion/skills/`, harness skill dirs, and subagent or `scion start` briefs. `synthesizer.md` is verbatim.

## Not ported cleanly
- **Transcript fidelity is lower.** Cursor transcripts include every tool call. `scion conversation` has messages only, and `scion logs` is terminal output. Reviewers scanning for "`Read` of a SKILL.md" may miss skill usage that the harness never logged visibly. The lead's own harness may keep a local session file (for example Claude Code's `~/.claude/projects/*.jsonl`), but the runtime declares no such store, so the port does not rely on it.
- **create-skill loops are lost.** Upstream relied on `create-skill`'s draft/test/iterate and description-optimization loops. The authoring-a-skill playbook has only validate, test-if-structural, and PR. Description tuning is now unassisted.
- `<program-slug>`: reflect is often ad hoc, outside any program. The lead needs a request slug for the store path.

## Open questions
- Should the runtime bless reading the harness's own local session file as source (0), ahead of the trail file?
- Should `pstack-models.yaml` split `reflect-judgment` from `judgment`, as upstream did?
