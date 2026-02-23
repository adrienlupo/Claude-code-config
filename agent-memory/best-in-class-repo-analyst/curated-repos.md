# Curated Best-in-Class Repositories

---

## Swift

### jordanbaird/Ice

- **GitHub**: https://github.com/jordanbaird/Ice
- **Category**: Menu Bar Utility
- **Stars**: 25,900
- **Last Commit**: 2025-09-20
- **Why Best in Class**: Pure SwiftUI, macOS 14+ APIs, liquid glass design. Best reference for building a modern menu bar utility.

### p0deje/Maccy

- **GitHub**: https://github.com/p0deje/Maccy
- **Category**: Clipboard Manager
- **Stars**: 18,600
- **Last Commit**: 2026-02-10
- **Why Best in Class**: KISS principle. Comprehensive unit + UI tests, SwiftLint, Periphery for dead code. Keyboard-first UX. Rewritten in SwiftUI 2026.

### glushchenko/fsnotes

- **GitHub**: https://github.com/glushchenko/fsnotes
- **Category**: Notes Manager
- **Stars**: 7,200
- **Last Commit**: 2026-02-10
- **Why Best in Class**: Shared FSNotesCore framework for macOS/iOS, AES-256 encryption, Markdown with 30+ syntax languages. Handles 10k+ files.

### buresdv/Cork

- **GitHub**: https://github.com/buresdv/Cork
- **Category**: Homebrew GUI
- **Stars**: 4,100
- **Last Commit**: 2026-01-31
- **Why Best in Class**: SwiftUI + CLI wrapping patterns, Tuist for project generation, 10x faster than Homebrew CLI. Modern build tooling.

### swiftbar/SwiftBar

- **GitHub**: https://github.com/swiftbar/SwiftBar
- **Category**: Menu Bar Plugins
- **Stars**: 3,700
- **Last Commit**: 2026-02-07
- **Why Best in Class**: Plugin-based architecture, any-language scripting, cron scheduling. Shows how to build extensible menu bar apps.

### ivoronin/TomatoBar

- **GitHub**: https://github.com/ivoronin/TomatoBar
- **Category**: Pomodoro Timer
- **Stars**: 3,100
- **Last Commit**: 2026-02-08
- **Why Best in Class**: Lean and focused (169 commits). JSON event logging, URL schemes, fully sandboxed, no special entitlements. Clean minimal app.

---

## Python (FastAPI)

### fastapi/full-stack-fastapi-template

- **GitHub**: https://github.com/fastapi/full-stack-fastapi-template
- **Category**: Official template
- **Stars**: 41,300
- **Last Commit**: Active (2025-2026)
- **Score**: 94/100
- **Official**: Linked from fastapi.tiangolo.com/project-generation
- **Why Best in Class**: The ONLY template directly linked from official FastAPI docs. Maintained by Sebastian Ramirez under the fastapi org. FastAPI + SQLModel + Pydantic + PostgreSQL + Docker Compose with JWT auth, Traefik, and Playwright E2E.
- **Key Learnings**: JWT auth flow, SQLModel ORM patterns, Pydantic BaseSettings, Docker Compose multi-service, Traefik HTTPS, CI/CD with GitHub Actions, Copier templating.
- **Caveats**: Opinionated stack (React frontend, SQLModel). Previously at tiangolo/full-stack-fastapi-postgresql.

### zhanymkanov/fastapi-best-practices

- **GitHub**: https://github.com/zhanymkanov/fastapi-best-practices
- **Category**: Best practices guide
- **Stars**: 14,200-16,200
- **Last Commit**: Aug 2025
- **Score**: 93/100
- **Why Best in Class**: Most-starred FastAPI best practices repo. Battle-tested conventions from production startups covering async/sync routing, DI, project structure (inspired by Netflix Dispatch), Pydantic validation, background tasks.
- **Key Learnings**: Domain-based project structure (src/auth/, src/posts/), async vs sync route decisions, DI for validation, Pydantic custom validators, Alembic migrations, CORS config.
- **Caveats**: Not a runnable project -- README with code snippets only.

