---
name: how
description: "Use for \"how does X work\", code walkthroughs before changing something, and placement / ownership / layering questions (\"where should this live\", \"which package owns this\", \"is this the right layer\"). Explains subsystem architecture, runtime flow, onboarding mental models. Use why for motivation."
---

# How

Explore the codebase to answer "how does X work?" questions. Produce architectural explanations at the level of a senior engineer onboarding onto a subsystem, enough to build a working mental model, not so much that it reads like annotated source code.

## Step 1. Assess Complexity

If the scope is ambiguous, state your interpretation and explore. The user can redirect.

- **Simple** (a single module, a small utility, a narrow question such as "how does function X work"): no explorers. One explainer explores and explains in a single pass. Go to Step 2b.
- **Complex** (a subsystem spanning multiple files or services, a cross-cutting feature, a full architectural overview): spawn parallel explorers first, then hand off to the explainer. Go to Step 2a.

When in doubt, take the simple path.

## Step 2a. Explore (complex questions only)

Decompose the question into 2 to 4 exploration angles, each a distinct slice of the subsystem. Spawn all explorers at once:

- tier: in-harness subagents (read-only, single family). When `roles.how-explorer` in `pstack-models.yaml` names a harness other than yours, start `pstack-reviewer` Scion agents on it instead (`pstack-scion-runtime` §1).
- model: `roles.how-explorer` (default `inherit`, your own model)
- readonly: `true` (a brief clause for Scion agents)

Each explorer gets the prompt in `references/explorer-prompt.md` with its angle filled in. Then go to Step 3.

## Step 2b. Direct Explain (simple questions)

Spawn one subagent that explores and explains in one pass:

- tier: in-harness subagent when `roles.judgment` resolves to your own harness, otherwise one `pstack-reviewer` Scion agent on it
- model: `roles.judgment` (the how-explainer role)
- readonly: `true` (a brief clause for Scion agents)

Build its prompt from `references/explainer-prompt.md` without the explorer-findings section. A Scion-agent explainer also needs the branch and SHA to read. Go to Step 4.

## Step 3. Synthesize (complex questions only)

Once all explorers have returned, spawn one subagent to synthesize their findings into one explanation:

- tier: in-harness subagent when `roles.judgment` resolves to your own harness, otherwise one `pstack-reviewer` Scion agent on it
- model: `roles.judgment` (the how-explainer role)
- readonly: `true` (a brief clause for Scion agents)

Build its prompt from `references/explainer-prompt.md` with every explorer's findings filled in. A Scion-agent explainer reads code in its own clone, so give it the branch and SHA you explored, and write long findings to the pstack store rather than inlining them.

## Step 4. Present

Present the explainer's output to the user. Light edits for clarity or context from the conversation are fine. Do not substantially rewrite it.

## Output Format

The explanation uses the sections defined in `references/explainer-prompt.md`, dropping any that do not apply: Overview, Key Concepts, How It Works, Where Things Live, Gotchas.
