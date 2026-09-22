# create-verification-skill: port notes

Upstream: `pstack/skills/create-verification-skill` at 5ff7a35. `references/feature-map-example/` unchanged.

## Changed
- Dropped `disable-model-invocation: true`; routed by name (runtime §5), and setup-pstack step 7 runs it.
- Output path `.cursor/skills/verify-<app>/` → `.scion/skills/verify-<app>/` (runtime §2), three places.
- Helpers: invocation shown as `bash <file>` / `bun <file>`, never `./file` (URI delivery drops exec bits).
- Cleanup: evidence location must be readable by others, since each agent's clone dies with its container; the pstack store when there is one.
- New paragraph after step 4: Scion does not load repo skills. Delivery is either `scion project skills add <github tree URL of .scion/skills/verify-<app>>` or copying into template `skills/` dirs. Ask the human which; don't do it unasked.
- `/maintain-verification-skill` → the skill by name.

## Finding: how Scion loads skills (checked in /workspace)
- Each harness-config sets `skills_dir` (`.claude/skills`, `.codex/skills`, `.gemini/skills`, `.grok/skills`, ... ; generic harness `.scion/skills`), relative to the agent's **home**, not the workspace.
- `pkg/agent/provision.go` fills `$HOME/<skills_dir>` from exactly three sources: (1) each template in the chain's `skills/` dir (step 3), (2) embedded platform skills (step 3a2), (3) skill URIs resolved via the Hub/skill bank (step 3b), which include project- and user-scoped injected skills (`scion project skills add`, `scion user skills add`). There is no read of the repo/workspace for `.scion/skills/` or any other repo skill dir.
- `gh://owner/repo/name` resolves only `skills/<name>` at repo root, but the full `https://github.com/<o>/<r>/tree/<ref>/<path>` form keeps an arbitrary path (`pkg/agent/github_uri.go`), so `.scion/skills/verify-<app>` is addressable that way.
- Side channel, not Scion's: some harness CLIs read project skill dirs natively from their working directory (e.g. Claude Code reads `<repo>/.claude/skills/`). That is vendor-specific and would make the verify skill visible to one vendor only, so the port does not rely on it.

## Unresolved
- Whether the verify skill should live at `.scion/skills/` (neutral, needs delivery) or also be mirrored into a harness-native dir. Current choice: neutral + explicit delivery.
- A driven UI inside a container needs a browser/display in the image or a template service; the generated skill may hit `verifier-blocked` (runtime §2 control-ui row).
