# maintain-formal-verification-skill: port notes

Upstream: `upstream/pstack-bf0c7cd/skills/maintain-formal-verification-skill/` (v0.15.42).

## Changed
- Frontmatter: dropped `disable-model-invocation: true` (routed by name per **pstack-scion-runtime** §5).
- Edit scope & Pass steps 1, 6: target `.scion/skills/<name>/` in the repo (never provisioned copies under `$HOME/.*/skills/`), noting `scion templates sync` or URI ref updates when skill text changes (**pstack-scion-runtime** §2).
