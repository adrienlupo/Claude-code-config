# Baseline

The repo's standards override every rule below.

- **DRY**: look for an existing helper or component before accepting new code. No duplication within the diff. A new shared abstraction only on the third copy, and only if it passes the deletion test.
- **Minimal**: no unused code, parameters or options. No handling for cases that cannot happen. No comments that restate the code. The smallest diff that meets the intent.
- **Straightforward**: no layer of indirection without two real implementations behind it. No pass-through wrappers. Names say what the thing does. Flat code over deeply nested code. When DRY and straightforward conflict, straightforward wins.
- **Design** (vocabulary from `codebase-design`): small interfaces over a lot of behaviour. Callers use a module only through its interface. Tests go through the interface too.
- **Tests**: test behaviour, not internals. No useless tests: tautologies (`expect(true).toBe(true)`), tests of the library or framework (that Prisma saves a row, that React renders), tests that repeat the implementation (asserting a mock got exactly what the code passes it). No test that cannot fail.
- **Errors**: no swallowed errors (`catch {}`). No `try/catch` that only re-throws. Handle errors at the level that can act on them.
- **Types** (TypeScript): no `any`, `as` casts or `!` used to quiet the compiler.
- **One way to do things**: if the codebase already solves a problem one way (fetching, validation, state…), the diff uses that way and does not add a second pattern.
- **No new dependency** when the stack or platform already covers it.
- **Leftovers**: no `console.log`, commented-out code, or TODO without a ticket.

## Fowler smells

Labelled possibilities — "possible Feature Envy" — never hard violations. Each reads *what it is* → *how to fix*:

- **Mysterious Name**: a function, variable, or type whose name doesn't reveal what it does or holds. → rename it; if no honest name comes, the design's murky.
- **Duplicated Code**: the same logic shape appears in more than one hunk or file in the change. → extract the shared shape, call it from both.
- **Feature Envy**: a method that reaches into another object's data more than its own. → move the method onto the data it envies.
- **Data Clumps**: the same few fields or params keep travelling together (a type wanting to be born). → bundle them into one type, pass that.
- **Primitive Obsession**: a primitive or string standing in for a domain concept that deserves its own type. → give the concept its own small type.
- **Repeated Switches**: the same `switch`/`if`-cascade on the same type recurs across the change. → replace with polymorphism, or one map both sites share.
- **Shotgun Surgery**: one logical change forces scattered edits across many files in the diff. → gather what changes together into one module.
- **Divergent Change**: one file or module is edited for several unrelated reasons. → split so each module changes for one reason.
- **Speculative Generality**: abstraction, parameters, or hooks added for needs the intent doesn't have. → delete it; inline back until a real need shows.
- **Message Chains**: long `a.b().c().d()` navigation the caller shouldn't depend on. → hide the walk behind one method on the first object.
- **Middle Man**: a class or function that mostly just delegates onward. → cut it, call the real target direct.
- **Refused Bequest**: a subclass or implementer that ignores or overrides most of what it inherits. → drop the inheritance, use composition.
