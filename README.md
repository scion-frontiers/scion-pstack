# scion-pstack

A port of [pstack](https://github.com/cursor/plugins/tree/main/pstack), a Cursor plugin, to a [Scion](https://github.com/GoogleCloudPlatform/scion) agent team. The upstream snapshot is pinned at `cursor/plugins@5ff7a35`.

## Team

| Template | Role |
|---|---|
| `pstack-lead` | The entry point. poteto-mode is always on. It routes each human message to a playbook, delegates, reviews, and replies. |
| `pstack-agent` | A worker driven by a brief: code delegate, PR owner, arena candidate, stacker, or babysitter. |
| `pstack-reviewer` | A read-only panel member (interrogate, architect, arena judge, verifier). Its vendor is chosen per spawn. |
| `pstack-comment-sicko` | The comment hunter behind `no-comments`. It commits only on its own `<branch>-sicko` branch. |

## Layout

- `upstream/`: SHA-pinned snapshots of `pstack` and `cursor-team-kit` (MIT, license included).
- `skills/`: adapted forks. Each has a `PORT-NOTES.md` beside it. `pstack-scion-runtime` is the port's contract, mapping every Cursor primitive to its Scion equivalent.
- `templates/<role>/`: the Scion templates, ready to use. Each has `agents.md` (the role instructions) and `scion-agent.yaml`. The yaml references every skill by URI: adapted skills as `gh://scion-frontiers/scion-pstack/<name>`, and unchanged upstream and team-kit skills as tree URIs pinned to `cursor/plugins@5ff7a35`. Exception: Scion's GitHub skill resolver drops subdirectories, so skills with nested files (poteto-mode, why, how, interrogate, reflect, architect, create-verification-skill, show-me-your-work, typescript-best-practices) are also committed as local copies in `templates/<role>/skills/`. Don't edit those copies. Edit `skills/` and re-run `build.sh`. No template carries a `system-prompt.md`, so the harness default prompt stays in place.
- `build.sh`: regenerates `templates/*/scion-agent.yaml` and the local skill copies from the per-role skill sets. `--check` fails if the committed files are stale. `--bundle DIR` writes self-contained templates with every skill copied locally, for hubs that cannot reach GitHub.
- `diffs/`: each fork's diff against upstream.
- `DESIGN.md` and `LEARNINGS.md`: the decisions made and the lessons learned (L1 to L58). The general porting meta-skills distilled from them live separately, with Scion.

## Use

```bash
cp -r templates/* <project>/.scion/templates/
scion templates sync pstack-lead                # repeat for each template
scion start my-lead --type pstack-lead "<request>"
```

This repo is private, so the hub resolving the `gh://scion-frontiers/scion-pstack/...` URIs needs GitHub credentials that can read it. If yours cannot, append `?token=<SECRET_NAME>` to those URIs, or use `bash build.sh --bundle DIR` and copy from `DIR` instead.

Prerequisites: a mounted shared dir, or `PSTACK_STORE` set, for the pstack store. Run `setup-pstack` once through the lead to write `pstack-models.yaml`. It test-starts each harness-config and records which ones can run.
