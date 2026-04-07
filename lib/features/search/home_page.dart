import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/echo_colors.dart';
import '../../providers/app_strings_provider.dart';
import '../widgets/locale_toggle_text_button.dart';

/// 创作者首页：Logo +「创作者入口」按钮。布局与搜索页一致，仅将搜索栏替换为按钮。
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    return Scaffold(
      backgroundColor: EchoColors.background,
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'images/echo_logo.png',
                        height: 180,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const SizedBox(height: 80),
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: () => context.push('/auth'),
                        style: FilledButton.styleFrom(
                          backgroundColor: EchoColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                        ),
                        child: Text(s.creatorEntry),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const Positioned(
            top: 8,
            right: 16,
            child: LocaleToggleTextButton(),
          ),
        ],
      ),
    );
  }
}
