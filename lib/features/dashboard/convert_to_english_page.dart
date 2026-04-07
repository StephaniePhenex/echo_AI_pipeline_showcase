import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/echo_colors.dart';
import '../../data/episode_model.dart';
import '../../providers/app_strings_provider.dart';
import '../../providers/podcasts_provider.dart';
import 'convert_to_english_visibility.dart';
import '../search/widgets/episode_card.dart';

class ConvertToEnglishPage extends ConsumerStatefulWidget {
  const ConvertToEnglishPage({super.key, required this.podcastId});

  final String podcastId;

  @override
  ConsumerState<ConvertToEnglishPage> createState() =>
      _ConvertToEnglishPageState();
}

class _ConvertToEnglishPageState extends ConsumerState<ConvertToEnglishPage> {
  bool _loadingTasks = false;
  bool _enqueueSubtitle = false;
  bool _enqueueAudio = false;
  final int _taskPage = 1;

  /// 与 `convert_english` tasks 接口上限一致（100）；过小会导致按 `updated_at` 排序时
  /// 进行中的任务落在后续页，`_hasExecutionTasks` 误判为无活跃任务从而隐藏整块进度 UI。
  final int _taskPageSize = 100;
  List<Map<String, dynamic>> _episodes = const [];
  List<Map<String, dynamic>> _tasks = const [];
  final Set<String> _selectedEpisodeSlugs = <String>{};
  final Map<String, TextEditingController> _subtitleControllers =
      <String, TextEditingController>{};
  final Map<String, List<TextEditingController>> _pairSubtitleControllers =
      <String, List<TextEditingController>>{};
  final Set<String> _savingSubtitleSlugs = <String>{};
  final Set<String> _subtitleExpandedSlugs = <String>{};
  Timer? _refreshTimer;
  bool _refreshing = false;
  DateTime? _currentBatchAnchorTime;
  Map<String, dynamic> _estimate = const {};
  bool _finalizeBusy = false;
  DateTime? _lastFinalizeAt;

  /// 首次拉取列表后只自动勾选「未完成」一次；之后保留用户勾选，便于指定重跑哪一期。
  bool _episodeSelectionSeeded = false;

  /// 与 `convert_english` options.force_subtitle_rerun 对应：入队前清空所选期已有英文等字段。
  bool _forceSubtitleRerun = false;

  bool _isEpisodeSubtitleCompleted(Map<String, dynamic> ep) {
    return isBilingualSubtitleCompleted(ep);
  }