### Netflix/dispatch

- **GitHub**: https://github.com/Netflix/dispatch
- **Category**: Production application (enterprise)
- **Stars**: 6,400
- **Last Commit**: Archived Sep 2025
- **Score**: 89/100
- **Official**: Testimonial on FastAPI homepage
- **Why Best in Class**: Netflix's production incident management platform. FastAPI + SQLAlchemy + PostgreSQL. Enterprise plugin architecture, multi-tenant data models, Slack/Jira/PagerDuty integrations. Inspired fastapi-best-practices structure.
- **Key Learnings**: Enterprise plugin architecture, domain-driven folder structure, complex SQLAlchemy relationships, Slack bot integration, multi-tenant data isolation, background task orchestration.
- **Caveats**: ARCHIVED. Very large codebase. Some patterns Netflix-specific.

### fastapi-users/fastapi-users

- **GitHub**: https://github.com/fastapi-users/fastapi-users
- **Category**: Library (auth/user management)
- **Stars**: 6,000
- **Last Commit**: Feb 2026 (maintenance mode)
- **Score**: 88/100
- **Why Best in Class**: De facto standard for FastAPI user management. Registration, login, OAuth2, JWT, password reset. Clean generics, DI, protocol-based abstractions with separate DB adapters.
- **Key Learnings**: Generic router factories with DI, transport/strategy/backend separation, Pydantic model inheritance for user schemas, OAuth2 flow, database adapter abstraction.
- **Caveats**: Maintenance mode -- security updates only. Successor toolkit in progress.

### polarsource/polar

- **GitHub**: https://github.com/polarsource/polar
- **Category**: Production SaaS
- **Stars**: 5,700
- **Last Commit**: Active (2025-2026)
- **Score**: 85/100
- **Why Best in Class**: Commercially operated SaaS on FastAPI + SQLAlchemy + PostgreSQL + Redis + Dramatiq. Handles real payments, subscriptions, license keys. Large-scale FastAPI application with background jobs and Stripe processing.
- **Key Learnings**: Dramatiq background jobs, Stripe/payment webhooks, OAuth2 multi-provider, SQLAlchemy 2.0 async at scale, SSE with sse-starlette, auto-generated TypeScript API clients from OpenAPI.
- **Caveats**: Very large codebase. Business logic is domain-specific.

### nsidnev/fastapi-realworld-example-app

- **GitHub**: https://github.com/nsidnev/fastapi-realworld-example-app
- **Category**: Reference architecture (RealWorld spec)
- **Stars**: 3,000
- **Last Commit**: Archived
- **Score**: 84/100
- **Why Best in Class**: FastAPI RealWorld spec implementation. Clean layered architecture: api/routes, api/dependencies, db/repositories, models/domain, models/schemas, services, core/config. 90 tests covering all endpoints.
- **Key Learnings**: Repository pattern, DI for auth/validation, domain vs schema model separation, custom error handlers, application factory pattern.
- **Caveats**: ARCHIVED. Uses older libs (encode/databases, Pydantic V1). Architectural reference only.

### s3rius/FastAPI-template

- **GitHub**: https://github.com/s3rius/FastAPI-template
- **Category**: Project generator
- **Stars**: 2,700
- **Last Commit**: Feb 2025
- **Score**: 81/100
- **Why Best in Class**: Most configurable FastAPI generator. Multiple ORMs (SQLAlchemy 2.0, TortoiseORM, Piccolo, Ormar, Beanie), multiple databases, Redis, RabbitMQ, Kafka, Prometheus, Sentry, OpenTelemetry, Kubernetes.
- **Key Learnings**: Multi-ORM patterns, Docker Compose stacks, Prometheus metrics, OpenTelemetry instrumentation, Kafka/RabbitMQ integration, K8s configs.
- **Caveats**: Generated code quality varies by config. Template complexity harder to study than output.

