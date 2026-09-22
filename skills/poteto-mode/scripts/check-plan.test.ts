import { expect, test } from "bun:test";
import { mkdtempSync, readFileSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

const here = import.meta.dir;
const playbook = readFileSync(join(here, "../playbooks/multi-phase-plan.md"), "utf8");
const skeleton = playbook.split("````markdown\n")[1].split("\n````")[0] + "\n";
const dir = mkdtempSync(join(tmpdir(), "check-plan-"));

function check(plan: string) {
	const file = join(dir, `${Math.random().toString(36).slice(2)}.md`);
	writeFileSync(file, plan);
	const r = Bun.spawnSync(["bun", join(here, "check-plan.mjs"), file]);
	return { exit: r.exitCode, err: r.stderr.toString() };
}

function mutate(from: RegExp, to: string) {
	const out = skeleton.replace(from, to);
	expect(out).not.toBe(skeleton);
	return out;
}

test("the playbook skeleton passes", () => {
	expect(check(skeleton)).toEqual({ exit: 0, err: "" });
});

const rejected: Record<string, () => string> = {
	"re-read list deleted": () => mutate(/^ {2}- \[ \] .*\n/gm, ""),
	"goal.md never written (Cursor /goal phrasing)": () =>
		mutate(/write `goal\.md` in the program directory of the pstack store/, "arm a `/goal`"),
	"no audit tick": () => mutate(/^.*30-minute audit tick.*\n/m, ""),
	"no status message": () => mutate(/status message/g, "report"),
	"lane dropped": () => mutate(/^- \[ \] Lane 7\..*\n/m, ""),
};

for (const [name, plan] of Object.entries(rejected)) {
	test(`rejects: ${name}`, () => {
		const r = check(plan());
		expect(r.exit).not.toBe(0);
		expect(r.err).not.toBe("");
	});
}
