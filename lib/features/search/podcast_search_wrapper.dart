import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/browser_detect.dart';
import '../../core/theme/echo_colors.dart';
import '../../providers/app_strings_provider.dart';
import '../../providers/podcasts_provider.dart';
import 'not_found_page.dart';
import 'search_page.dart';
import 'wechat_prompt_page.dart';

/// /p/:slug 路由包装：检查 slug 存在后渲染 SearchPage，否则 404
class PodcastSearchWrapper extends ConsumerWidget {
  const PodcastSearchWrapper({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final podcastAsync = ref.watch(podcastBySlugProvider(slug));

    return podcastAsync.when(
      loading: () => const Scaffold(
        backgroundColor: EchoColors.background,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Consumer(
        builder: (context, ref, _) {
          final s = ref.watch(appStringsProvider);
          return NotFoundPage(
            slug: slug,
            message: s.loadFailedRetryShort,
          );
        },
      ),
      data: (podcast) {
        if (podcast == null) {
          return NotFoundPage(slug: slug);
        }
        return isWeChatBrowser()
            ? const WeChatPromptPage()
            : const SearchPage();
      },
    );
  }
}
