import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/podcast_listen_launch.dart';
import '../../../core/podcast_listen_url_allowlist.dart';
import '../../../core/telemetry.dart';
import '../../../core/theme/echo_colors.dart';
import '../../../core/app_strings.dart';
import '../../../data/episode_model.dart';
import '../../../providers/app_strings_provider.dart';
import '../../../providers/episodes_provider.dart';

// --- 票根绘制参数 ---
const double _leftSectionWidth = 100.0;
const double _cornerRadius = 7.0; // 左上/左下 1/4 半圆缺口
const double _notchRadius = 11.0; // 虚线处半圆切口
const double _sawToothRadius = 4.5; // 锯齿半圆半径

/// 票根式卡片：左侧封面 + 虚线撕口 + 右侧正文。
/// 左上/左下角 1/4 半圆缺口，虚线处两个小半圆切口，左侧弧线锯齿。
/// 默认透明，hover 时显示背景色。点击打开小宇宙链接。
class EpisodeCard extends ConsumerStatefulWidget {
  const EpisodeCard({
    super.key,
    required this.episode,
  });

  final Episode episode;

  @override
  ConsumerState<EpisodeCard> createState() => _EpisodeCardState();
}

class _EpisodeCardState extends ConsumerState<EpisodeCard> {
  bool _isHovered = false;
  bool _topicsExpanded = false;
  bool _transcriptExpanded = false;

