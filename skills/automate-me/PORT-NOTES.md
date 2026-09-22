# automate-me: port notes

Upstream: `pstack/skills/automate-me` at 5ff7a35. Ported, not deferred.

## Why it is still meaningful
The human's working style on Scion is visible in their own messages (`scion conversation messages`) and, better than on Cursor, in orchestrate's `preferences.md` in the pstack store, which is already a numbered standing-orders list in their words. `gates.md` answers and correction/revert rows in `decisions.tsv` show what they overrode.

## Changed
- Dropped `disable-model-invocation: true` from this skill; routed by name (runtime §5).
- Mining source: `agent-transcripts/` → project-scoped conversations + pstack store program dirs. Workspace-boundary rule becomes a project-boundary rule. Slice subagents are in-harness (runtime §1).
- `AskQuestion` (multi-choice, `allow_multiple`) → runtime ask_user pattern with numbered options and "reply with every number that applies".
- Cursor built-in `create-skill` → poteto-mode's authoring-a-skill playbook + agentskills.io rules (runtime §2 row).
- Existing-skill lookup and output: `.cursor/skills/**` / `~/.cursor/skills/` → `.scion/skills/**`, template `skills/`, the agent's own skills dir; personal skill → `scion skills publish --scope user`.
- Frontmatter guidance `disable-model-invocation: true by default` → a Delivery bullet: Scion has no repo skill loading and no slash commands, so suggest forking `pstack-lead` into `<handle>-lead` that ships the mode skill and treats it as always on; an on-request mode stays out of the template instructions and the lead routes to it.
- "Work in a worktree off main" → branch off main.

## Unresolved
- Mining quality depends on Hub conversation retention and on programs having kept a store; a fresh project has little to mine, so step 2 (asking) carries more weight.
- The `<handle>-lead` fork is a suggestion only; the template-creation step itself is the team-creation skill's job.
- Harness-specific: Claude Code honors `disable-model-invocation` in frontmatter (see the verbatim-audit note in the port report); a generated mode skill should not carry it on Scion.
