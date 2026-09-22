---
name: reflect
description: Spawn three parallel review subagents over the active transcript, surface learnings, and route each to a concrete edit on an existing skill. Use when the user says reflect.
---

# Reflect

Mine the current conversation for durable learnings, then route them into skill edits.

## When to invoke

Invoke when the user says "reflect" or "/reflect". Skip when the conversation is trivial, off-topic, or already covered by an existing skill the parent followed correctly. One-offs are not learnings.

## Process

### 1. Locate the active transcript

The parent assembles its own transcript before fanning out. Scion has no `agent-transcripts/` store, so use the sources in `pstack-scion-runtime` §2 (`agent-transcripts/` row), in order: your trail file, `scion conversation` history for this request, then `scion logs` / `scion look` for the agents you delegated to. Stay inside this session's conversation and agents. Do not pull other programs' conversations or logs. That crosses workspace boundaries and reads private chats from unrelated projects.

Write the result, with a tight digest of the session on top, to `<store>/<program-slug>/reflect/transcript.md` in the pstack store, so reviewers in other containers can read it, and pass that absolute path. If none of the sources resolves, write the digest alone and pass that instead. Name the sources you used in step 6.

### 2. Spawn three reviewers in parallel

Launch all three at once, each on its configured role from `pstack-models.yaml`. The lenses differ by model family, so a lens whose role names a harness other than yours is a `pstack-reviewer` Scion agent. A lens on your own harness may be an in-harness subagent (`pstack-scion-runtime` §1). With the defaults, Tooling is a Scion agent. Reviewers need MCP access for context lookups (tickets, chat threads, observability traces referenced in the transcript), and they write nothing, which the brief states. A Scion-agent reviewer has only its template's MCP servers.

| Lens | role | Prompt template |
|---|---|---|
| Judgment | `roles.judgment` | `references/judgment-reviewer.md` |
| Tooling | `roles.reflect-tooling` | `references/tooling-reviewer.md` |
| Divergent | `roles.judgment` | `references/divergent-reviewer.md` |

Pass each template verbatim, substituting the transcript path or digest where marked. Scion-agent reviewers return findings as a REPORT message to you. In-harness reviewers return them in their response.

### 3. Synthesize

One subagent on `roles.judgment`: in-harness when that role resolves to your own harness, otherwise a `pstack-reviewer` Scion agent. It writes nothing, but keeps MCP access: the synthesizer's quality check includes spot-verifying citations, which can require MCP access. Use `references/synthesizer.md` verbatim, with each reviewer's full output inlined where marked. The synthesizer returns a structured Accepted / Rejected / Backlog list.

### 4. Structural enforcement check

Sanity-check the synthesizer's Accepted list. For any item that would be enforced more reliably by a lint rule, script, metadata flag, or runtime check, move it from Accepted to Backlog. See the **encode-lessons-in-structure** principle skill.

### 5. Apply

Before applying any Accepted edit, present the synthesizer's full Accepted/Rejected/Backlog output to the user and wait for explicit approval (ask per `pstack-scion-runtime` §2 and §5; put the full table in the store if it exceeds a message). The user picks which subset to apply and may redirect routings. Skill changes affect every future agent in the org. Do not auto-apply.

Backlog items file to whatever devex / backlog tracker your team uses automatically. Only the Accepted list waits for approval.

For each approved Accepted item, follow the Routing field exactly:

- Trivial existing-skill edit (a one-line bullet, a tightened sentence, a stale fact corrected): parent does directly.
- Substantive existing-skill edit (a new section, a new pattern table, more than ~10 lines): follow poteto-mode's authoring-a-skill playbook, which stands in for Cursor's built-in `create-skill` (`pstack-scion-runtime` §2).
- `tune description: <skill path>` (the skill exists but didn't trigger when it should have): follow the authoring-a-skill playbook, rewriting the description around the triggers the session missed.
- `new skill via create-skill: <kebab-name>`: create it via the authoring-a-skill playbook. Do not invent the shape ad hoc.

If your environment ships a SKILL.md validator, run it on every touched skill before declaring done. Skip this step if it doesn't.

### 6. Summarize for the user

Short list, no preamble:

- Edits applied: `<skill path>`. What changed, one line each.
- New skills created: `<skill path>`. One line each (rare).
- Backlog filed to the devex tracker: `<issue title>` (`<tags>`). One line each.
- Dropped: one line per rejected finding + reason from the synthesizer.
- Transcript source: which step 1 sources fed the review.
