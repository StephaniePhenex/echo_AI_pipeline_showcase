/// 用户界面文案（zh / en）。业务数据与接口返回的原文不经过此层。
abstract class AppStrings {
  String get localeToggleToEnglish;
  String get localeToggleToChinese;

  String get shareLink;
  String get linkCopied;

  String get startupFailed;

  String get creatorEntry;

  String get emailLabel;
  String get emailHint;
  String get passwordLabel;
  String get enterEmail;
  String get enterPassword;
  String get passwordMinLength;
  String get supabaseNotConfigured;
  String get checkEmailVerification;
  String get signIn;
  String get signUp;
  String get haveAccountSignIn;
  String get noAccountSignUp;

  String get searchHint;
  String get noSearchResults;
  String get retry;
  String searchPodcastDescription(String podcastName);
  String get searchErrorTimeout;
  String get searchErrorNetwork;
  String get searchErrorGeneric;

  String get podcastNotFound;
  String get loadFailedRetryShort;
  String get backToHome;

  String get wechatSuggestBrowserTitle;
  String get wechatSuggestBrowserBody;
  String get openInBrowser;
  String get wechatMenuHint;

  String get dashboardBreadcrumbList;
  String get logoutTooltip;
  String get loadFailedPrefix;
  String get noPodcastsYet;
  String get createPodcast;
  String get deletePodcast;
  String deletePodcastConfirm(String name);
  String get cancel;
  String get delete;

  String get podcastName;
  String get rssUrl;
  String get rssUrlHelper;
  String get slugOptional;
  String get slugHint;
  String get slugHelper;
  String get slugInvalid;
  String get createPodcastTitle;
  String get enterName;
  String get slugInUse;
  String get create;

  String get editPodcast;
  String get rssUrlLabel;
  String get lexiconJson;
  String get lexiconHint;
  String get lexiconInvalid;
  String get save;

  String get creatorDashboard;
  String get fetchingFromRss;
  String get fetchFromRss;

  String get loadFailed;
  String get podcastMissing;
  String get resetFailed;
  String get processFailed;
  String get processError;
  String get updateFailed;
  String get listenerLinkCopied;
  String get fillRssInEditFirst;
  String get rssFetchTimeout;

  String episodeStats(int count);
  String get loadEpisodesFailed;
  String get noEpisodesYet;
  String get searchableInSearchTooltip;
  String get excludedFromSearchTooltip;

  String get ingestionTasks;
  String get startProcessing;
  String get refreshTaskStatus;
  String taskProgress(int completed, int total, int failed);

  String statusLabel(String status);
  String get taskRetry;
  String get taskRerunFailed;
  String taskRerunFailedDone(int count);
  String get taskRerunFailedNone;
  String get taskAsrIncompleteNote;
  String get enableEnglishTts;
  String get enableEnglishTtsHint;
  String get convertToEnglish;
  String get convertEnglishPageTitle;
  String get convertQuotaSectionTitle;
  String get convertEstimateSectionTitle;
  String get convertActionSectionTitle;
  String get convertExecutionSectionTitle;
  String get convertScopeMissingOnly;
  String get convertScopeAllEpisodes;
  String get convertIncludeTts;
  String get convertStartButton;
  String get convertMockStarted;
  String convertEstimateText(
    int totalEpisodes,
    int missingEpisodes,
    int totalMinutes,
  );
  String get convertEpisodeSelectionTitle;
  String convertSelectedCount(int selected, int total);
  String get convertSubtitleEditorHint;
  String get convertConfirmSubtitleButton;
  String get convertGenerateSubtitleButton;
  String get convertGenerateAudioButton;
  String get convertNeedConfirmedForAudio;
  String get convertNoEpisodesSelected;
  String get convertSelectIncompleteOnly;
  String get convertRerunSelectionHint;
  String get convertForceSubtitleRerunTitle;
  String get convertForceSubtitleRerunSubtitle;
  String get convertForceSubtitleRerunDialogTitle;
  String get convertForceSubtitleRerunDialogBody;
  String get convertForceSubtitleRerunConfirm;
  String convertClearedRerunSnackPrefix(int count);

