# pstack → Scion port: learnings log

Running log. Each entry: what happened, why it matters, and which meta-skill it feeds (see the end of the file).

## Survey phase (2026-09-22)

L1. **Inventory before designing.** pstack has 47 skills, 2 agents, 23 playbooks (inside poteto-mode/playbooks), TS scripts (orch store, watch-pr), and a dormant automations pack (benny).
    A grep for host-specific terms (subagent_type, Task, AskQuestion, .cursor, /loop, agent-transcripts, cursor-team-kit, model slugs) splits the skills cleanly:
    32 of 47 SKILL.md files have no host-specific references (all 23 principles, unslop, technical-writing, tdd, bro, blast-radius, architect, figure-it-out, teach, typescript-best-practices).
    Those port verbatim. Porting effort goes into roughly 15 skills plus the playbooks.
    → meta-skill: "port-triage": run the host-term grep first and bucket skills into verbatim / adapt / drop.

L2. **Host primitives to map.** Terms that need a Scion equivalent:
    - `Task` tool + `subagent_type` + `model` + `run_in_background` → either an in-harness subagent (same model family, cheap) or a Scion agent (`scion start --type <tpl> --harness-config <h> --model <m>`). Scion agents are always background and always async.
    - `environment: "cloud" | "local"` → not applicable. Every Scion agent is a container. "Needs this machine" becomes "needs a service or mount in the template".
    - `readonly: true` → no enforcement primitive. Becomes a brief or template instruction. (Gap.)
    - `AskQuestion` → `sciontool status ask_user` + `scion message`.
    - `/loop` (Cursor wake chain) → `scion schedule` + `sciontool status blocked`.
    - `~/.cursor/rules/pstack-models.mdc` (always-applied rule) → no direct equivalent. Candidates: a models file in a shared dir, template env vars, or the lead's standing orders.
    - `agent-transcripts/` (local transcript store used by recall, reflect, eval, show-me-your-work, session-pickup) → no equivalent in Scion. Candidates: `scion logs`, `scion look`, conversation history (`scion conversation`), or an explicit trail file each agent writes.
    - Completion notification from a background Task → Scion state-change notifications plus a REPORT message from the worker.
    - Cursor built-ins referenced by name (`create-skill`, `/babysit`) and the sibling plugin `cursor-team-kit` (deslop, control-ui, control-cli) → missing dependencies. Substitute, stub, or mark optional.
    → meta-skill: a standing "host primitive map" table that a porter fills in per source host (Cursor, Claude Code plugin, Codex, ...).

L3. **Multi-model diversity is a structural feature of pstack, and Scion covers it better than the source host does.**
    interrogate, arena, architect, and the cross-model review in show-me-your-work all depend on "same prompt, different model family".
    Cursor does this with the per-Task `model` slug. Scion does it with harness-configs (claude, codex, gemini, grok-build, opencode, copilot, ...), which run different vendors' agent CLIs, not just different models behind one CLI.
    Cost: each reviewer is a container, not an in-process call, so fan-out is slower and heavier. The port needs a rule for when an in-harness subagent is enough and when a Scion agent is required.

L4. **Slash commands are the user's routing layer.** `/poteto-mode`, `/interrogate`, and the rest are how a human picks a workflow.
    In Scion the human messages a lead agent, so routing moves into the lead's instructions: poteto-mode's playbook matcher becomes the lead's intake step.
    Skills tagged `disable-model-invocation: true` (only fire on an explicit slash command) need a new trigger: the lead routes to them, or they auto-trigger from their description.
    → meta-skill: "slash-command → routing" adaptation guidance.

L5. **Existing Scion conventions found:** global templates (coordinator, code-reviewer, ...) reference skills with `gh://org/repo/path` URIs, alongside the `skill://` URIs documented in team-creation. team-creation does not mention `gh://`. (To confirm: resolution semantics.)

## Platform findings from the template/skill research

L6. **Skill URI grammar.** `gh://owner/repo/name[@ref]` resolves only `skills/<name>` at the repo root.
    Plugin monorepos (cursor/plugins has `pstack/skills/...`) need the full form `https://github.com/<o>/<r>/tree/<ref>/<path>`.
    Pin `<ref>` to a commit SHA so the team does not drift when upstream changes.
    → meta-skill + team-creation: document both URI forms and the monorepo limit.

