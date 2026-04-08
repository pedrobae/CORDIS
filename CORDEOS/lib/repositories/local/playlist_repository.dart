import 'package:cordeos/helpers/database.dart';
import 'package:cordeos/models/domain/playlist/playlist.dart';
import 'package:cordeos/models/domain/playlist/playlist_item.dart';

class PlaylistRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  // ===== PLAYLIST CRUD =====
  // ===== CREATE =====
  /// Creates a new playlist, as well as the playlist_version, and user_playlist relational objects
  Future<int> insertPlaylist(Playlist playlist) async {
    final db = await _databaseHelper.database;

    return await db.transaction((txn) async {
      // 1. Insert the playlist (basic info only)
      final playlistId = await txn.insert('playlist', playlist.toSqlite());

      // 2. Insert playlist items if any
      for (final item in playlist.items) {
        switch (item.type) {
          case PlaylistItemType.version:
            await txn.insert('playlist_version', {
              'version_id': item.contentId,
              'playlist_id': playlistId,
              'position': item.position,
            });
            break;
          case PlaylistItemType.flowItem:
            // Handle text sections if they exist
            // For now, just skip as we're removing text sections
            break;
        }
      }

      return playlistId;
    });
  }

  // ===== READ =====
  /// Gets all playlists stored in the database
  Future<List<Playlist>> getAllPlaylists() async {
    final db = await _databaseHelper.database;

    // Get playlists
    final playlistResults = await db.rawQuery('''
      SELECT p.* FROM playlist p
    ''');

    List<Playlist> playlists = [];

    for (Map<String, dynamic> playlistData in playlistResults) {
      final playlist = Playlist.fromSQLite(playlistData);

      /// Gets all items of a playlist in order
      final versionItems = await _getVersionItemsOfPlaylist(playlist.id);
      final textItems = await _getFlowItemsOfPlaylist(playlist.id);

      // Combine and sort all items by position
      final allItemResults = [...versionItems, ...textItems]
        ..sort((a, b) => (a.position).compareTo(b.position));

      playlists.add(playlist.copyWith(items: allItemResults));
    }

    return playlists;
  }

  /// Gets a single playlist by ID without relationships
  /// Returns null if not found
  Future<Playlist?> getPlaylistById(int playlistId) async {
    final db = await _databaseHelper.database;

    final playlistResults = await db.query(
      'playlist',
      where: 'id = ?',
      whereArgs: [playlistId],
    );

    if (playlistResults.isEmpty) return null;

    /// Gets all items of a playlist in order
    final versionItems = await _getVersionItemsOfPlaylist(playlistId);
    final textItems = await _getFlowItemsOfPlaylist(playlistId);

    // Combine and sort all items by position
    final allItemResults = [...versionItems, ...textItems]
      ..sort((a, b) => (a.position).compareTo(b.position));

    return Playlist.fromSQLite(
      playlistResults.first,
    ).copyWith(items: allItemResults);
  }

  // ===== UPDATE =====

  /// Upserts playlist metadata
  /// Used for syncing playlists from cloud to local database
  Future<int> upsertPlaylistMetadata(Playlist playlist) async {
    final db = await _databaseHelper.database;

    // First, try to find existing playlist by name
    final existingResult = await db.query(
      'playlist',
      columns: ['id'],
      where: 'name = ?',
      whereArgs: [playlist.name],
    );

    if (existingResult.isNotEmpty) {
      // Update existing playlist
      final playlistId = existingResult.first['id'] as int;

      await db.update(
        'playlist',
        {'name': playlist.name},
        where: 'id = ?',
        whereArgs: [playlistId],
      );
      return playlistId;
    } else {
      // Insert new playlist
      final playlistId = await db.insert(
        'playlist',
        playlist.toSqlite() as Map<String, Object?>,
      );
      return playlistId;
    }
  }

  Future<void> updatePlaylistMetadata(Playlist playlist) async {
    final db = await _databaseHelper.database;

    await db.update(
      'playlist',
      {'name': playlist.name},
      where: 'id = ?',
      whereArgs: [playlist.id],
    );
  }

  // ===== DELETE =====
  /// Deletes a playlist and all its related data
  Future<void> deletePlaylist(int playlistId) async {
    final db = await _databaseHelper.database;

    await db.delete('playlist', where: 'id = ?', whereArgs: [playlistId]);
    await db.delete(
      'playlist_version',
      where: 'playlist_id = ?',
      whereArgs: [playlistId],
    );
    await db.delete(
      'user_playlist',
      where: 'playlist_id = ?',
      whereArgs: [playlistId],
    );
  }

  // ===== VERSION MANAGEMENT =====
  /// Adds a version to the end of the playlist
  Future<void> addVersionToPlaylist(int playlistId, int versionID) async {
    final db = await _databaseHelper.database;

    await db.transaction((txn) async {
      // Get current max position
      final positionResult = await txn.rawQuery(
        '''
        SELECT COALESCE(MAX(position), -1) + 1 as next_position 
        FROM playlist_version 
        WHERE playlist_id = ?
      ''',
        [playlistId],
      );

      final nextPosition = positionResult.first['next_position'] as int;

      // Insert version relationship
      await txn.insert('playlist_version', {
        'version_id': versionID,
        'playlist_id': playlistId,
        'position': nextPosition,
      });
    });
  }

  Future<void> addVersionToPlaylistAt(
    int playlistId,
    int versionID,
    int position,
  ) async {
    final db = await _databaseHelper.database;

    // Insert version relationship
    await db.insert('playlist_version', {
      'version_id': versionID,
      'playlist_id': playlistId,
      'position': position,
    });
  }

  /// Upserts a version's position in a playlist
  Future<void> updatePlaylistVersionPosition(
    int playlistVersionId,
    int newPosition,
  ) async {
    final db = await _databaseHelper.database;

    await db.update(
      'playlist_version',
      {'position': newPosition},
      where: 'id = ?',
      whereArgs: [playlistVersionId],
    );
  }

  Future<void> updateFlowItemPosition(int flowItemId, int newPosition) async {
    final db = await _databaseHelper.database;

    await db.update(
      'flow_item',
      {'position': newPosition},
      where: 'id = ?',
      whereArgs: [flowItemId],
    );
  }

  /// Gets text items of a playlist
  Future<List<PlaylistItem>> _getFlowItemsOfPlaylist(int playlistId) async {
    final db = await _databaseHelper.database;

    final flowItemResults = await db.rawQuery(
      '''
        SELECT id as content_id, position, duration, firebase_id as firebase_id
        FROM flow_item
        WHERE playlist_id = ? 
        ORDER BY position ASC
      ''',
      [playlistId],
    );

    return flowItemResults.map((row) {
      final contentId = row['content_id'] as int;
      final position = row['position'] as int;
      final duration = Duration(seconds: row['duration'] as int);
      final firebaseId = row['firebase_id'] as String;

      return PlaylistItem.flowItem(
        flowItemId: contentId,
        position: position,
        duration: duration,
        flowItemFirebaseId: firebaseId,
      );
    }).toList();
  }

  /// Gets version items of a playlist
  Future<List<PlaylistItem>> _getVersionItemsOfPlaylist(int playlistId) async {
    final db = await _databaseHelper.database;

    final versionResults = await db.rawQuery(
      '''
        SELECT v.id as content_id, position, v.duration, pv.id, v.firebase_id as firebase_id
        FROM playlist_version AS pv JOIN version AS v ON pv.version_id = v.id
        WHERE playlist_id = ? 
        ORDER BY position ASC
      ''',
      [playlistId],
    );

    return versionResults.map((row) {
      final id = row['id'] as int;
      final contentId = row['content_id'] as int;
      final firebaseId = row['firebase_id'] as String?;
      final position = row['position'] as int;
      final duration = Duration(seconds: row['duration'] as int);

      return PlaylistItem.version(
        versionId: contentId,
        position: position,
        id: id,
        duration: duration,
        versionFirebaseId: firebaseId,
      );
    }).toList();
  }
}
