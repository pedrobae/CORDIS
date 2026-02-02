import 'package:cordis/models/domain/playlist/flow_item.dart';
import 'package:cordis/models/dtos/playlist_dto.dart';
import 'package:cordis/models/dtos/version_dto.dart';
import 'package:flutter/foundation.dart';
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

  Map<String, dynamic> toSQLite() {
    return {
      'id': id,
      'name': name,
      'created_by': createdBy,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  // Database-specific serialization (excludes relational data)
  Map<String, dynamic> toDatabaseJson() {
    return {'name': name, 'author_id': createdBy};
  }

  PlaylistDto toDto(
    String ownerFirebaseId,
    Map<String, VersionDto> versions,
    Map<String, FlowItem> flowItems,
  ) {
    return PlaylistDto(
      name: name,
      itemOrder: items
          .map(
            (item) =>
                '${item.type == PlaylistItemType.version ? 'v' : 't'}:${item.id}',
          )
          .toList(),
      versions: versions,
      flowItems: flowItems.map(
        (key, item) => MapEntry(key, item.toFirestore()),
      ),
    );
  }

  Playlist copyWith({
    int? id,
    String? name,
    Duration? duration,
    int? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? collaborators,
    String? shareCode,
    List<PlaylistItem>? items,
    bool? isPublic,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      createdBy: createdBy ?? this.createdBy,
      items: items ?? this.items,
    );
  }

  Playlist removeItem(PlaylistItemType type, int contentId) {
    final updatedItems = items
        .where((item) => !(item.type == type && item.contentId == contentId))
        .toList();

    // Reorder remaining items
    final reorderedItems = updatedItems
        .asMap()
        .entries
        .map((entry) => entry.value.copyWith(position: entry.key))
        .toList();

    return copyWith(items: reorderedItems, updatedAt: DateTime.now());
  }

  // Convenience getters for filtering items by type
  List<PlaylistItem> get cipherVersionItems =>
      items.where((item) => item.isCipherVersion).toList();

  List<PlaylistItem> get textSectionItems =>
      items.where((item) => item.isTextSection).toList();

  // Helper to get text section IDs from items
  List<int?> get textSectionIdsFromItems => items
      .where((item) => item.isTextSection)
      .map((item) => item.contentId)
      .toList();

  List<PlaylistItem> get orderedItems {
    final ordered = List<PlaylistItem>.from(items)
      ..sort((a, b) => a.position.compareTo(b.position));
    return ordered;
  }

  // Debug method for quick playlist inspection
  void debugPrint() {
    if (kDebugMode) {
      print('=== Playlist Debug ===');
      print('ID: $id | Name: $name');
      print('Items: ${items.length}');
      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        print(
          '  [$i] ${item.type} - ID: ${item.contentId} (order: ${item.position})',
        );
      }
      print('======================');
    }
  }
}
