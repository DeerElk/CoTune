import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/audio_player_service.dart';
import '../services/storage_service.dart';
import '../theme.dart';

class PlayerFullScreenSheet extends StatelessWidget {
  const PlayerFullScreenSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final audio = Provider.of<AudioPlayerService>(context);
    final storage = Provider.of<StorageService>(context);
    final current = audio.currentTrackId != null
        ? storage.getTrack(audio.currentTrackId!)
        : null;
    final theme = Theme.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.expand_more, color: theme.iconTheme.color),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'Моя музыка',
                      style: GoogleFonts.manrope(
                        textStyle: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.onBackground,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          if (current == null)
            Expanded(
              child: Center(
                child: Text(
                  'Ничего не играет',
                  style: GoogleFonts.manrope(
                    textStyle: theme.textTheme.headlineMedium?.copyWith(
                      color: theme.colorScheme.onBackground,
                    ),
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: StreamBuilder<bool>(
                        stream: audio.player.playingStream,
                        builder: (context, s) {
                          final playing = s.data ?? false;
                          return Icon(
                            playing
                                ? Icons.graphic_eq
                                : Icons.pause_circle_filled,
                            size: 72,
                            color: CotuneTheme.highlight,
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  // заголовок трека (видимый и в светлой теме и в тёмной)
                  Text(
                    current.title,
                    style: GoogleFonts.manrope(
                      textStyle: theme.textTheme.headlineMedium?.copyWith(
                        color: theme.colorScheme.onBackground,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    current.artist,
                    style: GoogleFonts.inter(
                      textStyle: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
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
                          Slider(
                            value: value.clamp(0, max <= 0 ? 1 : max),
                            min: 0,
                            max: max <= 0 ? 1 : max,
                            activeColor: CotuneTheme.highlight,
                            inactiveColor: theme.dividerColor,
                            onChanged: (v) =>
                                audio.seek(Duration(milliseconds: v.toInt())),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [Text(_fmt(pos)), Text(_fmt(dur))],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.skip_previous, size: 34),
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
                      const SizedBox(width: 18),
                      StreamBuilder<bool>(
                        stream: audio.player.playingStream,
                        builder: (context, s) {
                          final playing = s.data ?? false;
                          return IconButton(
                            icon: Icon(
                              playing
                                  ? Icons.pause_circle_filled
                                  : Icons.play_circle_fill,
                              size: 62,
                            ),
                            color: CotuneTheme.highlight,
                            onPressed: () {
                              if (playing)
                                audio.pause();
                              else
                                audio.playUri(
                                  current.path,
                                  trackId: current.id,
                                );
                            },
                          );
                        },
                      ),
                      const SizedBox(width: 18),
                      IconButton(
                        icon: const Icon(Icons.skip_next, size: 34),
                        color: theme.iconTheme.color,
                        onPressed: () => audio.next(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.repeat),
                        color: theme.iconTheme.color,
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: Icon(
                          current.liked
                              ? Icons.favorite
                              : Icons.favorite_border,
                        ),
                        color: current.liked
                            ? CotuneTheme.highlight
                            : theme.iconTheme.color,
                        onPressed: () async {
                          current.liked = !current.liked;
                          await storage.updateTrack(current);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.shuffle),
                        color: theme.iconTheme.color,
                        onPressed: () {},
                      ),
                    ],
                  ),
                ],
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
