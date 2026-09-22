# Trials

Dogfood runs, where the ported team is pointed at the port itself. Each directory is the pstack store folder for one run, copied as the lead left it. Folder names follow the runtime's ad-hoc naming, `adhoc-<yyyymmdd>-<topic>`.

## adhoc-20260922-check-plan-interrogate

A `pstack-lead` agent (claude) ran the **interrogate** skill on the port's own diff of `poteto-mode/scripts/check-plan.mjs` and `playbooks/multi-phase-plan.md`. It spawned `pstack-reviewer` agents as the panel, and it built a mutation corpus that compares the upstream and ported validators.

- **Verdict: not yet acceptable.** It found two issues to act on. First, a validator marker change silently dropped a check. Second, lane screenshots were still saved to container-local `/tmp`. Both are fixed in the initial commit, along with the smaller Consider and Noted items. `skills/poteto-mode/scripts/check-plan.test.ts` holds the negative fixtures that came out of it.
- **Port friction** (end of `verdict.md`): only claude could start agents in this project, so the panel was single-vendor. A 31 KB inline brief crashed 5 of 5 reviewers. One reviewer's report message was lost. `shared-dir list` did not show the mounted store. Each of these became a rule in `pstack-scion-runtime` (see LEARNINGS L43 to L51).

| File | What it is |
|---|---|
| `intent.md` | The stated intent the diff was judged against |
| `check-plan-port.diff` | The diff under review |
| `briefs/` | The lead's reviewer briefs. Most are failed vendor substitutions: codex, gemini, grok-build, hermes, copilot, opencode, and muse-code could not start |
| `inbox/` | Reviewer reports. Reviewer A's was recovered from terminal scrollback after its message was lost |
| `skeletons/`, `corpus.sh`, `corpus.tsv` | 25 plan mutations run through both validators. `corpus.sh` hard-codes the lead's paths (`/tmp/cp`, `/scion-volumes/...`), so it is a record, not a runnable test |
| `verdict.md` | The long-form verdict |
| `reply-sent.txt` | The short message the lead sent back |
