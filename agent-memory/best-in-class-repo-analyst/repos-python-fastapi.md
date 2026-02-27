# Python (FastAPI) Repositories

### fastapi/full-stack-fastapi-template
https://github.com/fastapi/full-stack-fastapi-template
Official template | 41.3K stars | Score: 94/100 | Active
Official: Linked from fastapi.tiangolo.com/project-generation
The ONLY template from official FastAPI docs. FastAPI + SQLModel + Pydantic + PostgreSQL + Docker Compose with JWT auth, Traefik, Playwright E2E.
**Caveats**: Opinionated stack (React frontend, SQLModel). Previously at tiangolo/full-stack-fastapi-postgresql.

### zhanymkanov/fastapi-best-practices
https://github.com/zhanymkanov/fastapi-best-practices
Best practices guide | 14.2-16.2K stars | Score: 93/100 | Last commit: Aug 2025
Most-starred FastAPI best practices repo. Battle-tested conventions from production startups covering async/sync routing, DI, project structure (inspired by Netflix Dispatch), Pydantic validation, background tasks.
**Caveats**: Not a runnable project -- README with code snippets only.

### Netflix/dispatch
https://github.com/Netflix/dispatch
Production application (enterprise) | 6.4K stars | Score: 89/100 | Archived Sep 2025
Official: Testimonial on FastAPI homepage
Netflix's production incident management platform. FastAPI + SQLAlchemy + PostgreSQL. Enterprise plugin architecture, multi-tenant data models, Slack/Jira/PagerDuty integrations. Inspired fastapi-best-practices structure.
**Caveats**: ARCHIVED. Very large codebase. Some patterns Netflix-specific.

### polarsource/polar
https://github.com/polarsource/polar
Production SaaS | 5.7K stars | Score: 85/100 | Active
Commercially operated SaaS on FastAPI + SQLAlchemy + PostgreSQL + Redis + Dramatiq. Handles real payments, subscriptions, license keys.
**Caveats**: Very large codebase. Business logic is domain-specific.

### nsidnev/fastapi-realworld-example-app
https://github.com/nsidnev/fastapi-realworld-example-app
Reference architecture (RealWorld spec) | 3K stars | Score: 84/100 | Archived
FastAPI RealWorld spec implementation. Clean layered architecture: api/routes, api/dependencies, db/repositories, models/domain, models/schemas, services, core/config. 90 tests covering all endpoints.
**Caveats**: ARCHIVED. Uses older libs (encode/databases, Pydantic V1). Architectural reference only.

### s3rius/FastAPI-template
https://github.com/s3rius/FastAPI-template
Project generator | 2.7K stars | Score: 81/100 | Last commit: Feb 2025
Most configurable FastAPI generator. Multiple ORMs (SQLAlchemy 2.0, TortoiseORM, Piccolo, Ormar, Beanie), multiple databases, Redis, RabbitMQ, Kafka, Prometheus, Sentry, OpenTelemetry, Kubernetes.
**Caveats**: Generated code quality varies by config. Template complexity harder to study than output.

### mealie-recipes/mealie
https://github.com/mealie-recipes/mealie
Production application (self-hosted recipe manager) | 11.5K stars | Score: 91/100 | Active (daily commits, 2026)
Textbook layered architecture nearly identical to a standard FastAPI production app. FastAPI + SQLAlchemy + PostgreSQL/SQLite + Alembic + Vue.js frontend in monorepo. ~30 models, ~50 endpoints, ~15 services. Repository pattern separating data access from business logic.
**Caveats**: SQLite as default (PostgreSQL optional). Vue.js frontend (not React).

### TracecatHQ/tracecat
https://github.com/TracecatHQ/tracecat
Production application (security automation) | 3.5K stars | Score: 90/100 | Active (daily commits, 2026)
Exceptionally clean domain-driven architecture. FastAPI + SQLAlchemy + PostgreSQL + Alembic + Temporal + Redis + Next.js frontend. ~25-30 models, ~40 endpoints. Dedicated auth/ and authz/ modules, audit logging, secret management, multi-workspace.
**Caveats**: Temporal adds infrastructure complexity. Enterprise features in ee/ directory.

### keephq/keep
https://github.com/keephq/keep
Production application (AIOps alert management) | 11.4K stars | Score: 89/100 | Active (daily commits, 2026)
AIOps platform with 100+ external provider integrations. FastAPI + SQLAlchemy + PostgreSQL + Alembic + ARQ + Redis + Next.js frontend. Routes/bl (business logic)/models/tasks layering. Workflow automation, alert correlation engine, rules engine, topology mapping.
**Caveats**: Very high complexity. Enterprise Edition. Many external dependencies.

### PrefectHQ/prefect
https://github.com/PrefectHQ/prefect
Production application (workflow orchestration server) | 21.7K stars | Score: 93/100 | Active (daily commits, 2026)
The FastAPI server component (src/prefect/server/) is a gold-standard layered FastAPI+SQLAlchemy application. ~50+ models, ~80+ endpoints. Composable orchestration policies, event-driven architecture, state machines. Built by a professional engineering team ($100M+ funded).
**Caveats**: Prefect is a workflow framework -- the web app is the server/ subdirectory only. Very large codebase.

### fief-dev/fief
https://github.com/fief-dev/fief
Production application (auth platform) | 727 stars | Score: 87/100 | Inactive (last commit Nov 2025)
Created by the author of fastapi-users. Textbook-perfect FastAPI+SQLAlchemy layered architecture: models/ -> schemas/ -> repositories/ -> services/ -> tasks/. Multi-tenant OAuth2/OIDC provider. ~15-20 models. The cleanest architectural reference in this list.
**Caveats**: INACTIVE (last commit Nov 2025). Low star count (727). Auth-domain specific.
