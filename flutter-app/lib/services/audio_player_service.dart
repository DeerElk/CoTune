import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'dart:math';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/track.dart';

enum RepeatModeState { off, all, one }

class _QueueItem {
  final String id;
  final String path;

  const _QueueItem({required this.id, required this.path});
}

class AudioPlayerService {
  final AudioPlayer player = AudioPlayer();
  String? currentTrackId;
  final Random _random = Random();
  List<_QueueItem> _queue = const [];
  int _currentIndex = -1;
  final ValueNotifier<bool> shuffleEnabled = ValueNotifier<bool>(false);
  final ValueNotifier<RepeatModeState> repeatMode =
      ValueNotifier<RepeatModeState>(RepeatModeState.off);

  AudioPlayerService() {
    player.playerStateStream.listen((state) {
      if (state.processingState != ProcessingState.completed) return;
      if (repeatMode.value == RepeatModeState.one) {
        unawaited(seek(Duration.zero).then((_) => player.play()));
        return;
      }
      unawaited(next(autoFromCompleted: true));
    });
  }

  void setQueueFromTracks(List<Track> tracks, {String? currentId}) {
    _queue = tracks
        .where((t) => t.path.trim().isNotEmpty)
        .map((t) => _QueueItem(id: t.id, path: t.path))
        .toList();
    if (_queue.isEmpty) {
      _currentIndex = -1;
      return;
    }
    if (currentId != null) {
      final idx = _queue.indexWhere((t) => t.id == currentId);
      _currentIndex = idx >= 0 ? idx : 0;
    } else if (_currentIndex < 0 || _currentIndex >= _queue.length) {
      _currentIndex = 0;
    }
  }

  Future<void> playUri(String uri, {String? trackId}) async {
    try {
      if (uri.trim().isEmpty) {
        throw Exception('Empty audio path');
      }
      final ps = player.playerState;
      final sameTrack = (trackId != null && trackId == currentTrackId);
      final alreadyLoaded =
          ps.processingState != ProcessingState.idle &&
          ps.processingState != ProcessingState.loading;
      if (sameTrack && alreadyLoaded) {
        await player.play();
        return;
      }

      currentTrackId = trackId;
      if (trackId != null) {
        final idx = _queue.indexWhere((t) => t.id == trackId);
        if (idx >= 0) _currentIndex = idx;
      }
      final normalized = _normalizeLocalPath(uri);
      if (normalized != null) {
        if (!normalized.startsWith('content://')) {
          final f = File(normalized);
          if (!f.existsSync()) {
            throw Exception('Audio file not found: $normalized');
          }
        }
        try {
          await player.setFilePath(normalized);
        } catch (_) {
          // Windows fallback: some codecs/paths work better via file URI.
          await player.setUrl(Uri.file(normalized).toString());
        }
      } else {
        await player.setUrl(uri);
      }
      await player.play();
    } catch (e) {
      print('AudioPlayerService.playUri error: $e, uri=$uri');
    }
  }

  String? _normalizeLocalPath(String uri) {
    if (uri.startsWith('content://')) {
      return uri;
    }
    if (uri.startsWith('file://')) {
      return Uri.parse(uri).toFilePath(windows: Platform.isWindows);
    }
    if (uri.startsWith('/') || RegExp(r'^[A-Za-z]:[\\/]').hasMatch(uri)) {
      return uri;
    }
    // Sometimes Windows paths can come as C:/...
    if (RegExp(r'^[A-Za-z]:/').hasMatch(uri)) {
      return uri.replaceAll('/', Platform.pathSeparator);
    }
    if (File(uri).existsSync()) {
      return uri;
    }
    return null;
  }

  void pause() => player.pause();

  Future<void> stop() async {
    await player.stop();
    currentTrackId = null;
  }

  Future<void> seek(Duration pos) => player.seek(pos);

  void toggleShuffle() {
    shuffleEnabled.value = !shuffleEnabled.value;
  }

  void cycleRepeatMode() {
    switch (repeatMode.value) {
      case RepeatModeState.off:
        repeatMode.value = RepeatModeState.all;
        break;
      case RepeatModeState.all:
        repeatMode.value = RepeatModeState.one;
        break;
      case RepeatModeState.one:
        repeatMode.value = RepeatModeState.off;
        break;
    }
  }

  Future<void> previous() async {
    if (_queue.isEmpty) return;
    if (_currentIndex < 0 || _currentIndex >= _queue.length) {
      _currentIndex = 0;
    }
    if (shuffleEnabled.value && _queue.length > 1) {
      var nextIndex = _random.nextInt(_queue.length);
      while (nextIndex == _currentIndex) {
        nextIndex = _random.nextInt(_queue.length);
      }
      _currentIndex = nextIndex;
    } else if (_currentIndex > 0) {
      _currentIndex--;
    } else if (repeatMode.value == RepeatModeState.all) {
      _currentIndex = _queue.length - 1;
    }

    final item = _queue[_currentIndex];
    await playUri(item.path, trackId: item.id);
  }

  Future<void> next({bool autoFromCompleted = false}) async {
    if (_queue.isEmpty) return;
    if (_currentIndex < 0 || _currentIndex >= _queue.length) {
      _currentIndex = 0;
    }

    if (shuffleEnabled.value && _queue.length > 1) {
      var nextIndex = _random.nextInt(_queue.length);
      while (nextIndex == _currentIndex) {
        nextIndex = _random.nextInt(_queue.length);
      }
      _currentIndex = nextIndex;
      final item = _queue[_currentIndex];
      await playUri(item.path, trackId: item.id);
      return;
    }

    if (_currentIndex < _queue.length - 1) {
      _currentIndex++;
      final item = _queue[_currentIndex];
      await playUri(item.path, trackId: item.id);
      return;
    }

    if (repeatMode.value == RepeatModeState.all) {
      _currentIndex = 0;
      final item = _queue[_currentIndex];
      await playUri(item.path, trackId: item.id);
      return;
    }

    if (autoFromCompleted) {
      await stop();
    }
  }

  Future<void> dispose() async {
    await player.dispose();
    shuffleEnabled.dispose();
    repeatMode.dispose();
  }
}