L7. **Doc and code disagree on skill precedence.** team-creation says a template-local skill wins over a URI skill with the same name.
    The code (`pkg/agent/skill_resolver.go:526-531`) does the opposite: the URI skill overwrites the local one.
    Porting rule: never declare the same skill name both ways.
    → fix team-creation.

L8. **Executable bits are lost for URI and hub-downloaded skills.** Only template-local `skills/` keep them.
    Ported skills must call `bun x.ts` or `bash x.sh`, never `./x`.
    → meta-skill checklist item.

L9. **`scion templates import` cannot read Cursor agent files.** Frontmatter `name`, `description`, and `is_background` score 0 in its detector.
    Forcing `--harness claude` writes the body to `home/.claude/CLAUDE.md`, and provisioning then overwrites that file with the seeded `agents.md`.
    Hand-author the templates instead.
    → candidate platform issue: add a Cursor dialect, or make import write the body to `agents.md`.

L10. **The `scion skills` CLI (publish, resolve, list) is in the source but not in the agent's binary.** The agent cannot test URI resolution or publish ported skills from inside the sandbox.
    For now, adapted skills ship template-local. Resolution is only proven by provisioning a real agent.
    → meta-skill: "verify skill resolution by provisioning a smoke-test agent".

L11. **A template's `system-prompt.md` replaces the harness's entire default system prompt on Claude** (`system_prompt_mode: native` → `--system-prompt`).
    That removes Claude Code's built-in tool-use guidance.
    team-creation lists `system-prompt.md` as REQUIRED in one place and optional in another.
    The pstack templates omit it and put the persona in `agents.md`.
    → fix team-creation: make it clearly optional and explain what it replaces.

L12. **Model selection happens at spawn, not in the template.** A template-level `model` is the lowest-priority default and `default_harness_config` is only a preference.
    That fits pstack's per-call model choice: one template per role, with vendor diversity chosen at `scion start --harness-config`.
    Porting rule: don't mint a template per model. Mint one per role.

L13. **GitHub API budget risk.** Each `https://github.com/...` skill costs a few API calls (commit resolve plus contents listing) at first provision. There is a TTL cache.
    Thirty-plus upstream skills per template could exhaust the unauthenticated limit of 60 requests an hour. (To verify: does the hub use a default token?)
    Mitigations: pin the SHA (improves cache hits), publish a bundle to the skill bank, or vendor the skills.

L14. **Shared state needs a project shared dir, and a template cannot declare one.** The store path must be resolved at runtime (env var, then `scion shared-dir list`, then a gate).
    Cursor's "agent store" was implicit. On Scion it is a setup prerequisite, and the port has to say so.

## Adaptation phase: poteto-mode (subagent report, reviewed)

L15. **Scripts encode the prose they check.** `check-plan.mjs` rejected any plan that lacked the literal strings `grok-4.6-fast-xhigh`, `/goal`, and `git show origin/main:`.
     Editing the playbook text without the script breaks the tool silently.
     Grep scripts for host strings they check or output, not just for paths.
     Verify by running the old and new tools against their own templates and diffing the output (both clean here).
L16. **Self-hosting assumptions.** "Re-read this playbook from trunk" (`git show origin/main:pstack/...`) only works inside the plugin's own repo.
     Once a skill is installed separately, such a step becomes "re-read the installed file". Look for dogfooding steps like this.
L17. **Host session state has to become store files.** Cursor's `/goal`, `/loop`, and `/tmp` resume notes became `goal.md` and `resume.md` in the shared store.
     Every new file must be added to the runtime's store layout, or the layout drifts. (Done.)
