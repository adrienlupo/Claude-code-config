# TypeScript (NestJS) Repositories

### nestjs/nest
https://github.com/nestjs/nest
Official examples | 74.7K stars | Score: 90/100 | Last commit: Jan 2026
Official: THE official framework repo (samples at /sample directory)
Canonical source of NestJS idioms. 30+ mini-applications covering CQRS, GraphQL, Mongoose, TypeORM, WebSockets, microservices (TCP, Redis, Kafka, RabbitMQ, gRPC, NATS, MQTT), Fastify, SSE.
**Caveats**: Samples are small -- great for individual patterns, not production structure. No tests or CI.

### vendure-ecommerce/vendure
https://github.com/vendure-ecommerce/vendure
Production application (headless e-commerce) | 7.9K stars | Score: 97/100 | Weekly releases through 2026
Official: Listed on nestjs/awesome-nestjs
Premier open-source headless commerce on NestJS + GraphQL + TypeORM. Used by IBM and Fortune 500. Plugin system (@VendurePlugin) is a NestJS Module superset -- masterclass in modular, extensible design. Enterprise event bus, job queues, multi-channel.
**Caveats**: Very large codebase. GPL-licensed. Commerce-domain specific.

### twentyhq/twenty
https://github.com/twentyhq/twenty
Production application (open-source CRM) | 40.1K stars | Last commit: 2026-02-26
Enterprise-grade CRM with NestJS + React in Nx monorepo (14+ packages). 20+ feature-based NestJS modules, GraphQL code-first API, TypeORM with multi-tenant workspace-scoped data model, BullMQ background jobs, Redis caching. Strict code quality: no `any` types, custom ESLint rules, file size limits (components <300 lines).
**Caveats**: Very large codebase. Heavy infrastructure requirements (PostgreSQL + Redis + optional ClickHouse).

### novuhq/novu
https://github.com/novuhq/novu
Notification Platform | 38K stars | Last commit: 2026-02-13
Production-grade notification infrastructure. Real-world NestJS at massive scale with clean architecture.

### ghostfolio/ghostfolio
https://github.com/ghostfolio/ghostfolio
Production application (fintech SaaS) | 7.4K stars | Score: 89/100 | Weekly commits through Jan 2026
Fully functional production-deployed wealth management SaaS (ghostfol.io). Pure NestJS + Prisma ORM + PostgreSQL + Redis in Nx workspace. Feature flags, premium subscription tiers, data provider integrations.
**Caveats**: Monorepo includes Angular frontend (NestJS in apps/api). AGPL licensed. Fintech-specific.

### brocoders/nestjs-boilerplate
https://github.com/brocoders/nestjs-boilerplate
Boilerplate | 4.1K stars | Score: 89/100 | Active (2026)
Official: Listed on nestjs/awesome-nestjs
Most popular actively maintained NestJS boilerplate. Auth (social + email), TypeORM/Mongoose, PostgreSQL/MongoDB, mailing, I18N, file uploads (local + S3), Docker, Swagger, seeding, E2E + unit tests, CI via GitHub Actions.

### rubiin/ultimate-nest
https://github.com/rubiin/ultimate-nest
Reference architecture / Opinionated starter | 421 stars | Score: 84/100 | Active (1,498 commits through 2026)
Official: Listed on nestjs/awesome-nestjs
Opinionated NestJS template using MikroORM with CASL authorization, RabbitMQ, Sentry, Redis, Stripe, extended ESLint, Docker, NestJS REPL.
**Caveats**: Smaller community. MikroORM less mainstream than TypeORM/Prisma.

### lujakob/nestjs-realworld-example-app
https://github.com/lujakob/nestjs-realworld-example-app
Reference application (RealWorld spec) | 3.3K stars | Score: 82/100 | Stable/mature
NestJS RealWorld spec -- standardized Medium.com clone API for cross-framework comparison. Clean CRUD, auth (JWT), pagination, following/favoriting with TypeORM. Also has Prisma branch.
**Caveats**: Low commit frequency. No tests. Focused on correctness over production infra.

### NarHakobyan/awesome-nest-boilerplate
https://github.com/NarHakobyan/awesome-nest-boilerplate
Boilerplate | 2.7K stars | Score: 82/100 | Active (2025-2026)
Official: Listed on nestjs/awesome-nestjs
Second most popular NestJS boilerplate. Postgres + TypeORM, Swagger, RBAC, JWT, notable multi-runtime support (Node, Bun, Deno).

### ever-co/ever-gauzy
https://github.com/ever-co/ever-gauzy
Production application (ERP/CRM/HRM) | 3.5K stars | Score: 79/100 | Continuous commits
Official: Listed on nestjs/awesome-nestjs
Full open-source business management platform (ERP/CRM/HRM) with NestJS + Angular in Nx. Time tracking, employee management, invoicing. TypeORM multi-DB, CQRS, Pulumi for AWS.
**Caveats**: Extremely large and complex. AGPL licensed. Quality varies across codebase.

### jmcdo29/testing-nestjs
https://github.com/jmcdo29/testing-nestjs
Testing Reference | 500 stars | Last commit: 2025-04-27
Comprehensive Unit/Integration/E2E testing examples. Covers pipes, filters, interceptors, GraphQL, multiple ORMs.

### meysamhadeli/booking-microservices-nestjs
https://github.com/meysamhadeli/booking-microservices-nestjs
Microservices Reference | 500 stars | Last commit: 2025-10-09
Vertical Slice + Event-Driven Architecture, CQRS, gRPC/REST sync + RabbitMQ/Kafka async.
