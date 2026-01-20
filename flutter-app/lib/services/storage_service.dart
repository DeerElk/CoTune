// lib/services/storage_service.dart
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/track.dart';
import '../models/playlist.dart';

class StorageService extends ChangeNotifier {
  final Box _tracks = Hive.box('tracks');
  final Box _playlists = Hive.box('playlists');
  final uuid = Uuid();

  List<Track> allTracks() {
    return _tracks.values
        .map((e) => Track.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  List<PlaylistModel> allPlaylists() {
    return _playlists.values
        .map((e) => PlaylistModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Track? getTrack(String id) {
    final m = _tracks.get(id);
    if (m == null) return null;
    return Track.fromJson(Map<String, dynamic>.from(m));
  }

  Future<void> updateTrack(Track t) async {
    await _tracks.put(t.id, t.toJson());
    notifyListeners();
  }

  Future<String> createId() async => uuid.v4();

  Future<void> deleteTrack(String id) async {
    final t = getTrack(id);
    if (t != null) {
      // попутно удаляем файл на диске, если есть
      try {
        final f = File(t.path);
        if (await f.exists()) await f.delete();
      } catch (_) {}
    }
    await _tracks.delete(id);
    notifyListeners();
  }

  Future<void> savePlaylist(PlaylistModel p) async {
    await _playlists.put(p.id, p.toJson());
    notifyListeners();
  }

  Future<void> deletePlaylist(String id) async {
    await _playlists.delete(id);
    notifyListeners();
  }

  PlaylistModel? getPlaylist(String id) {
    final m = _playlists.get(id);
    if (m == null) return null;
    return PlaylistModel.fromJson(Map<String, dynamic>.from(m));
  }

  Track? findByChecksum(String checksum) {
    for (final t in allTracks()) {
      if (t.checksum != null && t.checksum == checksum) return t;
    }
    return null;
  }

  Track? findByCTID(String ctid) {
    for (final t in allTracks()) {
      if (t.ctid != null && t.ctid == ctid) return t;
    }
    return null;
  }

  Future<void> saveTrack(Track t) async {
    // защита от дублей по checksum
    if (t.checksum != null) {
      final dup = findByChecksum(t.checksum!);
      if (dup != null) {
        throw Exception('Track already exists with the same checksum');
      }
    }
    if (_tracks.containsKey(t.id)) throw Exception('Track already exists (id)');
    await _tracks.put(t.id, t.toJson());
    notifyListeners();
  }
}
