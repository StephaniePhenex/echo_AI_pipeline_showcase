import 'dart:math';

import 'episode_model.dart';

/// 搜索服务：关键词匹配 + 命中强度累加式相关性排序。
/// topic 不参与匹配（避免弱关联），但参与计分以反映讨论深度。
/// 实体关联（示例）：主查询词命中时，若正文含关联词则额外加分。Showcase 使用通用示例词。
class SearchService {
  /// 实体关联：查询词 -> 强关联词列表。命中关联词时加分，提升排序。
  static const Map<String, List<String>> _entityAssociations = {
    'Alpha': ['Beta', 'Gamma'],
  };

  /// 在期数列表中搜索，返回匹配的期数按累加得分降序排列。
  List<Episode> search(List<Episode> episodes, String query) {
    final q = query.trim();
    if (q.isEmpty) return episodes;

    final matched = episodes.where((e) => _matches(e, q)).toList();
    matched.sort((a, b) {
      final sa = _computeScore(a, q);
      final sb = _computeScore(b, q);
      final cmp = sb.compareTo(sa);
      if (cmp != 0) return cmp;
      return a.id.compareTo(b.id);
    });
    return matched;
  }

  /// 判断期数是否匹配关键词。topic 不参与，避免弱关联。
  bool _matches(Episode e, String q) {
    final lower = q.toLowerCase();
    bool contains(String s) => s.toLowerCase().contains(lower);

    if (contains(e.title)) return true;
    if (e.entities.primary.any(contains)) return true;
    if (e.entities.secondary.any(contains)) return true;
    if (e.entities.aliases.keys.any((k) => contains(k))) return true;
    if (e.entities.aliases.values.any(contains)) return true;
    if (contains(e.summary)) return true;
    if (contains(e.transcriptOriginalPreview)) return true;
    if (contains(e.transcriptEnPreview)) return true;
    return false;
  }

  /// 累加式得分（命中强度）：primary 10×强度×位置衰减，title 8，aliases 6，secondary 3，summary 2×次数，topics 2×强度/段。
  /// 对外暴露供测试/调试使用。
  double computeScore(Episode e, String q) => _computeScore(e, q);

  double _computeScore(Episode e, String q) {
    final lower = q.toLowerCase();
    var score = 0.0;

    // primary: 位置衰减 + 多命中累加
    for (var i = 0; i < e.entities.primary.length; i++) {
      final strength = _matchStrength(e.entities.primary[i], lower);
      if (strength > 0) {
        score += 10 * strength * pow(0.9, i);
      }
    }

    // title: 单次命中，按强度
    final titleStrength = _matchStrength(e.title, lower);
    if (titleStrength > 0) score += 8 * titleStrength;

    // aliases: key 与 value 分别计，取较高者
    for (final entry in e.entities.aliases.entries) {
      final kStrength = _matchStrength(entry.key, lower);
      final vStrength = _matchStrength(entry.value, lower);
      if (kStrength > 0 || vStrength > 0) {
        score += 6 * max(kStrength, vStrength);
      }
    }

    // secondary: 多命中累加
    for (final s in e.entities.secondary) {
      final strength = _matchStrength(s, lower);
      if (strength > 0) score += 3 * strength;
    }

    // summary: 出现次数 × 0.5
    final count = _countOccurrences(e.summary.toLowerCase(), lower);
    score += 2 * 0.5 * count;

    score += 0.5 * _matchStrength(e.transcriptOriginalPreview, lower);
    score += 0.5 * _matchStrength(e.transcriptEnPreview, lower);

    // timestamped_topics: 每段 topic 命中则加分，反映讨论深度
    for (final t in e.timestampedTopics) {
      final strength = _matchStrength(t.topic, lower);
      if (strength > 0) score += 2 * strength;
    }

    // 实体关联加分
    score += _entityAssociationBonus(e, q);

    return score;
  }

  /// 匹配强度：完全 1.0，开头 0.8，包含 0.5。
  double _matchStrength(String field, String query) {
    final f = field.toLowerCase();
    if (f == query) return 1.0;
    if (f.startsWith(query)) return 0.8;
    if (f.contains(query)) return 0.5;
    return 0;
  }

  /// 统计 query 在 text 中的出现次数（不重叠）。
  int _countOccurrences(String text, String query) {
    if (query.isEmpty) return 0;
    var count = 0;
    var i = 0;
    while (true) {
      final idx = text.indexOf(query, i);
      if (idx < 0) break;
      count++;
      i = idx + query.length;
    }
    return count;
  }

  double _entityAssociationBonus(Episode e, String q) {
    final assoc = _entityAssociations[q.trim()];
    if (assoc == null) return 0;

    var bonus = 0.0;
    for (final term in assoc) {
      final tLower = term.toLowerCase();
      for (var i = 0; i < e.entities.primary.length; i++) {
        final strength = _matchStrength(e.entities.primary[i], tLower);
        if (strength > 0) bonus += 2 * strength * pow(0.9, i);
      }
      for (final s in e.entities.secondary) {
        final strength = _matchStrength(s, tLower);
        if (strength > 0) bonus += 1 * strength;
      }
      final titleStrength = _matchStrength(e.title, tLower);
      if (titleStrength > 0) bonus += 2 * titleStrength;
    }
    return bonus;
  }
}
