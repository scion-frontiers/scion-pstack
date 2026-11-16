---
name: poteto-help
description: Guides users through pstack setup, /poteto-mode, and picking the skill, playbook, or principle for a task. Type /poteto-help with a question.
---

# Poteto help

Answer the user's question about pstack, hand them a prompt they can send, and link the file the answer came from. For a help question, don't start the work. The user asked how, and a pstack run spends real tokens, so let them send the prompt.

A message that asks for work, such as "use pstack to fix this bug", is not a help question. Read [`poteto-mode`](../poteto-mode/SKILL.md), do the work under it, and mention once that the `pstack-lead` template keeps it on by default.

This file maps questions to the skills and guide pages that hold the answers. Those files own the details. Read the file you route to before you quote it, and trust it when it disagrees with this map. Installed skill paths live inside your container (`$HOME/<skills_dir>/`), which the user cannot open directly, so give the user the public GitHub link: `https://github.com/scion-frontiers/scion-pstack/blob/main/skills/<name>/SKILL.md` for Scion-adapted skills, or `https://github.com/cursor/plugins/blob/bf0c7cd80abdbf7fe47b634978a7d1b4071f71a7/pstack/` followed by `skills/<name>/SKILL.md` or `docs/guide/<page>.md` for verbatim upstream skills and guide pages.

## Find out what they need

Infer the need from the message and the conversation. A named situation, such as "which skill reviews a PR?", goes straight to its section. If the need is still unclear, ask one multiple-choice question (**pstack-scion-runtime** §2 `ask_user`) with these options, then answer only the section they pick:

- Get set up
- Start a task with `/poteto-mode`
- Pick a skill for a situation
- Fix a run that went wrong
- Make pstack my own

Check the state that changes the answer, and mention it only when it does:

- No `pstack-models.yaml` in the pstack store (**pstack-scion-runtime** §3 and §4) means `setup-pstack` hasn't run for this project, so every role and panel seat falls back to `inherit` (the lead's own harness and model, with 1-family degraded diversity on panels).
- No `verify-*` skill (under `.scion/skills/` or your installed skills dir) or other app harness in the project means agents have no scripted way to drive the app. Mention `create-verification-skill` when the question is about proving a change works.
- No formal verification skill in the project means no property is checked past what tests reach. Mention `create-formal-verification-skill` when the question is about a race, an invariant, or another case tests rarely hit. When one exists and the code it covers changed after the commit it records as last in sync, mention `maintain-formal-verification-skill` if the question touches that code.

When `pstack-models.yaml` is missing and it matters, ask whether the user wants to pick a harness-config and model for each role and a reasoning budget now. It matters when the user is new, the question is about setup or cost, or the answer depends on which models run. Ask at most once per chat. If the need is also unclear, ask both questions together. Offer two choices:

