# reflect: port notes

Upstream: `upstream/pstack-bf0c7cd/skills/reflect/` (v0.15.42). `references/synthesizer.md` is verbatim.

## Changed
- Frontmatter: dropped `disable-model-invocation: true` (routed by name per **pstack-scion-runtime** §5).
- Step 1: `agent-transcripts/` discovery became **pstack-scion-runtime** §2's ordered sources (local harness session log if readable, trail/`notes.md`, `scion conversation`, `scion look --full --plain` / `scion logs`), written to `<store>/<program-slug>/reflect/transcript.md`.
- Steps 2 & 3: `Task` calls and `pstack-models.mdc` roles became `roles.reflect-judgment` (`judgment`) and `roles.reflect-tooling` in `pstack-models.yaml` (defaulting every lens to `inherit` when `<store>/pstack-models.yaml` is missing per **pstack-scion-runtime** §3), using `pstack-reviewer` Scion agents when the harness differs from the caller's.
- Step 5: approval uses runtime §2/`§5` (>2000-char table stored if needed); upstream `#800`'s `plugins/cache/` guard translated to never editing provisioned copies under `$HOME/.*/skills/` and writing to `.scion/skills/<skill>/` (or template/repo source); `create-skill` mapped to `poteto-mode`'s authoring-a-skill playbook.
- Step 6: kept the "Transcript source" bullet required by runtime §2.
- `references/{divergent,judgment,tooling}-reviewer.md`: single-sentence adaptation of `.cursor/skills/` + `Task` prompt paths to template skills, `.scion/skills/`, harness skill dirs, and subagent/`scion start` briefs.