### blueswen/fastapi-observability

- **GitHub**: https://github.com/blueswen/fastapi-observability
- **Category**: Observability reference
- **Stars**: 725-810
- **Last Commit**: May 2025
- **Score**: 78/100
- **Official**: Author's observability talk merged into FastAPI docs (PR #13527)
- **Why Best in Class**: All three observability pillars: Traces (Grafana Tempo/OpenTelemetry), Metrics (Prometheus), Logs (Grafana Loki). Distributed tracing across three FastAPI instances.
- **Key Learnings**: OpenTelemetry FastAPI instrumentation, Prometheus histogram metrics with exemplars, distributed trace propagation, Grafana dashboards, metrics-to-traces correlation.
- **Caveats**: Narrow focus (observability only). Small codebase.

---

## TypeScript (NestJS)

### nestjs/nest (official samples)

- **GitHub**: https://github.com/nestjs/nest (samples at /sample directory)
- **Category**: Official examples
- **Stars**: 74,700
- **Last Commit**: Jan 2026
- **Score**: 90/100
- **Official**: THE official framework repo
- **Why Best in Class**: Canonical source of NestJS idioms. 30+ mini-applications covering CQRS, GraphQL, Mongoose, TypeORM, WebSockets, microservices (TCP, Redis, Kafka, RabbitMQ, gRPC, NATS, MQTT), Fastify, SSE. Written by NestJS core team.
- **Key Learnings**: Module/provider/controller structure, custom decorators, guard/interceptor/pipe patterns, microservice transports, WebSocket gateways, CQRS with events.
- **Caveats**: Samples are small -- great for individual patterns, not production structure. No tests or CI.

### vendure-ecommerce/vendure

- **GitHub**: https://github.com/vendure-ecommerce/vendure
- **Category**: Production application (headless e-commerce)
- **Stars**: 7,900
- **Last Commit**: Weekly releases through 2026
- **Score**: 97/100
- **Official**: Listed on nestjs/awesome-nestjs
- **Why Best in Class**: Premier open-source headless commerce on NestJS + GraphQL + TypeORM. Used by IBM and Fortune 500. Plugin system (@VendurePlugin) is a NestJS Module superset -- masterclass in modular, extensible design. Enterprise event bus, job queues, multi-channel.
- **Key Learnings**: NestJS plugin architecture (dynamic module extension), GraphQL schema extension, event bus/domain events, job queue for async, entity lifecycle hooks, multi-channel/multi-tenant architecture.
- **Caveats**: Very large codebase. GPL-licensed. Commerce-domain specific.

### novuhq/novu

- **GitHub**: https://github.com/novuhq/novu
- **Category**: Notification Platform
- **Stars**: 38,000
- **Last Commit**: 2026-02-13
- **Why Best in Class**: Production-grade notification infrastructure. Real-world NestJS at massive scale with clean architecture.

### ghostfolio/ghostfolio

- **GitHub**: https://github.com/ghostfolio/ghostfolio
- **Category**: Production application (fintech SaaS)
- **Stars**: 7,400
- **Last Commit**: Weekly commits through Jan 2026
- **Score**: 89/100
- **Why Best in Class**: Fully functional production-deployed wealth management SaaS (ghostfol.io). Pure NestJS + Prisma ORM + PostgreSQL + Redis in Nx workspace. Feature flags, premium subscription tiers, data provider integrations.
- **Key Learnings**: NestJS + Prisma ORM integration, Nx monorepo, Redis caching strategy, feature flags, SaaS subscription tiers, data provider abstraction.
- **Caveats**: Monorepo includes Angular frontend (NestJS in apps/api). AGPL licensed. Fintech-specific.

### brocoders/nestjs-boilerplate

