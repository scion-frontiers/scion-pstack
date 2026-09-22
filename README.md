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
- `templates-src/<role>/agents.md`: the per-role instructions.
- `build.sh`: assembles `templates/`. Adapted skills are copied in as local files. Unchanged upstream skills are referenced by SHA-pinned GitHub URI (`--vendor` copies them instead).
- `diffs/`: each fork's diff against upstream.
- `DESIGN.md` and `LEARNINGS.md`: the decisions made and the lessons learned (L1 to L55). The general porting meta-skills distilled from them live separately, with Scion.

## Use

```bash
bash build.sh                                   # writes templates/
cp -r templates/* <project>/.scion/templates/
scion templates sync pstack-lead                # repeat for each template
scion start my-lead --type pstack-lead "<request>"
```

Prerequisites: a mounted shared dir, or `PSTACK_STORE` set, for the pstack store. Run `setup-pstack` once through the lead to write `pstack-models.yaml`. It test-starts each harness-config and records which ones can run.
