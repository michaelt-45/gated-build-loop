# Pitfalls the loop has actually hit

Each entry: what happened, how it showed up, the rule that prevents it.

## Agents and isolation

- **"Remote" agents ran locally.** An agent started with remote isolation ran on the local machine and used local
  quota. *Rule:* verify where an agent runs (its worktree path, its machine) instead of assuming.
- **Worktrees inside the repo broke the linter.** Agent worktrees under `.claude/worktrees/` were picked up by the
  formatter/linter of the main tree. *Rule:* create worktrees outside the repo
  (`git worktree add <stable-dir>/wt/<BLOCK> -b <prefix>/<BLOCK> main`, not a session temp dir; see below) and
  give the agent the path; remove them when done.
- **Subagents may not write report files.** The harness refused summary files written by subagents. *Rule:* agents
  return summaries between markers; the orchestrator writes and commits them.
- **One agent reinstalled editable packages from its worktree** and switched every other tree to its code. *Rule:* no
  `pip install -e` / global installs inside agent worktrees; tests load code via the tree's own paths.
- **One agent ran `pkill` on test processes** and may have killed another agent's run. *Rule:* never kill processes
  you did not start.

## Gates and evals

- **A rounding mismatch turned every new baseline into a "regression".** Baselines were stored rounded to 6 digits,
  fresh values were compared unrounded with zero tolerance. *Rule:* compare at the precision you store; add a test
  with a non-terminating fraction (e.g. 246/291).
- **A test depended on the live project state.** It read the real eval config and assumed no block was finished, so
  every block merge broke it. *Rule:* tests load fixed thresholds or fixtures, never the live roadmap state.
- **A cloud session's "probe run" covered evals but not the full check command**, so the merge failed later.
  *Rule:* the probe that justifies a merge is the full check command on the merged tree.
- **Metrics that trivial strategies can pass.** "Put everything in one group", "attach every piece of evidence",
  "answer the majority class" reached targets on several metrics. *Rule:* every eval ships with negative controls;
  a metric a trivial strategy passes is reported as too lenient and must be fixed before it gates anything.
- **A metric that can never fail measures nothing.** A contradiction counter was always 0 because the test data never
  produced the case. *Rule:* for each metric, name the test case that would make it fail.

## Safety rules in practice

- **"Read-only" leaked through a temp directory.** A component created its temp folder relative to the working
  directory, which on the target machine could lie inside the data it must only read. *Rule:* temp roots come from
  config or an app-data folder and are refused if they lie under any read-only root; test with the working directory
  inside that root.
- **A filter had a race between two passes.** Items were filtered in pass 1 and fetched by position in pass 2; if the
  source changed in between, a filtered item was stored under another item's ID. *Rule:* pass 2 re-verifies identity
  (e.g. a hash) before storing.
- **Fail-open defaults.** "Production mode" was detected by one HTTP call; if it failed, the code assumed development
  and skipped a mandatory check. *Rule:* only an explicit development signal counts as development; everything else
  is production.
- **A convenience route exposed more than intended.** A read endpoint added for the test harness returned more
  metadata than any role should see. *Rule:* endpoints added for tests exist only in test mode until the access model
  is built.
- **Keyword lists are a floor, not a classifier.** A fixed word list in one language missed synonyms and other
  languages. *Rule:* lists may only make a classification stricter; the real classification comes from content, and
  lists live in configuration, not core code.

## Human in the loop

- **The orchestrator recorded the human's approval itself** and the harness blocked it as possible instruction
  poisoning. *Rule:* approvals are recorded when the human gives them in chat; the orchestrator only quotes them.
- **Too many questions stall the loop; too few surprise the human.** *Rule:* decide everything that is reversible,
  list it as "Decisions I made", ask only what blocks the next block, always with a recommendation.

## Worktrees and agent lifecycle

- **Worktrees in the session's temp directory vanished.** They sat in the session's scratch folder; a session
  restart deleted them with all uncommitted agent work and the transcripts the summary script reads. *Rule:* put
  worktrees in a stable folder outside the repo and outside any session directory (e.g.
  `~/.cache/<loop>/<repo>/wt/<BLOCK>`), and have agents commit before they report.
