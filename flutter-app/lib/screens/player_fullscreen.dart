import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/audio_player_service.dart';
import '../services/storage_service.dart';
import '../theme.dart';
import '../l10n/app_localizations.dart';

class PlayerFullScreenSheet extends StatelessWidget {
  const PlayerFullScreenSheet({super.key});

  static const String _animFrame1 = 'assets/player_anim/frame_1.png';
  static const String _animFrame2 = 'assets/player_anim/frame_2.png';

  @override
  Widget build(BuildContext context) {
    final audio = Provider.of<AudioPlayerService>(context);
    final storage = Provider.of<StorageService>(context);
    final current = audio.currentTrackId != null
        ? storage.getTrack(audio.currentTrackId!)
        : null;
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
      height: size.height * 0.92,
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
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Row(
              children: [
                const Spacer(),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: onSurface.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          if (current == null)
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
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: Column(
                  children: [
                    StreamBuilder<bool>(
                      stream: audio.player.playingStream,
                      builder: (context, snap) {
                        final playing = snap.data ?? false;
                        return Container(
                          width: double.infinity,
                          height: size.width * 0.68,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            color: Colors.white.withValues(alpha: 0.04),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Center(
                            child: _TwoFrameAnimation(
                              isPlaying: playing,
                              frameAAsset: _animFrame1,
                              frameBAsset: _animFrame2,
                              size: size.width * 0.52,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    Text(
                      current.title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.manrope(
                        textStyle: theme.textTheme.headlineMedium?.copyWith(
                          color: onSurface,
                          fontWeight: FontWeight.w700,
                          fontSize: 26,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      current.artist,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        textStyle: theme.textTheme.titleMedium?.copyWith(
                          color: onSurface.withValues(alpha: 0.72),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    StreamBuilder<Duration>(
                      stream: audio.player.positionStream,
                      builder: (context, snap) {
                        final pos = snap.data ?? Duration.zero;
                        final dur = audio.player.duration ?? Duration.zero;
                        final max = dur.inMilliseconds.toDouble();
                        final value = dur.inMilliseconds == 0
                            ? 0.0
                            : pos.inMilliseconds.toDouble();
                        return Column(
                          children: [
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 4,
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 7,
                                ),
                                activeTrackColor: CotuneTheme.highlight,
                                inactiveTrackColor: onSurface.withValues(
                                  alpha: 0.2,
                                ),
                                thumbColor: Colors.white,
                              ),
                              child: Slider(
                                value: value.clamp(0, max <= 0 ? 1 : max),
                                min: 0,
                                max: max <= 0 ? 1 : max,
                                onChanged: (v) => audio.seek(
                                  Duration(milliseconds: v.toInt()),
                                ),
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _fmt(pos),
                                  style: GoogleFonts.inter(
                                    color: onSurface.withValues(alpha: 0.62),
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  _fmt(dur),
                                  style: GoogleFonts.inter(
                                    color: onSurface.withValues(alpha: 0.62),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
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
                              tooltip: 'Shuffle',
                            );
                          },
                        ),
                        const SizedBox(width: 24),
                        ValueListenableBuilder<RepeatModeState>(
                          valueListenable: audio.repeatMode,
                          builder: (context, mode, _) {
                            IconData icon;
                            if (mode == RepeatModeState.one) {
                              icon = Icons.repeat_one_rounded;
                            } else {
                              icon = Icons.repeat_rounded;
                            }
                            final active = mode != RepeatModeState.off;
                            return IconButton(
                              icon: Icon(
                                icon,
                                color: active
                                    ? CotuneTheme.highlight
                                    : onSurface.withValues(alpha: 0.65),
                              ),
                              onPressed: audio.cycleRepeatMode,
                              tooltip: 'Repeat',
                            );
                          },
                        ),
                      ],
                    ),
                    const Spacer(),
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
                                    color: CotuneTheme.highlight.withValues(
                                      alpha: 0.38,
                                    ),
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
                                  color: Colors.black,
                                ),
                                onPressed: () {
                                  if (playing) {
                                    audio.pause();
                                  } else {
                                    audio.playUri(
                                      current.path,
                                      trackId: current.id,
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
                    const SizedBox(height: 8),
                    IconButton(
                      icon: Icon(
                        current.liked ? Icons.favorite : Icons.favorite_border,
                        color: current.liked
                            ? CotuneTheme.highlight
                            : onSurface.withValues(alpha: 0.72),
                      ),
                      onPressed: () async {
                        current.liked = !current.liked;
                        await storage.updateTrack(current);
                      },
                    ),
                  ],
                ),
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.asset(
        asset,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) {
          return Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Colors.white.withValues(alpha: 0.08),
            ),
            child: Icon(
              _frame == 0
                  ? Icons.graphic_eq_rounded
                  : Icons.multitrack_audio_rounded,
              size: widget.size * 0.42,
              color: CotuneTheme.highlight,
            ),
          );
        },
      ),
    );
  }
}
