import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/echo_colors.dart';
import '../../../data/podcast_model.dart';
import '../../../providers/app_strings_provider.dart';

/// 播客详情页头部：面包屑、标题、slug、操作按钮
class PodcastHeaderSection extends ConsumerWidget {
  const PodcastHeaderSection({
    super.key,
    required this.podcast,
    required this.isFetchingRss,
    required this.onEdit,
    required this.onCopyShareLink,
    required this.onFetchRss,
    required this.onConvertToEnglish,
  });

  final Podcast podcast;
  final bool isFetchingRss;
  final VoidCallback onEdit;
  final VoidCallback onCopyShareLink;
  final VoidCallback onFetchRss;
  final VoidCallback onConvertToEnglish;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
              ),
              child: Text(
                s.creatorDashboard,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
            Text(
              ' / ${podcast.name}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: EchoColors.textSecondary,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _TitleWithEdit(
          title: podcast.name,
          onEdit: onEdit,
        ),
        const SizedBox(height: 4),
        Text(
          podcast.slug,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: EchoColors.textSecondary,
              ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: onConvertToEnglish,
              icon: const Icon(Icons.translate, size: 18),
              label: Text(s.convertToEnglish),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: EchoColors.primary,
                side: const BorderSide(color: EchoColors.primary),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: isFetchingRss ? null : onFetchRss,
              icon: isFetchingRss
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.rss_feed, size: 18),
              label: Text(isFetchingRss ? s.fetchingFromRss : s.fetchFromRss),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: EchoColors.primary,
                side: const BorderSide(color: EchoColors.primary),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: onCopyShareLink,
              icon: const Icon(Icons.link, size: 18),
              label: Text(s.shareLink),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: EchoColors.primary,
                side: const BorderSide(color: EchoColors.primary),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TitleWithEdit extends StatefulWidget {
  const _TitleWithEdit({required this.title, required this.onEdit});

  final String title;
  final VoidCallback onEdit;

  @override
  State<_TitleWithEdit> createState() => _TitleWithEditState();
}

class _TitleWithEditState extends State<_TitleWithEdit> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            widget.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              Icons.edit_outlined,
              size: 20,
              color: _hovering ? EchoColors.primary : EchoColors.textTertiary,
            ),
            onPressed: widget.onEdit,
            style: IconButton.styleFrom(
              padding: const EdgeInsets.all(4),
              minimumSize: const Size(32, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}