- **GitHub**: https://github.com/brocoders/nestjs-boilerplate
- **Category**: Boilerplate
- **Stars**: 4,100
- **Last Commit**: Active (2026)
- **Score**: 89/100
- **Official**: Listed on nestjs/awesome-nestjs
- **Why Best in Class**: Most popular actively maintained NestJS boilerplate. Auth (social + email), TypeORM/Mongoose, PostgreSQL/MongoDB, mailing, I18N, file uploads (local + S3), Docker, Swagger, seeding, E2E + unit tests, CI via GitHub Actions. Dedicated documentation website.
- **Key Learnings**: JWT + social auth, RBAC, file upload abstraction (local/S3), email templating with i18n, database seeding, Docker multi-stage builds, TypeORM migrations, cursor + offset pagination.

### rubiin/ultimate-nest

- **GitHub**: https://github.com/rubiin/ultimate-nest
- **Category**: Reference architecture / Opinionated starter
- **Stars**: 421
- **Last Commit**: Active (1,498 commits through 2026)
- **Score**: 84/100
- **Official**: Listed on nestjs/awesome-nestjs
- **Why Best in Class**: Opinionated NestJS template using MikroORM with CASL authorization, RabbitMQ, Sentry, Redis, Stripe, extended ESLint, Docker, NestJS REPL. One of few high-quality repos showcasing MikroORM.
- **Key Learnings**: MikroORM with NestJS, CASL-based authorization, RabbitMQ integration, Sentry error reporting, Stripe payments, multi-environment config.
- **Caveats**: Smaller community. MikroORM less mainstream than TypeORM/Prisma.

### lujakob/nestjs-realworld-example-app

- **GitHub**: https://github.com/lujakob/nestjs-realworld-example-app
- **Category**: Reference application (RealWorld spec)
- **Stars**: 3,300
- **Last Commit**: Stable/mature
- **Score**: 82/100
- **Why Best in Class**: NestJS RealWorld spec -- standardized Medium.com clone API for cross-framework comparison. Clean CRUD, auth (JWT), pagination, following/favoriting with TypeORM. Also has Prisma branch.
- **Key Learnings**: Standard REST API structure, JWT middleware, TypeORM entity relations, controller/service separation, standardized API spec implementation.
- **Caveats**: Low commit frequency. No tests. Focused on correctness over production infra.

### NarHakobyan/awesome-nest-boilerplate

- **GitHub**: https://github.com/NarHakobyan/awesome-nest-boilerplate
- **Category**: Boilerplate
- **Stars**: 2,700
- **Last Commit**: Active (2025-2026)
- **Score**: 82/100
- **Official**: Listed on nestjs/awesome-nestjs
- **Why Best in Class**: Second most popular NestJS boilerplate. Postgres + TypeORM, Swagger, RBAC, JWT, notable multi-runtime support (Node, Bun, Deno).
- **Key Learnings**: Custom decorators for auth, DTO validation patterns, TypeORM repository pattern, interceptors for response transformation, multi-runtime support.

### ever-co/ever-gauzy

- **GitHub**: https://github.com/ever-co/ever-gauzy
- **Category**: Production application (ERP/CRM/HRM)
- **Stars**: 3,500
- **Last Commit**: Continuous commits
- **Score**: 79/100
- **Official**: Listed on nestjs/awesome-nestjs
- **Why Best in Class**: Full open-source business management platform (ERP/CRM/HRM) with NestJS + Angular in Nx. Time tracking, employee management, invoicing. TypeORM multi-DB, CQRS, Pulumi for AWS.
- **Key Learnings**: Enterprise Nx monorepo at massive scale, multi-database via TypeORM, CQRS, Pulumi cloud deployment (AWS EKS/Fargate), 50+ module organization.
- **Caveats**: Extremely large and complex. AGPL licensed. Quality varies across codebase.

### jmcdo29/testing-nestjs

- **GitHub**: https://github.com/jmcdo29/testing-nestjs
- **Category**: Testing Reference
- **Stars**: 500
- **Last Commit**: 2025-04-27
- **Why Best in Class**: Comprehensive Unit/Integration/E2E testing examples. Covers pipes, filters, interceptors, GraphQL, multiple ORMs.

