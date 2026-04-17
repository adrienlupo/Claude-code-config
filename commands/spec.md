---
allowed-tools: Read, Write, Edit, AskUserQuestion, Glob, Grep
description: Read a spec file and interview the user in depth, then write the refined spec back to the file.
---

Read this $ARGUMENTS and follow the process below. The input may range from a single sentence to an already detailed draft -- either way, the output must be an exhaustive, self-contained spec.

Read the spec file first. If the file is not found, try reading it once more (the path may have been misresolved). If the file is still not found on the second attempt, ABORT immediately -- do not interview, do not write anything, just inform the user that the file could not be found and stop.

Then interview me in detail using the AskUserQuestion tool about literally anything: technical implementation, UI & UX, concerns, tradeoffs, etc. but make sure the questions are not obvious.

Be very in-depth and continue interviewing me continually until it's complete, then write the fully enriched spec back to the file -- replacing the original content entirely. Every tradeoff, scope boundary, and design decision from the interview must be captured.

If the spec contains Figma URLs, keep them in the final spec.