import 'package:sqflite/sqflite.dart';

Future<Map<String, int>> insertTags(Transaction txn) async {
  final now = DateTime.now().toIso8601String();
  final classicId = await txn.insert('tag', {'title': 'Classic', 'created_at': now});
  final popularId = await txn.insert('tag', {'title': 'Popular', 'created_at': now});
  return {'classic': classicId, 'popular': popularId};
}