### meysamhadeli/booking-microservices-nestjs

- **GitHub**: https://github.com/meysamhadeli/booking-microservices-nestjs
- **Category**: Microservices Reference
- **Stars**: 500
- **Last Commit**: 2025-10-09
- **Why Best in Class**: Vertical Slice + Event-Driven Architecture, CQRS, gRPC/REST sync + RabbitMQ/Kafka async.

---

## TypeScript (Next.js)

### dubinc/dub

- **GitHub**: https://github.com/dubinc/dub
- **Category**: Production SaaS (link management)
- **Stars**: 23,000
- **Last Commit**: Daily commits
- **Score**: 93/100
- **Official**: Creator works at Vercel; listed on Vercel templates
- **Why Best in Class**: Created by Steven Tey (Vercel DX team). Best-in-class App Router usage with Turborepo. Powers 100M+ clicks/month. Redis caching for high-throughput redirects via Middleware, Prisma + PlanetScale MySQL, Upstash Redis/QStash, Tinybird analytics, Stripe billing.
- **Key Learnings**: Next.js Middleware for redirects, Redis caching, monorepo package organization (ui/utils/email/prisma), webhook processing, rate limiting, analytics pipeline.
- **Caveats**: AGPLv3 with commercial ee folder. Requires PlanetScale, Upstash, and several third-party services.

### calcom/cal.com

- **GitHub**: https://github.com/calcom/cal.com
- **Category**: Production SaaS (scheduling)
- **Stars**: 40,200
- **Last Commit**: Daily commits
- **Score**: 92/100
- **Official**: Referenced in Vercel blog posts
- **Why Best in Class**: Gold standard for production-grade Next.js at scale. Turborepo monorepo, tRPC for type-safe APIs, Prisma ORM, Playwright E2E, CSP, Docker, i18n, embeddable widgets, platform APIs. Used by thousands of companies.
- **Key Learnings**: Turborepo monorepo at scale, tRPC integration, Prisma schema across packages, middleware auth, embed/widget SDK, cron patterns, CSP security.
- **Caveats**: Very large codebase. Complexity may be overwhelming.

### vercel/next-forge

- **GitHub**: https://github.com/vercel/next-forge
- **Category**: Official Vercel boilerplate / Reference architecture
- **Stars**: 6,900
- **Last Commit**: Very active (1,473 commits)
- **Score**: 91/100
- **Official**: Under vercel/ org, Vercel Academy, vercel.com/templates
- **Why Best in Class**: Production-grade Turborepo template maintained by Vercel. Auth (Clerk), payments (Stripe), database (Prisma + Neon), email (Resend), feature flags, analytics, observability (Sentry), Storybook, docs. Recommended by Guillermo Rauch.
- **Key Learnings**: Turborepo monorepo structure, shared packages (design-system, database, auth), Server Actions patterns, Stripe webhooks, feature flags, Storybook in monorepo, .cursorrules for AI dev.
- **Caveats**: Requires many SaaS accounts. May be over-engineered for simple projects.

### vercel/commerce

- **GitHub**: https://github.com/vercel/commerce
- **Category**: Official Vercel template (e-commerce)
- **Stars**: 13,500
- **Last Commit**: Maintained by Lee Robinson (Vercel VP of DX)
- **Score**: 90/100
- **Official**: Linked from nextjs.org/commerce, maintained by Vercel staff
- **Why Best in Class**: THE canonical Next.js e-commerce reference from Vercel. App Router, React Server Components, Suspense boundaries, dynamic OG images, SEO best practices, Shopify Storefront API. Forked by BigCommerce, Saleor, Medusa, Swell.
- **Key Learnings**: RSC in e-commerce, Shopify GraphQL API, cart with cookies, dynamic metadata/OG images, search with URL params, clean lib/ abstraction for swappable providers.
- **Caveats**: v2 is Shopify-only. Relatively small codebase.

