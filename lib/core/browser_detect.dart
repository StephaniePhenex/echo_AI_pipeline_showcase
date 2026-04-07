// 导出平台相关实现：Web 端检测 UA，非 Web 端恒为 false
export 'browser_detect_stub.dart' if (dart.library.html) 'browser_detect_web.dart';
