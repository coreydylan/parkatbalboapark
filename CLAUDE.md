# Park at Balboa Park

Parking recommendation app for Balboa Park, San Diego. Helps visitors, residents, staff, and ADA users find the best parking lot based on destination, time, and pricing.

## Project Structure

Monorepo using pnpm workspaces + turborepo:

- `packages/shared` — TypeScript types, pricing engine, constants. Shared across all packages.
- `packages/chatgpt` — ChatGPT plugin (OpenAPI spec + system prompt).
- `data/` — Raw JSON data files (`data/raw/`), build scripts (`data/src/`), generated output (`data/generated/`).
- `supabase/` — Database migrations and seed SQL.
- `ios/` — SwiftUI app (Xcode project in `ios/ParkAtBalboaPark`). Primary client app.

> **Deprecated**: The web app (`packages/web`) has been archived to [parkatbalboapark-web-archive](https://github.com/coreydylan/parkatbalboapark-web-archive). Its Vercel deployment still serves API routes used by the iOS app. The iOS app is the sole active client.

## Commands

```
pnpm install          # Install all dependencies
pnpm build            # Build all packages
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
4. iOS app calls Supabase RPC `get_parking_recommendations()` via Next.js API routes (hosted on Vercel from the archived web repo)
5. Pricing engine in `packages/shared` provides shared TypeScript pricing logic (used for tests and validation)

## Pricing Logic

- **Tiers**: 0 (free), 1 (premium/Level 1), 2 (standard/Level 2), 3 (economy/Level 3)
- **User types**: resident, nonresident, staff, volunteer, ada
- **Verified vs unverified residents**: The city program distinguishes "verified residents" (registered with City of San Diego, $5 one-time fee) from unverified. In the backend, `user_type='resident'` = verified resident rates, `user_type='nonresident'` = full rates. The UI asks about verification status and maps unverified residents to `nonresident` for API calls.
- **Enforcement**: Mon-Sun 8am-8pm until March 1, 2026. Changes to 8am-6pm on March 2, 2026. Inactive on holidays.
- **ADA**: Free everywhere at all tiers (official policy since launch). ADA placard holders can use any available space, not just designated blue spaces.
- **Staff/Volunteer**: Free at tier 0/2/3. Pay at tier 1 ($5/block up to 4hrs, $8/day).
- **Residents (verified)**: Pay $5/day at tier 2/3 until March 1, 2026. Free at tier 2/3 starting March 2. Block pricing at tier 1 ($5 up to 4hrs, $8/day).
- **Nonresidents (and unverified residents)**: Block pricing at tier 1 ($10 up to 4hrs, $16/day). $10/day at tier 2/3.
- **Inspiration Point Lower**: First 3 hours free for everyone. Tier 3 lot.
- **Block pricing**: Tier 1 uses `duration_type = 'block'` — flat rate for up to 4 hours, `max_daily_cents` for longer visits. This is NOT hourly.

### Parking Passes

| Pass | Resident | Non-Resident |
|------|----------|--------------|
| Monthly | $30 | $40 |
| Quarterly | $60 | $120 |
| Annual | $150 | $300 |

### March 2, 2026 Changes (slated, confirmed)

- Enforcement hours reduce from 8am-8pm to 8am-6pm
- Tier 2/3 resident pricing drops to $0 (free for verified city residents)
- Palisades and Bea Evenson transition from tier 1 to tier 2 (free for verified residents)
- 7 specific lots free for verified residents: Pepper Grove, Federal Building, Inspiration Point Upper, Inspiration Point Lower, Marston Point, Palisades, Bea Evenson
- Note: nonresidents still pay full rates at all paid lots

### Holidays (free parking, no enforcement)

New Year's Day, MLK Day, Presidents' Day, Memorial Day, Independence Day, Labor Day, Veterans Day, Thanksgiving, Christmas Day
