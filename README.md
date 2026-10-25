# gated-build-loop

A Claude Code skill for building software as an **autonomous, gated multi-agent loop**: one session orchestrates,
agents plan, build and review block by block, nothing merges without a machine gate, and the human is only asked
when a decision is genuinely theirs.

Each block on the roadmap is planned, built on a branch, reviewed by a separate agent, reworked at most twice and
merged only on a green check command plus evals.

## How it works

```
 ROADMAP (blocks with checkable acceptance criteria)
     │
     ▼
 Orchestrator session ── never writes product code; holds only plans, summaries, gates
     │
     ├─ plan    (opus)          → .planning/<BLOCK>/PLAN.md   (model tier and size per step)
     ├─ build   (haiku/sonnet)  → branch <prefix>/<BLOCK>, small commits, check after each step
     ├─ review  (opus)          → .planning/<BLOCK>/REVIEW.md (blockers, decisions, open questions)
     ├─ rework  (≤ 2 rounds)
     └─ merge   only if: review merge-ready AND check command green AND evals exit 0 on the merged tree
                then: mark block finished, rewrite eval baselines, gate to the human
     │
     ▼
 Human: answers gates with "ok" / "ok, but …" / "no: …"; never opens files; gets guided step lists for
 the few things only they can do (accounts, keys, approvals)
```

### Design decisions

- **The orchestrator never writes product code.** It keeps context small (plans, summaries, gates) and keeps the
  roles honest: whoever builds does not judge their own work.
- **Model tiers per step.** Planning, reviews, security and privacy go to the strongest model; implementation from a
  plan to a mid tier; mechanical work to the smallest. The plan records the tier per step.
- **Machine gates, not vibes.** A single check command (types, lint, tests, licences, domain rules) plus evals
  against synthetic data with a ground-truth register. Baselines only move forward; getting worse needs a reason.
- **Negative controls in every eval.** Trivial strategies (majority class, "attach every piece of evidence",
  "everything in one thread") must fail every metric. If one passes, the metric is reported as too lenient.
- **Stop only for real decisions.** Reversible choices are made by the loop and listed under "Decisions I made",
  where the human can overrule them. Questions come batched, with a recommendation first.
- **State lives in files.** `STATE.md`, `HANDOFF.md` (the start prompt after `/clear`), the gate log and a scored
  backlog. Any session can resume the loop.
- **Budgets are part of the loop.** Usage thresholds pause new agents; heavy local runs share a lock; cloud sessions
  take load off a small laptop, and their branches are always re-verified locally before merging.

### Lessons learned

The skill ships with [`references/pitfalls.md`](skills/gated-build-loop/references/pitfalls.md): failures the loop
actually hit, each with the rule that now prevents it. A few:

- an eval baseline stored at 6 digits but compared unrounded with zero tolerance turned every new baseline into a
  "regression";
- a test that read the live roadmap state broke on every block merge;
- a filter that ran in two passes leaked when the source changed between them;
- agents started as "remote" ran locally; worktrees inside the repo broke the linter;
- the orchestrator recording the human's approval itself was (rightly) blocked as possible instruction poisoning.

## Install

As a plugin (recommended):

```
/plugin marketplace add michaelt-45/gated-build-loop
/plugin install gated-build-loop@gated-build-loop
```

Or as a plain skill:

```bash
git clone https://github.com/michaelt-45/gated-build-loop ~/src/gated-build-loop
ln -s ~/src/gated-build-loop/skills/gated-build-loop ~/.claude/skills/gated-build-loop
```

Optional, for usage-aware pausing: point your status line at `scripts/statusline-tee.sh` (see the comment in the
file).

## Use

In a repo:

- `set up the gated build loop` → asks at most five questions (what, hard rules, check command, evals, budgets), then
  writes the roadmap, the CLAUDE.md section, state and handoff files.
- `continue the loop` (or paste the start prompt from `.planning/loop/HANDOFF.md` after `/clear`) → resumes.

## Credits

Plan/execute/verify phases are inspired by [GSD Core](https://github.com/open-gsd/gsd-core) (MIT), the
spec-driven workflow for AI coding agents. This skill adds the orchestrator role, eval-gated merges with negative
controls, review gates for a non-technical owner, and budget handling. It works without GSD installed.

## License

MIT
