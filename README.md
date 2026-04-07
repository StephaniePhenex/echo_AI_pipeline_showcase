# Echo SaaS — Public showcase

Flutter Web listener experience: podcast-scoped search, relevance-ranked episode cards, and a Supabase **search** Edge Function integration pattern. Bundled JSON fixtures allow offline UI runs; connecting a **demo-only** Supabase project is optional but demonstrates the full stack.

## Legal / IP notice

**This is a public showcase version. The full source code is private due to proprietary business logic and intellectual property protection.**

**This repository is a public showcase. The complete application, backend ingestion pipelines, media processing workers, and proprietary datasets remain private.**

This project is shared **for portfolio and architectural demonstration only** and does **not** grant any license to the full commercial product, production data, or internal systems. Sample data and URLs in this repo are **fictional or placeholder** unless you connect your own Supabase demo project.

*(This notice is informational and not legal advice; consult qualified counsel for IP or employment contexts.)*

## Tech stack

- **Flutter** (Web) · Riverpod · go_router · http
- **Supabase** (Postgres + Row Level Security + Edge Functions) for the optional live demo

## Run locally (fixtures only)

Uses `assets/data/episodes.json` when the search API is unreachable.

```bash
flutter pub get
flutter run -d chrome
```

Open `/p/demo_showcase` for the listener page (default slug is `demo_showcase`).

## Run against your demo Supabase (tier C)

1. Create a **new** Supabase project (do not use production).
2. **Authentication**: add at least one user (Email signup is enough).
3. **SQL**: run [`docs/DEMO_SUPABASE.sql`](docs/DEMO_SUPABASE.sql) in the SQL Editor.
4. **Edge Function**: deploy [`supabase/functions/search`](supabase/functions/search) to that project (`supabase functions deploy search --no-verify-jwt` from a machine with CLI logged in), or use the Dashboard Edge Functions UI.
5. **Build / run** with your **anon** key (Settings → API → Project URL + anon public key):

```bash
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

Do **not** commit real keys. Rotating the anon key in the dashboard invalidates old clones; treat published keys as **demo-only**.

The Edge Function uses the standard Supabase runtime secrets `SUPABASE_URL` and `SUPABASE_ANON_KEY` (auto-injected when deployed). Optional `SUPABASE_SERVICE_ROLE_KEY` enables signed URLs for TTS paths; omit it for a minimal public demo.

## Tests

```bash
flutter test
flutter analyze
```

## Repository layout

| Path | Purpose |
|------|---------|
| `lib/` | UI, routing, client search ranking (`SearchService`) |
| `assets/data/episodes.json` | Fictional offline fixtures |
| `docs/DEMO_SUPABASE.sql` | Demo schema + seed |
| `supabase/functions/search` | Search API used by `EpisodeRepository` |

See [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) and [`docs/SHOWCASE_ALLOWLIST.md`](docs/SHOWCASE_ALLOWLIST.md).

## Publish this repo to GitHub

Create a **new public** repository (empty, no README). Then from this folder:

```bash
git init -b main   # skip if already initialized
git add -A && git commit -m "Initial public showcase import"
git remote add origin https://github.com/YOUR_ORG/echo-saas-showcase.git
git push -u origin main
```

Use a **dedicated** remote for this repo; do not add it as a second remote to your private monorepo working copy to avoid accidental pushes.

## License

MIT — see [LICENSE](LICENSE). Sample data is illustrative only.