  @override
  void didUpdateWidget(covariant ConvertToEnglishPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.podcastId != widget.podcastId) {
      _episodeSelectionSeeded = false;
      _forceSubtitleRerun = false;
    }
  }

  @override
  void dispose() {
    _stopAutoRefresh();
    for (final c in _subtitleControllers.values) {
      c.dispose();
    }
    for (final list in _pairSubtitleControllers.values) {
      for (final c in list) {
        c.dispose();
      }
    }
    super.dispose();
  }

  Future<void> _loadEstimateAndQuota({bool silent = false}) async {
    try {
      final body = {
        'action': 'estimate',
        'podcast_id': widget.podcastId,
        'options': {'scope': 'missing_en_only', 'include_tts': true},
      };
      final res = await Supabase.instance.client.functions.invoke(
        'convert_english',
        body: body,
      );
      final data = (res.data is Map)
          ? Map<String, dynamic>.from(res.data as Map)
          : <String, dynamic>{};
      setState(() {
        final eps = (data['episodes'] is List)
            ? (data['episodes'] as List)
                  .map((e) => Map<String, dynamic>.from(e as Map))
                  .toList()
            : <Map<String, dynamic>>[];
        eps.sort((a, b) {
          final ac = _isEpisodeSubtitleCompleted(a);
          final bc = _isEpisodeSubtitleCompleted(b);
          if (ac != bc) return ac ? -1 : 1;
          final as = (a['episode_slug'] ?? '').toString();
          final bs = (b['episode_slug'] ?? '').toString();
          return as.compareTo(bs);
        });
        _episodes = eps;
        _estimate = (data['estimate'] is Map)
            ? Map<String, dynamic>.from(data['estimate'] as Map)
            : <String, dynamic>{};
        final liveSlugs = eps
            .map((e) => (e['episode_slug'] ?? '').toString().trim())
            .where((s) => s.isNotEmpty)
            .toSet();
        for (final slug in liveSlugs) {
          final transcript =
              eps
                  .firstWhere(
                    (e) => (e['episode_slug'] ?? '') == slug,
                  )['transcript_en']
                  ?.toString() ??
              '';
          final ctrl = _subtitleControllers[slug];
          if (ctrl == null) {
            _subtitleControllers[slug] = TextEditingController(
              text: transcript,
            );
            _disposePairControllersForSlug(slug);
          } else if (!_savingSubtitleSlugs.contains(slug) &&
              ctrl.text != transcript) {
            ctrl.text = transcript;
            _disposePairControllersForSlug(slug);
          }
        }
        final stale = _subtitleControllers.keys
            .where((k) => !liveSlugs.contains(k))
            .toList();
        for (final k in stale) {
          _subtitleControllers.remove(k)?.dispose();
          _disposePairControllersForSlug(k);
        }
        final pendingSlugs = eps
            .where((e) => !_isEpisodeSubtitleCompleted(e))
            .map((e) => (e['episode_slug'] ?? '').toString().trim())
            .where((s) => s.isNotEmpty)
            .toSet();
        _selectedEpisodeSlugs.removeWhere((s) => !liveSlugs.contains(s));
        if (!_episodeSelectionSeeded) {
          _selectedEpisodeSlugs
            ..clear()
            ..addAll(pendingSlugs);
          _episodeSelectionSeeded = true;
        }
        _subtitleExpandedSlugs.removeWhere((s) => !liveSlugs.contains(s));
      });
    } catch (e) {
      if (!mounted) return;
      if (!silent) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('estimate failed: $e')));
      }
    }
  }

  Future<void> _loadTasks({
    bool showLoading = true,
    bool tryFinalize = true,
  }) async {
    if (showLoading) {
      setState(() => _loadingTasks = true);
    }
    try {
      final res = await Supabase.instance.client.functions.invoke(
        'convert_english',
        body: {
          'action': 'tasks',
          'podcast_id': widget.podcastId,
          'page': _taskPage,
          'page_size': _taskPageSize,
        },
      );
      final data = (res.data is Map)
          ? Map<String, dynamic>.from(res.data as Map)
          : <String, dynamic>{};
      final itemsRaw = data['items'];
      setState(() {
        _tasks = itemsRaw is List
            ? itemsRaw.map((e) => Map<String, dynamic>.from(e as Map)).toList()
            : const [];
      });
      _syncAutoRefreshWithTasks();
      if (tryFinalize) {
        await _finalizeTasksIfCollectedComplete();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('tasks failed: $e')));
    } finally {
      if (mounted && showLoading) setState(() => _loadingTasks = false);
    }
  }

  Future<void> _enqueueSubtitleOnly() async {
    if (_selectedEpisodeSlugs.isEmpty) {
      final s = ref.read(appStringsProvider);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(s.convertNoEpisodesSelected)));
      return;
    }
    final s = ref.read(appStringsProvider);
    if (_forceSubtitleRerun && _selectedEpisodeSlugs.isNotEmpty) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(s.convertForceSubtitleRerunDialogTitle),
          content: Text(s.convertForceSubtitleRerunDialogBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(s.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(s.convertForceSubtitleRerunConfirm),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }
    setState(() => _enqueueSubtitle = true);
    final batchAnchor = DateTime.now().subtract(const Duration(seconds: 5));
    try {
      final res = await Supabase.instance.client.functions.invoke(
        'convert_english',
        body: {
          'action': 'enqueue',
          'podcast_id': widget.podcastId,
          'episode_slugs': _selectedEpisodeSlugs.toList(),
          'options': {
            'scope': 'missing_en_only',
            'include_tts': false,
            if (_forceSubtitleRerun) 'force_subtitle_rerun': true,
          },
        },
      );
      final data = (res.data is Map)
          ? Map<String, dynamic>.from(res.data as Map)
          : <String, dynamic>{};
      final enqueued = (data['enqueued'] as num?)?.toInt() ?? 0;
      final skipped = (data['skipped'] as num?)?.toInt() ?? 0;
      final skippedReason = (data['skipped_reason'] ?? '').toString();
      final clearedRaw = data['cleared_en_slugs'];
      final clearedCount = clearedRaw is List ? clearedRaw.length : 0;
      if (mounted) {
        var msg = enqueued == 0
            ? _buildNoEnqueueMessage(skippedReason, data['debug'])
            : 'enqueued=$enqueued, skipped=$skipped';
        if (clearedCount > 0) {
          msg = '${s.convertClearedRerunSnackPrefix(clearedCount)}$msg';
        }
        if (enqueued > 0) {
          _currentBatchAnchorTime = batchAnchor;
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
      await _loadEstimateAndQuota();
      await _loadTasks();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('enqueue failed: $e')));
    } finally {
      if (mounted) setState(() => _enqueueSubtitle = false);
    }
  }

  Future<void> _enqueueTtsOnly() async {
    final s = ref.read(appStringsProvider);
    if (_selectedEpisodeSlugs.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(s.convertNoEpisodesSelected)));
      return;
    }
    final confirmedSlugs = _selectedEpisodeSlugs
        .where(_isEpisodeConfirmed)
        .toList();
    if (confirmedSlugs.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(s.convertNeedConfirmedForAudio)));
      return;
    }
    setState(() => _enqueueAudio = true);
    final batchAnchor = DateTime.now().subtract(const Duration(seconds: 5));
    try {
      final res = await Supabase.instance.client.functions.invoke(
        'convert_english',
        body: {
          'action': 'enqueue_tts',
          'podcast_id': widget.podcastId,
          'episode_slugs': confirmedSlugs,
          'options': {'include_tts': true},
        },
      );
      final data = (res.data is Map)
          ? Map<String, dynamic>.from(res.data as Map)
          : <String, dynamic>{};
      final enqueued = (data['enqueued'] as num?)?.toInt() ?? 0;
      final skipped = (data['skipped'] as num?)?.toInt() ?? 0;
      final skippedReason = (data['skipped_reason'] ?? '').toString();
      if (mounted) {
        final msg = enqueued == 0
            ? _buildNoEnqueueMessage(skippedReason, data['debug'])
            : 'tts enqueued=$enqueued, skipped=$skipped';
        if (enqueued > 0) {
          _currentBatchAnchorTime = batchAnchor;
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
      await _loadTasks();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('enqueue_tts failed: $e')));
    } finally {
      if (mounted) setState(() => _enqueueAudio = false);
    }
  }

  Future<void> _confirmSubtitle(String slug) async {
    final ctrl = _subtitleControllers[slug];
    if (ctrl == null) return;
    if (ctrl.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('字幕为空，不能确认。请先填写字幕文本')));
      }
      return;
    }
    setState(() => _savingSubtitleSlugs.add(slug));
    try {
      await Supabase.instance.client.functions.invoke(
        'convert_english',
        body: {
          'action': 'update_subtitle',
          'podcast_id': widget.podcastId,
          'episode_slug': slug,
          'transcript_en': ctrl.text,
        },
      );
      await _loadEstimateAndQuota();
      await _loadTasks();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('update_subtitle failed: $e')));
    } finally {
      if (mounted) {
        setState(() => _savingSubtitleSlugs.remove(slug));
      }
    }
  }

  Future<void> _copyChineseSubtitle(String transcriptZh) async {
    final text = transcriptZh.trim();
    if (text.isEmpty) return;
    try {
      await Clipboard.setData(ClipboardData(text: text));
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('已复制中文字幕')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('复制失败: $e')));
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadEstimateAndQuota();
      await _loadTasks();
      _syncAutoRefreshWithTasks();
    });
  }

  void _startAutoRefresh() {
    if (_refreshTimer != null) return;
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      if (!mounted || _refreshing) return;
      _refreshing = true;
      try {
        await _loadTasks(showLoading: false, tryFinalize: false);
        await _loadEstimateAndQuota(silent: true);
      } finally {
        _refreshing = false;
      }
    });
  }

  void _stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  void _syncAutoRefreshWithTasks() {
    if (_hasExecutionTasks()) {
      _startAutoRefresh();
    } else {
      _stopAutoRefresh();
    }
  }

  String _buildNoEnqueueMessage(String skippedReason, dynamic debugRaw) {
    if (skippedReason.isEmpty) return '没有可入队节目，请检查筛选条件';
    final debug = debugRaw is Map
        ? Map<String, dynamic>.from(debugRaw)
        : <String, dynamic>{};
    if (skippedReason ==
        'all_candidates_have_active_tasks_or_empty_or_unconfirmed') {
      final selected = (debug['selected_count'] as num?)?.toInt() ?? 0;
      final confirmed =
          (debug['confirmed_selected_count'] as num?)?.toInt() ?? 0;
      final nonEmptyConfirmed =
          (debug['non_empty_confirmed_selected_count'] as num?)?.toInt() ?? 0;
      final activeBlocked =
          (debug['active_blocked_count'] as num?)?.toInt() ?? 0;
      final action = (debug['action'] ?? '').toString();
      if (action == 'enqueue_tts') {
        return '未入队：已选$selected，已确认$confirmed，可用于音频$nonEmptyConfirmed，进行中冲突$activeBlocked';
      }
      return '未入队：已选$selected，进行中冲突$activeBlocked，或不满足当前范围条件';
    }
    return '未入队：$skippedReason';
  }

  bool _isEpisodeConfirmed(String slug) {
    final ep = _episodes.where((e) => (e['episode_slug'] ?? '') == slug);
    if (ep.isEmpty) return false;
    return ep.first['transcript_en_confirmed'] == true;
  }

  void _selectIncompleteOnly() {
    final pending = _episodes
        .where((e) => !_isEpisodeSubtitleCompleted(e))
        .map((e) => (e['episode_slug'] ?? '').toString().trim())
        .where((s) => s.isNotEmpty)
        .toSet();
    setState(() {
      _selectedEpisodeSlugs
        ..clear()
        ..addAll(pending);
    });
  }

  List<String> _splitParagraphs(String text) {
    final normalized = text.replaceAll('\r\n', '\n').trim();
    if (normalized.isEmpty) return const [];
    return normalized
        .split(RegExp(r'\n\s*\n+|\n'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  String _normalizeLine(String text) {
    return text.replaceFirst(RegExp(r'^[•◦○·\-]\s*'), '').trim();
  }

  String _minuteLabel(int idx) {
    final seconds = idx * 60;
    final mm = (seconds ~/ 60).toString().padLeft(2, '0');
    final ss = (seconds % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  void _disposePairControllersForSlug(String slug) {
    final list = _pairSubtitleControllers.remove(slug);
    if (list == null) return;
    for (final c in list) {
      c.dispose();
    }
  }

  List<TextEditingController> _ensurePairControllers(
    String slug, {
    required List<String> zhParas,
    required List<String> enParas,
  }) {
    final targetLen = [
      zhParas.length,
      enParas.length,
      1,
    ].reduce((a, b) => a > b ? a : b);
    final old = _pairSubtitleControllers[slug];
    if (old != null && old.length == targetLen) return old;

    final ctrls = List<TextEditingController>.generate(targetLen, (i) {
      final oldText = (old != null && i < old.length) ? old[i].text : null;
      final text = oldText ?? (i < enParas.length ? enParas[i] : '');
      return TextEditingController(text: text);
    });
    if (old != null) {
      for (final c in old) {
        c.dispose();
      }
    }
    _pairSubtitleControllers[slug] = ctrls;
    return ctrls;
  }

  String _joinPairEnglish(String slug) {
    final ctrls = _pairSubtitleControllers[slug];
    if (ctrls == null || ctrls.isEmpty) return '';
    return ctrls
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .join('\n\n');
  }

  bool _isActiveStatus(String status) {
    const active = {
      'pending',
      'processing',
      'downloading',
      'transcribing',
      'translating',
      'tts_synthesizing',
    };
    return active.contains(status);
  }

  bool _isConvertEnglishTask(Map<String, dynamic> t) {
    final meta = t['metadata'];
    if (meta is! Map) return false;
    return (meta['source'] ?? '').toString() == 'convert_english';
  }

  DateTime? _parseTaskTime(dynamic raw) {
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }

  bool _isTaskInCurrentBatch(Map<String, dynamic> t) {
    final anchor = _currentBatchAnchorTime;
    if (anchor == null) return false;
    final createdAt = _parseTaskTime(t['created_at']);
    final updatedAt = _parseTaskTime(t['updated_at']);
    if (createdAt != null && !createdAt.isBefore(anchor)) return true;
    if (updatedAt != null && !updatedAt.isBefore(anchor)) return true;
    return false;
  }

  List<Map<String, dynamic>> _tasksForModeFiltered(String mode) {
    final modeRows = _tasks.where((t) {
      if (!_isConvertEnglishTask(t)) return false;
      final meta = t['metadata'];
      if (meta is! Map) return false;
      if ((meta['mode'] ?? '').toString() != mode) return false;
      return true;
    }).toList();

    final anchor = _currentBatchAnchorTime;
    if (anchor == null) {
      // 页面重开后锚点丢失，仅显示活跃任务；无活跃任务时不显示执行面板。
      return modeRows
          .where((t) => _isActiveStatus((t['status'] ?? '').toString()))
          .toList();
    }

    final batchRows = modeRows.where(_isTaskInCurrentBatch).toList();
    if (batchRows.isNotEmpty) return batchRows;

    // 若当前批次无命中，仅回退活跃任务，避免历史任务撑住执行面板。
    return modeRows
        .where((t) => _isActiveStatus((t['status'] ?? '').toString()))
        .toList();
  }

  double _stageWeight(String status) {
    switch (status) {
      case 'pending':
        return 0.05;
      case 'downloading':
        return 0.18;
      case 'processing':
        return 0.22;
      case 'transcribing':
        return 0.38;
      case 'translating':
        return 0.55;
      case 'tts_synthesizing':
        return 0.82;
      case 'completed':
        return 1.0;
      case 'failed':
        return 0.0;
      default:
        return 0.08;
    }
  }

  double _progressForMode(String mode) {
    final rows = _tasksForModeFiltered(mode);
    if (rows.isEmpty) return 0;

    final activeRows = rows
        .where((t) => _isActiveStatus((t['status'] ?? '').toString()))
        .toList();
    if (activeRows.isNotEmpty) {
      final sum = activeRows.fold<double>(
        0,
        (a, t) => a + _stageWeight((t['status'] ?? '').toString()),
      );
      return (sum / activeRows.length).clamp(0.0, 1.0);
    }

    var ok = 0;
    for (final t in rows) {
      final st = (t['status'] ?? '').toString();
      if (st == 'completed') ok++;
    }
    return rows.isEmpty ? 0 : ok / rows.length;
  }

  bool _isModeRunning(String mode) {
    return _tasksForModeFiltered(mode).any((t) {
      return _isActiveStatus((t['status'] ?? '').toString());
    });
  }

  bool _hasExecutionTasks() {
    final subtitleActive = _tasksForModeFiltered(
      'subtitle_only',
    ).any((t) => _isActiveStatus((t['status'] ?? '').toString()));
    if (subtitleActive) return true;
    return _tasksForModeFiltered(
      'tts_only',
    ).any((t) => _isActiveStatus((t['status'] ?? '').toString()));
  }

  bool _isCollectedCompleteForConvert() {
    final total = (_estimate['total_episodes'] as num?)?.toInt() ?? 0;
    final withEnclosure = (_estimate['with_enclosure'] as num?)?.toInt() ?? 0;
    return total > 0 && withEnclosure >= total;
  }

  bool _hasResidualConvertTasks() {
    for (final t in _tasks) {
      if (!_isConvertEnglishTask(t)) continue;
      final st = (t['status'] ?? '').toString();
      if (st != 'completed' && st != 'cancelled') return true;
    }
    return false;
  }

  Future<void> _finalizeTasksIfCollectedComplete() async {
    if (_finalizeBusy) return;
    // 仅在当前无活跃执行任务时收口，避免轮询期间误收口。
    if (_hasExecutionTasks()) return;
    if (!_isCollectedCompleteForConvert()) return;
    if (!_hasResidualConvertTasks()) return;
    final now = DateTime.now();
    if (_lastFinalizeAt != null &&
        now.difference(_lastFinalizeAt!) < const Duration(seconds: 8)) {
      return;
    }
    _finalizeBusy = true;
    _lastFinalizeAt = now;
    try {
      final res = await Supabase.instance.client.functions.invoke(
        'convert_english',
        body: {
          'action': 'finalize_if_collected',
          'podcast_id': widget.podcastId,
        },
      );
      final data = (res.data is Map)
          ? Map<String, dynamic>.from(res.data as Map)
          : <String, dynamic>{};
      final finalizedCount = (data['finalized_count'] as num?)?.toInt() ?? 0;
      if (finalizedCount > 0) {
        await _loadTasks(showLoading: false, tryFinalize: false);
      }
    } catch (_) {
      // keep silent; next polling cycle will retry
    } finally {
      _finalizeBusy = false;
    }
  }

  ButtonStyle _blueOutlineButtonStyle() {
    const lineColor = Color(0xFF53C6D8);
    return OutlinedButton.styleFrom(
      foregroundColor: lineColor,
      side: const BorderSide(color: lineColor, width: 1.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final podcastAsync = ref.watch(podcastByIdProvider(widget.podcastId));

    return Scaffold(
      body: podcastAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('${s.loadFailedPrefix}$e')),
        data: (podcast) {
          if (podcast == null) return Center(child: Text(s.podcastMissing));
          // 只要后台仍有翻译/TTS 流水线任务在执行，就显示执行进度；与 RSS 是否已采齐无关。
          final showExecutionPanel = _hasExecutionTasks();
          final completedCount = _episodes
              .where(_isEpisodeSubtitleCompleted)
              .length;
          return Column(
            children: [
              Container(
                width: double.infinity,
                color: Colors.white,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FilledButton(
                          onPressed: () => context.go('/dashboard'),
                          style: FilledButton.styleFrom(
                            backgroundColor: EchoColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            surfaceTintColor: Colors.transparent,
                          ),
                          child: Text(
                            s.creatorDashboard,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '${podcast.name} · ${podcast.slug}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton.icon(
                              style: _blueOutlineButtonStyle(),
                              onPressed: _enqueueSubtitle
                                  ? null
                                  : _enqueueSubtitleOnly,
                              icon: const Icon(Icons.play_arrow),
                              label: Text(
                                _enqueueSubtitle
                                    ? '...'
                                    : s.convertGenerateSubtitleButton,
                              ),
                            ),
                            OutlinedButton.icon(
                              style: _blueOutlineButtonStyle(),
                              onPressed: _enqueueAudio ? null : _enqueueTtsOnly,
                              icon: const Icon(Icons.graphic_eq),
                              label: Text(
                                _enqueueAudio
                                    ? '...'
                                    : s.convertGenerateAudioButton,
                              ),
                            ),
                          ],
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          title: Text(
                            s.convertForceSubtitleRerunTitle,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          subtitle: Text(
                            s.convertForceSubtitleRerunSubtitle,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: EchoColors.textSecondary),
                          ),
                          value: _forceSubtitleRerun,
                          onChanged: _enqueueSubtitle
                              ? null
                              : (v) => setState(() => _forceSubtitleRerun = v),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    Card(
                      color: Theme.of(context).colorScheme.surface,
                      surfaceTintColor: Colors.transparent,
                      elevation: 0,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Text(
                                    s.convertSelectedCount(
                                      _selectedEpisodeSlugs.length,
                                      _episodes.length,
                                    ),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ),
                                TextButton(
                                  onPressed: _episodes.isEmpty
                                      ? null
                                      : _selectIncompleteOnly,
                                  child: Text(s.convertSelectIncompleteOnly),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              s.convertRerunSelectionHint,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: EchoColors.textSecondary),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '已完成中英字幕：$completedCount',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 8),
                            if (_episodes.isEmpty) Text(s.noEpisodesYet),
                            ..._episodes.map((ep) {
                              final slug = (ep['episode_slug'] ?? '')
                                  .toString()
                                  .trim();
                              if (slug.isEmpty) return const SizedBox.shrink();
                              final confirmed =
                                  ep['transcript_en_confirmed'] == true;
                              final completed = _isEpisodeSubtitleCompleted(ep);
                              final transcriptZh =
                                  (ep['transcript_original'] ?? '')
                                      .toString()
                                      .trim();
                              final episode = Episode.fromJson({
                                ...ep,
                                'id': (ep['id'] ?? slug).toString(),
                                'en_tts_signed_url': '',
                                // Convert page only needs episode card shell; hide highlights block.
                                'timestamped_topics': const [],
                              });
                              final ctrl =
                                  _subtitleControllers[slug] ??
                                  TextEditingController();
                              _subtitleControllers.putIfAbsent(
                                slug,
                                () => ctrl,
                              );
                              final zhParas = _splitParagraphs(transcriptZh);
                              final enParas = _splitParagraphs(ctrl.text);
                              final pairCtrls = _ensurePairControllers(
                                slug,
                                zhParas: zhParas,
                                enParas: enParas,
                              );
                              final expanded = _subtitleExpandedSlugs.contains(
                                slug,
                              );
                              final selected = _selectedEpisodeSlugs.contains(
                                slug,
                              );
                              return Padding(
                                key: ValueKey('episode_row_$slug'),
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Checkbox(
                                        value: selected,
                                        onChanged: (v) {
                                          if (v == null) return;
                                          setState(() {
                                            if (v) {
                                              _selectedEpisodeSlugs.add(slug);
                                            } else {
                                              _selectedEpisodeSlugs.remove(
                                                slug,
                                              );
                                            }
                                          });
                                        },
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          EpisodeCard(
                                            key: ValueKey('episode_card_$slug'),
                                            episode: episode,
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            completed
                                                ? (confirmed
                                                      ? '已完成（已确认）'
                                                      : '已完成中英字幕')
                                                : s.convertSubtitleEditorHint,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodySmall,
                                          ),
                                          const SizedBox(height: 2),
                                          Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              splashFactory:
                                                  NoSplash.splashFactory,
                                              onTap: () {
                                                setState(() {
                                                  if (expanded) {
                                                    _subtitleExpandedSlugs
                                                        .remove(slug);
                                                  } else {
                                                    _subtitleExpandedSlugs.add(
                                                      slug,
                                                    );
                                                  }
                                                });
                                              },
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 8,
                                                      horizontal: 2,
                                                    ),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      expanded
                                                          ? Icons.expand_less
                                                          : Icons.expand_more,
                                                      size: 20,
                                                      color: Theme.of(context)
                                                          .textTheme
                                                          .bodySmall
                                                          ?.color,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      completed
                                                          ? '中英文字幕（已完成）'
                                                          : '英文字幕',
                                                      style: Theme.of(
                                                        context,
                                                      ).textTheme.bodyMedium,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          AnimatedSize(
                                            duration: const Duration(
                                              milliseconds: 200,
                                            ),
                                            child: expanded
                                                ? Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Container(
                                                        width: double.infinity,
                                                        padding:
                                                            const EdgeInsets.all(
                                                              12,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          border: Border.all(
                                                            color: Theme.of(
                                                              context,
                                                            ).dividerColor,
                                                          ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                6,
                                                              ),
                                                        ),
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            const SizedBox(
                                                              height: 2,
                                                            ),
                                                            if (transcriptZh
                                                                .isEmpty)
                                                              Text(
                                                                '暂无中文原文（请等待该期字幕任务完成）',
                                                                style: Theme.of(
                                                                  context,
                                                                ).textTheme.bodySmall,
                                                              ),
                                                            ...List.generate(pairCtrls.length, (
                                                              i,
                                                            ) {
                                                              final zh =
                                                                  i <
                                                                      zhParas
                                                                          .length
                                                                  ? _normalizeLine(
                                                                      zhParas[i],
                                                                    )
                                                                  : '';
                                                              return Padding(
                                                                padding: EdgeInsets.only(
                                                                  bottom:
                                                                      i ==
                                                                          pairCtrls.length -
                                                                              1
                                                                      ? 0
                                                                      : 10,
                                                                ),
                                                                child: Column(
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .start,
                                                                  children: [
                                                                    Text(
                                                                      _minuteLabel(
                                                                        i,
                                                                      ),
                                                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                                        color:
                                                                            Theme.of(
                                                                              context,
                                                                            ).textTheme.bodySmall?.color?.withValues(
                                                                              alpha: 0.7,
                                                                            ),
                                                                      ),
                                                                    ),
                                                                    const SizedBox(
                                                                      height: 2,
                                                                    ),
                                                                    if (zh
                                                                        .isNotEmpty)
                                                                      SelectableText(
                                                                        zh,
                                                                        style: Theme.of(
                                                                          context,
                                                                        ).textTheme.bodySmall,
                                                                      ),
                                                                    if (zh
                                                                        .isNotEmpty)
                                                                      const SizedBox(
                                                                        height:
                                                                            4,
                                                                      ),
                                                                    if (completed)
                                                                      SelectableText(
                                                                        pairCtrls[i]
                                                                            .text
                                                                            .trim(),
                                                                        style: Theme.of(
                                                                          context,
                                                                        ).textTheme.bodySmall,
                                                                      )
                                                                    else
                                                                      TextField(
                                                                        controller:
                                                                            pairCtrls[i],
                                                                        minLines:
                                                                            1,
                                                                        maxLines:
                                                                            null,
                                                                        onChanged: (_) {
                                                                          ctrl.text = _joinPairEnglish(
                                                                            slug,
                                                                          );
                                                                        },
                                                                        decoration: InputDecoration(
                                                                          hintText:
                                                                              '英文翻译',
                                                                          border:
                                                                              const OutlineInputBorder(),
                                                                          isDense:
                                                                              true,
                                                                        ),
                                                                      ),
                                                                  ],
                                                                ),
                                                              );
                                                            }),
                                                          ],
                                                        ),
                                                      ),
                                                      const SizedBox(height: 6),
                                                      Align(
                                                        alignment: Alignment
                                                            .centerLeft,
                                                        child: Wrap(
                                                          spacing: 8,
                                                          runSpacing: 8,
                                                          children: [
                                                            OutlinedButton.icon(
                                                              style:
                                                                  _blueOutlineButtonStyle(),
                                                              onPressed:
                                                                  completed
                                                                  ? null
                                                                  : _savingSubtitleSlugs
                                                                        .contains(
                                                                          slug,
                                                                        )
                                                                  ? null
                                                                  : () =>
                                                                        _confirmSubtitle(
                                                                          slug,
                                                                        ),
                                                              icon: const Icon(
                                                                Icons.check,
                                                                size: 16,
                                                              ),
                                                              label: Text(
                                                                _savingSubtitleSlugs
                                                                        .contains(
                                                                          slug,
                                                                        )
                                                                    ? '...'
                                                                    : s.convertConfirmSubtitleButton,
                                                              ),
                                                            ),
                                                            OutlinedButton.icon(
                                                              style:
                                                                  _blueOutlineButtonStyle(),
                                                              onPressed:
                                                                  transcriptZh
                                                                      .trim()
                                                                      .isEmpty
                                                                  ? null
                                                                  : () => _copyChineseSubtitle(
                                                                      transcriptZh,
                                                                    ),
                                                              icon: const Icon(
                                                                Icons
                                                                    .content_copy,
                                                                size: 16,
                                                              ),
                                                              label: const Text(
                                                                '复制中文字幕',
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  )
                                                : const SizedBox.shrink(),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                    if (showExecutionPanel)
                      Card(
                        color: Theme.of(context).colorScheme.surface,
                        surfaceTintColor: Colors.transparent,
                        elevation: 0,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    s.convertExecutionSectionTitle,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleSmall,
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.refresh, size: 18),
                                    onPressed: _loadingTasks
                                        ? null
                                        : _loadTasks,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (_loadingTasks)
                                const SizedBox(
                                  height: 24,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '翻译',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                  ),
                                  Text(
                                    '${(_progressForMode('subtitle_only') * 100).round()}%',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: LinearProgressIndicator(
                                  minHeight: 8,
                                  value: _progressForMode('subtitle_only'),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '转音频',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                  ),
                                  Text(
                                    '${(_progressForMode('tts_only') * 100).round()}%',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: LinearProgressIndicator(
                                  minHeight: 8,
                                  value: _progressForMode('tts_only'),
                                ),
                              ),
                              if (_isModeRunning('subtitle_only') ||
                                  _isModeRunning('tts_only'))
                                const Padding(
                                  padding: EdgeInsets.only(top: 10),
                                  child: LinearProgressIndicator(minHeight: 2),
                                ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
