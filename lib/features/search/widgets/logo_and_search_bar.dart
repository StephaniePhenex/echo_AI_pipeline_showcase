import 'package:flutter/material.dart';

import '../../../core/layout_constants.dart';
import 'search_bar.dart' show EchoSearchBar;

/// Logo + 搜索框，桌面端与窄屏共用。
class LogoAndSearchBar extends StatelessWidget {
  const LogoAndSearchBar({
    super.key,
    required this.logoHeight,
    required this.searchBarKey,
    this.horizontalPadding = 0,
  });

  final double logoHeight;
  final Key searchBarKey;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'images/echo_logo.png',
          key: const ValueKey('logo'),
          height: logoHeight,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => const SizedBox(
            height: LayoutConstants.logoErrorPlaceholderHeight,
          ),
        ),
        const SizedBox(height: LayoutConstants.logoToSearchSpacing),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: LayoutConstants.searchBarMaxWidth),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: EchoSearchBar(key: searchBarKey),
          ),
        ),
      ],
    );
  }
}
