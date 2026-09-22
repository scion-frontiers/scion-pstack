---
name: recall
description: "Reconstruct your recent working context from your own history (pstack store, Scion conversations, agent logs), live state, and the shared record (user reports, prior fixes, incidents), then hand back a tight current-state brief. Use for 'recall my work on X', 'catch me up', 'what have I been working on', 'where did I leave off', before starting or resuming work."
---

# Recall

**Before you start or resume work, you rebuild the user's recent working context and hand back a tight capsule of where things stand now and what to do next.**

Keep it tight and on-topic. Read only what the in-scope threads need, then stop.

Your context lives in two records. Your own history holds what you did and decided. The shared record holds everything that happened around the same code under other names: the symptoms users keep reporting, the fixes that shipped and got reverted, the errors still firing in prod. That second record is what the **why** skill searches, across source control, the issue tracker, chat and issue channels, long-form docs, and error tracking. A feature with a long bug tail keeps most of its story there, so don't reconstruct it from your own history alone.

Scion keeps no local transcript store (the **pstack-scion-runtime** skill, section 2). Your history lives in four sources, richest first:

- **The pstack store.** Each program dir under the store root (runtime section 4) holds `status.md`, `units.tsv`, `ledger.tsv`, `decisions.tsv`, `gates.md`, and `inbox/` reports.
- **Conversations.** `scion conversation list`, then `scion conversation messages <ref>` (or `catch-up`) for the requests, replies, and REPORT blocks exchanged with the human and with workers.
- **Agent output.** `scion list` for the program's agents (they share the `<lead-slug>-` name prefix), then `scion logs <agent>` and `scion look <agent>` for what one of them actually did. Logs exist only while the agent does. For a deleted agent, fall back to its `inbox/` report and pushed branch.
- **Git.** Branches, commits, and PRs (`git log`, `gh pr list --author @me`, `gh pr view`).

1. Classify, then route. One specific prior program or conversation to resume is the `session-pickup` playbook, not this. Turning habits into a durable skill is `automate-me`. A human-readable summary of your work is a different task. Recall loads working context across recent work before you act. If the user already gave you a full state capsule (paths, branch, the change), use it and skip the mining.
2. Lock the scope before searching. Pin the window ("recent" is a real range, default the last 7 days), the topic if named, and the workspace (default the active project and its pstack store. Never read another project's store or conversations without being asked). State the scope back. Never quietly turn "all" into "recent N".
3. Fan out across your history. Spawn parallel in-harness subagents on a fast, cheap model (runtime section 1), each taking a slice: one per program dir in the store, one per busy conversation, one for the agent logs. Tell every subagent to order candidates by real modification or message time and never by name or ID, grep the topic first and then read only the matching programs, threads, and logs and only their relevant regions, and skip the current conversation plus obvious noise (eval and test runs). Each returns the same schema, one block per program or thread: topic, the user's goal, decisions, open threads, struggles and corrections, and artifacts (PRs, tickets, branches), each citing its source (store path, `conv:<id>`, or agent name). For one or two sources, skip the fan-out and search directly. The raw history stays in the subagents. The main thread gets only their findings.
4. Sweep the shared record whenever the topic names a feature, file, subsystem, area, or bug. This is the default, not a judgment call, and "my work on X" does not exempt it. Hand it to the **why** skill's source investigators, but steer their question from "why was this built this way" to "what's the current state, what's been tried and didn't hold, and what are users still reporting". Reuse its per-source playbooks, run the investigators in parallel with the history mining, and inherit its posture: one investigator per source, null results are findings, skip an unavailable MCP and say so. Fold what comes back into the brief. Skip this step only for pure activity recall with no named target ("what did I do this week"), where your own history and live state are the entire answer.
5. Verify against live state. Take the PRs, branches, and tickets that the mining and the sweep surfaced and check them with `git` and `gh`. When the answer hinges on what an agent actually did (the tools it ran, files it read, errors it hit), read its full output (`scion logs <agent> --tail` high enough to cover the run, plus its `inbox/` report), not just the REPORT summary. State which source you used.
6. Write the brief to the contract below. Group by thread. Stay on the named topic.

## Output contract

Lead with the capsule, then the thread status, then the problems, then the next move. Deeper detail goes below or gets cut.

- **Capsule.** At most 5 bullets. What this work is and where it stands overall.
- **Threads.** One line each, prefixed with exactly one status tag: `[merged #N]`, `[open PR #N]`, `[in flight <branch>]`, `[verified, uncommitted]`, `[reverted #N]`, or `[planned, not started]`. A thread with no tag is not done yet, so tag it.
- **Problems.** At most 5, the recurring ones. Include the symptoms users keep reporting and any fix that shipped and was reverted, so the next attempt starts where the last one failed.
- **Next move.** The single most useful next action, concrete.

An adjacent feature or ticket stays out unless it blocks this one. When the capsule and thread lines outgrow a screen, cut detail before you cut threads. Write the brief through the **unslop** skill, cite history findings by store path, `conv:<id>`, or agent name, and shared-record findings by their source (PR #, ticket ID, chat permalink, error-tracker issue), and sanitize private context before any public output.

**Reply:** the brief, to the contract above.
