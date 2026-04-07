bool hasNonEmptyText(dynamic value) {
  return (value ?? '').toString().trim().isNotEmpty;
}

bool isBilingualSubtitleCompleted(Map<String, dynamic> episode) {
  final hasZh = hasNonEmptyText(episode['transcript_original']);
  final hasEn = hasNonEmptyText(episode['transcript_en']);
  return hasZh && hasEn;
}
