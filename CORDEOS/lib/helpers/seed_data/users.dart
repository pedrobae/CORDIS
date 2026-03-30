import 'package:sqflite/sqflite.dart';

Future<Map<String, int>> insertUsers(Transaction txn) async {
  final now = DateTime.now().toIso8601String();

  // Main test user
  int testUserId = await txn.insert('user', {
    'username': 'testuser',
    'mail': 'test@example.com',
    'created_at': now,
    'updated_at': now,
    'is_active': 1,
  });

  // Band members
  int mariaId = await txn.insert('user', {
    'username': 'maria_santos',
    'mail': 'maria.santos@email.com',
    'profile_photo': null,
    'created_at': now,
    'updated_at': now,
    'is_active': 1,
  });

  int joaoId = await txn.insert('user', {
    'username': 'joao_guitarist',
    'mail': 'joao.silva@email.com',
    'profile_photo': null,
    'created_at': now,
    'updated_at': now,
    'is_active': 1,
  });

  int anaId = await txn.insert('user', {
    'username': 'ana_drummer',
    'mail': 'ana.costa@email.com',
    'profile_photo': null,
    'created_at': now,
    'updated_at': now,
    'is_active': 1,
  });

  int carlosId = await txn.insert('user', {
    'username': 'carlos_bass',
    'mail': 'carlos.oliveira@email.com',
    'profile_photo': null,
    'created_at': now,
    'updated_at': now,
    'is_active': 1,
  });

  int luciaId = await txn.insert('user', {
    'username': 'lucia_keys',
    'mail': 'lucia.ferreira@email.com',
    'profile_photo': null,
    'created_at': now,
    'updated_at': now,
    'is_active': 1,
  });

  int pedroDrumId = await txn.insert('user', {
    'username': 'pedro_percussao',
    'mail': 'pedro.drums@email.com',
    'profile_photo': null,
    'created_at': now,
    'updated_at': now,
    'is_active': 1,
  });

  return {
    'testuser': testUserId,
    'maria': mariaId,
    'joao': joaoId,
    'ana': anaId,
    'carlos': carlosId,
    'lucia': luciaId,
    'pedro': pedroDrumId,
  };
}

// For backward compatibility
Future<int> insertTestUser(Transaction txn) async {
  final users = await insertUsers(txn);
  return users['testuser']!;
}
