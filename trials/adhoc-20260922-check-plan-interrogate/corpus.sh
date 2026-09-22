#!/usr/bin/env bash
set -e; W=/tmp/cp; cd /scion-volumes/scratchpad/pstack-port
UP=upstream/pstack-5ff7a35/skills/poteto-mode/scripts/check-plan.mjs; NEW=skills/poteto-mode/scripts/check-plan.mjs
rm -rf $W/mut; mkdir -p $W/mut
declare -A M
M[drop-lane7]='/^- \[ \] Lane 7\./d'
M[dup-lane]='s/^- \[ \] Lane 8\./- [ ] Lane 7./'
M[no-screenshot]='s/^\(- \[ \] Lane 3\..*\) Save `<slug>.png`\./\1/'
M[no-predicate]='s/^\(- \[ \] Lane 4\..*\) Pass when <predicate>\./\1/'
M[rule-missing-unit]='s/^\*\*Verify, unit\.\*\* Tests alone are not sufficient verification\. A PR is verified only when its unit, live, and perf boxes are all checked\./**Verify, unit.**/'
M[long-dash]='s/^One box is one unit of work\./One box is one unit of work \xe2\x80\x94 always./'
M[curly-quote]='s/^\*\*Depends on\.\*\* <PR id, or None\.>/**Depends on.** \xe2\x80\x9cnone\xe2\x80\x9d/'
M[mid-colon]='s/^## Close the program/## Close the program: finish/'
M[no-goal]='/write `goal.md`\|arm a `\/goal`/d'
M[no-reread]='/Re-read them at every tick/d'
M[no-reread-list]='/^  - \[ \] /d'
M[no-tick]='/30-minute audit tick/d'
M[no-status]='s/status message/report/'
M[gate-none-with-boxes]='s/^\*\*Review gate\.\*\* The operator reviews before merge\./**Review gate.** None. X is not review-gated./'
M[gate-no-video]='s/video/clip/g'
M[perf-reorder]='s/^- \[ \] Baseline\./- [ ] Baselines./'
M[missing-merge-block]='/^\*\*Merge\.\*\*/,/^## Close the program/{/^## Close/!d}'
M[no-appendix-a]='s/^## Appendix A\. Prototype evidence/## Appendix A. Evidence/'
M[nonappendix-tail]='s/^## Appendix B\. Alternatives rejected/## Alternatives rejected/'
M[empty-depends]='s/^\*\*Depends on\.\*\* <PR id, or None\.>/**Depends on.**/'
M[no-files-box]='/^- \[ \] \(Edit\|Create\|Delete\) `<path>`\./d'
M[h3-order]='/^### Spawn owners/,/^### PR mechanics/{/^### PR mechanics/!d}'
M[intro-too-long]='s/^<Under ten lines\..*/&\nl2\nl3\nl4\nl5\nl6\nl7\nl8\nl9\nl10\nl11/'
M[fence-hides]='s/^\*\*Verify, perf\.\*\*.*/```\n&\n```/'
M[lanes-wrong-role]='s/Ten lanes on the `swarm-worker` role at the PR head/Ten lanes on `grok-4.6-fast-xhigh` at the PR head/; s/Ten lanes on `grok-4.6-fast-xhigh` at the PR head/Ten lanes on the `swarm-worker` role at the PR head/'
norm() { sed -e 's#/tmp/cp/mut/[a-z0-9-]*-\(up\|new\)\.md#PLAN#' -e 's/"Ten lanes on `grok-4.6-fast-xhigh` at the PR head"/LANES/' -e 's/"Ten lanes on the `swarm-worker` role at the PR head"/LANES/' -e 's#"/goal"#GOAL#' -e 's#"goal.md"#GOAL#' -e 's#"git show origin/main:"#REREAD#' -e 's#"Re-read them at every tick"#REREAD#'; }
printf 'mutation\tup_problems\tnew_problems\tsame\n' > $W/corpus.tsv
for k in $(printf '%s\n' "${!M[@]}" | sort); do
  sed -e "${M[$k]}" $W/up.md > $W/mut/$k-up.md; sed -e "${M[$k]}" $W/new.md > $W/mut/$k-new.md
  cmp -s $W/mut/$k-up.md $W/up.md && echo "WARN: $k did not change up.md"
  cmp -s $W/mut/$k-new.md $W/new.md && echo "WARN: $k did not change new.md"
  set +e
  bun $UP $W/mut/$k-up.md 2>$W/mut/$k-up.err >/dev/null; ue=$?
  bun $NEW $W/mut/$k-new.md 2>$W/mut/$k-new.err >/dev/null; ne=$?
  set -e
  norm < $W/mut/$k-up.err | sort > $W/mut/$k-up.n; norm < $W/mut/$k-new.err | sort > $W/mut/$k-new.n
  same=$(cmp -s $W/mut/$k-up.n $W/mut/$k-new.n && echo yes || echo NO)
  printf '%s\t%s(exit %s)\t%s(exit %s)\t%s\n' "$k" "$(wc -l < $W/mut/$k-up.n)" $ue "$(wc -l < $W/mut/$k-new.n)" $ne "$same" >> $W/corpus.tsv
done
column -t -s $'\t' $W/corpus.tsv
printf '\n##### diffs where outputs differ\n'; for k in $(awk -F'\t' '$4=="NO"{print $1}' $W/corpus.tsv); do echo "--- $k"; diff $W/mut/$k-up.n $W/mut/$k-new.n || true; done
printf '\n##### mutations neither validator catches\n'; awk -F'\t' '$2 ~ /^0/ && $3 ~ /^0/ {print $1}' $W/corpus.tsv
printf '\n##### sample messages (new validator)\n'; cat $W/mut/drop-lane7-new.err $W/mut/no-goal-new.err $W/mut/mid-colon-new.err
