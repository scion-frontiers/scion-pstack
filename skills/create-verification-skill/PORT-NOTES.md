# create-verification-skill: port notes

Upstream: `upstream/pstack-bf0c7cd/skills/create-verification-skill/` (v0.15.42). `references/feature-map-example/` is verbatim.

## Changed
- Frontmatter: dropped `disable-model-invocation: true` (routed by name per **pstack-scion-runtime** §5 and offered by `setup-pstack` step 7).
- Output path: `.cursor/skills/verify-<app>/` → `.scion/skills/verify-<app>/` (**pstack-scion-runtime** §2).
- Helpers & Cleanup: helper scripts invoked explicitly (`bash <file>`, `node <file>`, `bun <file>`) since URI delivery strips executable bits; proof evidence saved to the pstack store (**pstack-scion-runtime** §4) so it survives container teardown.
- Step 4 delivery: added explicit Scion skill-delivery reminder (`scion project skills add` URI vs `.scion/templates/<role>/skills/` + `scion templates sync`, **pstack-scion-runtime** §2).
- Step 5: `/maintain-verification-skill` → **maintain-verification-skill** by name.
