/// 搜索结果卡片「打开收听页」允许跳转的外部链接（仅 https）。
/// 与封面图策略无关；此处用于 url_launcher。
bool isAllowedPodcastListenUrl(Uri uri) {
  if (uri.scheme != 'https') return false;
  final h = uri.host.toLowerCase();
  if (_hostIs(h, 'xiaoyuzhoufm.com')) return true;
  if (_hostIs(h, 'podcasts.apple.com')) return true;
  if (_hostIs(h, 'itunes.apple.com')) return true;
  if (_hostIs(h, 'music.apple.com')) return true;
  if (_hostIs(h, 'apps.apple.com')) return true;
  // Spotify（含 open.spotify.com、spotify.com 等）
  if (_hostIs(h, 'spotify.com')) return true;
  if (h == 'spotify.link') return true;
  // 荔枝播客
  if (_hostIs(h, 'lizhi.fm')) return true;
  // 豆瓣播客（www.douban.com/podcast/… 等站内页）
  if (_hostIs(h, 'douban.com')) return true;
  return false;
}

bool _hostIs(String host, String apexDomain) {
  return host == apexDomain || host.endsWith('.$apexDomain');
}

/// 将 `http` 升为 `https`（仅当升级后仍通过白名单时）。
Uri normalizePodcastListenUri(Uri uri) {
  if (uri.scheme != 'http') return uri;
  final u = uri.replace(scheme: 'https');
  if (isAllowedPodcastListenUrl(u)) return u;
  return uri;
}
