---
id: <yyyymmdd>-<slug>
source: review:<BLOCK> | eval:<id> | build:<BLOCK>
impact: 1-3
confidence: 0.0-1.0
effort: 1-3
risk: 1-3
blocking: false
score: <impact * confidence * risk / effort>
block: <BLOCK where it belongs>
status: open | done
---
# <one-line finding>
**Finding:** what is wrong or missing.
**Evidence:** file:line, command, or eval report.
**Proposal:** smallest change that fixes it, and which block takes it.
