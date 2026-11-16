import { mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { spawnSync } from "node:child_process";
import { expect, test } from "bun:test";

const checker = join(import.meta.dir, "check-plan.mjs");
const rule =
	"Tests alone are not sufficient verification. A PR is verified only when its unit, live, and perf boxes are all checked.";

const validPlan = `# Demo

## How to read this
One box is one unit of work and names the evidence. Check a box only when its evidence exists. See playbooks/.
${rule}

## Program checklist
### Arm the program
  - [ ] \`swarm/SKILL.md\`
1-hour audit tick status message
### Spawn owners
### PR mechanics
### Verdict and merge
### Boot recipe

## PR 1
**Depends on.** None.
**Files.**
- [ ] Do the thing.
**Build.**
- [ ] Do the thing.
**You see.**
- [ ] Do the thing.
**Verify, unit.** ${rule}
- [ ] Check the thing.
**Verify, live.** ${rule} Ten lanes on \`example-model\` at the PR head
${Array.from({ length: 10 }, (_, i) => `- [ ] Lane ${i + 1}. Save \`lane-${i + 1}.png\`. Pass when evidence exists.`).join("\n")}
**Verify, perf.** ${rule}
- [ ] Metric. Recorded.
- [ ] Probe. Recorded.
- [ ] Baseline. Recorded.
- [ ] Rule. Recorded.
**Review gate.** None.
**Merge.**
- [ ] Merge when approved.

## Close the program
Close.

## Appendix Prototype evidence
Recorded.
`;

const checkRaw = (content: string) => {
	const directory = mkdtempSync(join(tmpdir(), "check-plan-test-"));
	const file = join(directory, "plan.md");
	writeFileSync(file, content);
	try {
		return spawnSync("node", [checker, file], { encoding: "utf8" });
	} finally {
		rmSync(directory, { recursive: true, force: true });
	}
};

const runPlan = (example: string, expectedExit: number) => {
	const result = checkRaw(validPlan + example);
	expect(result.status).toBe(expectedExit);
	return result;
};

test("accepts ordinary, indented, and longer closing fences", () => {
	for (const indent of ["", " ", "  ", "   "])
		runPlan(`${indent}\`\`\`markdown\n## Example only\n${indent}\`\`\`\n`, 0);
	runPlan("```markdown\n## Example only\n````\n", 0);
});

test("accepts nested backticks and tilde info strings", () => {
	runPlan("````markdown\n```markdown\n## Example only\n```\n````\n", 0);
	runPlan("~~~markdown `info`\n## Example only\n ~~~\n", 0);
});

test("keeps mismatched, shorter, and suffixed closers inside the fence", () => {
	runPlan("````markdown\n~~~\n## Example only\n````\n", 0);
	runPlan("````markdown\n```\n## Example only\n````\n", 0);
	runPlan("````markdown\n``` info\n## Example only\n````\n", 0);
});

test("rejects headings and prose outside a proper close", () => {
	for (const suffix of ["  ", "\t"]) {
		const heading = runPlan(`\`\`\`markdown\n## Example only\n\`\`\`${suffix}\n## Example only\n`, 1);
		expect(heading.stderr).toContain('"## Example only" after Close the program is not an appendix');
	}

	const prose = runPlan("```markdown\nThis prose has a mid-sentence colon: inside code\n```\nThis prose has a mid-sentence colon: bad.\n", 1);
	expect(prose.stderr).toContain("mid-sentence colon");
});

test("rejects backtick info strings containing a backtick", () => {
	const result = runPlan("```markdown `invalid`\n## Example only\n```\n", 1);
	expect(result.stderr).toContain('"## Example only" after Close the program is not an appendix');
});

test("ignores prose punctuation inside matching multi-backtick code spans", () => {
	for (const count of [2, 3, 4]) {
		const delimiter = "`".repeat(count);
		runPlan(`Use ${delimiter}echo \`x\`: “quoted” — example${delimiter}.\n`, 0);
	}
});

test("checks prose following a multi-backtick span and unmatched delimiters", () => {
	const outside = runPlan("Use ``echo `x`: y``. Bad: prose.\n", 1);
	expect(outside.stderr).toContain("mid-sentence colon");
	const unmatched = runPlan("Use ``unclosed: bad` here.\n", 1);
	expect(unmatched.stderr).toContain("mid-sentence colon");
});

const playbook = readFileSync(join(import.meta.dir, "../playbooks/multi-phase-plan.md"), "utf8");
const rawSkeleton = playbook.split("````markdown\n")[1].split("\n````")[0] + "\n";
const filledSkeleton = rawSkeleton.replace("`<swarm workers model>`", "`swarm-worker`");

test("rejects unfilled <swarm workers model> placeholder in playbook skeleton", () => {
	const result = checkRaw(rawSkeleton);
	expect(result.status).toBe(1);
	expect(result.stderr).toContain("Verify, live lacks");
});

test("accepts the playbook skeleton once <swarm workers model> is filled", () => {
	const result = checkRaw(filledSkeleton);
	expect(result.status).toBe(0);
	expect(result.stderr).toBe("");
});

const mutate = (from: RegExp, to: string) => {
	const out = filledSkeleton.replace(from, to);
	expect(out).not.toBe(filledSkeleton);
	return out;
};

const rejectedSkeletonMutations: Record<string, () => string> = {
	"re-read list deleted": () => mutate(/^ {2}- \[ \] .*\n/gm, ""),
	"1-hour audit tick deleted": () => mutate(/^.*1-hour audit tick.*\n/m, ""),
	"status message deleted": () => mutate(/status message/g, "report"),
	"lane dropped": () => mutate(/^- \[ \] Lane 7\..*\n/m, ""),
	"verification rule deleted": () => mutate(/Tests alone are not sufficient verification\./, "Tests are fine."),
};

for (const [name, buildMutatedPlan] of Object.entries(rejectedSkeletonMutations)) {
	test(`rejects skeleton mutation: ${name}`, () => {
		const result = checkRaw(buildMutatedPlan());
		expect(result.status).toBe(1);
		expect(result.stderr).not.toBe("");
	});
}
