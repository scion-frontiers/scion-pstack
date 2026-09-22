# show-me-your-work: port notes

Upstream: `pstack/skills/show-me-your-work` at 5ff7a35. `scripts/log.sh` and `references/` unchanged (log.sh has no host paths).

## Changed
- Dropped `disable-model-invocation: true`; the lead and other playbooks route here by name (runtime §5).
- Helper invoked as `bash scripts/log.sh` (URI-delivered skills lose the exec bit; DESIGN "Skill delivery").
- Default trail location: work dir → `<store-root>/<program-slug>/decisions.tsv` so the cross-vendor reviewer and a replacement lead can read it. Work dir / `.audit/` kept as the no-store fallback. Committing now means copying into the repo, since the store stays out of commits.
- "Read this run's transcript under agent-transcripts/" → rebuild the run from runtime §2 sources: request conversation, worker REPORTs and inbox files, `scion logs` (lead included), branches/PRs. The workspace-boundary rule becomes "stay inside this program's agents and conversations".
- Cross-model review: "subagent on a different model family" → a `pstack-reviewer` Scion agent on a different-vendor harness-config; brief points at store/conv/branch refs; report comes back by message. In-harness subagent on your own model explicitly ruled out.
- Attention header: `reviewed by <model>` → `reviewed by <harness-config>/<model>`.

## Unresolved
- The lead's own actions are only recoverable from `scion logs <lead>` (terminal scrollback, default tail 100) or its harness-native session file inside its container. Neither is a durable transcript. The audit is weaker than upstream's; the trail must be written as the run happens.
- The heading "Audit the log against the transcript" is kept for diff size although there is no transcript file.
