# Park at Balboa Park

Parking recommendation app for Balboa Park, San Diego. Helps visitors, residents, staff, and ADA users find the best parking lot based on destination, time, and pricing.

## Project Structure

Monorepo using pnpm workspaces + turborepo:

- `packages/shared` — TypeScript types, pricing engine, constants. Shared across all packages.
- `packages/web` — Next.js 15 web app with Mapbox GL map, Zustand store, Supabase backend.
- `packages/chatgpt` — ChatGPT plugin (OpenAPI spec + system prompt).
- `data/` — Raw JSON data files (`data/raw/`), build scripts (`data/src/`), generated output (`data/generated/`).
- `supabase/` — Database migrations and seed SQL.
- `ios/` — Future SwiftUI app (not yet started).

## Commands

```
pnpm install          # Install all dependencies
pnpm build            # Build all packages
pnpm dev              # Start dev server (web)
pnpm test             # Run tests across all packages
```

## Key Conventions

- **TypeScript everywhere** — camelCase in TS, snake_case in SQL
- **Prices in cents** — all monetary values stored as integers (cents). Use `formatCost()` for display.
- **Times in Pacific** — Balboa Park is in America/Los_Angeles. All server-side time logic must convert from UTC.
- **UUID primary keys** — Supabase uses `gen_random_uuid()`. FK references are UUIDs, not slugs.
- **Slug as human key** — Each lot and destination has a unique slug for URLs and lookups.

## Data Flow

1. Raw JSON files in `data/raw/` (lots, destinations, pricing rules, holidays, tram data, payment methods)
2. `data/src/generate-seed-sql.ts` → generates `supabase/seed/seed.sql`
3. Seed SQL loads into Supabase Postgres
4. Web app calls Supabase RPC `get_parking_recommendations()` via Next.js API routes
5. Pricing engine in `packages/shared` provides client-side fallback calculation

## Pricing Logic

- **Tiers**: 0 (free), 1 (premium), 2 (standard), 3 (economy)
- **User types**: resident, nonresident, staff, volunteer, ada
- **Enforcement**: Mon-Sun 8am-6pm, inactive on holidays
- **ADA**: Free everywhere after March 2, 2026. Before that, $5/day at tier 1.
- **Staff/Volunteer**: Free at tier 0/2/3. Pay at tier 1.
- **Residents**: Free at tier 0/2/3. Hourly at tier 1 ($5/hr, $8 max).
- **Inspiration Point Lower**: First 3 hours free for everyone.
