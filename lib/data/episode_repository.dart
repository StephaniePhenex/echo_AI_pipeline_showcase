import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'episode_model.dart';
import 'search_service.dart';

/// 从 assets 或 Supabase API 加载 Episode 列表。
class EpisodeRepository {
  static const String _assetPath = 'assets/data/episodes.json';

  /// 从本地 assets 加载全部期数。
  Future<List<Episode>> fetchAll() async {
    final jsonStr = await rootBundle.loadString(_assetPath);
    final list = jsonDecode(jsonStr) as List<dynamic>;
    return list
        .map((e) => Episode.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 从 Supabase Edge Function 搜索，失败时 fallback 到静态 JSON。
  /// [baseUrl] 如 http://127.0.0.1:54321（本地）或生产 URL。
  /// [anonKey] Supabase anon key，Edge Function 必需。
  /// [slug] 播客 slug，如 demo_showcase（与公开演示数据一致）。
  /// [q] 搜索关键词。
  Future<List<Episode>> fetchFromSupabase({
    required String baseUrl,
    required String anonKey,
    required String slug,
    String q = '',
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/functions/v1/search').replace(
        queryParameters: {'slug': slug, 'q': q.trim()},
      );
      final headers = <String, String>{
        if (anonKey.isNotEmpty) 'apikey': anonKey,
        if (anonKey.isNotEmpty) 'Authorization': 'Bearer $anonKey',
      };
      final res = await http.get(uri, headers: headers).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Request timeout'),
      );
      if (res.statusCode != 200) {
        throw Exception('API ${res.statusCode}');
      }
      final list = jsonDecode(res.body) as List<dynamic>;
      return list
          .map((e) => Episode.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return _fallbackStatic(slug, q);
    }
  }

  /// Fallback：从 assets 加载，按 podcast_id 过滤后搜索。
  Future<List<Episode>> _fallbackStatic(String slug, String q) async {
    final jsonStr = await rootBundle.loadString(_assetPath);
    final list = jsonDecode(jsonStr) as List<dynamic>;
    final filtered = slug.isEmpty
        ? list
        : list.where((e) => (e as Map)['podcast_id'] == slug).toList();
    final episodes = filtered
        .map((e) => Episode.fromJson(e as Map<String, dynamic>))
        .toList();
    return SearchService().search(episodes, q);
  }
}
