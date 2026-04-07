/// Episode 数据模型，映射 JSON Standard 2.0 格式。
class Episode {
  final String id;
  final String title;
  final String coverImage;
  /// 浏览器打开的收听页 URL（小宇宙 / 苹果播客等）；API 字段名为 `xiaoyuzhou_url`。
  final String xiaoyuzhouUrl;
  final String audioDeepLink;
  final EpisodeEntities entities;
  final List<TimestampedTopic> timestampedTopics;
  final String summary;
  /// Signed URL for generated English TTS audio (if available).
  final String enTtsSignedUrl;
  final bool searchable;
  /// 中文稿预览（search API 截断）；来自 ASR 整理后 `transcript_original`。
  final String transcriptOriginalPreview;
  /// 英文稿预览（search API 截断）。
  final String transcriptEnPreview;

  const Episode({
    required this.id,
    required this.title,
    required this.coverImage,
    required this.xiaoyuzhouUrl,
    required this.audioDeepLink,
    required this.entities,
    required this.timestampedTopics,
    required this.summary,
    this.enTtsSignedUrl = '',
    this.searchable = true,
    this.transcriptOriginalPreview = '',
    this.transcriptEnPreview = '',
  });

  factory Episode.fromJson(Map<String, dynamic> json) {
    return Episode(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      coverImage: json['cover_image'] as String? ?? '',
      xiaoyuzhouUrl: json['xiaoyuzhou_url'] as String? ?? '',
      audioDeepLink: json['audio_deep_link'] as String? ?? '',
      entities: EpisodeEntities.fromJson(
        json['entities'] as Map<String, dynamic>? ?? {},
      ),
      timestampedTopics: (json['timestamped_topics'] as List<dynamic>?)
              ?.map((e) => TimestampedTopic.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      summary: json['summary'] as String? ?? '',
      enTtsSignedUrl: json['en_tts_signed_url'] as String? ?? '',
      searchable: json['searchable'] as bool? ?? true,
      transcriptOriginalPreview:
          json['transcript_original_preview'] as String? ?? '',
      transcriptEnPreview: json['transcript_en_preview'] as String? ?? '',
    );
  }
}

/// entities：primary、secondary、aliases
class EpisodeEntities {
  final List<String> primary;
  final List<String> secondary;
  final Map<String, String> aliases;

  const EpisodeEntities({
    required this.primary,
    required this.secondary,
    required this.aliases,
  });

  factory EpisodeEntities.fromJson(Map<String, dynamic> json) {
    return EpisodeEntities(
      primary: (json['primary'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      secondary: (json['secondary'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      aliases: (json['aliases'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v.toString())) ??
          {},
    );
  }
}

/// timestamped_topics 单项
class TimestampedTopic {
  final String topic;
  final int timeSec;
  final String timeLabel;

  const TimestampedTopic({
    required this.topic,
    required this.timeSec,
    required this.timeLabel,
  });

  factory TimestampedTopic.fromJson(Map<String, dynamic> json) {
    return TimestampedTopic(
      topic: json['topic'] as String? ?? '',
      timeSec: json['time_sec'] as int? ?? 0,
      timeLabel: json['time_label'] as String? ?? '',
    );
  }
}
