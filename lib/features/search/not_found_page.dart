import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/echo_colors.dart';
import '../../providers/app_strings_provider.dart';

/// 404 页：slug 不存在时友好提示
class NotFoundPage extends ConsumerWidget {
  const NotFoundPage({
    super.key,
    this.slug,
    this.message,
  });

  final String? slug;
  /// 若为 null，使用 [AppStrings.podcastNotFound]
  final String? message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final displayMessage = message ?? s.podcastNotFound;
    return Scaffold(
      backgroundColor: EchoColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 64,
                  color: EchoColors.textTertiary,
                ),
                const SizedBox(height: 24),
                Text(
                  displayMessage,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: EchoColors.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),
                if (slug != null && slug!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'slug: $slug',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: EchoColors.textTertiary,
                        ),
                  ),
                ],
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: () => context.go('/'),
                  child: Text(s.backToHome),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
