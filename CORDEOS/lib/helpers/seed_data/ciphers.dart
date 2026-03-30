import 'package:sqflite/sqflite.dart';

Future<Map<String, int>> insertCiphers(Transaction txn) async {
  final now = DateTime.now().toIso8601String();

  int hymn1Id = await txn.insert('cipher', {
    'title': 'Amazing Grace',
    'author': 'John Newton',
    'tempo': 'Slow',
    'music_key': 'G',
    'language': 'en',
    'created_at': now,
    'updated_at': now,
  });

  int hymn2Id = await txn.insert('cipher', {
    'title': 'How Great Thou Art',
    'author': 'Carl Boberg',
    'tempo': 'Medium',
    'music_key': 'D',
    'language': 'en',
    'created_at': now,
    'updated_at': now,
  });

  return {'amazing': hymn1Id, 'howgreat': hymn2Id};
}
