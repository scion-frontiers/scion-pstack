# automate-me: port notes

Upstream: `upstream/pstack-bf0c7cd/skills/automate-me/` (v0.15.42).

## Changed
- Frontmatter: dropped `disable-model-invocation: true` (routed by name per **pstack-scion-runtime** §5).
- Step 0 & Step 4 paths: `.cursor/skills/**` / `~/.cursor/skills/` → `.scion/skills/**`, `.scion/templates/*/skills/`, `scion skills publish --scope user`, and template URI/`scion templates sync` delivery (**pstack-scion-runtime** §2).
- Step 1 mining: `agent-transcripts/` → project-scoped `scion conversation` messages plus pstack store program dirs (`notes.md` standing orders/gates and `decisions.tsv`, **pstack-scion-runtime** §4), mined via parallel in-harness subagents.
- `AskQuestion` → runtime `ask_user` pattern (§2); `create-skill` → `poteto-mode`'s authoring-a-skill playbook.