  String get episodeHighlights;
  String get timestampJumpHint;
  String get cannotOpenLinkTitle;
  String get timestampCopyBody;
  String get close;
  String get copyLinkButton;
  String get playEnglishAudio;
  String get englishAudioUnavailable;

  /// 听众搜索页：期数文稿预览（来自 ASR / 翻译）
  String get episodeTranscriptSection;
  String get transcriptTabZh;
  String get transcriptTabEn;

  String get notReturnedTaskId;
  String get notLoggedIn;
}

class AppStringsZh extends AppStrings {
  @override
  String get localeToggleToEnglish => 'English';

  @override
  String get localeToggleToChinese => '中文';

  @override
  String get shareLink => '分享链接';

  @override
  String get linkCopied => '链接已复制';

  @override
  String get startupFailed => '启动失败';

  @override
  String get creatorEntry => '创作者入口';

  @override
  String get emailLabel => '邮箱';

  @override
  String get emailHint => 'example@email.com';

  @override
  String get passwordLabel => '密码';

  @override
  String get enterEmail => '请输入邮箱';

  @override
  String get enterPassword => '请输入密码';

  @override
  String get passwordMinLength => '密码至少 6 位';

  @override
  String get supabaseNotConfigured =>
      'Supabase 未配置。请使用 ./scripts/run_local_docker.sh 启动，或传入 SUPABASE_URL 和 SUPABASE_ANON_KEY';

  @override
  String get checkEmailVerification => '请查收邮件验证链接';

  @override
  String get signIn => '登录';

  @override
  String get signUp => '注册';

  @override
  String get haveAccountSignIn => '已有账号？去登录';

  @override
  String get noAccountSignUp => '没有账号？去注册';

  @override
  String get searchHint => '搜索节目、导演、演员...';

  @override
  String get noSearchResults => '暂无搜索结果';

  @override
  String get retry => '重试';

  @override
  String searchPodcastDescription(String podcastName) =>
      '$podcastName - 搜索节目、导演、演员';

  @override
  String get searchErrorTimeout => '请求超时，请重试';

  @override
  String get searchErrorNetwork => '网络连接失败，请检查网络后重试';

  @override
  String get searchErrorGeneric => '数据加载失败，请稍后重试';

  @override
  String get podcastNotFound => '播客不存在';

  @override
  String get loadFailedRetryShort => '加载失败，请稍后重试';

  @override
  String get backToHome => '返回首页';

  @override
  String get wechatSuggestBrowserTitle => '建议使用浏览器打开';

  @override
  String get wechatSuggestBrowserBody =>
      '微信内置浏览器可能存在兼容问题，搜索框可能无法正常使用。\n请点击下方按钮，在 Safari 或 Chrome 中打开以获得最佳体验。';

  @override
  String get openInBrowser => '在浏览器中打开';

  @override
  String get wechatMenuHint => '请点击右上角 ⋯ 选择「在浏览器中打开」';

  @override
  String get dashboardBreadcrumbList => '创作者后台 > 播客列表';

  @override
  String get logoutTooltip => '退出登录';

  @override
  String get loadFailedPrefix => '加载失败：';

  @override
  String get noPodcastsYet => '暂无播客';

  @override
  String get createPodcast => '创建播客';

  @override
  String get deletePodcast => '删除播客';

  @override
  String deletePodcastConfirm(String name) => '确定删除「$name」？此操作不可恢复。';

  @override
  String get cancel => '取消';

  @override
  String get delete => '删除';

  @override
  String get podcastName => '播客名称';

  @override
  String get rssUrl => 'RSS 链接';

  @override
  String get rssUrlHelper => '填写后可一键从 RSS 抓取节目';

  @override
  String get slugOptional => 'Slug（可选）';

  @override
  String get slugHint => 'demo_showcase';

  @override
  String get slugHelper => '留空则根据名称自动生成';

  @override
  String get slugInvalid => '仅允许小写字母、数字、下划线';

  @override
  String get createPodcastTitle => '创建播客';

  @override
  String get enterName => '请输入名称';

  @override
  String get slugInUse => '该 slug 已被使用，请换一个';

  @override
  String get create => '创建';

