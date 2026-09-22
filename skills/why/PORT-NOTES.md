# why: port notes

Upstream: `pstack/skills/why` at 5ff7a35. The references (prompts, epistemics, sources/*) are verbatim. They contain no host mechanics.

## Changed
- Frontmatter: dropped `disable-model-invocation: true` (explicit-invocation intent; the lead routes by name).
- MCP discovery: Cursor's available-tools map and the `mcps/` dir became "the MCP servers your harness lists" (runtime §2).
- Investigators: **Tier: in-harness subagents**, so they inherit the lead's MCP servers. **Fallback: `pstack-reviewer` Scion agents** when `roles.why-investigator` names another harness. The fallback must check that the template carries the needed MCP server, otherwise the category is recorded as a gap. The model is `roles.why-investigator` (default `inherit`).
- Upstream's `readonly: false` rationale ("readonly strips MCPs") goes away: Scion has no readonly mode, only a brief clause. "Write nothing" stays as a brief clause, and the "don't strip MCP access" intent is kept in general form.
- Synthesizer: "why-synthesizer" maps to `roles.judgment`. **Tier: in-harness when `roles.judgment` is the caller's harness, otherwise `pstack-reviewer`.** Prefer in-harness when citations depend on MCPs.

## Not ported cleanly
- MCP availability now depends on the template (`mcp_servers`), not on the user's Cursor setup. A Scion-agent investigator on a vendor whose template lacks the Slack or Sentry MCP silently loses that category. The skill now says to record that as a gap.
- Step 1 still mentions "cursor location" (the editor cursor). It is harmless, but a Scion lead has no editor. Left verbatim to keep the diff small.

## Open questions
- Should `pstack-reviewer` declare the org's MCP servers so the Scion-agent fallback keeps full coverage?
- Should the yaml grow a `why-synthesizer` key?