  List<String> _splitParagraphs(String text) {
    final normalized = text.replaceAll('\r\n', '\n').trim();
    if (normalized.isEmpty) return const [];
    final chunks = normalized
        .split(RegExp(r'\n\s*\n+|\n'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    return chunks.isNotEmpty ? chunks : <String>[normalized];
  }

  String _minuteLabel(int idx) {
    final seconds = idx * 60;
    final mm = (seconds ~/ 60).toString().padLeft(2, '0');
    final ss = (seconds % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final tags = [
      ...widget.episode.entities.primary.take(5),
      ...widget.episode.entities.secondary.take(3),
    ];
    final displayTitle = widget.episode.title;

    final hasTopics = widget.episode.timestampedTopics.isNotEmpty;
    final hasTranscript = widget.episode.transcriptOriginalPreview.isNotEmpty ||
        widget.episode.transcriptEnPreview.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              boxShadow: _isHovered
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                splashFactory: NoSplash.splashFactory,
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                hoverColor: Colors.transparent,
                focusColor: Colors.transparent,
                onTap: () async {
                  ref.read(selectedEpisodeIdProvider.notifier).state =
                      widget.episode.id;
                  logEvent('search_result_click', {
                    'episodeId': widget.episode.id,
                    'url': widget.episode.xiaoyuzhouUrl,
                  });
                  await _openXiaoyuzhou(widget.episode.xiaoyuzhouUrl);
                },
                borderRadius: BorderRadius.circular(4),
                child: ClipPath(
                  clipper: _TicketShapeClipper(),
                  child: SizedBox(
                    height: 100,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: TicketBackgroundPainter(
                                isHovered: _isHovered),
                          ),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(
                              width: _leftSectionWidth,
                              child: Center(
                                child: _StubCover(
                                  coverImage: widget.episode.coverImage,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    16, 12, 20, 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      displayTitle,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            color: EchoColors.textPrimary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (tags.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        tags.join(' '),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: EchoColors.textSecondary,
                                              height: 1.4,
                                            ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                    if (widget.episode.enTtsSignedUrl.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: OutlinedButton.icon(
                                          onPressed: () async {
                                            await _openEnglishTts(context, s, widget.episode.enTtsSignedUrl);
                                          },
                                          icon: const Icon(Icons.volume_up_outlined, size: 16),
                                          label: Text(s.playEnglishAudio),
                                          style: OutlinedButton.styleFrom(
                                            minimumSize: const Size(44, 32),
                                            visualDensity: VisualDensity.compact,
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (hasTranscript) _buildTranscriptSection(context, s),
        if (hasTopics) _buildTimestampedSection(context, s),
      ],
    );
  }

  Widget _buildTranscriptSection(BuildContext context, AppStrings s) {
    final zh = widget.episode.transcriptOriginalPreview.trim();
    final en = widget.episode.transcriptEnPreview.trim();
    final zhParas = _splitParagraphs(zh);
    final enParas = _splitParagraphs(en);
    final hasPairMode = zhParas.isNotEmpty && enParas.isNotEmpty;
    final pairLen = hasPairMode
        ? (zhParas.length > enParas.length ? zhParas.length : enParas.length)
        : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            splashFactory: NoSplash.splashFactory,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
            focusColor: Colors.transparent,
            onTap: () =>
                setState(() => _transcriptExpanded = !_transcriptExpanded),
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Row(
                children: [
                  Icon(
                    _transcriptExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: EchoColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    s.episodeTranscriptSection,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: EchoColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: _transcriptExpanded
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 260),
                      child: SingleChildScrollView(
                        child: hasPairMode
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: List.generate(pairLen, (i) {
                                  final zhLine = i < zhParas.length ? zhParas[i] : '';
                                  final enLine = i < enParas.length ? enParas[i] : '';
                                  return Padding(
                                    padding: EdgeInsets.only(
                                      bottom: i == pairLen - 1 ? 0 : 12,
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _minuteLabel(i),
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: EchoColors.textTertiary,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        if (zhLine.isNotEmpty)
                                          SelectableText(
                                            zhLine,
                                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                  color: EchoColors.textPrimary,
                                                  height: 1.45,
                                                ),
                                          ),
                                        if (zhLine.isNotEmpty && enLine.isNotEmpty)
                                          const SizedBox(height: 4),
                                        if (enLine.isNotEmpty)
                                          SelectableText(
                                            enLine,
                                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                  color: EchoColors.textPrimary,
                                                  height: 1.45,
                                                ),
                                          ),
                                      ],
                                    ),
                                  );
                                }),
                              )
                            : SelectableText(
                                (zh.isNotEmpty ? zh : en).isNotEmpty ? (zh.isNotEmpty ? zh : en) : '—',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: EchoColors.textPrimary,
                                      height: 1.45,
                                    ),
                              ),
                      ),
                    ),
                  ],
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildTimestampedSection(BuildContext context, AppStrings s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            splashFactory: NoSplash.splashFactory,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
            focusColor: Colors.transparent,
            onTap: () =>
                setState(() => _topicsExpanded = !_topicsExpanded),
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              child: Row(
                children: [
                  Icon(
                    _topicsExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: EchoColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    s.episodeHighlights,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: EchoColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: _topicsExpanded
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 8),
                      child: Text(
                        s.timestampJumpHint,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: EchoColors.textTertiary,
                              height: 1.4,
                            ),
                      ),
                    ),
                    ...widget.episode.timestampedTopics.map((t) =>
                        _TopicItem(
                          timeLabel: t.timeLabel,
                          topic: t.topic,
                          onTap: () => _openXiaoyuzhouWithTime(
                            context,
                            s,
                            widget.episode.xiaoyuzhouUrl,
                            t.timeSec,
                          ),
                        )),
                  ],
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Future<void> _openXiaoyuzhou(String url) async {
    final parsed = Uri.tryParse(url.trim());
    if (parsed == null) {
      logEvent('open_url_fail', {
        'reason': 'invalid_or_blocked_url',
        'url': url,
      });
      return;
    }
    final uri = normalizePodcastListenUri(parsed);
    if (!isAllowedPodcastListenUrl(uri)) {
      logEvent('open_url_fail', {
        'reason': 'invalid_or_blocked_url',
        'url': url,
      });
      return;
    }

    final opened = await launchPodcastListenUrl(uri);
    if (!opened) {
      logEvent('open_url_fail', {
        'reason': 'launch_return_false',
        'url': url,
      });
    }
  }

  Future<void> _openXiaoyuzhouWithTime(
    BuildContext context,
    AppStrings s,
    String baseUrl,
    int timeSec,
  ) async {
    final parsed = Uri.tryParse(baseUrl.trim());
    if (parsed == null) return;
    final uri = normalizePodcastListenUri(parsed);
    if (!isAllowedPodcastListenUrl(uri)) return;

    final urlWithTime = uri.replace(
      queryParameters: {
        ...uri.queryParameters,
        't': timeSec.toString(),
      },
    );
    final urlStr = urlWithTime.toString();

    final opened = await launchPodcastListenUrl(urlWithTime);
    if (!opened && context.mounted) {
      _showCopyLinkFallback(context, s, urlStr);
    }
  }

  Future<void> _openEnglishTts(
    BuildContext context,
    AppStrings s,
    String signedUrl,
  ) async {
    final u = signedUrl.trim();
    if (u.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.englishAudioUnavailable)));
      }
      return;
    }
    final uri = Uri.tryParse(u);
    if (uri == null) return;
    final opened = await launchPodcastListenUrl(uri);
    if (!opened && context.mounted) {
      _showCopyLinkFallback(context, s, u);
    }
  }

  void _showCopyLinkFallback(
      BuildContext context, AppStrings s, String url) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.cannotOpenLinkTitle),
        content: Text(s.timestampCopyBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(s.close),
          ),
          FilledButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: url));
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text(s.linkCopied)),
                );
                Navigator.of(ctx).pop();
              }
            },
            child: Text(s.copyLinkButton),
          ),
        ],
      ),
    );
  }
}

