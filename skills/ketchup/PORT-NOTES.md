# ketchup: port notes

Upstream: `upstream/pstack-bf0c7cd/skills/ketchup/` (v0.15.42).

## Changed
- Frontmatter: dropped `disable-model-invocation: true` (routed by name per **pstack-scion-runtime** §5 and invoked by `autopilot-full`).
- Gather what changed: points at `notes.md`, trail, `scion conversation` history, and child `inbox/` / `verdicts/` files (**pstack-scion-runtime** §2, §4).
- >2000-char human message cap: preserves the never-cut-items rule while routing >2000-char full waiting sheets to `/scion-volumes/...` or `scion artifact publish` (`scion://artifact/<id>` plain text outside backticks, **pstack-scion-runtime** §2).
- Visuals: drops uninstalled `/visualize` references (`ketchup-video` is also dropped on Scion) and routes screenshots/videos through `/scion-volumes/...` or `scion artifact publish` alongside inline Mermaid diagrams.
