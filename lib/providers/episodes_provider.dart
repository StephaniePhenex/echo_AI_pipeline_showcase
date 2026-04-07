import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/browser_detect.dart';
import '../data/episode_model.dart';
import '../data/episode_repository.dart';
import '../core/supabase_config.dart';

/// 当前搜索的播客 slug，来自 URL ?slug=xxx。无则用默认。
final searchSlugProvider = Provider<String>((ref) {
  final slug = getQueryParameter('slug')?.trim();
  return (slug != null && slug.isNotEmpty) ? slug : defaultPodcastSlug;
});

/// 期数列表（异步加载）。有 slug 时按播客过滤，有搜索词时调用 Supabase API。
final episodesProvider = FutureProvider<List<Episode>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  final slug = ref.watch(searchSlugProvider);
  return EpisodeRepository().fetchFromSupabase(
    baseUrl: supabaseUrl,
    anonKey: supabaseAnonKey,
    slug: slug,
    q: query.trim(),
  );
}, dependencies: [searchSlugProvider, searchQueryProvider]);

/// 搜索关键词。仅从 URL `q` 初始化，不用 localStorage，避免打开干净分享链仍出现上次搜索。
final searchQueryProvider = StateProvider<String>((ref) {
  return getQueryParameter('q') ?? '';
});

/// 当前选中的节目 id（用于 URL 同步）。仅从 URL `ep` 初始化。
final selectedEpisodeIdProvider = StateProvider<String?>((ref) {
  final ep = getQueryParameter('ep');
  if (ep == null || ep.isEmpty) return null;
  return ep;
});

/// 搜索结果：与 episodesProvider 一致，API 已做搜索；保留 loading/error。
final searchResultsProvider = Provider<AsyncValue<List<Episode>>>((ref) {
  return ref.watch(episodesProvider);
}, dependencies: [episodesProvider]);
