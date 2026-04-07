/// Supabase 配置，支持本地/生产切换。
///
/// 构建时注入：flutter build web --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
/// 本地默认：127.0.0.1（避免部分环境下 localhost 走 IPv6 导致连不上 CLI）
///
/// [supabaseAnonKey] 默认值为 Supabase CLI `supabase start` 固定的 **本地 demo anon JWT**（公开、仅连本机 API）。
/// 生产构建务必传入 `--dart-define=SUPABASE_ANON_KEY=...`（与生产 URL 成对），否则会与线上项目不匹配。
const String supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'http://127.0.0.1:54321',
);

/// Anon key（本地 CLI 默认 JWT，与 `supabase status` 中 ANON_KEY 一致）。
const String supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue:
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0',
);

/// 默认播客 slug（单播客模式）
const String defaultPodcastSlug = 'demo_showcase';
