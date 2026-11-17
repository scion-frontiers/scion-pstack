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
- `build.sh`: regenerates `templates/*/scion-agent.yaml` from the per-role skill sets. `--check` fails if `templates/*/scion-agent.yaml` are stale, if any `templates/*/skills/` directory exists, or if a full `--bundle` check fails. `--bundle DIR` writes self-contained templates with every skill copied locally (excluding `PORT-NOTES.md`, `node_modules`, and `scripts/test`), for Hubs without GitHub access.
- `diffs/`: each fork's diff against upstream.
- `DESIGN.md` and `LEARNINGS.md`: the decisions made and the lessons learned (L1 to L65). The general porting meta-skills distilled from them live separately, with Scion.

## Use

Committed templates reference public GitHub skill URIs (`gh://scion-frontiers/scion-pstack/...` and `cursor/plugins@bf0c7cd`), so Scion Hubs resolve them directly with no GitHub token or Hub secret required.

### Import from GitHub URL (Web UI or CLI)

You can import all four templates directly from the repository URL without cloning `scion-pstack`:

- **Web UI:** In **Project Settings → Resources → Templates** (or **Settings → Templates** for global/user scope), select **Import from URL**, enter `https://github.com/scion-frontiers/scion-pstack/tree/main/templates`, and click **Import Templates**. Imported templates retain their source URL and can be refreshed later via **Refresh from Source** (or `scion templates update --all`).
- **CLI:** Import the `templates` directory from GitHub into your Scion project and sync to the Hub:

```bash
scion templates import --all https://github.com/scion-frontiers/scion-pstack/tree/main/templates
for t in pstack-lead pstack-agent pstack-reviewer pstack-comment-sicko; do
  scion templates sync "$t"
done
scion start my-lead --type pstack-lead "<request>"
```

### Sync from a local checkout

If you have a local clone of `scion-pstack`, copy (or `scion templates import --all ./templates`) and sync the templates:

```bash
cp -r templates/* <project>/.scion/templates/
for t in pstack-lead pstack-agent pstack-reviewer pstack-comment-sicko; do
  scion templates sync "$t"
done
scion start my-lead --type pstack-lead "<request>"
```

### Offline fallback: self-contained `--bundle`

If your Hub cannot reach GitHub to resolve external `skills:` URIs, bundle every skill locally (stripping external `skills:` URIs) and sync the bundled templates instead:

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
