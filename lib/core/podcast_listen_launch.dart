import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';

/// 打开收听页外链。
///
/// Flutter Web 上 [canLaunchUrl] 常对 `https` 外链误报 `false`，导致从不调用
/// [launchUrl]；因此在 Web 上直接 [launchUrl]，并用新标签页打开。
Future<bool> launchPodcastListenUrl(Uri uri) async {
  if (kIsWeb) {
    return launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
      webOnlyWindowName: '_blank',
    );
  }
  if (await canLaunchUrl(uri)) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
