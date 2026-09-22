# recall: port notes

Upstream: `pstack/skills/recall` at 5ff7a35.

## Changed
- Dropped `disable-model-invocation: true` (Cursor: fire only on explicit `/recall`). On Scion there are no slash commands; the lead routes to it when the human asks ("catch me up"), per runtime §5. Its description already carries those triggers.
- Transcript store (`~/.cursor/projects/<slug>/agent-transcripts/`) → four sources: the pstack store (status.md, units.tsv, ledger.tsv, decisions.tsv, gates.md, inbox/), `scion conversation` history, `scion list`/`logs`/`look` for program agents, and git/gh.
- Fan-out: same shape and return schema. Slices are now per program dir / per conversation / agent logs instead of per chat file; citations are store path, `conv:<id>`, or agent name instead of chat UUID. Subagents are in-harness (runtime §1).
- Step 5 "read the full transcript" → full `scion logs` plus the agent's inbox report, and say which source was used.
- Scope rule "never read another project's transcripts" → another project's store or conversations.

## Unresolved
- History is thinner than Cursor's. An agent's tool-by-tool record exists only in `scion logs` while the agent exists; after deletion, only its store report and branch remain. The lead's own reasoning is not recorded anywhere unless it wrote it to decisions.tsv. Consequence: recall is only as good as the trail discipline (show-me-your-work, orchestrate's store).
- `scion conversation` requires Hub mode. Without a Hub the conversation source is empty.
- `session-pickup` is referenced by name; its port lives in poteto-mode's playbooks.
