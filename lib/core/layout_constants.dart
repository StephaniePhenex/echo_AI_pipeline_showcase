/// 布局相关常量，集中管理魔法数字。
abstract final class LayoutConstants {
  /// 窄屏断点（宽度 < 此值视为移动端）
  static const double narrowBreakpoint = 500;

  /// 搜索栏最大宽度
  static const double searchBarMaxWidth = 560;

  /// 卡片列表最大宽度
  static const double cardsMaxWidth = 640;

  /// 移动端水平 padding
  static const double mobilePadding = 16;

  /// 桌面端水平 padding
  static const double desktopPadding = 24;

  /// 移动端卡片 padding
  static const double mobileCardsPadding = 12;

  /// 桌面端卡片 padding
  static const double desktopCardsPadding = 16;

  /// 移动端有搜索时顶部间距
  static const double mobileTopPaddingWithQuery = 24;

  /// 桌面端有搜索时顶部间距
  static const double desktopTopPaddingWithQuery = 48;

  /// 移动端无搜索时顶部间距
  static const double mobileTopPaddingNoQuery = 60;

  /// Logo 与搜索框间距
  static const double logoToSearchSpacing = 24;

  /// 结果卡片之间的间距
  static const double resultsItemSpacing = 12;

  /// 搜索框与结果列表间距
  static const double searchToResultsSpacing = 32;

  /// 桌面端 logo 与结果区间距
  static const double desktopLogoToResultsSpacing = 40;

  /// 窄屏底部留白（键盘/微信）
  static const double narrowBottomPadding = 100;

  /// Logo 错误占位高度
  static const double logoErrorPlaceholderHeight = 80;

  /// 移动端有搜索时 Logo 高度
  static const double mobileLogoHeightWithQuery = 100;

  /// 移动端无搜索时 Logo 高度
  static const double mobileLogoHeightNoQuery = 140;

  /// 桌面端有搜索时 Logo 高度
  static const double desktopLogoHeightWithQuery = 168;

  /// 桌面端无搜索时 Logo 高度
  static const double desktopLogoHeightNoQuery = 180;

  /// EpisodeCard 固定高度（用于 Sliver 懒加载 itemExtent）
  static const double episodeCardHeight = 100;
}
