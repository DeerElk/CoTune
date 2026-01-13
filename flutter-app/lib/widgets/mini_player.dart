import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/audio_player_service.dart';
import '../services/storage_service.dart';
import '../screens/player_fullscreen.dart';
import '../theme.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});
  static const double _height = 64;
  static const double _actionSize = 44;

  @override
  Widget build(BuildContext context) {
    final audio = Provider.of<AudioPlayerService>(context);
    final storage = Provider.of<StorageService>(context);
    final theme = Theme.of(context);
    final bg = theme.colorScheme.surface;

    return StreamBuilder<bool>(
      stream: audio.player.playingStream,
      initialData: audio.player.playing,
      builder: (context, snapPlaying) {
        final isPlaying = snapPlaying.data ?? false;
        final current = audio.currentTrackId != null
            ? storage.getTrack(audio.currentTrackId!)
            : null;

        if (!isPlaying && current == null) return const SizedBox.shrink();

        final title = (current?.title != null && current!.title.isNotEmpty)
            ? current.title
            : 'Без названия';
        final artist = (current?.artist != null && current!.artist.isNotEmpty)
            ? current.artist
            : '';

        return GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const PlayerFullScreenSheet(),
            );
          },
          child: Container(
            height: _height,
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const SizedBox(width: 8),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.manrope(
                              textStyle: theme.textTheme.titleLarge?.copyWith(
                                color: theme.colorScheme.onSurface,
                                fontSize: 15,
                              ),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),

                          if (artist.isNotEmpty)
                            Text(
                              artist,
                              style: GoogleFonts.inter(
                                textStyle: theme.textTheme.bodyMedium?.copyWith(
                                  fontSize: 12,
                                ),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),

                          const SizedBox(height: 4),

                          SizedBox(
                            height: 3,
                            child: StreamBuilder<Duration>(
                              stream: audio.player.positionStream,
                              builder: (context, sPos) {
                                final pos = sPos.data ?? Duration.zero;
                                final dur = audio.player.duration ?? Duration.zero;
                                final pct = dur.inMilliseconds > 0
                                    ? pos.inMilliseconds / dur.inMilliseconds
                                    : 0.0;

                                return LinearProgressIndicator(
                                  value: pct,
                                  backgroundColor: theme.dividerColor,
                                  valueColor: AlwaysStoppedAnimation(
                                    CotuneTheme.highlight,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: _actionSize,
                  height: _actionSize,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    iconSize: 34,
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, anim) =>
                          FadeTransition(opacity: anim, child: child),
                      child: Icon(
                        isPlaying
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_fill,
                        key: ValueKey(isPlaying),
                        color: CotuneTheme.highlight,
                        size: 34,
                      ),
                    ),
                    onPressed: () {
                      if (isPlaying) {
                        audio.pause();
                      } else if (current != null) {
                        audio.playUri(current.path, trackId: current.id);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
