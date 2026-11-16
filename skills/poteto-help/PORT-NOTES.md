# poteto-help: port notes

Upstream: `upstream/pstack-bf0c7cd/skills/poteto-help/` (v0.15.42).

## Changed
- Frontmatter: dropped `disable-model-invocation: true` (routed by name per **pstack-scion-runtime** §5).
- Public links: replaced broken `../../README.md` and `../../docs/guide/*.md` relative links (which do not exist inside provisioned `$HOME/<skills_dir>/poteto-help/` directories) with `scion-frontiers/scion-pstack` and pinned `cursor/plugins@bf0c7cd8` GitHub URLs.
- Setup & mode mechanics: adapted `/add-plugin`, `~/.cursor/rules/pstack-models.mdc`, Custom Modes, `subagent_type: "poteto-agent"`, and `/loop` to Scion `pstack-lead`, `pstack-models.yaml` in the shared store, `pstack-agent`, `scion schedule` / background watchers, and `pstack-scion-runtime`.
- Skill table: removed dropped `ketchup-video` and `make-bot-ui` rows and added `pstack-scion-runtime`.
- `references/prompting.md` & `references/recipes.md`: preserved almost verbatim, changing only `/loop` and worktree wording in the "Before stepping away" / "Away and back" items.
