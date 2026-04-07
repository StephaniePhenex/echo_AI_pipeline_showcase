/// 非 Web 平台：恒为 false
bool isWeChatBrowser() => false;

/// 非 Web 平台：无当前 URL
String? getCurrentWebUrl() => null;

/// 非 Web 平台：无 query 参数
String? getQueryParameter(String key) => null;

/// 非 Web 平台：更新 query 参数无操作
void replaceQueryParameters(Map<String, String?> updates) {}

/// 非 Web 平台：无会话存储
String? readSessionState(String key) => null;

void writeSessionState(String key, String value) {}

/// 非 Web 平台：无操作
void setPageTitle(String title) {}

/// 非 Web 平台：无操作
void setPageDescription(String description) {}
