import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_strings.dart';
import '../../core/browser_detect.dart';
import '../../core/podcast_public_url.dart';
import '../../providers/app_strings_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/podcasts_provider.dart';
import '../../core/telemetry.dart';
import '../../core/theme/echo_colors.dart';
import '../../data/episode_model.dart';
import '../../providers/episodes_provider.dart';
import '../widgets/locale_toggle_text_button.dart';
import 'widgets/episode_card.dart';
import 'widgets/search_bar.dart' show EchoSearchBar;

/// 搜索页：Google 风格。顶部 logo 区，居中搜索栏，搜索后显示 EpisodeCard 列表。
class SearchPage extends ConsumerWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final query = ref.watch(searchQueryProvider);
    final resultsAsync = ref.watch(searchResultsProvider);
    final slug = ref.watch(searchSlugProvider);

    void applyPodcastSeo() {
      ref.read(podcastBySlugProvider(slug)).when(
            data: (podcast) {
              final s = ref.read(appStringsProvider);
              if (podcast != null) {
                setPageTitle('${podcast.name} - Echo');
                setPageDescription(s.searchPodcastDescription(podcast.name));
              } else {
                setPageTitle('Echo');
                setPageDescription('');
              }
            },
            loading: () {},
            error: (err, st) {
              setPageTitle('Echo');
              setPageDescription('');
            },
          );
    }

    ref.listen<AsyncValue<dynamic>>(podcastBySlugProvider(slug), (prev, next) {
      applyPodcastSeo();
    });
    ref.listen<Locale>(localeProvider, (prev, next) {
      applyPodcastSeo();
    });

    ref.listen<String>(searchQueryProvider, (previous, next) {
      final normalized = next.trim();
      replaceQueryParameters({'q': normalized, 'ep': null});
      ref.read(selectedEpisodeIdProvider.notifier).state = null;
    });
    ref.listen<String?>(selectedEpisodeIdProvider, (previous, next) {
      replaceQueryParameters({'ep': next});
    });
    ref.listen<AsyncValue<List<Episode>>>(searchResultsProvider, (
      previous,
      next,
    ) {
      next.whenOrNull(
        error: (error, stackTrace) {
          logError(
            'search_results_load_fail',
            error,
            stackTrace,
            payload: {'query': ref.read(searchQueryProvider)},
          );
        },
      );
    });

    return Scaffold(
      backgroundColor: EchoColors.background,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          SafeArea(
            child: _Body(query: query, resultsAsync: resultsAsync),
          ),
          Positioned(
            top: 8,
            right: 16,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const LocaleToggleTextButton(),
                TextButton(
                  onPressed: () async {
                    final url = podcastPublicSearchUrl(slug);
                    await Clipboard.setData(ClipboardData(text: url));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(s.linkCopied)),
                      );
                    }
                  },
                  child: Text(
                    s.shareLink,
                    style: const TextStyle(
                      color: EchoColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.query, required this.resultsAsync});

  final String query;
  final AsyncValue<List<Episode>> resultsAsync;

  static const double _searchBarMaxWidth = 560;
  static const double _cardsMaxWidth = 640;

  @override
  Widget build(BuildContext context) {
    final hasQuery = query.trim().isNotEmpty;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isNarrow = screenWidth < 500;
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    final searchBarPadding = isNarrow ? 16.0 : 24.0;
    final cardsPadding = isNarrow ? 12.0 : 16.0;
    final topPadding = isNarrow ? 24.0 : (hasQuery ? 24.0 : 48.0);
    final logoHeight = isNarrow ? (hasQuery ? 100.0 : 140.0) : 180.0;

    final logoAndSearch = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'images/echo_logo.png',
          key: const ValueKey('logo'),
          height: logoHeight,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) =>
              const SizedBox(height: 80),
        ),
        const SizedBox(height: 24),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _searchBarMaxWidth),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: searchBarPadding),
            child: const EchoSearchBar(),
          ),
        ),
      ],
    );

    if (isNarrow) {
      if (hasQuery) {
        return Column(
          children: [
            Padding(
              padding: EdgeInsets.only(
                top: topPadding,
                left: searchBarPadding,
                right: searchBarPadding,
              ),
              child: Center(child: logoAndSearch),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: (screenWidth - _Body._cardsMaxWidth) / 2 > 0
                      ? (screenWidth - _Body._cardsMaxWidth) / 2
                      : searchBarPadding,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: _cardsMaxWidth),
                    child: _ResultsList(resultsAsync: resultsAsync),
                  ),
                ),
              ),
            ),
            SizedBox(height: keyboardOpen ? 16 : 100),
          ],
        );
      }
      return CustomScrollView(
        physics: const ClampingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.only(
              top: 60,
              left: searchBarPadding,
              right: searchBarPadding,
            ),
            sliver: SliverToBoxAdapter(child: Center(child: logoAndSearch)),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      );
    }

    if (hasQuery) {
      return Column(
        children: [
          Padding(
            padding: EdgeInsets.only(
              top: topPadding,
              left: searchBarPadding,
              right: searchBarPadding,
            ),
            child: Center(child: logoAndSearch),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _cardsMaxWidth),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: cardsPadding),
                  child: _ResultsList(resultsAsync: resultsAsync),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        Expanded(
          flex: 10,
          child: Align(
            alignment: const Alignment(0, -0.25),
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(top: topPadding),
                child: logoAndSearch,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ResultsList extends ConsumerWidget {
  const _ResultsList({required this.resultsAsync});

  final AsyncValue<List<Episode>> resultsAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return resultsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => _ResultsError(error: error),
      data: (episodes) {
        if (episodes.isEmpty) {
          final s = ref.watch(appStringsProvider);
          return Center(
            child: Text(
              s.noSearchResults,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: EchoColors.textSecondary),
            ),
          );
        }
        return ListView.separated(
          itemCount: episodes.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) => EpisodeCard(
            episode: episodes[index],
          ),
        );
      },
    );
  }
}

class _ResultsError extends ConsumerWidget {
  const _ResultsError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final message = _messageFor(s, error);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: EchoColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: () {
                logEvent('retry_click', {'reason': error.toString()});
                ref.invalidate(episodesProvider);
              },
              child: Text(s.retry),
            ),
          ],
        ),
      ),
    );
  }

  String _messageFor(AppStrings s, Object error) {
    final text = error.toString().toLowerCase();
    if (text.contains('timeout')) return s.searchErrorTimeout;
    if (text.contains('socket') ||
        text.contains('network') ||
        text.contains('xmlhttprequest')) {
      return s.searchErrorNetwork;
    }
    return s.searchErrorGeneric;
  }
}
