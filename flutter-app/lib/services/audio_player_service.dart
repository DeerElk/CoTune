// lib/services/audio_player_service.dart
import 'package:just_audio/just_audio.dart';

class AudioPlayerService {
  final AudioPlayer player = AudioPlayer();
  String? currentTrackId;

  AudioPlayerService() {
    // Можно инициализировать audio_session здесь
  }

  /// Если тот же trackId и источник уже загружен — просто resume,
  /// иначе загружаем источник и стартуем.
  Future<void> playUri(String uri, {String? trackId}) async {
    try {
      // Если у нас уже загружен тот же трек и не idle -> просто play (resume)
      final ps = player.playerState;
      final sameTrack = (trackId != null && trackId == currentTrackId);
      final alreadyLoaded =
          ps.processingState != ProcessingState.idle &&
          ps.processingState != ProcessingState.loading;
      if (sameTrack && alreadyLoaded) {
        await player.play();
        return;
      }

      // Иначе — загружаем источник заново
      currentTrackId = trackId;
      if (uri.startsWith('file://')) {
        await player.setFilePath(uri.replaceFirst('file://', ''));
      } else if (uri.startsWith('/') || uri.startsWith('content://')) {
        await player.setFilePath(uri);
      } else {
        await player.setUrl(uri);
      }
      await player.play();
    } catch (e) {
      print('AudioPlayerService.playUri error: $e');
    }
  }

  void pause() => player.pause();

  void stop() {
    player.stop();
    currentTrackId = null;
  }

  Future<void> seek(Duration pos) => player.seek(pos);

  // Заглушки для previous/next — можно расширить позже
  Future<void> previous() async {
    // TODO: интегрировать логику плейлиста
    print('previous pressed');
  }

  Future<void> next() async {
    print('next pressed');
  }
}
