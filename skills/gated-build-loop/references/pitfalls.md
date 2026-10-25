# Pitfalls the loop has actually hit

Each entry: what happened, how it showed up, the rule that prevents it.

## Agents and isolation

- **"Remote" agents ran locally.** An agent started with remote isolation ran on the local machine and used local
  quota. *Rule:* verify where an agent runs (its worktree path, its machine) instead of assuming.
- **Worktrees inside the repo broke the linter.** Agent worktrees under `.claude/worktrees/` were picked up by the
  formatter/linter of the main tree. *Rule:* create worktrees outside the repo
  (`git worktree add <tmp>/wt/<BLOCK> -b <prefix>/<BLOCK> main`) and give the agent the path; remove them when done.
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
