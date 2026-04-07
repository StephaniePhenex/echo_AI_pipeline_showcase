# Architecture (showcase)

```mermaid
flowchart TB
  subgraph client [Flutter_Web]
    Router[go_router]
    Riverpod[Riverpod_providers]
    SearchUI[SearchPage_listener_UX]
  end
  subgraph supa [Supabase_demo]
    SearchFn[Edge_Function_search]
    PG[(Postgres_RLS)]
  end
  SearchUI --> SearchFn
  SearchFn --> PG
```

- **Listener flow**: `EpisodeRepository.fetchFromSupabase` calls `GET /functions/v1/search?slug=&q=` with the anon key; on failure it falls back to bundled `assets/data/episodes.json` and client-side `SearchService` ranking.
- **Not included here**: RSS ingestion, media ASR/TTS workers, and proprietary creator pipelines remain private.
