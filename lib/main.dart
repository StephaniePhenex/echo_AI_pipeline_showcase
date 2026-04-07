import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/browser_detect.dart';
import 'core/supabase_config.dart';
import 'providers/app_strings_provider.dart';
import 'providers/episodes_provider.dart';
import 'providers/locale_provider.dart';
import 'core/theme/echo_theme.dart';
import 'features/auth/auth_page.dart';
import 'features/dashboard/dashboard_page.dart';
import 'features/dashboard/convert_to_english_page.dart';
import 'features/dashboard/podcast_detail_page.dart';
import 'features/search/home_page.dart';
import 'features/search/podcast_search_wrapper.dart';
import 'features/search/wechat_prompt_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exception}');
  };
  try {
    if (supabaseAnonKey.isNotEmpty) {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
        // Web：避免地址栏带 code / access_token 片段时误走 getSessionFromUrl，导致邮箱密码登录异常
        authOptions: FlutterAuthClientOptions(
          detectSessionInUri: !kIsWeb,
        ),
      );
    }
    runApp(
      const ProviderScope(
        child: EchoApp(),
      ),
    );
  } catch (e, st) {
    debugPrint('Init error: $e\n$st');
    runApp(
      ProviderScope(
        child: Consumer(
          builder: (context, ref, _) {
            final s = ref.watch(appStringsProvider);
            return MaterialApp(
              locale: ref.watch(localeProvider),
              supportedLocales: const [
                Locale('zh'),
                Locale('en'),
              ],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: Scaffold(
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(s.startupFailed,
                            style: const TextStyle(fontSize: 18)),
                        const SizedBox(height: 16),
                        Text('$e', style: const TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

final _router = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    if (supabaseAnonKey.isEmpty) return null;
    final loc = state.matchedLocation;
    if (loc.startsWith('/p/')) return null;
    final isAuth = loc == '/auth';
    final isDashboard = loc.startsWith('/dashboard');
    final user = Supabase.instance.client.auth.currentUser;
    if (isDashboard && user == null) return '/auth';
    if (isAuth && user != null) return '/dashboard';
    return null;
  },
  routes: [
    GoRoute(
      path: '/p/:slug',
      builder: (context, state) {
        final slug = state.pathParameters['slug']!;
        // 每个公开播客页独立一套搜索状态，避免从 A 频道切到 B 仍带着 A 的搜索词（内存）
        final q = state.uri.queryParameters['q'] ?? '';
        final epRaw = state.uri.queryParameters['ep'];
        final ep = (epRaw == null || epRaw.isEmpty) ? null : epRaw;

        return ProviderScope(
          overrides: [
            searchSlugProvider.overrideWith((ref) => slug),
            searchQueryProvider.overrideWith((ref) => q),
            selectedEpisodeIdProvider.overrideWith((ref) => ep),
          ],
          child: PodcastSearchWrapper(slug: slug),
        );
      },
    ),
    GoRoute(
      path: '/',
      builder: (context, _) =>
          isWeChatBrowser() ? const WeChatPromptPage() : const HomePage(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, _) =>
          isWeChatBrowser() ? const WeChatPromptPage() : const HomePage(),
    ),
    GoRoute(
      path: '/auth',
      builder: (context, _) => const AuthPage(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, _) => const DashboardPage(),
      routes: [
        GoRoute(
          path: 'podcasts/:id',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return PodcastDetailPage(podcastId: id);
          },
          routes: [
            GoRoute(
              path: 'convert-en',
              builder: (context, state) {
                final id = state.pathParameters['id']!;
                return ConvertToEnglishPage(podcastId: id);
              },
            ),
          ],
        ),
      ],
    ),
  ],
);

class EchoApp extends ConsumerWidget {
  const EchoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    return MaterialApp.router(
      title: 'Echo',
      theme: EchoTheme.light,
      locale: locale,
      supportedLocales: const [
        Locale('zh'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeResolutionCallback: (loc, supported) {
        if (loc == null) return const Locale('zh');
        for (final s in supported) {
          if (s.languageCode == loc.languageCode) return s;
        }
        return const Locale('zh');
      },
      routerConfig: _router,
    );
  }
}