- **The repo was moved while agents ran.** Every worktree's `.git` file pointed at the old path ("not a git
  repository"). *Rule:* find the repo and run `git worktree repair <worktree>` from the main checkout; never
  re-initialise a repo in place.
- **A merged block's worktree was removed while a planner still read from it.** *Rule:* planning agents read from
  the main checkout (read-only) or their own worktree, never from another block's.
- **A late message restarted a finished agent.** A correction sent to an agent that had already finished resumed
  it, which put one agent over the parallel-agent budget. *Rule:* stop or ignore finished agents; for a small
  correction, edit the plan text yourself.
- **Corrections to a running planner produced mixed plans.** Messages that changed scope reached the planner
  mid-write; it returned several versions, the last one still containing parts the correction removed. *Rule:*
  stop the agent and start a fresh one with the full corrected brief, or correct the returned plan directly.

## Planning and scope

- **Plans and builds bloated.** Without a size limit, planners added self-test modes, guards, flags and exit codes
  nobody asked for; one module grew to several times what the acceptance criteria needed, and the human asked to
  keep it "only as big as necessary". *Rule:* every plan states a size budget (lines of code, plan length) and
  "nothing beyond the acceptance criteria"; the review lists anything beyond them as a finding.
- **A cross-plan contract existed in only one plan.** A planner claimed shared lists were "fixed verbatim in both
  plans"; they were in one, and the orchestrator repeated the claim in the next brief. *Rule:* verify cross-plan
  claims before briefing parallel builders.
- **Parallel blocks share files.** Two parallel blocks both had to edit the check command and the CLI entry point.
  *Rule:* the plans assign ownership down to lines (who edits which line, which lines separate the edits) and state
  the merge order; the second block merges `main` before it wires anything that needs the first.
- **The gate before the eval exists.** The merge rule says "check green and evals exit 0", but early blocks have no
  eval yet. *Rule:* until the eval block merges, the check command is the gate; the eval is wired into the check
  command in the same block that creates it, and it fails closed (non-zero) when its data is missing.
- **Planning can run ahead of building.** With a budget of two agents, the next block's plan was ready when the
  current block merged. *Rule:* plan block N+1 while block N builds or is reviewed, as long as its interfaces
  are fixed.

## Evals on synthetic data

- **A trivial shortcut passed every threshold while every control failed.** A dev-fitted "first word → label"
  table reached all targets. *Rule:* negative controls are a floor; the review also runs one or two obvious
  shortcut probes and reports them in the gate, and the human decides whether the data must get harder.
- **A perfect score said nothing about real input.** Dev and test came from the same templates, the classifier
  scored 1.0, and everyday inputs (e.g. "Refactor the loader") still fell to the fallback. *Rule:* the review
  tries a handful of invented everyday inputs and reports them; the docs say what the score does not prove.
- **Anti-overfitting machinery broke itself.** A held-out-vocabulary scheme meant to keep the builder honest was
  undermined by the generator's own sampling; only the review noticed. *Rule:* use the cheapest guard the review
  can verify (a dev/test split plus "tune on dev only"), and state in the gate what it does not prove.
- **Thresholds are numbers, but bind later.** Eval targets need the human's approval, yet they only bind when the
  first real classifier merges. *Rule:* build the harness with proposed targets, ask early, and block only the
  merge that depends on the answer.

## Public repositories

- **Absolute paths leak the local user name.** Worktree paths in the handoff, temp paths in agent summaries and
  a review quoting them all ended up in committed planning files. *Rule:* briefs tell agents "no absolute paths
  in files or summaries"; the orchestrator scans every summary and gate for home and temp paths before committing,
  and the handoff names worktrees with `~`-relative or placeholder paths.
- **Read-only agents cannot file backlog entries.** Reviewers and builders proposed backlog items in their reports;
  nobody created the files. *Rule:* the orchestrator files every proposed entry when it records the report.

## Human in the loop (setup and rework)

- **A pre-answered setup still waited for "ok".** The human answered all setup questions up front and asked to run
  until the milestone merged. *Rule:* if the human already authorised running, show the roadmap and continue; a
  "no" stops the loop.
- **Unclear whether rework needs a second review.** *Rule:* say in the gate how the rework was verified (second
  review agent, or the orchestrator's diff read plus the check on the merged tree) so the human can object.
