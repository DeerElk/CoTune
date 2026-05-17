import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:cotune_mobile/models/playlist.dart';
import 'package:cotune_mobile/models/track.dart';
import 'package:cotune_mobile/services/storage_service.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('cotune_hive_test_');
    Hive.init(tempDir.path);
    await Hive.openBox('tracks');
    await Hive.openBox('playlists');
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('saveTrack, getTrack, updateTrack and deleteTrack work', () async {
    final service = StorageService();
    final track = Track(
      id: 'track-1',
      title: 'Night Drive',
      artist: 'CoTune Artist',
      path: '${tempDir.path}/missing.wav',
      ctid: 'ctid-1',
    );

    await service.saveTrack(track);
    expect(service.getTrack(track.id)?.title, 'Night Drive');
    expect(service.allTracks(), hasLength(1));

    track.liked = true;
    await service.updateTrack(track);
    expect(service.getTrack(track.id)?.liked, isTrue);

    await service.deleteTrack(track.id);
    expect(service.getTrack(track.id), isNull);
    expect(service.allTracks(), isEmpty);
  });

  test('saveTrack rejects duplicate id and duplicate CTID', () async {
    final service = StorageService();
    final first = Track(
      id: 'track-1',
      title: 'First',
      artist: 'Artist',
      path: '/tmp/first.wav',
      ctid: 'same-ctid',
    );
    final duplicateId = Track(
      id: 'track-1',
      title: 'Second',
      artist: 'Artist',
      path: '/tmp/second.wav',
    );
    final duplicateCTID = Track(
      id: 'track-2',
      title: 'Third',
      artist: 'Artist',
      path: '/tmp/third.wav',
      ctid: 'same-ctid',
    );

    await service.saveTrack(first);

    expect(service.saveTrack(duplicateId), throwsException);
    expect(service.saveTrack(duplicateCTID), throwsException);
  });

  test('playlists are saved, restored and deleted', () async {
    final service = StorageService();
    final playlist = PlaylistModel(
      id: 'playlist-1',
      name: 'Favorites',
      trackIds: ['track-1'],
    );

    await service.savePlaylist(playlist);
    expect(service.getPlaylist(playlist.id)?.name, 'Favorites');
    expect(service.allPlaylists(), hasLength(1));

    await service.deletePlaylist(playlist.id);
    expect(service.getPlaylist(playlist.id), isNull);
    expect(service.allPlaylists(), isEmpty);
  });
}