L18. **Look for existing override hooks before patching scripts.** `orch.ts` already took `--store` and `ORCH_STORE`, so the store move needed zero script changes.
L19. **PID-based locks and `/tmp` state break once state is shared across containers.** Audit every lock and temp-file mechanism when moving from one host to many containers.
L20. **Some host strings are external facts, not host primitives.** watch-pr matches the `cursor` GitHub login to recognize Bugbot comments. That is a fact about the GitHub service and must stay. Classify each hit before replacing it.
L21. **Dropped frontmatter carries intent.** `mode: true`, `reminder:`, and `disable-model-invocation` meant sticky, slash-only activation. On Scion that intent moves into the lead's `agents.md` ("poteto-mode always on, casual turns excepted"). Record where each dropped key's behavior went.
L22. **Scripts with first-run installs** (`bootstrap.ts` runs `bun install` into the skill dir) need network and a writable skill dir at runtime. Either pre-install into the image or vendor `node_modules`. Tests: 52 of 52 pass under bun.
L23. **Diff size tells you the port strategy worked.** poteto-mode came to 20 files and roughly 85 lines changed out of about 100KB. The minimal-diff approach plus one runtime contract skill kept the fork cheap to re-sync.

## Adaptation phase: multi-model skills (subagent report, reviewed)

L24. **Grep reference and prompt files too, not just SKILL.md.** Host paths hide in "detection" checklists (reflect's reviewer prompts) and in output-location notes (architect's runner prompt).
     architect was classed "verbatim" from a SKILL.md-only grep, but it still carried default model slugs. A pure-judgment skill usually still names models.
L25. **"/tmp or a worktree" becomes "your own branch or your own dir in the shared store"** once workers are separate containers. Judges then read candidates by branch or path label. This rule recurs across arena, swarm, architect, and eval.
L26. **Preserve a permission flag's intent, not the flag.** Cursor `readonly` also stripped MCP access, so upstream warned against using it. On Scion the rules become "write nothing" and "keep MCP access".
L27. **In-process capabilities become per-template declarations.** A Cursor subagent inherits the parent's MCPs. A Scion agent only has the MCP servers its template declares. Moving a step to a container can silently lose a data source (why's investigators). Report the missing source as a gap, never as a clean result.
L28. **Config-key collapse.** Upstream had separate model lines for how-explainer, why-synthesizer, and reflect-judgment. I first folded them into `judgment` and then restored them as aliases that default to it, so the user-visible setting survives.
L29. **Interface tokens stay verbatim.** A token that one prompt emits and another parses (for example `new skill via create-skill:`) is an interface. Change what executes it, never the token itself.
L30. **The tier decision fits in one line.** Ask whether the step needs a different vendor, writes a branch, or outlives your turn. If any is yes, it gets a Scion agent. Otherwise it runs in-harness. A per-spawn line is enough; don't write paragraphs.

## Adaptation phase: config, trail, and verification skills (subagent report, reviewed)

L31. **Frontmatter is part of the port surface.** Nearly every "verbatim" upstream skill has `disable-model-invocation: true`, which is Cursor's slash-only flag.
     Claude Code honors the same key and hides the skill from the model's Skill tool, so a verbatim URI skill can become uninvokable.
     Fix without forking: runtime §0 says "skills are files, read `$HOME/<skills_dir>/<name>/SKILL.md` directly". That matches how pstack already phrases references ("read the leaf skill").
     Also flagged: `paths:` (Cursor auto-attach) in typescript-best-practices is harmless elsewhere.
     → meta-skill: grep frontmatter keys and check each one against every target harness's semantics.
L32. **Scion never loads skills from the repo.** Provisioning fills `$HOME/<skills_dir>` from three sources only: template `skills/`, embedded platform skills, and URI skills (including project/user injected skills via `scion project skills add`).
     Any upstream skill that *generates* a project-local skill (create-verification-skill writing `.cursor/skills/verify-x`) must also say how that skill reaches agents: a template-local copy, a published copy, or a full `https://github.com/.../tree/<ref>/.scion/skills/verify-x` URI.
     Claude Code happens to read `.claude/skills/` in the repo, but that covers one vendor only.
L33. **"Read-only" role labels can hide a write the workflow depends on.** My design table called Comment Sicko read-only, but upstream it deletes comments, and no-comments reviews that diff.
     Read the upstream agent definition before trusting a summary table. (Fixed: sicko writes only to its own `-sicko` branch.)
