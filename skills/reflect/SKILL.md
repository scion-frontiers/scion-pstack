---
name: reflect
description: Spawn three parallel review subagents over the active transcript, surface learnings, and route each to a concrete edit on an existing skill. Use when the user says reflect.
---

# Reflect

Mine the current conversation for durable learnings, then route them into skill edits.

Invoke when the user says "reflect" or "/reflect". Skip when the conversation is trivial, off-topic, or already covered by an existing skill the parent followed correctly. One-offs are not learnings.

## 1. Locate the active transcript

Before fanning out, assemble this session's transcript from the sources in **pstack-scion-runtime** §2 (`agent-transcripts/` row), in order: your own harness's local session log if readable inside your container, your trail file (`decisions.tsv`) and `notes.md`, `scion conversation` history for this request, and `scion look <agent> --full --plain` (or `scion logs <agent>` when available) for the agents you delegated to. Stay inside this session's conversation and agents. Do not pull other projects' conversations or logs. That crosses project boundaries and reads private threads.

Write the assembled record, with a tight digest of the session on top, to `<store>/<program-slug>/reflect/transcript.md` in the pstack store so reviewers in other containers can read it, and pass that path. If none of the sources resolves, pass a tight digest of the session instead.

## 2. Spawn three reviewers in parallel

Launch all three at once, each on its configured role in `pstack-models.yaml` (**pstack-scion-runtime** §3; when `<store>/pstack-models.yaml` is missing, every lens defaults to `inherit` so unpreflighted harnesses are never spawned). When a lens's harness differs from yours, start a `pstack-reviewer` Scion agent; when it resolves to your own harness (including `inherit`), an in-harness subagent is allowed (**pstack-scion-runtime** §1). Reviewers keep MCP access to look up the tickets, chat threads, and observability traces the transcript references, and write nothing (a Scion-agent reviewer has its template's MCP servers). Substitute unavailable harnesses per **pstack-scion-runtime** §3 and pick each reviewer's reasoning level per the Subagents section of the **poteto-mode** skill.

| Lens | Role key | `# defaults: 2` target (when preflighted; `inherit` if `pstack-models.yaml` is missing) | Prompt template |
|---|---|---|---|
| Judgment | `roles.reflect-judgment` (`judgment`) | `{harness: claude, model: extra-large}` | `references/judgment-reviewer.md` |
| Tooling | `roles.reflect-tooling` | `{harness: codex, model: extra-large}` | `references/tooling-reviewer.md` |
| Divergent | `roles.reflect-judgment` (`judgment`) | `{harness: claude, model: extra-large}` | `references/divergent-reviewer.md` |

Pass each template verbatim, substituting the transcript path or digest where marked. Scion-agent reviewers return findings via `inbox/` and `scion message`; in-harness reviewers return them in their response body.

## 3. Synthesize

One subagent on `roles.reflect-judgment` (`judgment`), in-harness when that role resolves to your own harness, otherwise a `pstack-reviewer` Scion agent. It writes nothing and keeps MCP access to spot-verify citations. Pass `references/synthesizer.md` verbatim, with each reviewer's full output inlined where marked. It returns an Accepted / Rejected / Backlog list.

## 4. Structural enforcement check

Move any Accepted item that a lint rule, script, metadata flag, or runtime check would enforce more reliably to Backlog. See the **encode-lessons-in-structure** principle skill.

## 5. Apply

Present the synthesizer's full Accepted / Rejected / Backlog output and wait for explicit approval before applying any Accepted edit (**pstack-scion-runtime** §2 and §5; put the full table in the store if it exceeds 2000 characters). The user picks the subset and may redirect routings. Skill changes affect every future agent in the org. Do not auto-apply.

File each Backlog item to your team's devex or backlog tracker without waiting. Only the Accepted list waits for approval.

Never edit a provisioned copy under `$HOME/.*/skills/` (it is read-only cache that dies with the container or gets overwritten on sync; **pstack-scion-runtime** §2). Before approval, show its source destination: `.scion/skills/<skill>/`, `.scion/templates/<role>/skills/<skill>/`, or the `scion-pstack` source checkout. After approval, copy the skill folder into `.scion/skills/<skill>/` when overriding an installed skill locally and edit that source copy. Never open a PR or push.

Follow each approved row's Routing exactly:

- Trivial existing-skill edit (a one-line bullet, a tightened sentence, a stale fact corrected): the parent does it directly.
- Substantive existing-skill edit (a new section, a new pattern table, more than ~10 lines): follow **poteto-mode**'s authoring-a-skill playbook (**pstack-scion-runtime** §2).
- `tune description: <skill path>` (the skill exists but didn't trigger when it should have): follow the authoring-a-skill playbook, rewriting the description around the triggers the session missed.
- `new skill via create-skill: <kebab-name>`: create it via the authoring-a-skill playbook. Do not invent the shape ad hoc.

If your environment ships a SKILL.md validator, run it on every touched skill before declaring done.

## 6. Summarize for the user

Short list, no preamble:

- Edits applied: `<skill path>`. What changed, one line each.
- New skills created: `<skill path>`. One line each (rare).
- Backlog filed to the devex tracker: `<issue title>` (`<tags>`). One line each.
- Dropped: one line per rejected finding + reason from the synthesizer.
- Transcript source: which step 1 sources fed the review.
