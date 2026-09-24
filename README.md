# LUMÉA Suite

Production-oriented multi-tenant salon SaaS foundation built with Next.js, TypeScript, Tailwind CSS and Supabase.

## Current scope

Foundation currently includes:

- Next.js 16 App Router and strict TypeScript;
- Tailwind CSS 4 design tokens;
- Supabase SSR browser/server clients with cookie-based sessions;
- Next.js 16 proxy session refresh;
- tenant role and permission primitives;
- onboarding validation;
- booking slot generation with unit tests;
- CI for lint, typecheck, tests and production build;
- Supabase migrations under `supabase/migrations`.

## Requirements

- Node.js 22.13+
- npm
- a dedicated Supabase project

## Environment

Copy `.env.example` to `.env.local` and set the values. Never expose the Supabase secret key in browser code.

## Development

```bash
npm install
npm run dev
```

Verification:

```bash
npm run lint
npm run typecheck
npm run test:run
npm run build
```

## Supabase

Use a dedicated project for this application. Do not reuse unrelated projects.

Apply migrations with the Supabase CLI or connected Supabase tooling, then generate database types. New public tables are protected by RLS and explicit grants.

## Architecture

- `src/app`: routes and layouts
- `src/lib/booking`: booking rules and availability primitives
- `src/lib/supabase`: SSR/database clients
- `src/lib/validation`: Zod schemas
- `src/lib/permissions.ts`: application permission model
- `supabase/migrations`: database schema, RLS and transactional booking logic
