#!/usr/bin/env bash
# Assemble Scion templates for the pstack team from templates-src/ + skills/ + upstream.
#
# A skill counts as "adapted" when skills/<name>/ exists here, and is copied template-local.
# Every other skill is "verbatim" and is referenced from upstream by a SHA-pinned URI,
# or copied from the upstream snapshot when SKILL_MODE=vendor.
#
# Usage: bash build.sh [--vendor] [--out DIR]
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
UPSTREAM_SHA="5ff7a359dec6be2128b15c0fe53c1c12a46e41c8"
UPSTREAM_DIR="$ROOT/upstream/pstack-5ff7a35"
URI_BASE="https://github.com/cursor/plugins/tree/$UPSTREAM_SHA/pstack/skills"
# pstack depends on three cursor-team-kit skills (same repo, same SHA, MIT). They are host-neutral, so they are referenced verbatim.
TEAMKIT_DIR="$ROOT/upstream/cursor-team-kit-5ff7a35"
TEAMKIT_URI_BASE="https://github.com/cursor/plugins/tree/$UPSTREAM_SHA/cursor-team-kit/skills"
TEAMKIT="deslop control-ui control-cli"
SKILL_MODE=uri
OUT="$ROOT/templates"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --vendor) SKILL_MODE=vendor ;;
    --out) OUT="$2"; shift ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
  shift
done

PRINCIPLES=$(cd "$UPSTREAM_DIR/skills" && ls -d principle-* | sort)
DROPPED="make-bot-ui"

all_skills() {
  { ls "$UPSTREAM_DIR/skills"; ls "$ROOT/skills"; } | sort -u | grep -vxF "$DROPPED"
}

skills_for() {
  case "$1" in
    pstack-lead)   all_skills; printf '%s\n' $TEAMKIT ;;
    pstack-agent)  all_skills | grep -vxE 'setup-pstack|automate-me'; printf '%s\n' $TEAMKIT ;;
    pstack-reviewer)
      printf '%s\n' pstack-scion-runtime unslop technical-writing typescript-best-practices \
        blast-radius how why control-ui control-cli $PRINCIPLES ;;
    pstack-comment-sicko) printf '%s\n' pstack-scion-runtime how why ;;
    *) echo "no skill set for $1" >&2; exit 1 ;;
  esac
}

description_for() {
  case "$1" in
    pstack-lead) echo "pstack lead: poteto-mode always on; routes requests to playbooks, delegates, reviews, replies" ;;
    pstack-agent) echo "pstack worker: brief-driven code delegate, PR owner, arena candidate, stacker, or babysitter in poteto style" ;;
    pstack-reviewer) echo "pstack read-only panel member: interrogate/architect/arena judge, explainer, verifier, trail reviewer" ;;
    pstack-comment-sicko) echo "pstack Comment Sicko: hunts comments on its own branch, flags MUST KILL refactors" ;;
  esac
}

rm -rf "$OUT"
for tpl in $(ls "$ROOT/templates-src"); do
  dest="$OUT/$tpl"
  mkdir -p "$dest/skills"
  cp "$ROOT/templates-src/$tpl/agents.md" "$dest/agents.md"
  uris=()
  n_local=0
  for s in $(skills_for "$tpl"); do
    if [[ -d "$ROOT/skills/$s" ]]; then
      rsync -a --exclude PORT-NOTES.md --exclude node_modules "$ROOT/skills/$s/" "$dest/skills/$s/"
      n_local=$((n_local + 1))
    elif [[ -d "$TEAMKIT_DIR/skills/$s" ]]; then
      if [[ "$SKILL_MODE" == vendor ]]; then
        rsync -a "$TEAMKIT_DIR/skills/$s/" "$dest/skills/$s/"; n_local=$((n_local + 1))
      else
        uris+=("$TEAMKIT_URI_BASE/$s")
      fi
    elif [[ -d "$UPSTREAM_DIR/skills/$s" ]]; then
      if [[ "$SKILL_MODE" == vendor ]]; then
        rsync -a --exclude node_modules "$UPSTREAM_DIR/skills/$s/" "$dest/skills/$s/"
        n_local=$((n_local + 1))
      else
        uris+=("$URI_BASE/$s")
      fi
    else
      echo "missing skill $s for $tpl" >&2; exit 1
    fi
  done
  {
    echo 'schema_version: "1"'
    echo "description: \"$(description_for "$tpl")\""
    echo "agent_instructions: agents.md"
    echo "# Harness and model are chosen per spawn from pstack-models.yaml (see pstack-scion-runtime)."
    [[ "$tpl" == pstack-lead ]] && echo "model: extra-large"
    if [[ ${#uris[@]} -gt 0 ]]; then
      echo "# Verbatim upstream pstack and cursor-team-kit skills, pinned to cursor/plugins@${UPSTREAM_SHA:0:7}."
      echo "skills:"
      for u in "${uris[@]}"; do echo "  - uri: \"$u\""; done
    fi
  } > "$dest/scion-agent.yaml"
  rmdir "$dest/skills" 2>/dev/null || true
  echo "$tpl: $n_local local skills, ${#uris[@]} URI skills"
done
