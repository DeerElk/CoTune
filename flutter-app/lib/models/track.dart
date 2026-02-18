import 'package:uuid/uuid.dart';

class Track {
  final String id;
  String title;
  String artist;
  String path;
  bool liked;
  bool recognized;
  bool sharedToNetwork;
  String? ctid; // Canonical Track ID (SHA256 of normalized PCM)

  Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.path,
    this.liked = false,
    this.recognized = true,
    this.sharedToNetwork = false,
    this.ctid,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'artist': artist,
    'path': path,
    'liked': liked,
    'recognized': recognized,
    'sharedToNetwork': sharedToNetwork,
    'ctid': ctid,
  };

  static Track fromJson(Map m) {
    final id = (m['id'] as String?) ?? const Uuid().v4();
    final title = (m['title'] as String?) ?? '';
    final artist = (m['artist'] as String?) ?? 'Unknown Artist';
    final path = (m['path'] as String?) ?? '';
    final liked = (m['liked'] as bool?) ?? false;
    final recognized = (m['recognized'] as bool?) ?? true;
    final sharedToNetwork = (m['sharedToNetwork'] as bool?) ?? false;
    final ctid = (m['ctid'] as String?);

    return Track(
      id: id,
      title: title,
      artist: artist,
      path: path,
      liked: liked,
      recognized: recognized,
      sharedToNetwork: sharedToNetwork,
      ctid: ctid,
    );
  }
}
