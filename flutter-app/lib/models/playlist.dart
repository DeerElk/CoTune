class PlaylistModel {
  final String id;
  String name;
  List<String> trackIds;

  PlaylistModel({
    required this.id,
    required this.name,
    List<String>? trackIds,
  }) : trackIds = trackIds ?? [];

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'trackIds': trackIds,
  };

  static PlaylistModel fromJson(Map m) {
    return PlaylistModel(
      id: m['id'] as String,
      name: m['name'] as String,
      trackIds:
          (m['trackIds'] as List?)?.map((e) => e as String).toList() ?? [],
    );
  }
}