### midday-ai/midday

- **GitHub**: https://github.com/midday-ai/midday
- **Category**: Finance/Invoicing
- **Stars**: 13,700
- **Last Commit**: 2026-02-13
- **Why Best in Class**: Bun, Supabase, Next.js App Router, AI assistant. Modern 2025+ stack patterns for freelancer toolkit.

### formbricks/formbricks

- **GitHub**: https://github.com/formbricks/formbricks
- **Category**: Survey Platform
- **Stars**: 11,800
- **Last Commit**: 2026-02-13
- **Why Best in Class**: Privacy-first architecture, multi-channel surveys, advanced targeting. Clean separation of concerns.

### elie222/inbox-zero

- **GitHub**: https://github.com/elie222/inbox-zero
- **Category**: AI Email
- **Stars**: 10,000
- **Last Commit**: 2026-02-13
- **Why Best in Class**: Next.js + AI patterns, Turborepo, shadcn/ui, Prisma. Showcases Vercel AI SDK integration.

### mfts/papermark

- **GitHub**: https://github.com/mfts/papermark
- **Category**: Document Sharing
- **Stars**: 7,500
- **Last Commit**: 2026-02-12
- **Why Best in Class**: DocSend alternative with analytics. Clean Next.js patterns, custom domains, well-maintained.

### Blazity/next-enterprise

- **GitHub**: https://github.com/Blazity/next-enterprise
- **Category**: Enterprise boilerplate
- **Stars**: 6,600
- **Last Commit**: Updated to Next.js 15
- **Score**: 86/100
- **Official**: Listed on Vercel marketplace
- **Why Best in Class**: Purpose-built for enterprise by Blazity (Next.js consulting firm). Extremely strict TypeScript (ts-reset), OpenTelemetry, coupling-graph visualization (Madge), Storybook with play function acceptance tests, bundle analyzer, semantic release, K8s Docker.
- **Key Learnings**: Enterprise TypeScript strictness (ts-reset), OpenTelemetry in Next.js, coupling graph analysis, Storybook acceptance testing, bundle monitoring, K8s deployment, semantic release.

### vercel/platforms

- **GitHub**: https://github.com/vercel/platforms
- **Category**: Official Vercel template (multi-tenant)
- **Stars**: 5,000+
- **Last Commit**: Updated to Next.js 15
- **Score**: 86/100
- **Official**: vercel/ org, vercel.com/templates, dedicated blog post
- **Why Best in Class**: Official Vercel template for multi-tenant apps with custom subdomain routing. Next.js Middleware for tenant detection, Redis for tenant data, Vercel Domains API. Foundation for Hashnode (35K+ custom domains), Mintlify, Incident.io, Dub.
- **Key Learnings**: Multi-tenant subdomain routing with Middleware, custom domain management, tenant data isolation with Redis, environment-aware subdomain detection, ISR for multi-tenant content.
- **Caveats**: Tightly coupled to Vercel platform. Self-hosting requires significant modification.

### shadcn-ui/taxonomy

- **GitHub**: https://github.com/shadcn-ui/taxonomy
- **Category**: Reference architecture (App Router pioneer)
- **Stars**: 19,100
- **Last Commit**: Largely inactive since mid-2023
- **Score**: 86/100
- **Why Best in Class**: Created by shadcn (now at Vercel). First major demo of Next.js 13 App Router patterns -- routing, layouts, RSC, middleware auth, Stripe subscriptions, MDX blog. Spawned the shadcn/ui library.
- **Key Learnings**: App Router layout composition (nested layouts, layout groups), NextAuth.js with middleware, Radix UI component architecture, Stripe subscriptions, MDX content pipeline.
- **Caveats**: STALE -- stuck on Next.js 13. Contentlayer abandoned. Learning reference only, NOT a production starter.

### ixartz/Next-js-Boilerplate

