// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:echo/core/theme/echo_theme.dart';
import 'package:echo/data/podcast_model.dart';
import 'package:echo/features/search/search_page.dart';
import 'package:echo/providers/episodes_provider.dart';
import 'package:echo/providers/podcasts_provider.dart';

void main() {
  testWidgets('search page renders', (WidgetTester tester) async {
    const slug = 'demo_showcase';
    final mockPodcast = Podcast(
      id: 'test-id',
      slug: slug,
      name: '测试播客',
      rssUrl: null,
      lexicon: null,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          searchSlugProvider.overrideWith((ref) => slug),
          podcastBySlugProvider(slug).overrideWith(
            (ref) => Future.value(mockPodcast),
          ),
          episodesProvider.overrideWith(
            (ref) => Future.value([]),
          ),
        ],
        child: MaterialApp(
          theme: EchoTheme.light,
          home: const SearchPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('搜索节目、导演、演员...'), findsOneWidget);
  });
}
