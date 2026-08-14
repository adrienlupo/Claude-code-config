---
name: stack-this
description: Take a large diff — typically the uncommitted output of an implement loop — and slice it into a stack of dependent GitHub PRs so it can be reviewed in readable pieces. Use when the user says "stack this", has a big diff or oversized branch to split for review, or wants stacked PRs from finished work.
argument-hint: "Nothing (current working-tree diff), or a branch/range"
---

Take a finished diff and slice it into a stack of pull requests a reviewer can actually read. This skill does not build or change the work — the diff is done; only its packaging for review changes. If the diff is not done, this is the wrong skill.

## The input

The working-tree diff by default — uncommitted, unpushed, exactly as `implement-loop` leaves it. A branch or range, if one was given. Read the whole diff before slicing: the cut lines come from what the diff actually contains, not from how the work happened to be built.

Only where the work ships by pull request — a git repo with a remote the user reviews in. A scratch build or a repo with no remote has nothing to stack: say so and stop.

## The slicing

Slice by dependency layer, bottom-up, not by the pieces the work was built in: the schema before the API that uses it, the API before the UI that calls it, the utility before its callers. Each branch is one logical change, short enough to read in one sitting, and green on its own base — the repo's checks pass at every layer of the stack, not just at the top, because a reviewer approves each PR as if the layers above it did not exist yet.

A hunk that serves two layers goes in the lower one. A file that mixes layers gets split across commits, not shoved wholesale into whichever branch touched it first.

Propose the slicing to the user before pushing anything — the layers, one line each on what and why — since pushing and opening PRs is outward-facing. Then execute.

## The mechanics

Use the `gh-stack` skill for the branch and PR mechanics: creating the chain of dependent branches, pushing, opening the PRs with their bases pointing at each other, and the sync/rebase commands the user will need later. Each PR's description says what its layer does and what it sits on.

When the stack is up, report it: each PR, its layer, its link, in order from the bottom.
