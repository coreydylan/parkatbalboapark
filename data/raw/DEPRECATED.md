# DEPRECATED - Do Not Edit

These JSON files are **no longer the source of truth** for the app.

## What happened

The app reads data from **Supabase** (via Vercel API routes). These JSON files
were originally used to generate `supabase/seed/seed.sql` via the script at
`data/src/generate-seed-sql.ts`. However, the Supabase database has since been
modified directly through migrations (`supabase/migrations/`), and these JSON
files were never kept in sync.

## Where the real data lives

- **Source of truth**: Supabase database, managed via migrations in `supabase/migrations/`
- **Data flow**: Supabase → Vercel API (`/api/lots`, `/api/recommend`, etc.) → iOS app

## What to do

- **To update lot data**: Write a new migration in `supabase/migrations/`
- **Do NOT edit these JSON files** — changes here will have no effect on the app
- **The seed SQL** (`supabase/seed/seed.sql`) uses `ON CONFLICT DO NOTHING`, so
  re-running it will not overwrite data already in Supabase

## Files in this directory

| File | Status |
|------|--------|
| `lots.json` | Stale — coordinates and lot list differ from Supabase |
| `destinations.json` | Stale — used only for initial seed |
| `pricing-rules.json` | Stale — pricing managed via migrations |
| `holidays.json` | Stale — holidays managed via migrations |
| `payment-methods.json` | Stale — payment methods managed via migrations |
| `tram-data.json` | Stale — tram data managed via migrations |
| `waypoints.json` | Stale — waypoints managed via migrations |

Deprecated as of 2026-02-11. See migration `00009_fix_lot_coordinates.sql` for
the most recent coordinate audit.
