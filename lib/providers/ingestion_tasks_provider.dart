import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 单个接入任务
class IngestionTask {
  final String id;
  final String status;
  final String title;
  final String episodeSlug;
  final DateTime createdAt;
  final String? errorMessage;
  final String source;
  final bool completedWithAsrGaps;

  const IngestionTask({
    required this.id,
    required this.status,
    required this.title,
    required this.episodeSlug,
    required this.createdAt,
    this.errorMessage,
    required this.source,
    this.completedWithAsrGaps = false,
  });

  factory IngestionTask.fromJson(Map<String, dynamic> json) {
    final created = json['created_at'];
    final metadata = json['metadata'];
    final source = metadata is Map
        ? (metadata['source'] as String? ?? '')
        : '';
    final result = json['result'];
    var gaps = false;
    if (result is Map<String, dynamic>) {
      gaps = result['completed_with_asr_gaps'] == true;
    }
    return IngestionTask(
      id: json['id'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      title: json['title'] as String? ?? '',
      episodeSlug: json['episode_slug'] as String? ?? '',
      createdAt: created is String
          ? DateTime.tryParse(created) ?? DateTime.now()
          : DateTime.now(),
      errorMessage: json['error_message'] as String?,
      source: source,
      completedWithAsrGaps: gaps,
    );
  }
}

final ingestionTasksByPodcastProvider =
    FutureProvider.family<List<IngestionTask>, String>((ref, podcastId) async {
  final res = await Supabase.instance.client
      .from('ingestion_tasks')
      .select('id, status, title, episode_slug, created_at, error_message, metadata, result')
      .eq('podcast_id', podcastId)
      .order('created_at', ascending: false)
      .limit(500);

  return (res as List)
      .map((e) => IngestionTask.fromJson(Map<String, dynamic>.from(e as Map<String, dynamic>)))
      .toList();
});
