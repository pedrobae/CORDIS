import '../helpers/database.dart';
import '../models/domain/playlist/flow_item.dart';

class FlowItemRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  // ===== CREATE =====
  Future<int> createFlowItem(FlowItem flowItem) async {
    final db = await _databaseHelper.database;

    return await db.insert('flow_item', flowItem.toSQLite(flowItem));
  }

  // ===== READ =====
  Future<FlowItem?> getFlowItem(int id) async {
    final db = await _databaseHelper.database;

    final results = await db.query(
      'flow_item',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (results.isNotEmpty) {
      return FlowItem.fromFirestore(results.first);
    }
    return null;
  }

  Future<FlowItem?> getFlowItemByFirebaseId(String firebaseId) async {
    final db = await _databaseHelper.database;

    final results = await db.query(
      'flow_item',
      where: 'firebase_id = ?',
      whereArgs: [firebaseId],
    );

    if (results.isNotEmpty) {
      return FlowItem.fromFirestore(results.first);
    }
    return null;
  }

  Future<Map<int, FlowItem>> getFlowItemsByIds(List<int> ids) async {
    final db = await _databaseHelper.database;
    Map<int, FlowItem> flowItems = {};

    final placeholders = List.filled(ids.length, '?').join(',');
    final results = await db.query(
      'flow_item',
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );

    for (final row in results) {
      flowItems[row['id'] as int] = FlowItem.fromFirestore(row);
    }

    return flowItems;
  }

  Future<List<FlowItem>> getFlowItemsByPlaylistId(int playlistId) async {
    final db = await _databaseHelper.database;

    final results = await db.query(
      'flow_item',
      where: 'playlist_id = ?',
      whereArgs: [playlistId],
      orderBy: 'position ASC',
    );

    return results.map((row) => FlowItem.fromFirestore(row)).toList();
  }

  // ===== UPDATE =====
  Future<void> updateFlowItem(
    int id, {
    String? title,
    String? content,
    int? position,
    int? duration,
  }) async {
    final db = await _databaseHelper.database;

    await db.transaction((txn) async {
      Map<String, dynamic> updates = {};

      if (title != null) updates['title'] = title;
      if (content != null) updates['content'] = content;
      if (position != null) updates['position'] = position;
      if (duration != null) updates['duration'] = duration;

      if (updates.isNotEmpty) {
        final result = await txn.update(
          'flow_item',
          updates,
          where: 'id = ?',
          whereArgs: [id],
        );

        if (result == 0) {
          throw Exception(
            'Failed to update text section with id $id - no rows affected',
          );
        }
      }
    });
  }

  // ===== DELETE =====
  Future<void> deleteFlowItem(int id) async {
    final db = await _databaseHelper.database;

    await db.transaction((txn) async {
      // First, get the position and playlist_id of the item being deleted
      final result = await txn.query(
        'flow_item',
        columns: ['position', 'playlist_id'],
        where: 'id = ?',
        whereArgs: [id],
      );

      if (result.isNotEmpty) {
        final deletedPosition = result.first['position'] as int;
        final playlistId = result.first['playlist_id'] as int;

        // Delete the text section
        await txn.delete('flow_item', where: 'id = ?', whereArgs: [id]);

        // Adjust positions of items that come after the deleted item
        await txn.rawUpdate(
          'UPDATE flow_item SET position = position - 1 WHERE playlist_id = ? AND position > ?',
          [playlistId, deletedPosition],
        );

        // Also adjust positions in playlist_version table for the same playlist
        await txn.rawUpdate(
          'UPDATE playlist_version SET position = position - 1 WHERE playlist_id = ? AND position > ?',
          [playlistId, deletedPosition],
        );
      }
    });
  }
}
