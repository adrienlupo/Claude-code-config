# TypeScript (Next.js) Repositories

### dubinc/dub
https://github.com/dubinc/dub
Production SaaS (link management) | 23K stars | Score: 93/100 | Daily commits
Official: Creator works at Vercel; listed on Vercel templates
Created by Steven Tey (Vercel DX team). Best-in-class App Router usage with Turborepo. Powers 100M+ clicks/month. Redis caching for high-throughput redirects via Middleware, Prisma + PlanetScale MySQL, Upstash Redis/QStash, Tinybird analytics, Stripe billing.
**Caveats**: AGPLv3 with commercial ee folder. Requires PlanetScale, Upstash, and several third-party services.

### calcom/cal.com
https://github.com/calcom/cal.com
Production SaaS (scheduling) | 40.2K stars | Score: 92/100 | Daily commits
Official: Referenced in Vercel blog posts
Gold standard for production-grade Next.js at scale. Turborepo monorepo, tRPC for type-safe APIs, Prisma ORM, Playwright E2E, CSP, Docker, i18n, embeddable widgets, platform APIs. Used by thousands of companies.
**Caveats**: Very large codebase. Complexity may be overwhelming.

### vercel/next-forge
https://github.com/vercel/next-forge
Official Vercel boilerplate / Reference architecture | 6.9K stars | Score: 91/100 | Very active (1,473 commits)
Official: Under vercel/ org, Vercel Academy, vercel.com/templates
Production-grade Turborepo template maintained by Vercel. Auth (Clerk), payments (Stripe), database (Prisma + Neon), email (Resend), feature flags, analytics, observability (Sentry), Storybook, docs. Recommended by Guillermo Rauch.
**Caveats**: Requires many SaaS accounts. May be over-engineered for simple projects.

### vercel/commerce
https://github.com/vercel/commerce
Official Vercel template (e-commerce) | 13.5K stars | Score: 90/100 | Maintained by Lee Robinson (Vercel VP of DX)
Official: Linked from nextjs.org/commerce, maintained by Vercel staff
THE canonical Next.js e-commerce reference from Vercel. App Router, React Server Components, Suspense boundaries, dynamic OG images, SEO best practices, Shopify Storefront API. Forked by BigCommerce, Saleor, Medusa, Swell.
**Caveats**: v2 is Shopify-only. Relatively small codebase.

### midday-ai/midday
https://github.com/midday-ai/midday
Finance/Invoicing | 13.7K stars | Last commit: 2026-02-13
Bun, Supabase, Next.js App Router, AI assistant. Modern 2025+ stack patterns for freelancer toolkit.

### formbricks/formbricks
https://github.com/formbricks/formbricks
Survey Platform | 11.8K stars | Last commit: 2026-02-13
Privacy-first architecture, multi-channel surveys, advanced targeting. Clean separation of concerns.

### elie222/inbox-zero
https://github.com/elie222/inbox-zero
AI Email | 10K stars | Last commit: 2026-02-13
Next.js + AI patterns, Turborepo, shadcn/ui, Prisma. Showcases Vercel AI SDK integration.

### mfts/papermark
https://github.com/mfts/papermark
Document Sharing | 7.5K stars | Last commit: 2026-02-12
DocSend alternative with analytics. Clean Next.js patterns, custom domains, well-maintained.

### Blazity/next-enterprise
https://github.com/Blazity/next-enterprise
Enterprise boilerplate | 6.6K stars | Score: 86/100 | Updated to Next.js 15
Official: Listed on Vercel marketplace
Purpose-built for enterprise by Blazity (Next.js consulting firm). Extremely strict TypeScript (ts-reset), OpenTelemetry, coupling-graph visualization (Madge), Storybook with play function acceptance tests, bundle analyzer, semantic release, K8s Docker.

### vercel/platforms
https://github.com/vercel/platforms
Official Vercel template (multi-tenant) | 5K+ stars | Score: 86/100 | Updated to Next.js 15
Official: vercel/ org, vercel.com/templates, dedicated blog post
Official Vercel template for multi-tenant apps with custom subdomain routing. Next.js Middleware for tenant detection, Redis for tenant data, Vercel Domains API. Foundation for Hashnode (35K+ custom domains), Mintlify, Incident.io, Dub.
**Caveats**: Tightly coupled to Vercel platform. Self-hosting requires significant modification.

### shadcn-ui/taxonomy
https://github.com/shadcn-ui/taxonomy
Reference architecture (App Router pioneer) | 19.1K stars | Score: 86/100 | Largely inactive since mid-2023
Created by shadcn (now at Vercel). First major demo of Next.js 13 App Router patterns -- routing, layouts, RSC, middleware auth, Stripe subscriptions, MDX blog. Spawned the shadcn/ui library.
**Caveats**: STALE -- stuck on Next.js 13. Contentlayer abandoned. Learning reference only, NOT a production starter.

### ixartz/Next-js-Boilerplate
https://github.com/ixartz/Next-js-Boilerplate
Community boilerplate (DX-focused) | 12.6K stars | Score: 84/100 | Very active (Next.js 16 + Tailwind 4)
Most-starred community Next.js boilerplate. Comprehensive DX: ESLint, Prettier, Husky, lint-staged, Commitlint, Vitest + Testing Library, Playwright E2E, Storybook, Sentry, Drizzle ORM, Clerk auth, i18n with next-intl.
**Caveats**: More "kitchen sink" DX boilerplate than architectural reference.
