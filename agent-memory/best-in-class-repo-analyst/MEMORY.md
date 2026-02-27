# Best-in-Class Repository Analyst - Memory

## Repository Files
Read ONLY the file(s) matching the user's language/framework context:
- repos-swift.md -- 6 Swift/macOS repos
- repos-python-fastapi.md -- 11 Python/FastAPI repos
- repos-ts-nestjs.md -- 12 TypeScript/NestJS repos
- repos-ts-nextjs.md -- 12 TypeScript/Next.js repos
- repos-mobile-expo.md -- 7 Expo/React Native repos
- repos-js-electron.md -- 1 Electron repo

## Cross-Framework Patterns
- **Monorepo architecture** dominates at scale: Turborepo + pnpm (cal.com, Dub, next-forge, create-t3-turbo, byCedric's Expo example).
- **Type-safe API layers** converge: tRPC (cal.com, create-t3-turbo), auto-generated TS clients from OpenAPI (Polar/FastAPI), GraphQL codegen (Vendure/NestJS).
- **RealWorld spec** implementations (FastAPI + NestJS) enable cross-framework comparison.
- **Observability** underrepresented except Blazity/next-enterprise (OpenTelemetry).
- **File-based routing** standard in 3 of 4 ecosystems: Next.js App Router, Expo Router, NestJS modules. FastAPI uses manual route registration.
- Strongest repos enforce conventions via tooling (linters, generators, strict TS), separate concerns at package/module level, and demonstrate patterns under real production load.

## User Preferences
(None recorded yet)
