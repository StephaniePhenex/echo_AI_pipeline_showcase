import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/podcast_model.dart';

/// 公开播客列表（首页选择，无需登录）
final publicPodcastsProvider = FutureProvider<List<Podcast>>((ref) async {
  final res = await Supabase.instance.client
      .from('podcasts')
      .select('id, slug, name, rss_url, lexicon, enable_en_tts')
      .order('created_at', ascending: false);
  return (res as List)
      .map((e) => Podcast.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();
});

/// 按 id 获取播客（创作者后台、上传页共用）
final podcastByIdProvider =
    FutureProvider.family<Podcast?, String>((ref, id) async {
  final res = await Supabase.instance.client
      .from('podcasts')
      .select('id, slug, name, rss_url, lexicon, enable_en_tts')
      .eq('id', id)
      .maybeSingle();
  if (res == null) return null;
  return Podcast.fromJson(Map<String, dynamic>.from(res));
});

/// 按 slug 获取播客（公开，用于 /p/:slug 页面标题等）
final podcastBySlugProvider =
    FutureProvider.family<Podcast?, String>((ref, slug) async {
  if (slug.trim().isEmpty) return null;
  final res = await Supabase.instance.client
      .from('podcasts')
      .select('id, slug, name, rss_url, lexicon, enable_en_tts')
      .eq('slug', slug.trim())
      .maybeSingle();
  if (res == null) return null;
  return Podcast.fromJson(Map<String, dynamic>.from(res));
});

final creatorPodcastsProvider = FutureProvider<List<Podcast>>((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return [];

  final res = await Supabase.instance.client
      .from('podcasts')
      .select('id, slug, name, rss_url, enable_en_tts')
      .eq('creator_id', user.id)
      .order('created_at', ascending: false);

  return (res as List)
      .map((e) => Podcast.fromJson(e as Map<String, dynamic>))
      .toList();
});