/// Day 13：片段项，hover/按下有反馈，移动端触摸区域 ≥ 44pt
class _TopicItem extends StatefulWidget {
  const _TopicItem({
    required this.timeLabel,
    required this.topic,
    required this.onTap,
  });

  final String timeLabel;
  final String topic;
  final VoidCallback onTap;

  @override
  State<_TopicItem> createState() => _TopicItemState();
}

class _TopicItemState extends State<_TopicItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Material(
        color: _isHovered ? EchoColors.cardHover : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          splashFactory: NoSplash.splashFactory,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
          focusColor: Colors.transparent,
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(4),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.timeLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: EchoColors.textSecondary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.topic,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: EchoColors.textPrimary,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 票根形状裁剪器（与 TicketBackgroundPainter 共享同一 Path 逻辑）
class _TicketShapeClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return _buildTicketPath(size);
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

Path _buildTicketPath(Size size) {
  const cr = _cornerRadius;
  const nr = _notchRadius;
  const sr = _sawToothRadius;
  const lsw = _leftSectionWidth;

  final path = Path();

  // 1. 起点 (cornerRadius, 0)
  path.moveTo(cr, 0);

  // 2. 左上角 1/4 半圆缺口：从 (cr, 0) 到 (0, cr)
  path.arcToPoint(
    const Offset(0, cr),
    radius: const Radius.circular(cr),
    clockwise: true,
  );

  // 3. 左侧弧线锯齿：从 (0, cr) 到 (0, size.height - cr)
  final teethCount = ((size.height - 2 * cr) / (2 * sr)).floor();
  for (int i = 0; i < teethCount; i++) {
    path.relativeArcToPoint(
      const Offset(0, sr * 2),
      radius: const Radius.circular(sr),
      clockwise: true,
    );
  }
  path.lineTo(0, size.height - cr);

  // 4. 左下角 1/4 半圆缺口：从 (0, h-cr) 到 (cr, h)
  path.arcToPoint(
    Offset(cr, size.height),
    radius: const Radius.circular(cr),
    clockwise: true,
  );

  // 5. 底边到下半圆切口前
  path.lineTo(lsw - nr, size.height);

  // 6. 下半圆切口
  path.arcToPoint(
    Offset(lsw + nr, size.height),
    radius: const Radius.circular(nr),
    clockwise: false,
  );

  // 7. 右边、顶边
  path.lineTo(size.width, size.height);
  path.lineTo(size.width, 0);
  path.lineTo(lsw + nr, 0);

  // 8. 上半圆切口（与下半圆一致，向内凹的半圆）
  path.arcToPoint(
    Offset(lsw - nr, 0),
    radius: const Radius.circular(nr),
    clockwise: true,
  );

  path.close();
  return path;
}

/// 票根背景绘制：左区 + 右区（同色）+ 虚线
class TicketBackgroundPainter extends CustomPainter {
  TicketBackgroundPainter({required this.isHovered});

  final bool isHovered;

  @override
  void paint(Canvas canvas, Size size) {
    const lsw = _leftSectionWidth;
    const nr = _notchRadius;

    // 左区 Path（紫色存根）
    final leftPath = Path();
    leftPath.moveTo(_cornerRadius, 0);
    leftPath.arcToPoint(
      const Offset(0, _cornerRadius),
      radius: const Radius.circular(_cornerRadius),
      clockwise: true,
    );
    final teethCount =
        ((size.height - 2 * _cornerRadius) / (2 * _sawToothRadius)).floor();
    for (int i = 0; i < teethCount; i++) {
      leftPath.relativeArcToPoint(
        const Offset(0, _sawToothRadius * 2),
        radius: const Radius.circular(_sawToothRadius),
        clockwise: true,
      );
    }
    leftPath.lineTo(0, size.height - _cornerRadius);
    leftPath.arcToPoint(
      Offset(_cornerRadius, size.height),
      radius: const Radius.circular(_cornerRadius),
      clockwise: true,
    );
    leftPath.lineTo(lsw - nr, size.height);
    leftPath.arcToPoint(
      Offset(lsw, size.height - nr),
      radius: const Radius.circular(nr),
      clockwise: false,
    );
    leftPath.lineTo(lsw, nr);
    leftPath.arcToPoint(
      Offset(lsw - nr, 0),
      radius: const Radius.circular(nr),
      clockwise: true,
    );
    leftPath.close();

    // 左区与右区同色（透明或 hover 灰），取消紫色
    canvas.drawPath(
      leftPath,
      Paint()..color = isHovered ? EchoColors.cardHover : Colors.transparent,
    );

    // 右区 Path（白/透明或 hover 灰）
    final rightPath = Path();
    rightPath.moveTo(lsw + nr, 0);
    rightPath.lineTo(size.width, 0);
    rightPath.lineTo(size.width, size.height);
    rightPath.lineTo(lsw + nr, size.height);
    rightPath.arcToPoint(
      Offset(lsw, size.height - nr),
      radius: const Radius.circular(nr),
      clockwise: false,
    );
    rightPath.lineTo(lsw, nr);
    rightPath.arcToPoint(
      Offset(lsw + nr, 0),
      radius: const Radius.circular(nr),
      clockwise: false,
    );
    rightPath.close();

    canvas.drawPath(
      rightPath,
      Paint()..color = isHovered ? EchoColors.cardHover : Colors.transparent,
    );

    // 虚线
    final dashPaint = Paint()
      ..color = EchoColors.textTertiary.withValues(alpha: 0.6)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const dashHeight = 5.0;
    const dashSpace = 5.0;
    double y = nr;
    while (y < size.height - nr) {
      canvas.drawLine(
        Offset(lsw, y),
        Offset(lsw, (y + dashHeight).clamp(0.0, size.height)),
        dashPaint,
      );
      y += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant TicketBackgroundPainter oldDelegate) =>
      oldDelegate.isHovered != isHovered;
}

/// 存根封面图：圆角正方形，居中于左侧
class _StubCover extends StatelessWidget {
  const _StubCover({required this.coverImage});

  final String coverImage;

  @override
  Widget build(BuildContext context) {
    const size = 68.0; // 52 * 1.3 ≈ 68，圆角正方形

    if (coverImage.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: EchoColors.divider,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.movie_outlined,
          color: EchoColors.textTertiary,
          size: 28,
        ),
      );
    }

    if (!_isAllowedImageUrl(coverImage)) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: EchoColors.divider,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.broken_image_outlined,
          color: EchoColors.textTertiary,
          size: 28,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        coverImage,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: size,
          height: size,
          color: EchoColors.divider,
          child: Icon(
            Icons.broken_image_outlined,
            color: EchoColors.textTertiary,
            size: 28,
          ),
        ),
      ),
    );
  }
}

bool _isAllowedImageUrl(String value) {
  final uri = Uri.tryParse(value);
  if (uri == null || uri.scheme != 'https') return false;
  return true;
}
