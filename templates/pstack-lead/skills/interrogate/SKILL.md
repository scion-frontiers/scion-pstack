---
name: interrogate
description: "Use for \"interrogate\", \"adversarial review\", \"multi-model review\", \"challenge this\", \"stress test this code\", \"find blind spots\", or \"tear this apart\". Multiple LLM reviewers challenge changes from independent angles."
---

# Interrogate

Spawn one reviewer per configured model to adversarially review code changes. Each model gets the same prompt and rubric. The adversarial signal comes from model diversity, not assigned personas.

The deliverable is a synthesized verdict. Do NOT auto-apply changes.

## Step 1, Determine Scope

Identify what to review from context:

- If the user points at specific files or a diff, use that
- If on a feature branch, run `git diff main...HEAD` (or the appropriate base branch) for the full changeset
- If the user's message references recent work, gather the relevant files

Package the diff (or file contents) plus any surrounding context files the reviewers need to understand the code. Reviewers run in their own clones, so package it as something they can reach: a pushed branch plus base SHA, a PR URL, or the diff written to the pstack store (see `pstack-scion-runtime` §1, "File pointers").

## Step 2, State the Intent

Before spawning reviewers, state the intent explicitly. Derive this from:

- The user's message
- Commit messages
- PR description if one exists
- The code itself

Write one clear paragraph. If you're unsure about the intent, ask the user before proceeding.

## Step 3, Spawn Reviewers

Launch all reviewers at once as Scion agents. Model diversity is the point, so this is the Scion-agent tier, never in-harness subagents (see `pstack-scion-runtime` §1 for spawn mechanics). Start one `pstack-reviewer` per entry in `panels.interrogate` of `pstack-models.yaml`, or per entry of the runtime's default panel when the file or key is absent. Label them Reviewer A, B, C, D, extending or shrinking the labels to the entry count.

For each reviewer:
- template: `pstack-reviewer`
- harness-config and model: the panel entry
- readonly: the runtime's readonly brief clause

If a panel entry's harness-config is not in `scion harness-config list`, substitute per `pstack-scion-runtime` §3 (nearest available from another vendor), note the substitution in the verdict, and propose the `pstack-models.yaml` update separately. Do not block the review on the config issue. If the entry is `inherit`, omit `--harness-config` and `--model` so that reviewer runs on your own harness and model. Never treat `inherit` as a broken entry or enter this fallback for it.

Read `references/reviewer-prompt.md` and fill in the template with:
1. The stated intent
2. The diff or file contents
3. The review rubric from `references/rubric.md`
4. The code-quality lens from `references/code-quality-review.md`

The same filled template goes to all reviewers, so every model applies the code-quality lens. End each brief with the runtime's report line so findings come back as a REPORT message to you.

## Step 4, Synthesize

As REPORT messages come back, build a unified picture:

1. **Parse all findings** from the reviewers
2. **Identify consensus**. Findings raised by 2+ models independently are highest signal.
3. **Identify lone-model findings**. Still worth reading, but weight accordingly.
4. **Deduplicate**. Different models may describe the same issue differently. Merge these and note which models raised it.
5. **Note disagreements**. If one model flags something and another explicitly says the opposite, that's useful context for the verdict.

## Step 5, Lead Judgment

You are the lead reviewer, a pragmatic senior engineer, not a neutral aggregator.

Read `references/lead-judgment.md` for the full framework.

Categorize every finding using these buckets:

- **Act on**. Real issues affecting correctness, security, or maintainability given the actual goals. These would block a real PR.
- **Consider**. Legitimate points, but you're not sure they outweigh the cost of addressing them right now. Worth the user's attention.
- **Noted**. Technically valid but not actionable. Context-dependent, premature optimization, or low-impact given the current stage.
- **Dismissed**. Wrong, nitpicky, or missing context. Brief explanation why.

For each finding, include:
- Which model(s) raised it
- The category (act on / consider / noted / dismissed)
- A one-line rationale for the categorization

## Output Format

Present the verdict in this structure:

### Intent
> [The stated intent paragraph from Step 2]

### Reviewers
- Reviewer [label]: [harness-config and model], [N findings] (one bullet per reviewer)

### Act On
[Findings that should be addressed. For each: description, which models raised it, why it matters.]

### Consider
[Findings worth thinking about. For each: description, which models raised it, tradeoff involved.]

### Noted
[Valid but low-priority. Brief list.]

### Dismissed
[Rejected findings with brief rationale.]

### Agreement Map
[Where did models agree, where did they diverge, and what does the pattern of agreement/disagreement tell us?]