- **GitHub**: https://github.com/ixartz/Next-js-Boilerplate
- **Category**: Community boilerplate (DX-focused)
- **Stars**: 12,600
- **Last Commit**: Very active (Next.js 16 + Tailwind 4)
- **Score**: 84/100
- **Why Best in Class**: Most-starred community Next.js boilerplate. Comprehensive DX: ESLint, Prettier, Husky, lint-staged, Commitlint, Vitest + Testing Library, Playwright E2E, Storybook, Sentry, Drizzle ORM, Clerk auth, i18n with next-intl.
- **Key Learnings**: Comprehensive project setup (linting, formatting, testing, CI), Drizzle ORM schema + migrations, Clerk auth, i18n with next-intl, Storybook config, GitHub Actions CI.
- **Caveats**: More "kitchen sink" DX boilerplate than architectural reference.

---

## Mobile (Expo / React Native)

### infinitered/ignite

- **GitHub**: https://github.com/infinitered/ignite
- **Category**: Boilerplate / Reference architecture
- **Stars**: 19,500
- **Last Commit**: Jan 2026 (v11.4.0)
- **Score**: 94/100
- **Official**: Referenced in Expo community resources
- **Why Best in Class**: Oldest, most popular, most battle-tested RN/Expo boilerplate -- 9+ years active. Used by Infinite Red on real client projects. Since v9 ("Expresso"), full Expo integration with CNG workflow, Expo Router, MobX-State-Tree, TypeScript strict, generators.
- **Key Learnings**: MobX-State-Tree integration, CLI code generators, feature-based folder structure, Maestro E2E testing, Expo CNG workflow, theming/dark mode.
- **Caveats**: Opinionated (MobX-State-Tree). Large boilerplate. v11 dropped Expo Go support.

### obytes/react-native-template-obytes

- **GitHub**: https://github.com/obytes/react-native-template-obytes
- **Category**: Boilerplate / Starter kit
- **Stars**: 4,000
- **Last Commit**: Jan 2026 (v9.0.0, Expo 53+)
- **Score**: 92/100
- **Why Best in Class**: Most modern and comprehensive Expo starter. Expo Router, TypeScript, NativeWind (TailwindCSS), React Query, Zustand, react-hook-form + Zod, MMKV, i18next, 10+ GitHub Actions workflows, unit (Jest/RTL) and E2E (Maestro) testing. Designed for AI-assisted development. Outstanding docs at starter.obytes.com.
- **Key Learnings**: Expo Router file-based navigation, Zustand + MMKV auth flow, React Query data fetching, Zod environment validation, comprehensive CI/CD with EAS, NativeWind styling, i18n with ESLint validation.

### founded-labs/react-native-reusables

- **GitHub**: https://github.com/founded-labs/react-native-reusables
- **Category**: UI component library / Reference architecture
- **Stars**: 7,000+
- **Last Commit**: Active
- **Score**: 91/100
- **Why Best in Class**: Definitive shadcn/ui port for React Native and Expo. Accessible, customizable UI components with NativeWind. CLI (@react-native-reusables/cli), copy-paste philosophy, light/dark themes. Full docs at reactnativereusables.com.
- **Key Learnings**: Accessible component design for RN, NativeWind/Tailwind styling, Radix UI primitive adaptation for mobile, theme/dark mode, CLI-based scaffolding, cross-platform (iOS/Android/Web).
- **Caveats**: Component library, not full app template. Transitioning to founded-labs org.

### t3-oss/create-t3-turbo

- **GitHub**: https://github.com/t3-oss/create-t3-turbo
- **Category**: Reference architecture / Monorepo template
- **Stars**: 6,000
- **Last Commit**: Recent (Expo SDK 54)
- **Score**: 90/100
- **Official**: Referenced in Expo monorepo docs
- **Why Best in Class**: Official T3 Stack monorepo with Expo alongside Next.js. Turborepo with shared packages for API (tRPC v11), auth (Better Auth), DB (Drizzle + Supabase), UI (shadcn-ui), shared configs. Expo Router with NativeWind and typesafe tRPC.
- **Key Learnings**: Turborepo monorepo web + mobile, shared tRPC API between Next.js and Expo, shared auth/DB/UI packages, pnpm workspace management, cross-platform code splitting.
- **Caveats**: Expo app portion is thin. Best for teams building web + mobile simultaneously.

