# create-formal-verification-skill: port notes

Upstream: `upstream/pstack-bf0c7cd/skills/create-formal-verification-skill/` (v0.15.42).

## Changed
- Frontmatter: dropped `disable-model-invocation: true` (routed by name per **pstack-scion-runtime** §5 and offered by `setup-pstack` step 8).
- Output path & helpers: `.scion/skills/<name>/SKILL.md` with explicit interpreter invocation (`bash`/`node`/`bun`) since URI delivery strips executable bits (**pstack-scion-runtime** §2).
- `/statechart` pointer: added one-line cross-reference to **pstack-scion-runtime** §2 (`java` prerequisite check, shared-store `--out` path, and `--view` trust boundary).
- Delivery: added explicit Scion skill-delivery reminder (`scion project skills add` URI vs `.scion/templates/<role>/skills/` + `scion templates sync`, **pstack-scion-runtime** §2).
