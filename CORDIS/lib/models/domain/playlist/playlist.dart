import 'package:cordis/models/domain/playlist/flow_item.dart';
import 'package:cordis/models/dtos/playlist_dto.dart';
import 'package:cordis/models/dtos/version_dto.dart';
import 'playlist_item.dart';

class Playlist {
  final int id;
  final String name;
  final int createdBy;
  final List<PlaylistItem> items; // Unified content items

  const Playlist({
    required this.id,
    required this.name,
    required this.createdBy,
    this.items = const [],
  });

  factory Playlist.fromSQLite(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      createdBy: json['created_by'] as int? ?? 0,
    );
  }

  Duration getTotalDuration() {
    return items.fold(Duration.zero, (a, b) => a + b.duration);
  }

  // Database-specific serialization (excludes relational data)
  Map<String, dynamic> toDatabaseJson() {
    return {'name': name, 'author_id': createdBy};
  }

  PlaylistDto toDto({
    required List<String> itemOrder,
    required Map<String, VersionDto> versions,
    required Map<String, FlowItem> flowItems,
  }) {
    return PlaylistDto(
      name: name,
      itemOrder: itemOrder,
      versions: versions,
      flowItems: flowItems.map(
        (key, item) => MapEntry(key, item.toFirestore()),
      ),
    );
  }

  Playlist copyWith({
    int? id,
    String? name,
    int? createdBy,
    List<PlaylistItem>? items,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      createdBy: createdBy ?? this.createdBy,
      items: items ?? this.items,
    );
  }
}
