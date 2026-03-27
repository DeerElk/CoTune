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
  String? currentTitle;
  String? currentArtist;
  String? currentPath;
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

  Future<bool> playUri(
    String uri, {
    String? trackId,
    String? title,
    String? artist,
  }) async {
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
        return true;
      }

      currentTrackId = trackId;
      currentTitle = title;
      currentArtist = artist;
      currentPath = uri;
      if (trackId != null) {
        final idx = _queue.indexWhere((t) => t.id == trackId);
        if (idx >= 0) _currentIndex = idx;
      }
      final normalized = _normalizeLocalPath(uri);
      final loaded = await _loadSource(uri: uri, normalized: normalized);
      if (!loaded) {
        throw Exception('Unable to load audio source');
      }
      await player.play();
      debugPrint(
        'AudioPlayerService.playUri started: trackId=$trackId uri=$uri',
      );
      return true;
    } catch (e) {
      debugPrint('AudioPlayerService.playUri error: $e, uri=$uri');
      return false;
    }
  }

  Future<bool> _loadSource({
    required String uri,
    required String? normalized,
  }) async {
    if (normalized != null) {
      if (normalized.startsWith('content://')) {
        try {
          await player.setUrl(normalized);
          return true;
        } catch (_) {}
        return false;
      }

      final f = File(normalized);
      if (!f.existsSync()) {
        debugPrint('AudioPlayerService: file not found: $normalized');
        return false;
      }

      try {
        await player.setFilePath(normalized);
        debugPrint('AudioPlayerService source via setFilePath: $normalized');
        return true;
      } catch (_) {}

      try {
        await player.setAudioSource(AudioSource.uri(Uri.file(normalized)));
        debugPrint(
          'AudioPlayerService source via setAudioSource(file): $normalized',
        );
        return true;
      } catch (_) {}

      try {
        await player.setUrl(Uri.file(normalized).toString());
        debugPrint('AudioPlayerService source via setUrl(file): $normalized');
        return true;
      } catch (_) {}
      return false;
    }

    try {
      await player.setUrl(uri);
      debugPrint('AudioPlayerService source via setUrl(raw): $uri');
      return true;
    } catch (_) {}

    // As a last resort, try treating input as local path.
    try {
      await player.setFilePath(uri);
      debugPrint('AudioPlayerService source via setFilePath(raw): $uri');
      return true;
    } catch (_) {}
    return false;
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
    currentTitle = null;
    currentArtist = null;
    currentPath = null;
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