  @override
  String get editPodcast => '编辑播客';

  @override
  String get rssUrlLabel => 'RSS URL';

  @override
  String get lexiconJson => '词库 (JSON)';

  @override
  String get lexiconHint => '{"aliases":{"发哥":"周润发"},"people":[],"movies":[]}';

  @override
  String get lexiconInvalid => '词库 JSON 格式无效';

  @override
  String get save => '保存';

  @override
  String get creatorDashboard => '创作者后台';

  @override
  String get fetchingFromRss => '抓取中...';

  @override
  String get fetchFromRss => '从 RSS 抓取';

  @override
  String get loadFailed => '加载失败：';

  @override
  String get podcastMissing => '播客不存在';

  @override
  String get resetFailed => '重置失败: ';

  @override
  String get processFailed => '处理失败: ';

  @override
  String get processError => '处理出错: ';

  @override
  String get updateFailed => '更新失败: ';

  @override
  String get listenerLinkCopied => '听众链接已复制到剪贴板';

  @override
  String get fillRssInEditFirst => '请先在编辑中填写 RSS URL';

  @override
  String get rssFetchTimeout => 'RSS 抓取超时，期数较多时请稍后重试';

  @override
  String episodeStats(int count) => '期数统计: $count期';

  @override
  String get loadEpisodesFailed => '加载期数失败：';

  @override
  String get noEpisodesYet => '暂无期数';

  @override
  String get searchableInSearchTooltip => '已加入搜索，点击排除';

  @override
  String get excludedFromSearchTooltip => '已排除，点击加入搜索';

  @override
  String get ingestionTasks => '接入任务';

  @override
  String get startProcessing => '开始处理';

  @override
  String get refreshTaskStatus => '刷新任务状态';

  @override
  String taskProgress(int completed, int total, int failed) {
    if (failed > 0) {
      return '$completed/$total 已完成 · $failed 失败';
    }
    return '$completed/$total 已完成';
  }

  @override
  String statusLabel(String status) {
    switch (status) {
      case 'pending':
        return '待处理';
      case 'processing':
        return '处理中';
      case 'completed':
        return '已完成';
      case 'failed':
        return '失败';
      default:
        return status;
    }
  }

  @override
  String get taskRetry => '重试';

  @override
  String get taskRerunFailed => '重跑失败任务';

  @override
  String taskRerunFailedDone(int count) => '已重跑 $count 条失败任务';

  @override
  String get taskRerunFailedNone => '没有可重跑的失败任务';

  @override
  String get taskAsrIncompleteNote => '部分音频段未转写完整，可重试任务补跑';

  @override
  String get enableEnglishTts => '启用英文 TTS';

  @override
  String get enableEnglishTtsHint => '开启后，该播客任务可生成英文音频';

  @override
  String get convertToEnglish => '转为英文';

  @override
  String get convertEnglishPageTitle => '转为英文';

  @override
  String get convertQuotaSectionTitle => '配额';

  @override
  String get convertEstimateSectionTitle => '预估';

  @override
  String get convertActionSectionTitle => '操作';

  @override
  String get convertExecutionSectionTitle => '执行状况';

  @override
  String get convertScopeMissingOnly => '仅缺英文的期数';

  @override
  String get convertScopeAllEpisodes => '全部期数';

  @override
  String get convertIncludeTts => '包含英文 TTS';

  @override
  String get convertStartButton => '确认并开始';

  @override
  String get convertMockStarted => 'Day15 MVP：已记录选项，真实入队将在 Day16 接入';

  @override
  String convertEstimateText(
    int totalEpisodes,
    int missingEpisodes,
    int totalMinutes,
  ) => '共 $totalEpisodes 期；缺英文 $missingEpisodes 期；估算总时长约 $totalMinutes 分钟';

  @override
  String get convertEpisodeSelectionTitle => '节目选择与字幕确认';

  @override
  String convertSelectedCount(int selected, int total) =>
      '已选 $selected / $total';

  @override
  String get convertSubtitleEditorHint => '可编辑英文字幕，确认后用于生成音频';

  @override
  String get convertConfirmSubtitleButton => '确认字幕';

