import 'package:sqflite/sqflite.dart';

Future<void> insertCollaborators(
  Transaction txn,
  Map<String, int> userIds,
  Map<String, int> playlistIds,
) async {
  final now = DateTime.now().toIso8601String();
  final testUserId = userIds['testuser']!;

  // Worship playlist collaborators - Complete band setup
  await txn.insert('user_playlist', {
    'user_id': userIds['maria']!,
    'playlist_id': playlistIds['worship']!,
    'role': 'Vocalista',
    'added_by': testUserId,
    'added_at': now,
  });

  await txn.insert('user_playlist', {
    'user_id': userIds['joao']!,
    'playlist_id': playlistIds['worship']!,
    'role': 'Guitarrista',
    'added_by': testUserId,
    'added_at': now,
  });

  await txn.insert('user_playlist', {
    'user_id': userIds['carlos']!,
    'playlist_id': playlistIds['worship']!,
    'role': 'Baixista',
    'added_by': testUserId,
    'added_at': now,
  });

  await txn.insert('user_playlist', {
    'user_id': userIds['ana']!,
    'playlist_id': playlistIds['worship']!,
    'role': 'Baterista',
    'added_by': testUserId,
    'added_at': now,
  });

  await txn.insert('user_playlist', {
    'user_id': userIds['lucia']!,
    'playlist_id': playlistIds['worship']!,
    'role': 'Tecladista',
    'added_by': testUserId,
    'added_at': now,
  });

  // Evening playlist collaborators - Smaller acoustic setup
  await txn.insert('user_playlist', {
    'user_id': userIds['maria']!,
    'playlist_id': playlistIds['evening']!,
    'role': 'Vocalista',
    'added_by': testUserId,
    'added_at': now,
  });

  await txn.insert('user_playlist', {
    'user_id': userIds['joao']!,
    'playlist_id': playlistIds['evening']!,
    'role': 'Violão',
    'added_by': testUserId,
    'added_at': now,
  });

  await txn.insert('user_playlist', {
    'user_id': userIds['pedro']!,
    'playlist_id': playlistIds['evening']!,
    'role': 'Percussão',
    'added_by': testUserId,
    'added_at': now,
  });

  await txn.insert('user_playlist', {
    'user_id': userIds['lucia']!,
    'playlist_id': playlistIds['evening']!,
    'role': 'Piano',
    'added_by': testUserId,
    'added_at': now,
  });
}
