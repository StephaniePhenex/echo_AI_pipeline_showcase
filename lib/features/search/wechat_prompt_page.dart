import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/browser_detect.dart';
import '../../core/telemetry.dart';
import '../../core/theme/echo_colors.dart';
import '../../providers/app_strings_provider.dart';

/// 微信内置浏览器提示页：建议用户用系统浏览器打开
class WeChatPromptPage extends ConsumerWidget {
  const WeChatPromptPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final url = getCurrentWebUrl();

    return Scaffold(
      backgroundColor: EchoColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.open_in_browser,
                size: 64,
                color: EchoColors.textTertiary,
              ),
              const SizedBox(height: 24),
              Text(
                s.wechatSuggestBrowserTitle,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: EchoColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                s.wechatSuggestBrowserBody,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: EchoColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              if (url != null)
                FilledButton.icon(
                  onPressed: () => _openInBrowser(url),
                  icon: const Icon(Icons.open_in_new),
                  label: Text(s.openInBrowser),
                  style: FilledButton.styleFrom(
                    backgroundColor: EchoColors.primary,
                    foregroundColor: EchoColors.textPrimary,
                  ),
                )
              else
                Text(
                  s.wechatMenuHint,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: EchoColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openInBrowser(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'https') {
      logEvent('open_url_fail', {'reason': 'invalid_scheme', 'url': url});
      return;
    }
    if (await canLaunchUrl(uri)) {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) {
        logEvent('open_url_fail', {
          'reason': 'launch_return_false',
          'url': url,
        });
      }
      return;
    }
    logEvent('open_url_fail', {'reason': 'cannot_launch', 'url': url});
  }
}
