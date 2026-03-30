import 'package:sqflite/sqflite.dart';

Future<Map<String, int>> insertPlaylists(
  Transaction txn,
  Map<String, int> userIds,
  Map<String, int> versionIds,
) async {
  final now = DateTime.now().toIso8601String();
  final testUserId = userIds['testuser']!;

  int worshipPlaylistId = await txn.insert('playlist', {
    'name': 'Culto Dominical',
    'description': 'Músicas para o culto de domingo',
    'author_id': testUserId,
    'is_public': 0,
    'created_at': now,
    'updated_at': now,
  });

  int eveningPlaylistId = await txn.insert('playlist', {
    'name': 'Culto da Noite',
    'description': 'Seleção especial para cultos noturnos',
    'author_id': testUserId,
    'is_public': 1,
    'created_at': now,
    'updated_at': now,
  });

  // Additional playlist for Maria (vocalist)
  int mariaPlaylistId = await txn.insert('playlist', {
    'name': 'Ministério de Louvor',
    'description': 'Repertório especial para momentos de adoração',
    'author_id': userIds['maria']!,
    'is_public': 0,
    'created_at': now,
    'updated_at': now,
  });

  // Add cipher maps to worship playlist
  await txn.insert('playlist_version', {
    'version_id': versionIds['amazing1'],
    'playlist_id': worshipPlaylistId,
    'position': 1, // After opening text
    'included_at': now,
  });

  await txn.insert('playlist_version', {
    'version_id': versionIds['howgreat1'],
    'playlist_id': worshipPlaylistId,
    'position': 3, // After prayer text
    'included_at': now,
  });

  // Add cipher maps to evening playlist
  await txn.insert('playlist_version', {
    'version_id': versionIds['howgreat1'],
    'playlist_id': eveningPlaylistId,
    'position': 0,
    'included_at': now,
  });

  // Add cipher maps to Maria's playlist
  await txn.insert('playlist_version', {
    'version_id': versionIds['amazing1'],
    'playlist_id': mariaPlaylistId,
    'position': 0,
    'included_at': now,
  });

  // Add text sections to playlists for mixed content
  await txn.insert('playlist_text', {
    'playlist_id': worshipPlaylistId,
    'title': 'Abertura do Culto',
    'content':
        'Bem-vindos ao culto dominical!\n\nAnnúncios:\n- Reunião de oração na quarta-feira às 19h\n- Próximo domingo: Santa Ceia\n- Inscrições abertas para o coral',
    'position': 0, // Before Amazing Grace
    'added_by': testUserId,
    'added_at': now,
  });

  await txn.insert('playlist_text', {
    'playlist_id': worshipPlaylistId,
    'title': 'Momento de Oração',
    'content':
        'Vamos nos dirigir ao Senhor em oração.\n\nMotivos de oração:\n- Pelos enfermos da congregação\n- Pelos missionários\n- Pelas autoridades\n- Pela paz mundial',
    'position': 2, // After How Great Thou Art
    'added_by': testUserId,
    'added_at': now,
  });

  await txn.insert('playlist_text', {
    'playlist_id': eveningPlaylistId,
    'title': 'Reflexão Noturna',
    'content':
        'Uma noite especial de comunhão e adoração.\n\n"Aquietai-vos e sabei que Eu sou Deus" - Salmos 46:10\n\nConvite para um momento de silêncio e reflexão.',
    'position': 1, // After How Great Thou Art
    'added_by': testUserId,
    'added_at': now,
  });

  await txn.insert('playlist_text', {
    'playlist_id': mariaPlaylistId,
    'title': 'Ministração Especial',
    'content':
        'Preparação para o momento de ministração:\n\n1. Verificar microfones\n2. Ajustar instrumentos\n3. Oração em equipe\n4. Começar com adoração espontânea',
    'position': 1, // After Amazing Grace
    'added_by': userIds['maria']!,
    'added_at': now,
  });

  return {
    'worship': worshipPlaylistId,
    'evening': eveningPlaylistId,
    'maria_ministry': mariaPlaylistId,
  };
}

// For backward compatibility with old signature
Future<Map<String, int>> insertPlaylistsLegacy(
  Transaction txn,
  int testUserId,
  Map<String, int> versionIds,
) async {
  final userIds = {'testuser': testUserId};
  final playlists = await insertPlaylists(txn, userIds, versionIds);
  return {'worship': playlists['worship']!, 'evening': playlists['evening']!};
}
