#!/usr/bin/env python3
"""Check a workflow script before it runs. Exit 2, naming each breach, unless it dispatches only through ventilate's run().

Usage:
    preflight.py SCRIPT

- GUARD and run() are pasted exactly as ventilate's SKILL.md prints them (trailing spaces and CRLF aside):
  intact, run() refuses any model but haiku|sonnet|opus and any effort it can't name;
- the code - comments, strings and prompt text aside - names `agent` nowhere but inside run();
- it starts no nested workflow(), whose script this never reads.

A model or effort chosen at run time passes run()'s guard only if it is one run() allows; what each
agent actually ran on is ventilation.py --check's, once the workflow returns.
Exit 1 when the script can't be read.
"""
import pathlib
import re
import sys

SKILL = pathlib.Path(__file__).resolve().parent.parent / "SKILL.md"


def norm(s):
    return "\n".join(line.rstrip() for line in s.strip().splitlines())


def code_only(src):
    """src with comments, strings and template text blanked; ${…} inside templates stays code."""
    out, i, n, tpl, depth = [], 0, len(src), False, []   # depth: open braces in each ${…}
    while i < n:
        c = src[i]
        if tpl:
            if c == "\\":
                i += 2
            elif c == "`":
                tpl, i = False, i + 1
                out.append(" ")
            elif src.startswith("${", i):
                tpl, i = False, i + 2
                depth.append(0)
                out.append(" ")
            else:
                i += 1
            continue
        if src.startswith("//", i):
            j = src.find("\n", i)
            i = n if j < 0 else j
        elif src.startswith("/*", i):
            j = src.find("*/", i + 2)
            i = n if j < 0 else j + 2
            out.append(" ")
        elif c in "'\"":
            j = i + 1
            while j < n and src[j] not in (c, "\n"):
                j += 2 if src[j] == "\\" else 1
            i = j + 1
            out.append(" ")
        elif c == "`":
            tpl, i = True, i + 1
            out.append(" ")
        elif c == "}" and depth and depth[-1] == 0:
            depth.pop()
            tpl, i = True, i + 1
            out.append(" ")
        else:
            if depth and c == "{":
                depth[-1] += 1
            elif depth and c == "}":
                depth[-1] -= 1
            out.append(c)
            i += 1
    return "".join(out)


def main():
    if len(sys.argv) != 2 or sys.argv[1] in ("-h", "--help"):
        print(__doc__.strip())
        return 1
    try:
        src = pathlib.Path(sys.argv[1]).read_text()
    except OSError as e:
        print(f"preflight: {e}", file=sys.stderr)
        return 1
    block = re.search(r"```js\n(.*?)```", SKILL.read_text(), re.S)[1]

    breaches = []
    if norm(block) not in norm(src):
        breaches.append("GUARD or run() differs from ventilate's — paste them exactly as printed, never loosened")
    code = code_only(src)
    if len(re.findall(r"\bagent\b", code)) > len(re.findall(r"\bagent\b", code_only(block))):
        breaches.append("agent named outside run() — every dispatch goes through run()")
    if re.search(r"\bworkflow\s*\(", code):
        breaches.append("nested workflow() — its script skips this preflight")

    if breaches:
        print(f"preflight: {sys.argv[1]} refused —\n" + "\n".join(f"  {b}" for b in breaches))
        return 2
    print(f"preflight: {sys.argv[1]} ok — run() as printed, every dispatch through it")
    return 0


if __name__ == "__main__":
    sys.exit(main())