### byCedric/expo-monorepo-example

- **GitHub**: https://github.com/byCedric/expo-monorepo-example
- **Category**: Reference architecture / Monorepo example
- **Stars**: 1,800+
- **Last Commit**: Active
- **Score**: 85/100
- **Official**: By Expo team member, referenced in Expo docs
- **Why Best in Class**: Created by Cedric van Putten (senior dev at Expo). Canonical "vanilla" Expo monorepo -- intentionally minimal with no heavy frameworks. pnpm + Turborepo, Metro cache reuse, shared packages, efficient CI.
- **Key Learnings**: pnpm monorepo setup, Turborepo pipeline config, Metro cache optimization, workspace package sharing, EAS Build in monorepos.
- **Caveats**: Intentionally minimal -- not a full app template.

### roninoss/create-expo-stack

- **GitHub**: https://github.com/roninoss/create-expo-stack
- **Category**: CLI tool / Configurable starter generator
- **Stars**: 2,500
- **Last Commit**: Active (981 commits)
- **Score**: 80/100
- **Why Best in Class**: Interactive CLI for customized Expo projects. Choose TypeScript, Expo Router/React Navigation, NativeWind/Unistyles/Tamagui, Firebase/Supabase. Available at rn.new. Generates production-ready from latest SDK.
- **Key Learnings**: Configurable template patterns, multiple styling solutions, auth integration patterns, modern Expo SDK config.
- **Caveats**: Value in generated output, not as reference codebase. Quality varies by config.

### expo/examples

- **GitHub**: https://github.com/expo/examples
- **Category**: Official examples collection
- **Stars**: 2,000+
- **Last Commit**: Continuously updated
- **Score**: 76/100
- **Official**: Official Expo repo, referenced in docs and CLI
- **Why Best in Class**: Official Expo examples repo with 50+ focused examples. Each standalone and bootstrappable via npx create-expo --example <name>. Covers Expo Router, AI, auth, styling, API integrations.
- **Key Learnings**: Idiomatic Expo API usage, integration patterns (Firebase, Supabase, Stripe), file-based routing with Expo Router.
- **Caveats**: Small and focused -- not full architectures. Quality varies.

---

## JavaScript (Electron)

### hovancik/stretchly

- **GitHub**: https://github.com/hovancik/stretchly
- **Category**: Pomodoro Timer
- **Stars**: 5,907
- **Last Commit**: 2026-02-20
- **Why Best in Class**: INSPIRATION ONLY (code is a bit old). Cross-platform Electron break reminder with smart idle detection, Do Not Disturb awareness, and strict mode. JSON-based config enables version-controlled preferences. Good UX patterns for tray/notification apps.

---

## Cross-Framework Patterns

- **Monorepo architecture** dominates at scale: Turborepo + pnpm (cal.com, Dub, next-forge, create-t3-turbo, byCedric's Expo example).
- **Type-safe API layers** converge: tRPC (cal.com, create-t3-turbo), auto-generated TS clients from OpenAPI (Polar/FastAPI), GraphQL codegen (Vendure/NestJS).
- **RealWorld spec** implementations (FastAPI + NestJS) enable cross-framework comparison.
- **Observability** underrepresented except blueswen/fastapi-observability and Blazity/next-enterprise.
- **File-based routing** standard in 3 of 4 ecosystems: Next.js App Router, Expo Router, NestJS modules. FastAPI uses manual route registration.
- Strongest repos enforce conventions via tooling (linters, generators, strict TS), separate concerns at package/module level, and demonstrate patterns under real production load.
