import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/episode_model.dart';

final episodesByPodcastProvider =
    FutureProvider.family<List<Episode>, String>((ref, podcastId) async {
  final res = await Supabase.instance.client
      .from('episodes')
      .select(
          'episode_slug, title, cover_image, xiaoyuzhou_url, audio_deep_link, entities, timestamped_topics, summary, searchable')
      .eq('podcast_id', podcastId)
      .order('episode_slug');

  return (res as List)
      .map((e) {
        final m = Map<String, dynamic>.from(e as Map<String, dynamic>);
        m['id'] = m['episode_slug'] ?? '';
        return Episode.fromJson(m);
      })
      .toList();
});
