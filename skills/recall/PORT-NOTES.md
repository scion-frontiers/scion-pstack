# recall: port notes

Upstream: `upstream/pstack-bf0c7cd/skills/recall/` (v0.15.42).

## Changed
- Frontmatter: dropped `disable-model-invocation: true` (routed by name per **pstack-scion-runtime** §5).
- Transcript store (`~/.cursor/projects/<slug>/agent-transcripts/`): replaced with **pstack-scion-runtime** §2/§4 sources (`notes.md`, `goal.md`, `resume.md`, `decisions.tsv`, `inbox/`, `verdicts/` in the pstack store; `scion conversation`; `scion list` + `scion look --full --plain` / `scion logs`; and `git`/`gh`).
- Step 3 & Output contract: slice subagents are in-harness (**pstack-scion-runtime** §1), citing store path, `conv:<id>`, or agent name instead of chat UUID.
- Step 4: matches upstream `bf0c7cd`'s direct per-source investigator fan-out (decoupled from `why`).
- Step 5: reads full `scion look --full --plain` (or `scion logs` when available) + `inbox/` report and states which source was used.
