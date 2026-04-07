// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

/// Web 端：检测微信内置浏览器（UA 含 MicroMessenger，不区分大小写）
bool isWeChatBrowser() =>
    html.window.navigator.userAgent.toLowerCase().contains('micromessenger');

/// Web 端：当前页面 URL
String? getCurrentWebUrl() => html.window.location.href;

/// Web 端：读取 query 参数
String? getQueryParameter(String key) {
  final uri = Uri.parse(html.window.location.href);
  return uri.queryParameters[key];
}

/// Web 端：批量更新 query 参数（replaceState，不刷新页面）
void replaceQueryParameters(Map<String, String?> updates) {
  final current = Uri.parse(html.window.location.href);
  final nextQuery = Map<String, String>.from(current.queryParameters);

  updates.forEach((k, v) {
    if (v == null || v.trim().isEmpty) {
      nextQuery.remove(k);
    } else {
      nextQuery[k] = v;
    }
  });

  final next = current.replace(
    queryParameters: nextQuery.isEmpty ? null : nextQuery,
  );
  html.window.history.replaceState(null, '', next.toString());
}

/// Web 端：会话级持久化（localStorage）
String? readSessionState(String key) => html.window.localStorage[key];

void writeSessionState(String key, String value) {
  html.window.localStorage[key] = value;
}

/// Web 端：设置页面标题（浏览器标签）
void setPageTitle(String title) {
  html.document.title = title;
}

/// Web 端：设置 meta description（SEO）
void setPageDescription(String description) {
  var meta = html.document.querySelector('meta[name="description"]');
  if (meta == null) {
    meta = html.document.createElement('meta');
    meta.setAttribute('name', 'description');
    html.document.head?.append(meta);
  }
  meta.setAttribute('content', description);
}
