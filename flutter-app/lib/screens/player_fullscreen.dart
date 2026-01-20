import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/audio_player_service.dart';
import '../services/storage_service.dart';
import '../theme.dart';
import '../l10n/app_localizations.dart';
import '../widgets/animated_cat.dart';

class PlayerFullScreenSheet extends StatelessWidget {
  const PlayerFullScreenSheet({super.key});

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

    return Container(
      height: size.height * 0.92,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: theme.brightness == Brightness.dark
              ? [const Color(0xFF1a1a1a), theme.scaffoldBackgroundColor]
              : [theme.scaffoldBackgroundColor, theme.scaffoldBackgroundColor],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: Column(
        children: [
          // Header with drag handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Row(
              children: [
                const Spacer(),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withOpacity(0.3),
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
                  icon: Icon(
                    Icons.expand_more,
                    color: theme.iconTheme.color,
                    size: 28,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.more_vert, color: theme.iconTheme.color),
                  onPressed: () {},
                ),
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
                      color: theme.iconTheme.color?.withOpacity(0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.playerNothingPlaying,
                      style: GoogleFonts.manrope(
                        textStyle: theme.textTheme.headlineSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      // Animated cat (replaces album art)
                      StreamBuilder<bool>(
                        stream: audio.player.playingStream,
                        builder: (context, s) {
                          final playing = s.data ?? false;
                          return Container(
                            width: size.width * 0.85,
                            height: size.width * 0.85,
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: CotuneTheme.highlight.withOpacity(0.3),
                                  blurRadius: 30,
                                  spreadRadius: 10,
                                ),
                              ],
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  CotuneTheme.highlight.withOpacity(0.8),
                                  CotuneTheme.highlight.withOpacity(0.4),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: AnimatedCat(
                                isPlaying: playing,
                                size: size.width * 0.7,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 32),
                      // Track title
                      Text(
                        current.title,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.manrope(
                          textStyle: theme.textTheme.headlineMedium?.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Artist name
                      Text(
                        current.artist,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          textStyle: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Progress bar with time
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
                                    enabledThumbRadius: 8,
                                  ),
                                  overlayShape: const RoundSliderOverlayShape(
                                    overlayRadius: 16,
                                  ),
                                  activeTrackColor: CotuneTheme.highlight,
                                  inactiveTrackColor: theme.dividerColor
                                      .withOpacity(0.3),
                                  thumbColor: Colors.white,
                                  overlayColor: CotuneTheme.highlight
                                      .withOpacity(0.2),
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
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _fmt(pos),
                                      style: GoogleFonts.inter(
                                        textStyle: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: theme.colorScheme.onSurface
                                                  .withOpacity(0.6),
                                              fontSize: 12,
                                            ),
                                      ),
                                    ),
                                    Text(
                                      _fmt(dur),
                                      style: GoogleFonts.inter(
                                        textStyle: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: theme.colorScheme.onSurface
                                                  .withOpacity(0.6),
                                              fontSize: 12,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      // Main controls (play/pause, previous, next)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.shuffle),
                            iconSize: 24,
                            color: theme.iconTheme.color?.withOpacity(0.7),
                            onPressed: () {},
                          ),
                          const SizedBox(width: 16),
                          IconButton(
                            icon: const Icon(Icons.skip_previous),
                            iconSize: 36,
                            color: theme.iconTheme.color,
                            onPressed: () async {
                              final pos = audio.player.position;
                              if (pos.inSeconds > 5) {
                                await audio.seek(Duration.zero);
                              } else {
                                await audio.previous();
                              }
                            },
                          ),
                          const SizedBox(width: 8),
                          StreamBuilder<bool>(
                            stream: audio.player.playingStream,
                            builder: (context, s) {
                              final playing = s.data ?? false;
                              return Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: CotuneTheme.highlight.withOpacity(
                                        0.4,
                                      ),
                                      blurRadius: 20,
                                      spreadRadius: 4,
                                    ),
                                  ],
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    playing
                                        ? Icons.pause_circle_filled
                                        : Icons.play_circle_fill,
                                    size: 72,
                                  ),
                                  color: CotuneTheme.highlight,
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
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.skip_next),
                            iconSize: 36,
                            color: theme.iconTheme.color,
                            onPressed: () => audio.next(),
                          ),
                          const SizedBox(width: 16),
                          IconButton(
                            icon: Icon(
                              current.liked
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                            ),
                            iconSize: 24,
                            color: current.liked
                                ? CotuneTheme.highlight
                                : theme.iconTheme.color?.withOpacity(0.7),
                            onPressed: () async {
                              current.liked = !current.liked;
                              await storage.updateTrack(current);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Repeat button
                      IconButton(
                        icon: const Icon(Icons.repeat),
                        iconSize: 24,
                        color: theme.iconTheme.color?.withOpacity(0.7),
                        onPressed: () {},
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
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
