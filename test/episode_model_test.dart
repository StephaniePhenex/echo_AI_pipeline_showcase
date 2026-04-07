import 'package:echo/data/episode_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Episode.fromJson', () {
    test('正常 JSON 解析', () {
      final json = {
        'id': 'ep001',
        'title': '测试期',
        'cover_image': 'https://example.com/cover.jpg',
        'xiaoyuzhou_url': 'https://xyz.com/ep001',
        'audio_deep_link': 'xiaoyuzhou://episode/xxx',
        'entities': {
          'primary': ['周润发', '杜琪峰'],
          'secondary': ['港片', '动作'],
          'aliases': {'发哥': '周润发'},
        },
        'timestamped_topics': [
          {'topic': '开场', 'time_sec': 0, 'time_label': '00:00'},
          {'topic': '正片', 'time_sec': 120, 'time_label': '02:00'},
        ],
        'summary': '本期聊周润发',
        'searchable': true,
      };

      final ep = Episode.fromJson(json);

      expect(ep.id, 'ep001');
      expect(ep.title, '测试期');
      expect(ep.coverImage, 'https://example.com/cover.jpg');
      expect(ep.xiaoyuzhouUrl, 'https://xyz.com/ep001');
      expect(ep.audioDeepLink, 'xiaoyuzhou://episode/xxx');
      expect(ep.entities.primary, ['周润发', '杜琪峰']);
      expect(ep.entities.secondary, ['港片', '动作']);
      expect(ep.entities.aliases, {'发哥': '周润发'});
      expect(ep.timestampedTopics.length, 2);
      expect(ep.timestampedTopics[0].topic, '开场');
      expect(ep.timestampedTopics[0].timeSec, 0);
      expect(ep.timestampedTopics[0].timeLabel, '00:00');
      expect(ep.summary, '本期聊周润发');
      expect(ep.searchable, true);
    });

    test('缺字段使用默认值', () {
      final json = <String, dynamic>{};

      final ep = Episode.fromJson(json);

      expect(ep.id, '');
      expect(ep.title, '');
      expect(ep.coverImage, '');
      expect(ep.xiaoyuzhouUrl, '');
      expect(ep.audioDeepLink, '');
      expect(ep.entities.primary, isEmpty);
      expect(ep.entities.secondary, isEmpty);
      expect(ep.entities.aliases, isEmpty);
      expect(ep.timestampedTopics, isEmpty);
      expect(ep.summary, '');
      expect(ep.searchable, true);
    });

    test('aliases 格式：Map<String,String>', () {
      final json = {
        'entities': {
          'primary': [],
          'secondary': [],
          'aliases': {'发哥': '周润发', '杜sir': '杜琪峰'},
        },
      };

      final ep = Episode.fromJson(json);

      expect(ep.entities.aliases['发哥'], '周润发');
      expect(ep.entities.aliases['杜sir'], '杜琪峰');
    });

    test('aliases 值为非字符串时 toString', () {
      final json = {
        'entities': {
          'primary': [],
          'secondary': [],
          'aliases': {'k': 123},
        },
      };

      final ep = Episode.fromJson(json);

      expect(ep.entities.aliases['k'], '123');
    });

    test('timestamped_topics 缺 time_sec 默认为 0', () {
      final json = {
        'timestamped_topics': [
          {'topic': '测试', 'time_label': '01:00'},
        ],
      };

      final ep = Episode.fromJson(json);

      expect(ep.timestampedTopics.length, 1);
      expect(ep.timestampedTopics[0].topic, '测试');
      expect(ep.timestampedTopics[0].timeSec, 0);
      expect(ep.timestampedTopics[0].timeLabel, '01:00');
    });

    test('searchable 缺省为 true', () {
      final json = {'id': 'ep1'};
      final ep = Episode.fromJson(json);
      expect(ep.searchable, true);
    });

    test('searchable 显式 false', () {
      final json = {'id': 'ep1', 'searchable': false};
      final ep = Episode.fromJson(json);
      expect(ep.searchable, false);
    });
  });

  group('EpisodeEntities.fromJson', () {
    test('null primary/secondary 返回空列表', () {
      final json = <String, dynamic>{
        'primary': null,
        'secondary': null,
        'aliases': <String, dynamic>{},
      };

      final entities = EpisodeEntities.fromJson(json);

      expect(entities.primary, isEmpty);
      expect(entities.secondary, isEmpty);
    });
  });

  group('TimestampedTopic.fromJson', () {
    test('缺字段默认值', () {
      final json = <String, dynamic>{};
      final t = TimestampedTopic.fromJson(json);
      expect(t.topic, '');
      expect(t.timeSec, 0);
      expect(t.timeLabel, '');
    });
  });
}
