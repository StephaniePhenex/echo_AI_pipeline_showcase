import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/echo_colors.dart';
import '../../../data/episode_model.dart';
import '../../../providers/app_strings_provider.dart';
import '../../search/widgets/episode_card.dart';

/// 播客详情页期数列表：统计 + 卡片 + searchable 勾选
class EpisodeListSection extends ConsumerWidget {
  const EpisodeListSection({
    super.key,
    required this.episodesAsync,
    required this.onToggleSearchable,
  });

  final AsyncValue<List<Episode>> episodesAsync;
  final void Function(Episode episode, bool searchable) onToggleSearchable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    return episodesAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Text('${s.loadEpisodesFailed}$e'),
      data: (episodes) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.episodeStats(episodes.length),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),
            if (episodes.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  s.noEpisodesYet,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: EchoColors.textSecondary,
                      ),
                ),
              )
            else
              ...episodes.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: EpisodeCard(
                            episode: e,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 12,
                            top: 40,
                          ),
                          child: Tooltip(
                            message: e.searchable
                                ? s.searchableInSearchTooltip
                                : s.excludedFromSearchTooltip,
                            child: Checkbox(
                              value: e.searchable,
                              onChanged: (v) =>
                                  onToggleSearchable(e, v ?? true),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
          ],
        );
      },
    );
  }
}
