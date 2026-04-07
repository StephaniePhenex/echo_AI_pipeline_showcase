import 'package:echo/data/episode_model.dart';
import 'package:echo/data/episode_repository.dart';
import 'package:echo/data/search_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Showcase fixtures', () {
    late List<Episode> episodes;

    setUpAll(() async {
      final repo = EpisodeRepository();
      episodes = await repo.fetchAll();
    });

    test('episodeRepository.fetchAll() returns at least 3 episodes', () {
      expect(episodes.length, greaterThanOrEqualTo(3));
    });

    test('search finds Flutter-related content', () {
      final service = SearchService();
      final results = service.search(episodes, 'Flutter');
      expect(results, isNotEmpty);
    });
  });
}
