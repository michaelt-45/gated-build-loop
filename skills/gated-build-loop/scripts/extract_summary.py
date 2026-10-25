#!/usr/bin/env python3
"""Extract agent summaries from a Claude Code task output (JSONL) and write them to files.

Agents return their summary between ===SUMMARY-START=== and ===SUMMARY-END===. The last string in the
transcript that contains the markers wins. With several output paths, several blocks are written in order.

Usage: extract_summary.py <task-output.jsonl> <target.md> [<target2.md> ...]
"""

import json
import sys

START, END = "===SUMMARY-START===", "===SUMMARY-END==="


def strings(node):
    if isinstance(node, str):
        yield node
    elif isinstance(node, dict):
        for value in node.values():
            yield from strings(value)
    elif isinstance(node, list):
        for value in node:
            yield from strings(value)


def main() -> int:
    if len(sys.argv) < 3:
        print(__doc__.strip(), file=sys.stderr)
        return 2
    source, targets = sys.argv[1], sys.argv[2:]
    best = None
    with open(source, encoding="utf-8") as fh:
        for line in fh:
            try:
                record = json.loads(line)
            except json.JSONDecodeError:
                continue
            for text in strings(record):
                if text.count(START) >= len(targets) and text.count(END) >= len(targets):
                    best = text
    if best is None:
        print("no summary markers found", file=sys.stderr)
        return 1
    blocks = [part.split(END, 1)[0].strip() for part in best.split(START)[1:]][-len(targets):]
    for block, target in zip(blocks, targets):
        lines = block.splitlines()
        # The harness may indent hand-back reports by two spaces; undo that consistently.
        if lines and all(not l or l.startswith("  ") for l in lines[1:]):
            lines = [lines[0]] + [l[2:] for l in lines[1:]]
        with open(target, "w", encoding="utf-8") as fh:
            fh.write("\n".join(lines) + "\n")
        print(f"{target}: {lines[0] if lines else ''}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
