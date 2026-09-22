# interrogate: port notes

Upstream: `pstack/skills/interrogate` at 5ff7a35. References are verbatim.

## Changed
- Frontmatter: dropped `disable-model-invocation: true` (Cursor-only). Intent was "run only when the user explicitly asks". On Scion the lead routes to it when the human names it (`pstack-scion-runtime` §5); the description already carries the trigger phrases.
- Step 1: the reviewers can't see the lead's working tree, so the scope must be a pushed branch plus base SHA, a PR URL, or a diff in the pstack store.
- Step 3: `Task` + `subagent_type` + `readonly` + model-slug table became "one `pstack-reviewer` Scion agent per entry in `panels.interrogate`". **Tier: Scion agent, always.** Model diversity is the whole point, and in-harness subagents are single-vendor.
- Slug-rejected fallback became "harness-config not in `scion harness-config list`" → substitute from another vendor (runtime §3), note it, propose a `pstack-models.yaml` update. Upstream said "open a separate PR", but the config no longer lives in a repo.
- `inherit-parent` / `auto` became the runtime's single `inherit` alias (omit `--harness-config`/`--model`).
- Results arrive as REPORT messages, not Task results. The report line comes from the runtime's brief rule.
- Output: "model name" became "harness-config and model".

## Not ported cleanly
- Cost and latency: four containers per review instead of four in-process calls. No budget knob exists yet (`budget:` sits in the yaml but nothing reads it).
- Readonly is only a brief clause. A reviewer could still push. The template repeats the rule, but nothing enforces it.

## Open questions
- Should a small diff be inlined into the brief (fast) instead of pushed (always reachable)? Right now the lead decides, per the runtime's "paste only when small".