  @override
  String get convertGenerateSubtitleButton => '开始生成字幕';

  @override
  String get convertGenerateAudioButton => '基于确认字幕生成音频';

  @override
  String get convertNeedConfirmedForAudio => '请先确认至少一条字幕，再生成音频';

  @override
  String get convertNoEpisodesSelected => '请先选择至少一条节目';

  @override
  String get convertSelectIncompleteOnly => '只选未完成';

  @override
  String get convertRerunSelectionHint => '勾选要入队的期；刷新后保留勾选。首次进入默认只选未完成。';

  @override
  String get convertForceSubtitleRerunTitle => '强制重跑字幕';

  @override
  String get convertForceSubtitleRerunSubtitle =>
      '入队前清空所选期的中文稿、英文稿、确认状态、结构化摘要及英文 TTS/时间戳路径，再从 ASR 整期重跑。';

  @override
  String get convertForceSubtitleRerunDialogTitle => '清空中英字幕并重跑？';

  @override
  String get convertForceSubtitleRerunDialogBody =>
      '将对所有已勾选节目清空中文与英文字幕及相关字段，再重新入队生成。此操作不可撤销。';

  @override
  String get convertForceSubtitleRerunConfirm => '清空并入队';

  @override
  String convertClearedRerunSnackPrefix(int count) => '已清空 $count 期中英字幕稿；';

  @override
  String get episodeHighlights => '本集精彩';

  @override
  String get timestampJumpHint => '部分浏览器/App 可能不支持精准定位，若未跳转到指定时间，可手动拖动进度条。';

  @override
  String get cannotOpenLinkTitle => '无法打开链接';

  @override
  String get timestampCopyBody => '部分浏览器/App 可能不支持精准定位。可复制下方链接到浏览器打开：';

  @override
  String get close => '关闭';

  @override
  String get copyLinkButton => '复制链接';

  @override
  String get playEnglishAudio => '播放英文音频';

  @override
  String get englishAudioUnavailable => '该期暂无英文音频';

  @override
  String get episodeTranscriptSection => '文稿';

  @override
  String get transcriptTabZh => '中文';

  @override
  String get transcriptTabEn => 'English';

  @override
  String get notReturnedTaskId => '未返回 task_id';

  @override
  String get notLoggedIn => '未登录';
}

class AppStringsEn extends AppStrings {
  @override
  String get localeToggleToEnglish => 'English';

  @override
  String get localeToggleToChinese => '中文';

  @override
  String get shareLink => 'Share link';

  @override
  String get linkCopied => 'Link copied';

  @override
  String get startupFailed => 'Startup failed';

  @override
  String get creatorEntry => 'Creator sign-in';

  @override
  String get emailLabel => 'Email';

  @override
  String get emailHint => 'example@email.com';

  @override
  String get passwordLabel => 'Password';

  @override
  String get enterEmail => 'Please enter your email';

  @override
  String get enterPassword => 'Please enter your password';

  @override
  String get passwordMinLength => 'Password must be at least 6 characters';

  @override
  String get supabaseNotConfigured =>
      'Supabase is not configured. Run ./scripts/run_local_docker.sh or set SUPABASE_URL and SUPABASE_ANON_KEY.';

  @override
  String get checkEmailVerification =>
      'Check your email for the verification link';

  @override
  String get signIn => 'Sign in';

  @override
  String get signUp => 'Sign up';

  @override
  String get haveAccountSignIn => 'Already have an account? Sign in';

  @override
  String get noAccountSignUp => 'No account? Sign up';

  @override
  String get searchHint => 'Search episodes, people, topics...';

  @override
  String get noSearchResults => 'No results';

  @override
  String get retry => 'Retry';

  @override
  String searchPodcastDescription(String podcastName) =>
      '$podcastName - Search episodes and topics';

  @override
  String get searchErrorTimeout => 'Request timed out. Try again.';

  @override
  String get searchErrorNetwork =>
      'Network error. Check your connection and try again.';

  @override
  String get searchErrorGeneric => 'Could not load data. Try again later.';

  @override
  String get podcastNotFound => 'Podcast not found';

