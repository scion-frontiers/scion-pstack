---
name: no-comments
description: "Spawn Comment Sicko, fix accepted findings, and offer encodings for claimed constraints."
---

# No comments

Spawn Comment Sicko. Act on accepted findings.

Defer to Comment Sicko's fresh perspective.

## Scope

Use the caller's files or diff. Otherwise use the current diff against the base branch, default `main`, including the working tree.

Before pushing or spawning, check the scoped lines (all lines in caller-named files, or added `+` lines in the scoped diff excluding `+++` headers) for any comment or suppression syntax, including trailing inline comments (`//`, `/*`, `#`, `<!--`, `--`, `eslint-disable`, `@ts-ignore`, `@ts-expect-error`). Never check leading-comment lines alone, or inline workaround comments slip past. If `0` lines match, report `0 deletions` and stop without spawning `pstack-comment-sicko`.

Comment Sicko runs in its own clone and cannot see yours. Commit the scope (working tree included) and push it to a branch first. The scope you pass is that branch, its SHA, and the base, plus the file list when the caller named files.

## Steps

1. Spawn a `pstack-comment-sicko` Scion agent with `--role baseline` (**pstack-scion-runtime** §1). Pass the scope ref, and tell it: when it makes edits, push them as one commit on its own branch off that SHA (`<branch>-sicko`); when it makes `0` edits, push no branch and no empty commit, reporting `0 deletions` (plus any `MUST KILL` flags or skips) via `inbox/` and `scion message` only. Pick each subagent's reasoning level and fast or standard speed for the job, per the Subagents section of the **poteto-mode** skill. Do not restate its rules.
2. Inspect its report, and when it pushed `<its-branch>`, its diff (`git fetch origin <its-branch> && git diff <scope-sha>...origin/<its-branch>`; when `0` edits were made and no branch was pushed, inspect the scoped code directly against its report). Reject application-code edits, scope escapes, exception-protected deletions, misstated `MUST KILL` reasons, and flags that treat kept intentional code as guilty. Reshape flags on our-code surprises stay actionable. Do not restore those comments. A keep survives only with proof it is about something we cannot change. Audit missed scoped lint and TypeScript suppressions. Correctness or safety suppressions stay actionable `MUST KILL`s. Restore deletions only with exact exceptions and scoped proof. Before accepting thin `IMPORTANT` or `do not remove` kills or keeps, trace their symbol or run `/why` on it. If a kill is ambiguous, do not restore. If a keep is refuted or still ambiguous, delete it. Take only the accepted hunks onto your branch. Rerun one rejected report on a fresh agent with the failure named. Reject a second, report it open, and fail `/no-comments`.
3. Fix trivial accepted flags directly by deleting a dead path, dropping a parameter, or using the real API. If any fix needs a shape, run `/architect` once for the accepted set and surrounding code. Stop at the sketch. Architect shapes. Step 4 implements.
4. Implement the smallest root-cause fix in scope. Remove every named workaround. If the root cause is out of scope, land the smallest in-scope fix and report the rest open. The **principle-fix-root-causes** and **principle-redesign-from-first-principles** skills guide intent only. Neither authorizes widening the fence nor fixing instances outside it. Never bolt on symptom guards.
5. Constraint comments say `do not remove`, `do not change wording`, or `talk to X before changing`. Leave keeps about things we cannot change. Offer the cheapest in-scope type, runtime, test, or CI lint. Wait for interactive approval. Unattended and eval require caller pre-approval. If approved, encode then delete. Otherwise delete, report the constraint open, and sketch out-of-scope work.
6. Report the deletion count, restored comments, reruns, architect sketch, fixes, encoding offers, encodings, unenforced constraints, and other open work.
