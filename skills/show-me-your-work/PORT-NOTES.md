# show-me-your-work: port notes

Upstream: `upstream/pstack-bf0c7cd/skills/show-me-your-work/` (v0.15.42). `scripts/log.sh` and `references/decision-log-template.tsv` are verbatim.

## Changed
- Frontmatter: dropped `disable-model-invocation: true` (routed by name per **pstack-scion-runtime** §5).
- Helper invoked via `bash scripts/log.sh` (URI-delivered skills do not preserve executable bits).
- Default trail location: `<store-root>/<program-slug>/decisions.tsv` (**pstack-scion-runtime** §4) so cross-container reviewers and replacement leads can read it, keeping work dir / `.audit/` as the no-store fallback.
- Transcript audit: `agent-transcripts/` replaced with **pstack-scion-runtime** §2 sources (preferring `scion look <agent> --full --plain` over `scion logs <agent>`) while preserving upstream's `phase: start` stretch rule and append-only supersede-never-delete audit contract.
- Cross-model review: `pstack-reviewer` Scion agent on a different vendor (**pstack-scion-runtime** §1), reporting `reviewed by <harness-config>/<model>`.
