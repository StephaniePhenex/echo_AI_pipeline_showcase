import 'package:echo/features/dashboard/convert_to_english_visibility.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isBilingualSubtitleCompleted', () {
    test('仅中文时返回 false', () {
      final episode = <String, dynamic>{
        'transcript_original': '这是中文原文',
        'transcript_en': '',
      };

      expect(isBilingualSubtitleCompleted(episode), isFalse);
    });

    test('仅英文时返回 false', () {
      final episode = <String, dynamic>{
        'transcript_original': '',
        'transcript_en': 'This is English subtitle.',
      };

      expect(isBilingualSubtitleCompleted(episode), isFalse);
    });

    test('中英都非空时返回 true', () {
      final episode = <String, dynamic>{
        'transcript_original': '这是中文原文',
        'transcript_en': 'This is English subtitle.',
      };

      expect(isBilingualSubtitleCompleted(episode), isTrue);
    });
  });
}
