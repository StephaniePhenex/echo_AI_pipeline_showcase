import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/telemetry.dart';
import '../../../core/theme/echo_colors.dart';
import '../../../providers/app_strings_provider.dart';
import '../../../providers/episodes_provider.dart';

/// 搜索框，按回车或停止输入 250ms 后更新 searchQueryProvider。
class EchoSearchBar extends ConsumerStatefulWidget {
  const EchoSearchBar({super.key});

  @override
  ConsumerState<EchoSearchBar> createState() => _EchoSearchBarState();
}

class _EchoSearchBarState extends ConsumerState<EchoSearchBar> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  Timer? _debounceTimer;
  static const _debounceDuration = Duration(milliseconds: 250);

  bool get _isImeComposing {
    final composing = _controller.value.composing;
    return composing.isValid && !composing.isCollapsed;
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: ref.read(searchQueryProvider));
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _updateQuery(String value) {
    _debounceTimer?.cancel();
    // 中文/日文等输入法在「组合态」会先产生拼音/字母，需等上屏后再触发搜索。
    if (_isImeComposing) {
      return;
    }

    final normalized = value.trim();
    if (normalized.isEmpty) {
      ref.read(searchQueryProvider.notifier).state = '';
      return;
    }
    _debounceTimer = Timer(_debounceDuration, () {
      if (mounted) {
        ref.read(searchQueryProvider.notifier).state = normalized;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final query = ref.watch(searchQueryProvider);

    // 避免输入法组合态时被外部状态反向覆盖输入中的文本。
    final shouldSyncController = !_focusNode.hasFocus || !_isImeComposing;
    if (shouldSyncController && _controller.text != query) {
      _controller.value = TextEditingValue(
        text: query,
        selection: TextSelection.collapsed(offset: query.length),
      );
    }

    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      style: const TextStyle(fontSize: 16, color: EchoColors.textPrimary),
      onChanged: _updateQuery,
      onSubmitted: (value) {
        _debounceTimer?.cancel();
        final query = value.trim();
        ref.read(searchQueryProvider.notifier).state = query;
        logEvent('search_submit', {'query': query});
      },
      decoration: InputDecoration(
        hintText: s.searchHint,
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: EchoColors.background,
        contentPadding: const EdgeInsets.symmetric(vertical: 15),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: EchoColors.divider.withValues(alpha: 0.4),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: EchoColors.divider.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}
