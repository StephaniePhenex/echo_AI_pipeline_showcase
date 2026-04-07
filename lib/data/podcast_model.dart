/// 播客模型
class Podcast {
  final String id;
  final String slug;
  final String name;
  final String? rssUrl;
  final Map<String, dynamic>? lexicon;
  final bool enableEnTts;

  const Podcast({
    required this.id,
    required this.slug,
    required this.name,
    this.rssUrl,
    this.lexicon,
    this.enableEnTts = false,
  });

  factory Podcast.fromJson(Map<String, dynamic> json) {
    final lex = json['lexicon'];
    return Podcast(
      id: json['id'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      name: json['name'] as String? ?? '',
      rssUrl: json['rss_url'] as String?,
      lexicon: lex is Map ? Map<String, dynamic>.from(lex) : null,
      enableEnTts: json['enable_en_tts'] as bool? ?? false,
    );
  }
}
