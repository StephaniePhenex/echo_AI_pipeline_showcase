import 'package:echo/data/episode_model.dart';
import 'package:echo/data/search_service.dart';
import 'package:flutter_test/flutter_test.dart';

Episode _episode({
  String id = 'ep001',
  String title = '测试期',
  String summary = '',
  List<String> primary = const [],
  List<String> secondary = const [],
  Map<String, String> aliases = const {},
  List<TimestampedTopic> topics = const [],
}) {
  return Episode(
    id: id,
    title: title,
    coverImage: '',
    xiaoyuzhouUrl: '',
    audioDeepLink: '',
    entities: EpisodeEntities(
      primary: primary,
      secondary: secondary,
      aliases: aliases,
    ),
    timestampedTopics: topics,
    summary: summary,
  );
}

void main() {
  late SearchService service;

  setUp(() {
    service = SearchService();
  });

  group('SearchService', () {
    test('空列表返回空', () {
      final results = service.search([], '关键词');
      expect(results, isEmpty);
    });

    test('空查询返回全部期数', () {
      final episodes = [
        _episode(id: 'ep1', title: 'A'),
        _episode(id: 'ep2', title: 'B'),
      ];
      final results = service.search(episodes, '');
      expect(results.length, 2);
    });

    test('单期命中 title', () {
      final episodes = [
        _episode(id: 'ep1', title: '周润发电影'),
      ];
      final results = service.search(episodes, '周润发');
      expect(results.length, 1);
      expect(results.first.id, 'ep1');
    });

    test('单期命中 primary', () {
      final episodes = [
        _episode(id: 'ep1', primary: ['周润发', '杜琪峰']),
      ];
      final results = service.search(episodes, '发哥');
      expect(results, isEmpty);
      final results2 = service.search(episodes, '周润发');
      expect(results2.length, 1);
    });

    test('单期命中 aliases key', () {
      final episodes = [
        _episode(id: 'ep1', aliases: {'发哥': '周润发'}),
      ];
      final results = service.search(episodes, '发哥');
      expect(results.length, 1);
    });

    test('单期命中 aliases value', () {
      final episodes = [
        _episode(id: 'ep1', aliases: {'发哥': '周润发'}),
      ];
      final results = service.search(episodes, '周润发');
      expect(results.length, 1);
    });

    test('单期命中 summary', () {
      final episodes = [
        _episode(id: 'ep1', summary: '本期聊周润发'),
      ];
      final results = service.search(episodes, '周润发');
      expect(results.length, 1);
    });

    test('多期按得分降序', () {
      final episodes = [
        _episode(id: 'ep1', title: '其他', summary: '提到周润发'),
        _episode(id: 'ep2', primary: ['周润发'], title: '周润发专题'),
        _episode(id: 'ep3', secondary: ['周润发']),
      ];
      final results = service.search(episodes, '周润发');
      expect(results.length, 3);
      for (var i = 0; i < results.length - 1; i++) {
        final s1 = service.computeScore(results[i], '周润发');
        final s2 = service.computeScore(results[i + 1], '周润发');
        expect(s1, greaterThanOrEqualTo(s2));
      }
    });

    test('computeScore 不命中返回 0', () {
      final ep = _episode(title: '无关标题', primary: ['其他']);
      expect(service.computeScore(ep, '周润发'), 0);
    });

    test('computeScore 完全匹配 > 包含匹配', () {
      final epExact = _episode(primary: ['周润发']);
      final epContains = _episode(primary: ['影帝周润发']);
      expect(
        service.computeScore(epExact, '周润发'),
        greaterThan(service.computeScore(epContains, '周润发')),
      );
    });

    test('computeScore primary 高于 secondary', () {
      final epPrimary = _episode(primary: ['周润发']);
      final epSecondary = _episode(secondary: ['周润发']);
      expect(
        service.computeScore(epPrimary, '周润发'),
        greaterThan(service.computeScore(epSecondary, '周润发')),
      );
    });

    test('大小写不敏感', () {
      final episodes = [
        _episode(id: 'ep1', title: 'ZHOURUNFA'),
      ];
      final results = service.search(episodes, 'zhourunfa');
      expect(results.length, 1);
    });
  });
}
