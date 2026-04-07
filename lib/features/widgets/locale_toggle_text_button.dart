import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/echo_colors.dart';
import '../../providers/app_strings_provider.dart';
import '../../providers/locale_provider.dart';

/// 灰色小字，与搜索页「分享链接」同风格；中文界面显示「English」，英文界面显示「中文」。
class LocaleToggleTextButton extends ConsumerWidget {
  const LocaleToggleTextButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final s = ref.watch(appStringsProvider);
    final label = locale.languageCode == 'zh'
        ? s.localeToggleToEnglish
        : s.localeToggleToChinese;

    return TextButton(
      onPressed: () {
        ref.read(localeProvider.notifier).toggleZhEn();
      },
      child: Text(
        label,
        style: const TextStyle(
          color: EchoColors.textSecondary,
          fontSize: 14,
        ),
      ),
    );
  }
}
