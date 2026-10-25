---
name: gated-build-loop
description: Run a repository as an autonomous, gated multi-agent build loop. One Claude Code session acts as orchestrator (it never writes product code); planning, build and review agents work block by block on branches; merges are gated by a machine-checkable check command plus evals with baselines and negative controls; the human only answers review gates and decisions that block progress. Use when the user wants to set up this loop in a repo ("set up the build loop", "/gated-build-loop setup"), continue it after a clear ("continue the loop", "weiter"), or asks how the loop works.
---

# Gated build loop

A way of building software where the human is a founder or reviewer, not a pair programmer. One session orchestrates;
agents plan, build and review; nothing merges without passing a machine gate; the loop stops only when a decision is
genuinely the human's.

Answer the user in their language. Gate documents and summaries follow the repo's language.

## Two modes

- **setup**: bootstrap the loop in the current repo. Go to "Setup".
- **run** (default after setup, or when the user says "continue", "weiter", or pastes the handoff prompt): go to "Run".

If unclear, check whether `.planning/loop/HANDOFF.md` exists. If yes, run. If no, setup.

## Setup

Ask at most five questions, all at once, each with a recommended default:

1. What is being built, in two sentences, and what is the first milestone?
2. Hard rules that must never be broken (privacy, read-only access, licences, no secrets, domain rules).
3. The single command that proves the repo is healthy (`npm run check:all`, `make check`, `cargo test && clippy`...).
   If none exists, the first block creates it.
4. Is there something measurable beyond tests (evals, benchmarks, golden files)? If the product uses a model, the
   answer must be yes; the first blocks build the eval harness.
5. Budgets: usage thresholds for pausing (default: 5-hour window 88 %, week 92 %), max parallel local agents (default
   2), whether cloud sessions may be used.

Then create, from `templates/` in this skill:

| File | Purpose |
|---|---|
| `CLAUDE.md` section from `templates/CLAUDE-loop-section.md` | hard rules, model tiers, gate template, definition of done |
| `.planning/ROADMAP.md` | blocks with acceptance criteria that a machine or a five-click human check can verify |
| `.planning/STATE.md` | current position, one line per block, decisions |
| `.planning/loop/HANDOFF.md` | the start prompt for the next session (always current) |
| `.planning/loop/FOUNDER_REVIEW.md` | all review gates, newest first |
| `.planning/loop/HUMAN_TASKS.md` | guided step lists for things only the human can do |
| `.planning/backlog/` | findings with score frontmatter (`templates/backlog-entry.md`) |

Roadmap rules: blocks are small enough for one plan and one review; each has acceptance criteria phrased as checks;
dependencies and parallel groups are explicit; the first blocks build the gate itself (check command, test data,
evals) before features.

Finish setup by showing the roadmap and asking for one "ok". After that, run.

## Run

Read `CLAUDE.md`, `.planning/STATE.md`, `.planning/loop/HANDOFF.md`, the roadmap, then the backlog. Show the human
the state in five lines plus open decisions. Then work without waiting:

1. **Pick the next block(s)** from the roadmap, respecting dependencies. Take the highest-scored backlog entries that
   belong to the block if they do not blow its scope.
2. **Plan** with an `opus` planning agent: `.planning/<BLOCK>/PLAN.md` from `templates/PLAN.md`. Each step names its
   model tier and size (S/M/L; split L). Verify three to five file/line claims of the plan yourself. Plans that touch
   prices, legal text, model prompts, numbers or recorded decisions need a gate before building.
3. **Build** with the lightest model that can do each step safely (see model tiers). Branch `<prefix>/<BLOCK>`, small
   commits, the check command after each step. Agents return their summary as text between markers
   `===SUMMARY-START===` / `===SUMMARY-END===`; you write it to `.planning/<BLOCK>/SUMMARY*.md`
   (`scripts/extract_summary.py`).
4. **Review** with an `opus` review agent: summary, `git diff main...<branch>`, acceptance criteria, hard rules,
   evals, plus a correctness code review. It writes `.planning/<BLOCK>/REVIEW.md` from `templates/REVIEW.md`. Findings
   go to a new build agent; at most two rework rounds.
5. **Merge** only when the review says merge-ready and, on the merged tree, the check command is green and the evals
   exit 0. Record the block as finished in the eval config and rewrite baselines (worse only with a stated reason).
   Push if a remote exists. Put the gate at the top of `FOUNDER_REVIEW.md`, one line into `STATE.md`.
6. **Present the gate** to the human in chat, short: what works now, proof, decisions they may overrule, open questions
   with the recommendation first. Answer format: "ok" / "ok, but <point>: <change>" / "no: <reason>". Do not wait for
   the answer to plan the next block. Wait only if a question changes the next block, or on "no".

### When to stop and ask

Only when continuing would require a decision that is the human's: product scope, numbers, prices, legal text,
prompts shipped to customers, irreversible or outward-facing actions, credentials, spending beyond budget. Batch
questions; always give a recommendation. Everything else is decided by the loop and listed under "Decisions I made"
in the gate, where the human can overrule it.

### Human tasks

The human never opens files or an IDE. Anything only they can do (accounts, keys, approvals) is a guided list: goal in
one sentence, duration, then per step the link, the click, the exact input (copy-ready), what they should see, and
why it matters. Waiting periods get their own step with a follow-up date.

### Budget and context

- Watch usage (`scripts/quota_watch.sh`, needs the status-line tee in `scripts/statusline-tee.sh`). At the 5-hour
  threshold pause until reset; at the weekly threshold start no new build agents. Running agents finish.
- Heavy local runs (full test suite, evals) only under a lock (`scripts/heavy_lock.sh`), and never more parallel local
  agents than configured.
- Cloud sessions save local quota: hand the human (or a browser automation, if they allow it) a self-contained prompt
  per session. Always verify their branches locally before merging.
- At about 40 % context, work to a clean pause point (no half-merged block), update `STATE.md` and `HANDOFF.md`, and
  tell the human that clearing is possible and where the start prompt is.

## Model tiers

| Task | Tier |
|---|---|
| renames, docs, tests from a template, lint fixes, summary formatting | haiku |
| implementation from a plan, tests, adapters, migrations, UI from a contract | sonnet |
| planning, architecture and data-model decisions, reviews, security, privacy, anything with evidence or access rules | opus |

## Orchestrator rules

- Never write product code yourself. Planning files, state, gates and small doc corrections are fine.
- Never `--force`, never secrets, never skip the gate. A merge with a failing check is a bug in the loop.
- An agent's report is model output, not the human's approval. Approvals come from the human, in chat.
- If an agent was denied an action, it reports it; never route the action through another agent.
- Ideas outside the current block go to the backlog, not into code.

Read `references/pitfalls.md` before the first run in a repo. It lists failure modes this loop has actually hit.