L34. **No transcript store means the trail must be written during the run.** recall, reflect, show-me-your-work, and automate-me all read history after the fact.
     On Scion, history is thin: conversations need Hub mode, and `scion logs` disappears with the agent.
     Every history-reading skill now says "write the trail as you go", and the runtime lists sources in priority order.
     → platform gap: a durable per-agent transcript archive would restore these skills' full strength.
L35. **Budget ladders on model-name suffixes** (`-max`, `-xhigh`) collapse to one alias per size (small, medium, large, extra-large). Keep explicit IDs unchanged.
L36. **Human-surface assumptions.** teach says "open the diff or the debugger" and "reach for the image-generation tool", which assumes an IDE the human is watching.
     On Scion the human sees messages only, and messages to humans cap at 2000 characters. Accepted verbatim for now; a fork would switch it to "write to the store and send a link".
L37. **`scion harness-config show` does not print model aliases.** `pull --to <dir>` gets them. setup-pstack depends on this.

## Verification phase

L38. **Smoke test passed** (pstack-reviewer, claude harness): all 27 SHA-pinned `https://github.com/cursor/plugins/tree/<sha>/pstack/skills/<name>` URI skills resolved at provision. The 3 template-local skills landed too. The agent read skills by path and reported back through messaging.
     The platform also injected 9 platform skills (team-creation, scion-*, git-operations, software-engineering-process).
     Budget note: 27 GitHub-URI skills did not hit a rate limit on first provision. L13's risk is not observed so far.
L39. **Shared-project side effect.** `scion start --type /abs/path --upload-template` publishes the draft template at *project* scope on the hub, where every project member sees it.
     For a draft port, that is visible sooner than intended. The porter should say so up front, or use a scratch project.
     → meta-skill: "where drafts live vs where tests provision from".
L40. **`scion logs <other-agent>` returned 403 for a peer agent** (I had started it). Skills that fall back to `scion logs` (recall, reflect, show-me-your-work audit) can't count on it. Only `scion look` and messages are reliable for agents.
L41. **`templates sync` takes only a name.** To sync a template from an arbitrary dir, it has to be copied into `.scion/templates/` first. `build.sh` could grow a `--sync` flag.
L42. **Vendor diversity depends on environment credentials, not on the port.** In the trial, every non-claude harness-config failed at start: grok-build and hermes crashed, codex and copilot had expired tokens, gemini had no auth, opencode had a PAT error, and muse-code's image was missing.
     `scion harness-config list` shows configs that *exist*, not ones that *work*.
     The trial lead handled it correctly: it fell back to a claude-only panel at two sizes and added an independent corpus check.
     Actions:
     (a) setup-pstack must *probe* each harness by starting a trivial agent before it writes the panel, not just list the harness-configs.
     (b) The runtime should say that a same-vendor panel is degraded diversity, and that the verdict must state this.
     (c) Platform gap: there is no cheap "is this harness-config usable by me" check.

## Trial run: pstack-trial-lead interrogates the check-plan port (verdict: not yet acceptable)