  @override
  String get loadFailedRetryShort => 'Failed to load. Please try again later.';

  @override
  String get backToHome => 'Back to home';

  @override
  String get wechatSuggestBrowserTitle => 'Open in a browser';

  @override
  String get wechatSuggestBrowserBody =>
      'WeChat’s in-app browser may limit features.\nUse the button below to open in Safari or Chrome for the best experience.';

  @override
  String get openInBrowser => 'Open in browser';

  @override
  String get wechatMenuHint =>
      'Tap ⋯ in the top right, then choose “Open in browser”.';

  @override
  String get dashboardBreadcrumbList => 'Creator > Podcasts';

  @override
  String get logoutTooltip => 'Sign out';

  @override
  String get loadFailedPrefix => 'Failed to load: ';

  @override
  String get noPodcastsYet => 'No podcasts yet';

  @override
  String get createPodcast => 'Create podcast';

  @override
  String get deletePodcast => 'Delete podcast';

  @override
  String deletePodcastConfirm(String name) =>
      'Delete “$name”? This cannot be undone.';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get podcastName => 'Podcast name';

  @override
  String get rssUrl => 'RSS URL';

  @override
  String get rssUrlHelper => 'Optional. Used to fetch episodes from RSS.';

  @override
  String get slugOptional => 'Slug (optional)';

  @override
  String get slugHint => 'demo_showcase';

  @override
  String get slugHelper => 'Leave empty to generate from the name';

  @override
  String get slugInvalid =>
      'Use lowercase letters, numbers, and underscores only';

  @override
  String get createPodcastTitle => 'Create podcast';

  @override
  String get enterName => 'Please enter a name';

  @override
  String get slugInUse => 'This slug is already taken. Choose another.';

  @override
  String get create => 'Create';

  @override
  String get editPodcast => 'Edit podcast';

  @override
  String get rssUrlLabel => 'RSS URL';

  @override
  String get lexiconJson => 'Lexicon (JSON)';

  @override
  String get lexiconHint =>
      '{"aliases":{"nickname":"Canonical name"},"people":[],"movies":[]}';

  @override
  String get lexiconInvalid => 'Invalid lexicon JSON';

  @override
  String get save => 'Save';

  @override
  String get creatorDashboard => 'Creator';

  @override
  String get fetchingFromRss => 'Fetching…';

  @override
  String get fetchFromRss => 'Fetch from RSS';

  @override
  String get loadFailed => 'Failed to load: ';

  @override
  String get podcastMissing => 'Podcast not found';

  @override
  String get resetFailed => 'Reset failed: ';

  @override
  String get processFailed => 'Processing failed: ';

  @override
  String get processError => 'Error: ';

  @override
  String get updateFailed => 'Update failed: ';

  @override
  String get listenerLinkCopied => 'Listener link copied to clipboard';

  @override
  String get fillRssInEditFirst => 'Add an RSS URL in edit first';

  @override
  String get rssFetchTimeout =>
      'RSS fetch timed out. If there are many episodes, try again later.';

  @override
  String episodeStats(int count) => 'Episodes: $count';

  @override
  String get loadEpisodesFailed => 'Failed to load episodes: ';

  @override
  String get noEpisodesYet => 'No episodes yet';

  @override
  String get searchableInSearchTooltip => 'Included in search — tap to exclude';

  @override
  String get excludedFromSearchTooltip => 'Excluded — tap to include in search';

  @override
  String get ingestionTasks => 'Ingestion tasks';

  @override
  String get startProcessing => 'Start';

  @override
  String get refreshTaskStatus => 'Refresh status';

  @override
  String taskProgress(int completed, int total, int failed) {
    if (failed > 0) {
      return '$completed/$total done · $failed failed';
    }
    return '$completed/$total done';
  }

