import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/audio_player_service.dart';
import '../services/storage_service.dart';
import '../theme.dart';
import '../l10n/app_localizations.dart';

class PlayerFullScreenSheet extends StatelessWidget {
  const PlayerFullScreenSheet({super.key});

  static const String _animFrame1Light = 'assets/player_anim/frame_1_light.png';
  static const String _animFrame2Light = 'assets/player_anim/frame_2_light.png';
  static const String _animFrame1Dark = 'assets/player_anim/frame_1_dark.png';
  static const String _animFrame2Dark = 'assets/player_anim/frame_2_dark.png';

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black.withValues(alpha: 0.16),
        pageBuilder: (context, animation, secondaryAnimation) {
          return const _PlayerFullScreenRouteBody();
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutQuart,
            reverseCurve: Curves.easeInQuart,
          );
          final slide = Tween<Offset>(
            begin: const Offset(0, 0.08),
            end: Offset.zero,
          ).animate(curved);
          final fade = Tween<double>(begin: 0.0, end: 1.0).animate(curved);
          return FadeTransition(
            opacity: fade,
            child: SlideTransition(position: slide, child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 220),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final audio = Provider.of<AudioPlayerService>(context);
    final storage = Provider.of<StorageService>(context);
    final current = audio.currentTrackId != null
        ? storage.getTrack(audio.currentTrackId!)
        : null;
    final fallbackTitle = (audio.currentTitle ?? '').trim();
    final fallbackArtist = (audio.currentArtist ?? '').trim();
    final fallbackPath = (audio.currentPath ?? '').trim();
    final title =
        current?.title ?? (fallbackTitle.isNotEmpty ? fallbackTitle : '');
    final artist = current?.artist ?? fallbackArtist;
    final playbackPath = current?.path ?? fallbackPath;
    final hasPlayable = playbackPath.isNotEmpty;
    final canLike = current != null;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.of(context).size;
    final onSurface = theme.colorScheme.onSurface;
    final bgTop = theme.brightness == Brightness.dark
        ? const Color(0xFF121212)
        : const Color(0xFFF6F7FB);
    final bgBottom = theme.brightness == Brightness.dark
        ? const Color(0xFF0D0D0D)
        : const Color(0xFFEDEFF5);

    return Container(
      height: size.height * 0.94,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [bgTop, bgBottom],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.expand_more, color: onSurface, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
                const Spacer(),
                const SizedBox(width: 48),
              ],
            ),
          ),
          if (!hasPlayable)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.music_note,
                      size: 64,
                      color: onSurface.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.playerNothingPlaying,
                      style: GoogleFonts.manrope(
                        textStyle: theme.textTheme.headlineSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final contentWidth = math.min(constraints.maxWidth, 1080.0);
                  final animSize = math.min(
                    contentWidth * 0.72,
                    size.height * 0.38,
                  );
                  final animFrameA = theme.brightness == Brightness.dark
                      ? _animFrame1Dark
                      : _animFrame1Light;
                  final animFrameB = theme.brightness == Brightness.dark
                      ? _animFrame2Dark
                      : _animFrame2Light;

                  return Align(
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: contentWidth,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(8, 16, 8, 18),
                        child: Column(
                          children: [
                            StreamBuilder<bool>(
                              stream: audio.player.playingStream,
                              builder: (context, snap) {
                                final playing = snap.data ?? false;
                                return SizedBox(
                                  width: double.infinity,
                                  height: animSize,
                                  child: Center(
                                    child: _TwoFrameAnimation(
                                      isPlaying: playing,
                                      frameAAsset: animFrameA,
                                      frameBAsset: animFrameB,
                                      size: animSize,
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 32),
                            Text(
                              title,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.manrope(
                                textStyle: theme.textTheme.headlineMedium
                                    ?.copyWith(
                                      color: onSurface,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 26,
                                    ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              artist,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                textStyle: theme.textTheme.titleMedium
                                    ?.copyWith(
                                      color: onSurface.withValues(alpha: 0.72),
                                    ),
                              ),
                            ),
                            const SizedBox(height: 26),
                            StreamBuilder<Duration>(
                              stream: audio.player.positionStream,
                              builder: (context, snap) {
                                final pos = snap.data ?? Duration.zero;
                                final dur =
                                    audio.player.duration ?? Duration.zero;
                                final max = dur.inMilliseconds.toDouble();
                                final value = dur.inMilliseconds == 0
                                    ? 0.0
                                    : pos.inMilliseconds.toDouble();
                                return Column(
                                  children: [
                                    SliderTheme(
                                      data: SliderTheme.of(context).copyWith(
                                        trackHeight: 2,
                                        thumbShape: const RoundSliderThumbShape(
                                          enabledThumbRadius: 5,
                                        ),
                                        activeTrackColor: CotuneTheme.highlight,
                                        inactiveTrackColor: onSurface
                                            .withValues(alpha: 0.2),
                                        thumbColor: Colors.white,
                                      ),
                                      child: Slider(
                                        value: value.clamp(
                                          0,
                                          max <= 0 ? 1 : max,
                                        ),
                                        min: 0,
                                        max: max <= 0 ? 1 : max,
                                        onChanged: (v) => audio.seek(
                                          Duration(milliseconds: v.toInt()),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24.0,
                                        vertical: 0.0,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            _fmt(pos),
                                            style: GoogleFonts.inter(
                                              color: onSurface.withValues(
                                                alpha: 0.62,
                                              ),
                                              fontSize: 12,
                                            ),
                                          ),
                                          Text(
                                            _fmt(dur),
                                            style: GoogleFonts.inter(
                                              color: onSurface.withValues(
                                                alpha: 0.62,
                                              ),
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 30),
                            StreamBuilder<bool>(
                              stream: audio.player.playingStream,
                              builder: (context, s) {
                                final playing = s.data ?? false;
                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        Icons.skip_previous_rounded,
                                        color: onSurface,
                                        size: 38,
                                      ),
                                      onPressed: () async {
                                        final pos = audio.player.position;
                                        if (pos.inSeconds > 5) {
                                          await audio.seek(Duration.zero);
                                        } else {
                                          await audio.previous();
                                        }
                                      },
                                    ),
                                    const SizedBox(width: 10),
                                    Container(
                                      width: 88,
                                      height: 88,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: CotuneTheme.highlight,
                                        boxShadow: [
                                          BoxShadow(
                                            color: CotuneTheme.highlight
                                                .withValues(alpha: 0.38),
                                            blurRadius: 24,
                                            spreadRadius: 4,
                                          ),
                                        ],
                                      ),
                                      child: IconButton(
                                        icon: Icon(
                                          playing
                                              ? Icons.pause_rounded
                                              : Icons.play_arrow_rounded,
                                          size: 44,
                                          color:
                                              CotuneTheme.playerPrimaryControlIcon(
                                                theme,
                                              ),
                                        ),
                                        onPressed: () {
                                          if (playing) {
                                            audio.pause();
                                          } else {
                                            audio.playUri(
                                              playbackPath,
                                              trackId: current?.id,
                                              title: title,
                                              artist: artist,
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    IconButton(
                                      icon: Icon(
                                        Icons.skip_next_rounded,
                                        color: onSurface,
                                        size: 38,
                                      ),
                                      onPressed: () => audio.next(),
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 28),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                ValueListenableBuilder<bool>(
                                  valueListenable: audio.shuffleEnabled,
                                  builder: (context, enabled, _) {
                                    return IconButton(
                                      icon: Icon(
                                        Icons.shuffle_rounded,
                                        color: enabled
                                            ? CotuneTheme.highlight
                                            : onSurface.withValues(alpha: 0.65),
                                      ),
                                      onPressed: audio.toggleShuffle,
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: Icon(
                                    (current?.liked ?? false)
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: (current?.liked ?? false)
                                        ? CotuneTheme.highlight
                                        : onSurface.withValues(alpha: 0.72),
                                  ),
                                  onPressed: !canLike
                                      ? null
                                      : () async {
                                          current.liked = !current.liked;
                                          await storage.updateTrack(current);
                                        },
                                ),
                                ValueListenableBuilder<RepeatModeState>(
                                  valueListenable: audio.repeatMode,
                                  builder: (context, mode, _) {
                                    final icon = mode == RepeatModeState.one
                                        ? Icons.repeat_one_rounded
                                        : Icons.repeat_rounded;
                                    final active = mode != RepeatModeState.off;
                                    return IconButton(
                                      icon: Icon(
                                        icon,
                                        color: active
                                            ? CotuneTheme.highlight
                                            : onSurface.withValues(alpha: 0.65),
                                      ),
                                      onPressed: audio.cycleRepeatMode,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  String _fmt(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hh = d.inHours;
    if (hh > 0) return '$hh:$mm:$ss';
    return '$mm:$ss';
  }
}

class _PlayerFullScreenRouteBody extends StatefulWidget {
  const _PlayerFullScreenRouteBody();

  @override
  State<_PlayerFullScreenRouteBody> createState() =>
      _PlayerFullScreenRouteBodyState();
}

class _PlayerFullScreenRouteBodyState
    extends State<_PlayerFullScreenRouteBody> {
  double _dragDistance = 0;
  bool _closing = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onVerticalDragStart: (_) {
          _dragDistance = 0;
          _closing = false;
        },
        onVerticalDragUpdate: (details) {
          if (_closing) return;
          final delta = details.primaryDelta ?? 0;
          if (delta > 0) {
            _dragDistance += delta;
          }
        },
        onVerticalDragEnd: (details) {
          if (_closing) return;
          final velocity = details.velocity.pixelsPerSecond.dy;
          final shouldClose = _dragDistance > 80 || velocity > 900;
          if (shouldClose) {
            _closing = true;
            Navigator.of(context).maybePop();
          }
        },
        child: Align(
          alignment: Alignment.bottomCenter,
          child: const PlayerFullScreenSheet(),
        ),
      ),
    );
  }
}

class _TwoFrameAnimation extends StatefulWidget {
  final bool isPlaying;
  final String frameAAsset;
  final String frameBAsset;
  final double size;

  const _TwoFrameAnimation({
    required this.isPlaying,
    required this.frameAAsset,
    required this.frameBAsset,
    required this.size,
  });

  @override
  State<_TwoFrameAnimation> createState() => _TwoFrameAnimationState();
}

class _TwoFrameAnimationState extends State<_TwoFrameAnimation> {
  Timer? _timer;
  int _frame = 0;

  @override
  void initState() {
    super.initState();
    _syncTimer();
  }

  @override
  void didUpdateWidget(covariant _TwoFrameAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isPlaying != widget.isPlaying) {
      _syncTimer();
    }
  }

  void _syncTimer() {
    _timer?.cancel();
    if (widget.isPlaying) {
      _timer = Timer.periodic(const Duration(milliseconds: 200), (_) {
        if (!mounted) return;
        setState(() {
          _frame = _frame == 0 ? 1 : 0;
        });
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asset = _frame == 0 ? widget.frameAAsset : widget.frameBAsset;
    return Image.asset(
      asset,
      width: widget.size,
      height: widget.size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, _error, _stackTrace) {
        return Icon(
          _frame == 0
              ? Icons.graphic_eq_rounded
              : Icons.multitrack_audio_rounded,
          size: widget.size * 0.42,
          color: CotuneTheme.highlight,
        );
      },
    );
  }
}
