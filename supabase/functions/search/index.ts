// Echo SaaS (showcase): search episodes by podcast slug + query
// GET /functions/v1/search?slug=demo_showcase&q=Flutter

import "jsr:@supabase/functions-js/edge-runtime.d.ts"
import { createClient } from "npm:@supabase/supabase-js@2"

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
}

interface EpisodeRow {
  id: string
  podcast_id: string
  episode_slug: string
  title: string
  cover_image: string
  xiaoyuzhou_url: string
  audio_deep_link: string
  entities: { primary: string[]; secondary: string[]; aliases: Record<string, string> }
  timestamped_topics: Array<{ topic: string; time_sec: number; time_label: string }>
  summary: string
  en_tts_storage_path?: string | null
  transcript_original?: string | null
  transcript_en?: string | null
}

const TRANSCRIPT_PREVIEW_MAX = 4000

function truncateForApi(s: string | null | undefined): string {
  const t = (s ?? "").trim()
  if (t.length <= TRANSCRIPT_PREVIEW_MAX) return t
  return t.slice(0, TRANSCRIPT_PREVIEW_MAX) + "…"
}

function rewriteSignedUrlHostForClient(
  signedUrl: string,
  reqUrl: string,
  preferredBaseUrl?: string | null,
): string {
  try {
    const s = new URL(signedUrl)
    const r = new URL(reqUrl)
    // Prefer caller-visible base URL; req.url inside edge runtime may be internal host.
    const base = preferredBaseUrl && preferredBaseUrl.trim()
      ? preferredBaseUrl
      : `${r.protocol}//${r.host}`
    // Keep signed path/token and rewrite host for browser reachability.
    return new URL(`${s.pathname}${s.search}`, base).toString()
  } catch {
    return signedUrl
  }
}

function resolvePublicBaseUrl(req: Request): string | null {
  const envPublic = Deno.env.get("SUPABASE_PUBLIC_URL") ?? Deno.env.get("SITE_URL")
  if (envPublic && envPublic.trim()) return envPublic.trim()

  const xfHost = req.headers.get("x-forwarded-host")
  const xfProto = req.headers.get("x-forwarded-proto")
  const xfPort = req.headers.get("x-forwarded-port")
  if (xfHost && xfHost.trim()) {
    const proto = (xfProto && xfProto.trim()) ? xfProto : "https"
    const hasPort = xfHost.includes(":")
    const hostWithPort = (!hasPort && xfPort && xfPort.trim())
      ? `${xfHost}:${xfPort}`
      : xfHost
    return `${proto}://${hostWithPort}`
  }
  const host = req.headers.get("host")
  if (host && host.trim()) {
    const proto = host.includes("localhost") || host.includes("127.0.0.1") ? "http" : "https"
    if (!host.includes(":") && (host.includes("localhost") || host.includes("127.0.0.1"))) {
      return `${proto}://${host}:54321`
    }
    return `${proto}://${host}`
  }
  return null
}

function toApiEpisode(row: EpisodeRow, enTtsSignedUrl?: string | null): Record<string, unknown> {
  return {
    id: row.episode_slug,
    podcast_id: row.podcast_id,
    title: row.title,
    cover_image: row.cover_image,
    xiaoyuzhou_url: row.xiaoyuzhou_url,
    audio_deep_link: row.audio_deep_link,
    entities: row.entities ?? { primary: [], secondary: [], aliases: {} },
    timestamped_topics: row.timestamped_topics ?? [],
    summary: row.summary ?? "",
    en_tts_signed_url: enTtsSignedUrl ?? "",
    transcript_original_preview: truncateForApi(row.transcript_original),
    transcript_en_preview: truncateForApi(row.transcript_en),
  }
}

/** 从 podcast.lexicon 扩展查询词：别名双向映射，搜「发哥」可命中含「周润发」的期数 */
function expandQueryTerms(
  q: string,
  lexicon: Record<string, unknown> | null,
): string[] {
  const trimmed = q.trim()
  if (!trimmed) return []
  const terms = new Set<string>([trimmed])
  if (!lexicon) return [...terms]
  const aliases = lexicon.aliases as Record<string, string> | undefined
  if (!aliases || typeof aliases !== "object") return [...terms]
  const lower = trimmed.toLowerCase()
  for (const [key, value] of Object.entries(aliases)) {
    if (key.toLowerCase() === lower || value.toLowerCase() === lower) {
      terms.add(key)
      terms.add(value)
    }
  }
  return [...terms]
}

