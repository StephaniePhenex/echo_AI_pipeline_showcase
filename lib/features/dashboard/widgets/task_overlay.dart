import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_strings.dart';
import '../../../core/theme/echo_colors.dart';
import '../../../providers/app_strings_provider.dart';
import '../../../providers/ingestion_tasks_provider.dart';

/// 接入任务区域：进度条、任务列表、重试 UI
class TaskOverlay extends ConsumerWidget {
  const TaskOverlay({
    super.key,
    required this.tasksAsync,
    required this.onRetry,
    required this.onRefresh,
    required this.onRerunFailed,
  });

  final AsyncValue<List<IngestionTask>> tasksAsync;
  final void Function(IngestionTask task) onRetry;
  final VoidCallback onRefresh;
  final VoidCallback onRerunFailed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    return tasksAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (tasks) {
        if (tasks.isEmpty) return const SizedBox.shrink();
        // 每期只看“最新一条任务”，避免历史重复任务干扰完成度。
        final latestByEpisode = <String, IngestionTask>{};
        for (final t in tasks) {
          final key = t.episodeSlug.isNotEmpty ? t.episodeSlug : t.id;
          latestByEpisode.putIfAbsent(key, () => t);
        }
        final effectiveTasks = latestByEpisode.values.toList();
        // 终态（成功或失败）都视为该期已结束；混有失败时整体进度也会到 100%，此时应隐藏区块。
        bool isTerminal(String status) =>
            status == 'completed' || status == 'failed';
        final allTerminal = effectiveTasks.every((t) => isTerminal(t.status));
        final gapCompleted = effectiveTasks
            .where((t) => t.status == 'completed' && t.completedWithAsrGaps)
            .toList();
        if (allTerminal) {
          if (gapCompleted.isEmpty) return const SizedBox.shrink();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.ingestionTasks,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              ...gapCompleted.map(
                (t) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 18,
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.title.isNotEmpty ? t.title : t.episodeSlug,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            Text(
                              s.taskAsrIncompleteNote,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: EchoColors.textSecondary,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }

        final completed = effectiveTasks.where((t) => t.status == 'completed').length;
        final failed = effectiveTasks.where((t) => t.status == 'failed').length;
        final total = effectiveTasks.length;
        final progress = total > 0 ? (completed + failed) / total : 0.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  s.ingestionTasks,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(width: 8),
                if (failed > 0)
                  TextButton.icon(
                    onPressed: onRerunFailed,
                    icon: const Icon(Icons.replay, size: 16),
                    label: Text(s.taskRerunFailed),
                  ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18),
                  tooltip: s.refreshTaskStatus,
                  onPressed: onRefresh,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: EchoColors.divider,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      failed > 0
                          ? Theme.of(context).colorScheme.error
                          : EchoColors.statusGreen,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  s.taskProgress(completed, total, failed),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: EchoColors.textSecondary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...effectiveTasks.map((t) => _TaskRow(
                  task: t,
                  strings: s,
                  onRetry:
                      t.status == 'failed' ? () => onRetry(t) : null,
                )),
          ],
        );
      },
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({
    required this.task,
    required this.strings,
    this.onRetry,
  });

  final IngestionTask task;
  final AppStrings strings;
  final VoidCallback? onRetry;

  int _progressPercent(String status) {
    switch (status) {
      case 'pending':
        return 0;
      case 'processing':
      case 'downloading':
        return 25;
      case 'transcribing':
        return 50;
      case 'translating':
        return 75;
      case 'tts_synthesizing':
        return 90;
      case 'completed':
        return 100;
      case 'failed':
        return 100;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPending =
        task.status == 'pending' ||
        task.status == 'processing' ||
        task.status == 'downloading' ||
        task.status == 'transcribing' ||
        task.status == 'translating' ||
        task.status == 'tts_synthesizing';
    final isFailed = task.status == 'failed';
    final color = isFailed
        ? Theme.of(context).colorScheme.error
        : isPending
            ? EchoColors.textSecondary
            : EchoColors.statusGreen;
    final percent = _progressPercent(task.status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.circle, size: 8, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title.isNotEmpty ? task.title : task.episodeSlug,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: color,
                            fontWeight: isPending
                                ? FontWeight.normal
                                : FontWeight.w500,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${strings.statusLabel(task.status)} · $percent%',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: EchoColors.textSecondary,
                              ),
                        ),
                        if (onRetry != null) ...[
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: onRetry,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(strings.taskRetry),
                          ),
                        ],
                      ],
                    ),
                    if (task.errorMessage != null &&
                        task.errorMessage!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        task.errorMessage!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.error,
                              fontSize: 12,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 4,
            child: LinearProgressIndicator(
              value: task.status == 'processing' ? null : percent / 100,
              backgroundColor: EchoColors.divider,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}
