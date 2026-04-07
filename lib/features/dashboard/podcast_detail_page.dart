import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/podcast_public_url.dart';
import '../../data/episode_model.dart';
import '../../data/podcast_model.dart';
import '../../providers/episodes_by_podcast_provider.dart';
import '../../providers/app_strings_provider.dart';
import '../../providers/ingestion_tasks_provider.dart';
import '../../providers/podcasts_provider.dart';
import 'widgets/edit_podcast_dialog.dart';
import 'widgets/episode_list_section.dart';
import 'widgets/podcast_header_section.dart';
import 'widgets/task_overlay.dart';

class PodcastDetailPage extends ConsumerStatefulWidget {
  const PodcastDetailPage({super.key, required this.podcastId});

  final String podcastId;

  @override
  ConsumerState<PodcastDetailPage> createState() => _PodcastDetailPageState();
}

class _PodcastDetailPageState extends ConsumerState<PodcastDetailPage> {
  bool _isFetchingRss = false;
  Timer? _pollTimer;

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _retryTask(IngestionTask task) async {
    final s = ref.read(appStringsProvider);
    try {
      await Supabase.instance.client
          .from('ingestion_tasks')
          .update({'status': 'pending', 'error_message': null})
          .eq('id', task.id);
      ref.invalidate(ingestionTasksByPodcastProvider(widget.podcastId));
      ref.invalidate(episodesByPodcastProvider(widget.podcastId));
    } catch (e) {
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${s.resetFailed}$e')),
        );
      }
    }
  }

  Future<void> _rerunFailedTasks() async {
    final s = ref.read(appStringsProvider);
    try {
      final failedRows = await Supabase.instance.client
          .from('ingestion_tasks')
          .select('id')
          .eq('podcast_id', widget.podcastId)
          .eq('status', 'failed');
      final failedCount = (failedRows as List).length;
      if (failedCount == 0) {
        if (mounted && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(s.taskRerunFailedNone)),
          );
        }
        return;
      }

      await Supabase.instance.client
          .from('ingestion_tasks')
          .update({
            'status': 'pending',
            'error_message': null,
            'last_error_stage': null,
            'next_retry_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('podcast_id', widget.podcastId)
          .eq('status', 'failed');

      ref.invalidate(ingestionTasksByPodcastProvider(widget.podcastId));
      ref.invalidate(episodesByPodcastProvider(widget.podcastId));
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.taskRerunFailedDone(failedCount))),
        );
      }
    } catch (e) {
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${s.resetFailed}$e')),
        );
      }
    }
  }

  void _maybeStartPolling(List<IngestionTask> tasks) {
    final hasPending = tasks.any((t) =>
        t.status == 'pending' ||
        t.status == 'processing' ||
        t.status == 'downloading' ||
        t.status == 'transcribing' ||
        t.status == 'translating' ||
        t.status == 'tts_synthesizing');
    if (hasPending && _pollTimer == null) {
      _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
        if (!mounted) return;
        ref.invalidate(ingestionTasksByPodcastProvider(widget.podcastId));
        ref.invalidate(episodesByPodcastProvider(widget.podcastId));
      });
    } else if (!hasPending && _pollTimer != null) {
      _pollTimer!.cancel();
      _pollTimer = null;
    }
  }

  Future<void> _toggleSearchable(Episode episode, bool searchable) async {
    final s = ref.read(appStringsProvider);
    try {
      await Supabase.instance.client
          .from('episodes')
          .update({'searchable': searchable})
          .eq('podcast_id', widget.podcastId)
          .eq('episode_slug', episode.id);
      ref.invalidate(episodesByPodcastProvider(widget.podcastId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${s.updateFailed}$e')),
        );
      }
    }
  }

  Future<void> _copyShareLink(BuildContext context, Podcast podcast) async {
    final s = ref.read(appStringsProvider);
    final link = podcastPublicSearchUrl(podcast.slug);
    await Clipboard.setData(ClipboardData(text: link));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.listenerLinkCopied)),
      );
    }
  }

  Future<void> _fetchRss(BuildContext context, Podcast podcast) async {
    final s = ref.read(appStringsProvider);
    if (podcast.rssUrl == null || podcast.rssUrl!.trim().isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.fillRssInEditFirst)),
        );
      }
      return;
    }
    setState(() => _isFetchingRss = true);
    try {
      final res = await Supabase.instance.client.functions
          .invoke('fetch_rss', body: {'podcast_id': podcast.id})
          .timeout(
            const Duration(seconds: 120),
            onTimeout: () => throw TimeoutException(s.rssFetchTimeout),
          );
      if (!context.mounted) return;
      final data = res.data as Map<String, dynamic>?;
      final created = data?['created'] as int? ?? 0;
      final skipped = data?['skipped'] as int? ?? 0;
      final msg = data?['message'] as String? ??
          (res.status == 200
              ? '已创建 $created 个任务，跳过 $skipped 期已存在'
              : (data?['error'] ?? '抓取失败').toString());
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      if (created > 0) {
        ref.invalidate(ingestionTasksByPodcastProvider(widget.podcastId));
        ref.invalidate(episodesByPodcastProvider(widget.podcastId));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('抓取失败：$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isFetchingRss = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final podcastAsync = ref.watch(podcastByIdProvider(widget.podcastId));
    final episodesAsync = ref.watch(episodesByPodcastProvider(widget.podcastId));
    final tasksAsync = ref.watch(ingestionTasksByPodcastProvider(widget.podcastId));
    final nonConvertTasksAsync = tasksAsync.whenData(
      (tasks) => tasks.where((t) => t.source != 'convert_english').toList(),
    );

    ref.listen<AsyncValue<List<IngestionTask>>>(
      ingestionTasksByPodcastProvider(widget.podcastId),
      (_, next) {
        next.whenData((tasks) {
          if (mounted) _maybeStartPolling(tasks);
        });
      },
    );

    return Scaffold(
      body: podcastAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
            child: Text(
                '${ref.watch(appStringsProvider).loadFailed}$e')),
        data: (podcast) {
          if (podcast == null) {
            return Center(
                child: Text(ref.watch(appStringsProvider).podcastMissing));
          }
          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PodcastHeaderSection(
                  podcast: podcast,
                  isFetchingRss: _isFetchingRss,
                  onEdit: () {
                    showDialog(
                      context: context,
                      builder: (_) => EditPodcastDialog(
                        podcast: podcast,
                        onUpdated: () {
                          ref.invalidate(podcastByIdProvider(widget.podcastId));
                          // 列表页与详情共用名称；返回 dashboard 时需刷新缓存
                          ref.invalidate(creatorPodcastsProvider);
                        },
                      ),
                    );
                  },
                  onCopyShareLink: () => _copyShareLink(context, podcast),
                  onConvertToEnglish: () =>
                      context.push('/dashboard/podcasts/${widget.podcastId}/convert-en'),
                  onFetchRss: () => _fetchRss(context, podcast),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TaskOverlay(
                          tasksAsync: nonConvertTasksAsync,
                          onRetry: _retryTask,
                          onRerunFailed: _rerunFailedTasks,
                          onRefresh: () {
                            ref.invalidate(
                                ingestionTasksByPodcastProvider(
                                    widget.podcastId));
                            ref.invalidate(
                                episodesByPodcastProvider(widget.podcastId));
                          },
                        ),
                        const SizedBox(height: 24),
                        EpisodeListSection(
                          episodesAsync: episodesAsync,
                          onToggleSearchable: _toggleSearchable,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

}
