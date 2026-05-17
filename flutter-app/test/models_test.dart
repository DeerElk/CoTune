import 'package:flutter_test/flutter_test.dart';
import 'package:cotune_mobile/models/playlist.dart';
import 'package:cotune_mobile/models/track.dart';

void main() {
  test('Track serializes and restores all fields', () {
    final track = Track(
      id: 'track-1',
      title: 'Night Drive',
      artist: 'CoTune Artist',
      path: '/music/night-drive.wav',
      liked: true,
      recognized: false,
      sharedToNetwork: true,
      ctid: 'ctid-1',
    );

    final restored = Track.fromJson(track.toJson());

    expect(restored.id, track.id);
    expect(restored.title, track.title);
    expect(restored.artist, track.artist);
    expect(restored.path, track.path);
    expect(restored.liked, isTrue);
    expect(restored.recognized, isFalse);
    expect(restored.sharedToNetwork, isTrue);
    expect(restored.ctid, track.ctid);
  });

  test('Track fromJson applies defaults for optional fields', () {
    final restored = Track.fromJson({
      'id': 'track-2',
      'title': 'Local Song',
      'artist': 'Tester',
      'path': '/tmp/local.wav',
    });

    expect(restored.liked, isFalse);
    expect(restored.recognized, isTrue);
    expect(restored.sharedToNetwork, isFalse);
    expect(restored.ctid, isNull);
  });

  test('PlaylistModel serializes and restores track ids', () {
    final playlist = PlaylistModel(
      id: 'playlist-1',
      name: 'Favorites',
      trackIds: ['track-1', 'track-2'],
    );

    final restored = PlaylistModel.fromJson(playlist.toJson());

    expect(restored.id, playlist.id);
    expect(restored.name, playlist.name);
    expect(restored.trackIds, ['track-1', 'track-2']);
  });
}
