## Hard rules (never break)

1. <rule> — e.g. read-only access to external systems until block <X>.
2. <rule> — e.g. every database migration is reversible and tested up/down/up.
3. No secrets in code, logs, tests, commits. Only `.env` (git-ignored).
4. Ideas outside the current block go to `.planning/backlog/`, not into code.
5. No numbers, prices, legal texts or customer-facing prompts without the human's approval.

## Build loop

**Orchestrator:** one session; plans and builds nothing itself; starts planning, build and review agents; keeps
only plans, summaries and gates in context; keeps `.planning/STATE.md` and `.planning/loop/HANDOFF.md` current.

**Model per task, always the lightest that is safe:**

| Task | Model |
|---|---|
| renames, docs, tests from a template, lint fixes, summary formatting | haiku |
| implementation from a plan, tests, adapters, migrations, UI from a contract | sonnet |
| planning, architecture, reviews, security, privacy, access rules | opus |

**Commits and push:** build agents commit small and thematic on `<prefix>/<BLOCK>`; after a passed gate the
orchestrator merges to `main` and pushes. Never `--force`, never secrets. Every merge to `main` needs
`<CHECK COMMAND>` green and `<EVAL COMMAND>` exit 0 on the merged tree.

**Stop only for the human's decisions** (scope, numbers, prices, legal, credentials, irreversible or outward-facing
actions, budget). Everything else: decide, and list it in the gate under "Decisions I made".

**Budgets:** pause at 5-hour usage <88 %>, no new build agents at weekly usage <92 %>, at most <2> local agents,
heavy runs under a lock. At about 40 % context: clean pause point, update STATE and HANDOFF, tell the human.

## Review gate (`.planning/<BLOCK>/REVIEW.md`, also at the top of `.planning/loop/FOUNDER_REVIEW.md`)

See `templates/REVIEW.md` in the gated-build-loop skill. The human answers "ok" / "ok, but …" / "no: …".

## Definition of done

1. All must-requirements of the block implemented; acceptance criteria checkable.
2. `<CHECK COMMAND>` green; new logic tested including error paths; anything touching data, rights or evidence
   always tested.
3. Evals not worse than before the block; on merge the block is marked finished and baselines are rewritten
   (worse only with a stated reason).
4. UI changes clicked through on the golden path, at phone width.
5. Docs, glossary and `.planning/STATE.md` updated.