function matches(
  ep: EpisodeRow,
  queryTerms: string[],
): boolean {
  const entities = ep.entities ?? { primary: [], secondary: [], aliases: {} }
  const text = [
    ep.title ?? "",
    ...(entities.primary ?? []),
    ...(entities.secondary ?? []),
    ...Object.keys(entities.aliases ?? {}),
    ...Object.values(entities.aliases ?? {}),
    ep.summary ?? "",
    ep.transcript_original ?? "",
    ep.transcript_en ?? "",
  ].join(" ")
  const textLower = text.toLowerCase()
  return queryTerms.some((t) => {
    const lower = t.toLowerCase()
    return lower && textLower.includes(lower)
  })
}

function score(ep: EpisodeRow, queryTerms: string[]): number {
  let s = 0
  const entities = ep.entities ?? { primary: [], secondary: [], aliases: {} }
  for (const q of queryTerms) {
    const lower = q.toLowerCase()
    if (!lower) continue
    const strength = (field: string) => {
      const f = field.toLowerCase()
      if (f === lower) return 1
      if (f.startsWith(lower)) return 0.8
      if (f.includes(lower)) return 0.5
      return 0
    }
    entities.primary?.forEach((p, i) => {
      s += 10 * strength(p) * Math.pow(0.9, i)
    })
    s += 8 * strength(ep.title ?? "")
    entities.secondary?.forEach((p) => { s += 3 * strength(p) })
    Object.entries(entities.aliases ?? {}).forEach(([k, v]) => {
      s += 6 * Math.max(strength(k), strength(v))
    })
    s += 2 * strength(ep.summary ?? "")
    s += 0.5 * strength((ep.transcript_original ?? "").slice(0, 800))
    s += 0.5 * strength((ep.transcript_en ?? "").slice(0, 800))
  }
  return s
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders })
  }

  try {
    const url = new URL(req.url)
    const slug = url.searchParams.get("slug")?.trim()
    const q = url.searchParams.get("q")?.trim() ?? ""

    if (!slug) {
      return new Response(
        JSON.stringify({ error: "Missing slug" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      )
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!
    const publicBaseUrl = resolvePublicBaseUrl(req)
    const supabaseKey = Deno.env.get("SUPABASE_ANON_KEY")!
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")
    const ttsBucket = Deno.env.get("TTS_BUCKET") ?? "tts-artifacts"
    const signedUrlTtlSec = Math.max(60, parseInt(Deno.env.get("TTS_SIGNED_URL_TTL_SEC") ?? "3600", 10))

    const supabase = createClient(supabaseUrl, supabaseKey)
    const admin = serviceRoleKey
      ? createClient(supabaseUrl, serviceRoleKey)
      : null

    const { data: podcasts } = await supabase
      .from("podcasts")
      .select("id, lexicon")
      .eq("slug", slug)
      .limit(1)

    if (!podcasts?.length) {
      return new Response(
        JSON.stringify([]),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } },
      )
    }

    const podcastId = podcasts[0].id
    const lexicon = (podcasts[0] as { lexicon?: Record<string, unknown> }).lexicon ?? null
    const queryTerms = expandQueryTerms(q, lexicon)

    const { data: rows, error } = await supabase
      .from("episodes")
      .select("*")
      .eq("podcast_id", podcastId)
      .eq("searchable", true)

    if (error) {
      console.error("episodes fetch error:", error)
      return new Response(
        JSON.stringify({ error: error.message }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      )
    }

    const episodes = (rows ?? []) as EpisodeRow[]
    const filtered = queryTerms.length > 0
      ? episodes.filter((e) => matches(e, queryTerms))
      : episodes
    filtered.sort((a, b) => {
      const cmp = score(b, queryTerms) - score(a, queryTerms)
      if (cmp !== 0) return cmp
      return a.episode_slug.localeCompare(b.episode_slug)
    })

    const ttsUrlBySlug = new Map<string, string>()
    if (admin) {
      await Promise.all(
        filtered.map(async (ep) => {
          const path = (ep.en_tts_storage_path ?? "").trim()
          if (!path) return
          const { data } = await admin.storage.from(ttsBucket).createSignedUrl(path, signedUrlTtlSec)
          if (data?.signedUrl) {
            ttsUrlBySlug.set(
              ep.episode_slug,
              rewriteSignedUrlHostForClient(data.signedUrl, req.url, publicBaseUrl),
            )
          }
        }),
      )
    }

    const result = filtered.map((row) => toApiEpisode(row, ttsUrlBySlug.get(row.episode_slug)))

    return new Response(JSON.stringify(result), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    })
  } catch (err) {
    console.error("search error:", err)
    return new Response(
      JSON.stringify({ error: String(err) }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    )
  }
})