- Now: give them `/setup-pstack` to send, and answer their question too.
- Later: answer their question, and add one line saying every role and panel seat stays on `inherit` (the lead's own harness and model, with 1-family degraded diversity on panels) until they run `setup-pstack`.

## Get set up

1. Provision the project's templates from `scion-frontiers/scion-pstack` (`pstack-lead`, `pstack-agent`, `pstack-reviewer`, `pstack-comment-sicko`) and mount a shared volume (`scratchpad`) for the pstack store.
2. Run [`setup-pstack`](../setup-pstack/SKILL.md). It preflights runnable harness-configs, asks for a reasoning budget, maps a harness-config and model to each role, and writes `pstack-models.yaml` in the pstack store. The file applies to agents spawned from then on. Then it offers once each to generate a verification skill and a formal verification skill for the project, unless the project already has one.
3. Start a real task on `pstack-lead` with a goal and a check that can pass or fail.

The [`scion-pstack` README](https://github.com/scion-frontiers/scion-pstack/blob/main/README.md), [`pstack-scion-runtime`](../pstack-scion-runtime/SKILL.md), and [upstream guide page 1](https://github.com/cursor/plugins/blob/bf0c7cd80abdbf7fe47b634978a7d1b4071f71a7/pstack/docs/guide/01-setup.md) have the details. Offer to word their first prompt with them, per [`references/prompting.md`](references/prompting.md).

If cost is the worry, say where the tokens go and how to spend fewer. pstack spends extra tokens on Scion worker/reviewer containers and multi-vendor review panels. Rerun `setup-pstack` and pick a smaller budget (`large`, `medium`, or `small`) or cheaper harness-configs. A role set to `inherit` runs on the caller's own harness and model. A shorter panel list runs fewer agents, one for each entry. Opt out on casual turns when rigor isn't needed.

pstack was written for Cursor and ported to Scion via [`pstack-scion-runtime`](../pstack-scion-runtime/SKILL.md), which translates subagents, per-role models, `ask_user`, schedules, and the shared store onto Scion containers. Slash commands like `/how` or `/interrogate` do not exist natively in Scion chat, so `pstack-lead` routes to any skill the user names by `/skill-name` or plain words (**pstack-scion-runtime** §5).

## Start a task with `/poteto-mode`

`poteto-mode` matches the task to a playbook, copies the playbook's steps into the todo list, and runs the other skills as the steps need them. A step it skips stays in the list as `skip: <reason>`. A good prompt states the goal and how to tell it's done. It doesn't list skills, because a hand-written sequence tends to drop or reorder steps the playbook would keep. Read [`references/prompting.md`](references/prompting.md) before you help word one. [Upstream guide page 2](https://github.com/cursor/plugins/blob/bf0c7cd80abdbf7fe47b634978a7d1b4071f71a7/pstack/docs/guide/02-poteto-mode.md) has examples.

On Scion:

- `pstack-lead` keeps `poteto-mode` always on across turns, skipping casual turns or turns where the user opts out (**pstack-scion-runtime** §5).
- Mid-conversation, starting a message with `"new task"` makes the lead match a fresh playbook.
- `poteto-mode` spawns `pstack-agent` Scion agents for delegated code-writing steps (**pstack-scion-runtime** §1).

## Pick a skill

The default answer is `/poteto-mode`, which runs most of the others when its steps need them. Name a skill directly when the user wants more or less of something than the playbook gives. Read the skill before you recommend it, and give one example prompt.

| The user wants to | Skill |
|---|---|
| Do any non-trivial task with rigor | [`/poteto-mode`](../poteto-mode/SKILL.md) |
| Check that the agent understood their goal and the problem before it starts | [`/in-your-own-words`](../in-your-own-words/SKILL.md) |
| Get a prompt rewritten deeper, not bigger, before sending it: what a top professional would add, their raw material and methods, and an outside check. It returns the prompt and doesn't do the task | [`/sharpen`](../sharpen/SKILL.md) |
| Know how code works now, or where new code should live | [`/how`](../how/SKILL.md) |
| Know why code is shaped this way, or where a number came from | [`/why`](../why/SKILL.md) |
| Understand a change or subsystem, explained plainly | [`/teach`](../teach/SKILL.md) |
| Catch up on their own recent work on a topic | [`/recall`](../recall/SKILL.md) |
| Catch up on what changed in this chat since their last message, in plain words and small visuals, with every item waiting on them listed and decidable from the reply alone | [`/ketchup`](../ketchup/SKILL.md) |
| Know what a small diff could break outside itself | [`/blast-radius`](../blast-radius/SKILL.md) |
| Settle types and module shape before code that crosses a function boundary | [`/architect`](../architect/SKILL.md) |
| Get several attempts at one brief, merged into the best one | [`/arena`](../arena/SKILL.md) |
| Run parallel checks over slices, or race workers, across Scion agents | [`/swarm`](../swarm/SKILL.md) |
| Have different models review a diff and try to break it | [`/interrogate`](../interrogate/SKILL.md) |
| Fix a bug test-first when a cheap local test exists | [`/tdd`](../tdd/SKILL.md) |
| Apply TypeScript rules to `.ts` or `.tsx` work | [`/typescript-best-practices`](../typescript-best-practices/SKILL.md) |
| Strip comments before review, using a reviewer that didn't write them | [`/no-comments`](../no-comments/SKILL.md) |
| Clean AI tells out of prose | [`/unslop`](../unslop/SKILL.md) |
| Write docs, an RFC, a README, a PR description, or a commit message to a standard | [`/technical-writing`](../technical-writing/SKILL.md) |
| Hear the last reply again in plain words | [`/bro`](../bro/SKILL.md) |
| Give agents a scripted way to drive the app and prove behavior | [`/create-verification-skill`](../create-verification-skill/SKILL.md) |
| Bring a verification skill and its feature map back in line with the app | [`/maintain-verification-skill`](../maintain-verification-skill/SKILL.md) |
| Formally verify a race, invariant, or other property that tests rarely reach | [`/create-formal-verification-skill`](../create-formal-verification-skill/SKILL.md) |
| Bring a formal verification back in line after the code it covers changed, and learn whether a failure is drift or a bug | [`/maintain-formal-verification-skill`](../maintain-formal-verification-skill/SKILL.md) |
| Show a PM or designer what the user sees as a chart checked by a TLA+ model, with the shortest path to each state that breaks a rule | [`/statechart`](../statechart/SKILL.md) |
| Vet a performance number before reporting or acting on it | [`/benchmark-checklist`](../benchmark-checklist/SKILL.md) |
| Run a large or cross-cutting change, or one to review after stepping away | [`/figure-it-out`](../figure-it-out/SKILL.md) |
| Keep a decision log during a run, and review it afterward | [`/show-me-your-work`](../show-me-your-work/SKILL.md) |
| Pick a harness-config and model for each role and a reasoning budget | [`/setup-pstack`](../setup-pstack/SKILL.md) |
| Turn their own working habits into a personal mode skill | [`/automate-me`](../automate-me/SKILL.md) |
| Turn what a finished task taught into skill edits | [`/reflect`](../reflect/SKILL.md) |
| Stop agents from repeating the same mistakes in this repo | [`/correct`](../correct/SKILL.md) |
| See how pstack maps onto Scion templates, schedules, and the shared store | [`/pstack-scion-runtime`](../pstack-scion-runtime/SKILL.md) |
| Find their way around pstack | `/poteto-help` |

If a skill directory next to this one is missing from the table, read its frontmatter and route by its description. The `principle-*` directories are covered under principles below.

Close calls:

- `/how` explains what the code does. `/why` explains the reasons. `/teach` runs one or both and explains the result plainly.
- `/arena` gives every worker the same brief and merges the best parts. `/swarm` splits work into slices or a race and returns one report.
- `/architect` implements right after it settles the design. Add "with checkpoint" to review the design before it writes code.
- `/interrogate` reviews the diff. `/blast-radius` looks for breakage outside the diff and proves the one fact that makes the change safe.
- `/recall` rebuilds context across recent work. `/ketchup` covers only this conversation since the user's last message. Resuming one specific conversation or branch is the Session pickup playbook.
- `/figure-it-out` designs one rigorous run. The Orchestrate playbook runs a program that spans days and many PRs. The Autonomous run playbook drives one task to a finish condition.

Not in pstack:

- `/deslop`, `control-cli`, and `control-ui` ship in `cursor-team-kit` (installed alongside pstack on Scion).
- `/loop` and `/create-skill` are Cursor built-ins; on Scion they map to `scion schedule` + background watchers and the authoring-a-skill playbook (**pstack-scion-runtime** §2).
- pstack has no `/orchestrate` skill. Orchestrate is a `/poteto-mode` playbook.

## Playbooks and principles

Playbooks are step lists inside `/poteto-mode`, not skills, so they have no separate skill directory. Inside `pstack-lead`, describing the task picks one, and these phrases name one directly:

- "babysit this pr" or "check on pr 123" runs Babysit. It drives the PR to merge-ready and stops there. It doesn't merge unless the user asks to merge, land, or ship.
- "land the stack" runs Shipping.
- "take over this branch" runs Session pickup.
- "pause safely" runs Pause safely.
- "full autopilot on this queue" runs Autopilot-full. "autopilot, don't merge" runs Autopilot-stack.
- "run the eval playbook" runs Eval.

The Playbooks section of [`poteto-mode`](../poteto-mode/SKILL.md) lists every playbook and when it applies. [Upstream guide page 6](https://github.com/cursor/plugins/blob/bf0c7cd80abdbf7fe47b634978a7d1b4071f71a7/pstack/docs/guide/06-verify-and-ship.md) covers opening, babysitting, and landing a PR.

For work that spans phases or stacked PRs, asking `poteto-mode` for a plan runs the [Multi-phase plan playbook](../poteto-mode/playbooks/multi-phase-plan.md), which writes the plan and doesn't implement it. For a design question, the Prototype playbook or `/architect` settles it in code first.

Principles are one-rule skills that `poteto-mode` reads and cites in its replies. The user rarely invokes one. They steer with the names instead, as in "apply prove it works. show me the real output." Naming `/principle-<name>` still loads one on demand. [Upstream guide page 8](https://github.com/cursor/plugins/blob/bf0c7cd80abdbf7fe47b634978a7d1b4071f71a7/pstack/docs/guide/08-principles.md) lists them.

## Fix a run that went wrong

| Symptom | Fix |
|---|---|
| `poteto-mode` wasn't applied | Start the agent from the `pstack-lead` template, or ask the agent to read `poteto-mode`. |
| A question got treated as the next step of the last task | Say "new task", or say the turn doesn't need the mode. |
| A new model choice had no effect | `pstack-models.yaml` from `setup-pstack` applies to newly spawned agents. Running agents keep the harness they started with. |
| Runs cost more than expected | See the cost paragraph under Get set up. |
| A project-local skill didn't load on spawned agents | Scion does not auto-load `/workspace/.scion/skills/`. Deliver it via `scion project skills add <URI>` or copy into `.scion/templates/<role>/skills/` and run `scion templates sync`. |
| Parallel agents overwrote each other | Give each Scion agent its own pushed branch and its own `inbox/` file in the pstack store. |
| An overnight run moved but finished nothing | A loop or recurring schedule needs a check that can pass or fail, not a duration. See [upstream guide page 7](https://github.com/cursor/plugins/blob/bf0c7cd80abdbf7fe47b634978a7d1b4071f71a7/pstack/docs/guide/07-overnight.md). |
| The reply claims success from a green build | Ask for the real command, flow, stored value, or profile. That's the prove-it-works principle. |

For a run that drifts, [`references/prompting.md`](references/prompting.md) has one-line steers. [Upstream guide page 10](https://github.com/cursor/plugins/blob/bf0c7cd80abdbf7fe47b634978a7d1b4071f71a7/pstack/docs/guide/10-recipes-and-pitfalls.md) has more pitfalls and the recipes worth copying.

## Make pstack my own

- [`/automate-me`](../automate-me/SKILL.md) drafts a personal mode skill from the user's own history, to use alongside `poteto-mode`.
- [`/reflect`](../reflect/SKILL.md) after a session turns its lessons into skill edits the user approves.
- `write a skill for <workflow>` under `poteto-mode` runs the authoring playbook. The eval playbook tests a skill change blind.
- Fix a misbehaving skill in its own PR, not inside the feature work where it went wrong.

[Upstream guide page 9](https://github.com/cursor/plugins/blob/bf0c7cd80abdbf7fe47b634978a7d1b4071f71a7/pstack/docs/guide/09-make-it-yours.md) covers each of these.

## Reply

Lead with the answer. Give at most one example prompt in a code block, adapted from [`references/recipes.md`](references/recipes.md) when one fits, then the link to that file. Keep it short unless the user asked for the whole map.
