/// 播客公开搜索页 URL（仅 path，无 query），用于「分享链接」复制。
/// 不包含 `q`、`ep` 等会话状态，避免把他人搜索内容一并分享出去。
String podcastPublicSearchUrl(String slug) {
  final origin = Uri.base.origin;
  final s = slug.trim();
  if (s.isEmpty) return origin;
  return '$origin/p/${Uri.encodeComponent(s)}';
}