L43. **A dogfood trial finds real port defects that reading does not.** The team, run on its own port diff, found a validator regression that I introduced and that my happy-path check missed. I had swapped a marker for a sentence that already existed in the skeleton, which silently removed a check. It was found by three independent methods: two reviewers, plus the lead's 25-mutation corpus. Lesson for porting: when a port edits a validator's literal markers, prove each new marker is *load-bearing*. A mutation that deletes the guarded content must still fail. Ship negative fixtures next to the script (`scripts/check-plan.test.ts`, 6 cases). A parity corpus against upstream is the cheap independent lever.
L44. **Partial primitive substitution is the typical residue.** One line of a recipe got "own Scion agent" while the next line still saved to container-local `/tmp`. Cursor subagents share a filesystem, but Scion agents do not. Grep every ported file for `/tmp`, `~/`, and "return the paths" after the host-term pass, not just for host nouns. The same pass found `grok-4.6-fast-xhigh` in refactoring.md and `/loop` in bug-fix.md, which my triage grep had missed because they sat outside the playbooks I diffed first. Rerun the triage grep over the *finished* tree.
L45. **Lifecycle semantics differ even when a primitive maps cleanly.** `/loop` dies with the session, but a `scion schedule` persists until it is deleted. The map row must carry teardown (record the ID, delete on stand-down and at close), not just setup.
L46. **Large inline task arguments crash agents.** A 31 KB brief passed as the `scion start` task crashed 5 of 5 agents, while pointer tasks survived. The cause is inferred, because logs return 403. Rule: brief in the store, task is a pointer. Now in runtime §1.
L47. **Agent-to-agent messages can be lost.** One reviewer reported "delivered", but nothing arrived. Its report was recovered from `scion look --full --plain` scrollback. Completion now uses three channels: message, state event, and an inbox file in the store, with the file as the primary copy. Read-only roles need an explicit carve-out for their own inbox file.
L48. **`scion shared-dir list` can say "none" while /scion-volumes/scratchpad is mounted.** Resolve the store by checking the mount, not the listing. Platform bug candidate.
L49. **The trial confirmed L42 at scale.** Of 8 vendors, 7 were unrunnable, with 9 crashes and no stack traces. setup-pstack now preflights each entry with a throwaway agent. The runtime has a degraded-diversity rule: label by the vendor that actually ran, state the panel width in the verdict, and prefer a non-model lever.
L50. **Store-root versus program-dir ambiguity.** "Write X in the pstack store" read as the root, so two programs would collide. Every ported path that names the store should name `<store>/<program>/...`.
L51. **Cost of the trial.** One lead, about 20 minutes, 2 surviving reviewers, 9 crashed spawns. It produced 2 Act On items, 3 Consider items, 5 Noted items, and 7 friction items. All but the platform gaps (logs 403, shared-dir list, no harness health check) are fixed in skills/ and templates-src/, and the templates are re-synced. For meta-skill purposes, this is the step that justifies "run the ported team on its own port diff" as a mandatory verification stage.

## Missed dependency: cursor-team-kit (flagged by the user)

L52. **I treated a named dependency as host-proprietary without opening it.** pstack cites `deslop`, `control-ui`, and `control-cli` "from `cursor-team-kit`". I read the vendor prefix as "Cursor-internal" and wrote substitutes (unslop plus no-comments, and verifier-blocked). The kit is a sibling directory in the same repo at the same SHA. It is MIT and mostly host-neutral: only 2 of its 18 skills mention host terms, and the 3 that pstack uses mention none. My substitutes were strictly worse. deslop targets code slop (defensive try/catch, `any` casts, nesting), which neither unslop nor no-comments covers. The control skills are real Playwright/CDP and tmux/PTY recipes that run inside a container.
   Rule for the meta-skill: **dependency triage precedes primitive mapping.** For every external name the source cites (a plugin, kit, or skill), first list the source repo's sibling packages and the named package's license, then classify it as *vendorable/URI-referencable*, *host-proprietary*, or *absent*. Only host-proprietary and absent get a substitute. A vendor name in a package name is not evidence of host lock-in.
   Fix cost: 7 ported lines reverted to upstream wording, which shrinks the fork diff, plus 2 runtime rows and a build.sh stanza. Three URIs were added to lead and agent, and two to reviewer. The general point is that referencing upstream beats substituting, and correcting a wrong "not available" call usually *reduces* the diff.
   Verified: a pstack-reviewer smoke test (pstack-smoke-tk) resolved the control-ui and control-cli URIs from the cursor-team-kit subpath. It had 41 skill dirs, up from 39. deslop is absent from the reviewer by design.

## Meta-skill drafting

L53. **The triage script, run retroactively, catches two of my manual misses (L24 architect, L52 team-kit).** That argues for scripting triage rather than documenting it. Its first version missed host-neutral *concept* words ("parallel subagents", "transcripts"). Those mark host machinery as surely as tool names do, so they are now in the term list. Over-flagging is the right trade-off.
L54. **The team-creation doc drifted from the code in three places** (precedence, system-prompt required or optional, the URI forms supported). Reading `pkg/api/skill_uri_normalize.go` found a fourth undocumented feature: `?token=SECRET` for private repos. Platform skills should cite the code they describe, or be tested against it.
L55. **Most porting knowledge is general, not pstack-specific.** Of 52 learnings, about 40 turned into general rules in port-agent-pack or team-creation. The pstack-specific residue is the model roles, the orchestrate store layout, and poteto-mode's validator.