  @override
  String statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'processing':
        return 'Processing';
      case 'completed':
        return 'Completed';
      case 'failed':
        return 'Failed';
      default:
        return status;
    }
  }

  @override
  String get taskRetry => 'Retry';

  @override
  String get taskRerunFailed => 'Rerun failed tasks';

  @override
  String taskRerunFailedDone(int count) => 'Rerun $count failed tasks';

  @override
  String get taskRerunFailedNone => 'No failed tasks to rerun';

  @override
  String get taskAsrIncompleteNote =>
      'Some audio chunks were not transcribed; retry the task to fill gaps.';

  @override
  String get enableEnglishTts => 'Enable English TTS';

  @override
  String get enableEnglishTtsHint =>
      'When enabled, this podcast can generate English audio';

  @override
  String get convertToEnglish => 'Convert to English';

  @override
  String get convertEnglishPageTitle => 'Convert to English';

  @override
  String get convertQuotaSectionTitle => 'Quota';

  @override
  String get convertEstimateSectionTitle => 'Estimate';

  @override
  String get convertActionSectionTitle => 'Action';

  @override
  String get convertExecutionSectionTitle => 'Execution';

  @override
  String get convertScopeMissingOnly => 'Missing English only';

  @override
  String get convertScopeAllEpisodes => 'All episodes';

  @override
  String get convertIncludeTts => 'Include English TTS';

  @override
  String get convertStartButton => 'Confirm and Start';

  @override
  String get convertMockStarted =>
      'Day15 MVP: options recorded, real enqueue comes in Day16';

  @override
  String convertEstimateText(
    int totalEpisodes,
    int missingEpisodes,
    int totalMinutes,
  ) =>
      '$totalEpisodes episodes; $missingEpisodes missing English; estimated $totalMinutes minutes total';

  @override
  String get convertEpisodeSelectionTitle =>
      'Episode selection and subtitle confirm';

  @override
  String convertSelectedCount(int selected, int total) =>
      'Selected $selected / $total';

  @override
  String get convertSubtitleEditorHint =>
      'Edit English subtitle and confirm before audio generation';

  @override
  String get convertConfirmSubtitleButton => 'Confirm subtitle';

  @override
  String get convertGenerateSubtitleButton => 'Generate subtitles';

  @override
  String get convertGenerateAudioButton =>
      'Generate audio from confirmed subtitle';

  @override
  String get convertNeedConfirmedForAudio =>
      'Confirm at least one subtitle before generating audio';

  @override
  String get convertNoEpisodesSelected => 'Please select at least one episode';

  @override
  String get convertSelectIncompleteOnly => 'Incomplete only';

  @override
  String get convertRerunSelectionHint =>
      'Check episodes to enqueue; selection persists on refresh. First visit defaults to incomplete only.';

  @override
  String get convertForceSubtitleRerunTitle => 'Force subtitle rerun';

  @override
  String get convertForceSubtitleRerunSubtitle =>
      'Before enqueue: clear Chinese and English transcripts, confirmation, structured fields, and EN TTS/timestamp paths, then full ASR/subtitle rerun.';

  @override
  String get convertForceSubtitleRerunDialogTitle => 'Clear CN/EN and re-run?';

  @override
  String get convertForceSubtitleRerunDialogBody =>
      'All checked episodes will have Chinese and English transcripts and related fields cleared, then re-enqueued. This cannot be undone.';

  @override
  String get convertForceSubtitleRerunConfirm => 'Clear and enqueue';

  @override
  String convertClearedRerunSnackPrefix(int count) =>
      'Cleared CN/EN transcripts on $count episode(s); ';

  @override
  String get episodeHighlights => 'Highlights';

  @override
  String get timestampJumpHint =>
      'Some apps may not jump to the exact time; scrub manually if needed.';

  @override
  String get cannotOpenLinkTitle => 'Could not open link';

  @override
  String get timestampCopyBody =>
      'Some browsers may not support deep links. Copy the URL below and open it in a browser:';

  @override
  String get close => 'Close';

  @override
  String get copyLinkButton => 'Copy link';

  @override
  String get playEnglishAudio => 'Play English audio';

  @override
  String get englishAudioUnavailable => 'English audio is not available yet';

  @override
  String get episodeTranscriptSection => 'Transcript';

  @override
  String get transcriptTabZh => 'Chinese';

  @override
  String get transcriptTabEn => 'English';

  @override
  String get notReturnedTaskId => 'No task_id returned';

  @override
  String get notLoggedIn => 'Not signed in';
}
