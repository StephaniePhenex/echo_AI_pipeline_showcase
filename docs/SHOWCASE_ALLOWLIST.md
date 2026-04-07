# Showcase copy manifest

This public repository was produced from a **private** monorepo using an allowlist (fresh history, no production git tree).

## Included

- `lib/` — Flutter UI, routing, Riverpod, search/listener UX patterns
- `web/`, `images/`, `assets/data/episodes.json` — small **fictional** fixtures
- `test/` — unit/widget tests that run offline
- `supabase/functions/search/` — Edge Function sample for `GET /functions/v1/search` (deploy to **your** demo project)
- `docs/DEMO_SUPABASE.sql` — schema + seed for a **new** Supabase project (no production data)

## Excluded from the private app (not in this repo)

- Internal `scripts/` data pipelines, transcripts, lexicons, deployment keys
- `workers/` (Python RSS/media ingestion)
- Full `supabase/migrations` history and production-only Edge Functions
- Proprietary business rules and creator-dashboard integrations not required for the listener demo

## Copy command (maintainers)

Regenerate from the private tree with `rsync` and the exclusions described in the private delivery playbook; always run a secrets grep before `git push` to the public remote.
