-- Echo SaaS — Public showcase: minimal schema + seed for a NEW Supabase project.
-- Run in Supabase Dashboard → SQL Editor.
--
-- Prerequisite: create ONE user via Authentication → Add user → Email (or sign up from a client).
-- The script attaches the demo podcast to the first user in auth.users.

create extension if not exists "pgcrypto";

-- ---------------------------------------------------------------------------
-- podcasts
-- ---------------------------------------------------------------------------
create table if not exists public.podcasts (
  id uuid primary key default gen_random_uuid(),
  slug text not null,
  name text not null,
  creator_id uuid not null references auth.users (id) on delete cascade,
  rss_url text,
  lexicon jsonb default '{}'::jsonb,
  created_at timestamptz not null default now(),
  constraint podcasts_slug_unique unique (slug)
);

create index if not exists idx_podcasts_slug on public.podcasts (slug);

alter table public.podcasts enable row level security;

drop policy if exists "podcasts_select_public" on public.podcasts;
create policy "podcasts_select_public"
  on public.podcasts for select
  using (true);

-- ---------------------------------------------------------------------------
-- episodes (columns required by search Edge Function)
-- ---------------------------------------------------------------------------
create table if not exists public.episodes (
  id uuid primary key default gen_random_uuid(),
  podcast_id uuid not null references public.podcasts (id) on delete cascade,
  episode_slug text not null,
  title text not null default '',
  cover_image text default '',
  xiaoyuzhou_url text default '',
  audio_deep_link text default '',
  entities jsonb default '{}'::jsonb,
  timestamped_topics jsonb default '[]'::jsonb,
  summary text default '',
  transcript_original text,
  transcript_en text,
  searchable boolean not null default true,
  en_tts_storage_path text,
  created_at timestamptz not null default now(),
  constraint episodes_podcast_slug_unique unique (podcast_id, episode_slug)
);

create index if not exists idx_episodes_podcast_id on public.episodes (podcast_id);

alter table public.episodes enable row level security;

drop policy if exists "episodes_select_public" on public.episodes;
create policy "episodes_select_public"
  on public.episodes for select
  using (true);

-- ---------------------------------------------------------------------------
-- seed (idempotent-ish: delete demo rows then insert)
-- ---------------------------------------------------------------------------
do $$
declare
  uid uuid;
  pid uuid;
begin
  select id into uid from auth.users order by created_at asc limit 1;
  if uid is null then
    raise exception 'Create at least one Auth user first (Authentication → Users), then re-run.';
  end if;

  delete from public.episodes where podcast_id in (
    select id from public.podcasts where slug = 'demo_showcase'
  );
  delete from public.podcasts where slug = 'demo_showcase';

  insert into public.podcasts (slug, name, creator_id, lexicon)
  values (
    'demo_showcase',
    'Demo Showcase Podcast',
    uid,
    '{"aliases":{"nick":"nickname"}}'::jsonb
  )
  returning id into pid;

  insert into public.episodes (
    podcast_id, episode_slug, title, cover_image, xiaoyuzhou_url, audio_deep_link,
    entities, timestamped_topics, summary, searchable
  ) values
  (
    pid,
    'ep_demo_1',
    'Demo episode: architecture overview',
    'https://placehold.co/120x120/e0e0e0/333?text=Demo',
    'https://example.com/episodes/demo-1',
    '',
    '{"primary":["Flutter","Riverpod","Supabase"],"secondary":["Web","Search UX"],"aliases":{"F":"Flutter"}}'::jsonb,
    '[{"topic":"Introduction","time_sec":0,"time_label":"00:00"}]'::jsonb,
    'Sample episode for the public showcase repository.',
    true
  ),
  (
    pid,
    'ep_demo_2',
    'Ranking and entity scoring',
    'https://placehold.co/120x120/e0e0e0/333?text=Demo2',
    'https://example.com/episodes/demo-2',
    '',
    '{"primary":["SearchService","Relevance"],"secondary":["Testing"],"aliases":{}}'::jsonb,
    '[]'::jsonb,
    'Discusses client-side ranking heuristics used in the showcase.',
    true
  ),
  (
    pid,
    'ep_demo_3',
    'Edge function integration',
    'https://placehold.co/120x120/e0e0e0/333?text=Demo3',
    'https://example.com/episodes/demo-3',
    '',
    '{"primary":["Deno","Postgres"],"secondary":["RLS"],"aliases":{}}'::jsonb,
    '[]'::jsonb,
    'How the listener UI loads episodes via the search Edge Function.',
    true
  );
end $$;
