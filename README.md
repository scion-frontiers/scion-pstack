# scion-pstack

A port of [pstack](https://github.com/cursor/plugins/tree/main/pstack), a Cursor plugin, to a [Scion](https://github.com/GoogleCloudPlatform/scion) agent team. The upstream snapshot is pinned at `cursor/plugins@bf0c7cd` (v0.15.42).

## Team

| Template | Role |
|---|---|
| `pstack-lead` | The entry point. poteto-mode is always on. It routes each human message to a playbook, delegates, reviews, and replies. |
| `pstack-agent` | A worker driven by a brief: code delegate, PR owner, arena candidate, stacker, or babysitter. |
| `pstack-reviewer` | A read-only panel member (interrogate, architect, arena judge, verifier). Its vendor is chosen per spawn. |
| `pstack-comment-sicko` | The comment hunter behind `no-comments`. It commits only on its own `<branch>-sicko` branch. |

## Layout

- `upstream/`: SHA-pinned snapshots of `pstack` and `cursor-team-kit` (`bf0c7cd`, MIT, license included).
- `skills/`: adapted forks. Each has a `PORT-NOTES.md` beside it. `pstack-scion-runtime` is the port's contract, mapping every Cursor primitive to its Scion equivalent.
- `templates/<role>/`: the Scion templates, ready to use (requires Scion `v0.3.26+` for recursive GitHub skill directory resolution). Each has `agents.md` (the role instructions) and `scion-agent.yaml`. The yaml references every skill by URI: adapted skills as `gh://scion-frontiers/scion-pstack/<name>`, and unchanged upstream and team-kit skills as tree URIs pinned to `cursor/plugins@bf0c7cd`. No template carries local `skills/` copies or a `system-prompt.md`, so the harness default prompt stays in place.
- `build.sh`: regenerates `templates/*/scion-agent.yaml` from the per-role skill sets. `--check` fails if `templates/*/scion-agent.yaml` are stale, if any `templates/*/skills/` directory exists, or if a full `--bundle` check fails. `--bundle DIR` writes self-contained templates with every skill copied locally (excluding `PORT-NOTES.md`, `node_modules`, and `scripts/test`), for hubs without GitHub access or private-repo credentials.
- `diffs/`: each fork's diff against upstream.
- `DESIGN.md` and `LEARNINGS.md`: the decisions made and the lessons learned (L1 to L65). The general porting meta-skills distilled from them live separately, with Scion.

## Use

### Prerequisite: project-scope `GH_SCION_FRONTIERS`

Committed templates reference adapted skills via private `gh://scion-frontiers/scion-pstack/...` URIs. Scion's Hub resolves template skill URIs using **project-scope** credentials only — a **user-scope** secret is injected into agent containers at runtime but ignored during template skill resolution (causing `skill_resolution_failed` 404s at start). Set `GH_SCION_FRONTIERS` (or `GH_SCION_FRONTIERS__SCION_PSTACK`) at **project scope** before syncing URI templates:

```bash
# Host / admin CLI:
scion hub secret set --project GH_SCION_FRONTIERS <PAT>

# Or from inside a running role=full agent (defaults to project scope):
sciontool secret set GH_SCION_FRONTIERS <PAT>
```

Then copy and sync all four templates:

```bash
cp -r templates/* <project>/.scion/templates/
for t in pstack-lead pstack-agent pstack-reviewer pstack-comment-sicko; do
  scion templates sync "$t"
done
scion start my-lead --type pstack-lead "<request>"
```

### Fallback: self-contained `--bundle` (no private-repo secret on Hub)

If your Hub cannot read `scion-frontiers/scion-pstack` and you cannot set a project-scope secret, bundle every skill locally (stripping external `skills:` URIs) and sync the bundled templates instead:

```bash
bash build.sh --bundle /tmp/pstack-bundle
rm -rf <project>/.scion/templates/pstack-*
cp -r /tmp/pstack-bundle/* <project>/.scion/templates/
for t in pstack-lead pstack-agent pstack-reviewer pstack-comment-sicko; do
  scion templates sync "$t"
done
scion start my-lead --type pstack-lead "<request>"
```

### Runtime store & model preflight

Mount a project shared dir (for example `/scion-volumes/scratchpad`), or set `PSTACK_STORE`, for the pstack store. Run `setup-pstack` once through the lead to write `pstack-models.yaml`; it test-starts each harness-config and records which ones can run.
