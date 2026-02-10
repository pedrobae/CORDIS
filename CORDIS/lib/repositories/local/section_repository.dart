import 'package:sqflite/sqflite.dart';

import 'package:cordis/models/domain/cipher/section.dart';

import 'package:cordis/helpers/database.dart';

class SectionRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  // ===== CREATE =====
  /// Inserts a section to the SQLite database
  /// Returns the local ID of the inserted section
  Future<int> insertSection(Section section) async {
    final db = await _databaseHelper.database;
    return await db.insert(
      'section',
      section.toSqlite()..['version_id'] = section.versionId,
    );
  }

  Future<int> upsertSection(Section section) async {
    final db = await _databaseHelper.database;
    return await db.insert(
      'section',
      section.toSqlite()..['version_id'] = section.versionId,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ===== READ =====
  /// Gets all sections of a version
  Future<Map<String, Section>> getSections(int versionId) async {
    final db = await _databaseHelper.database;
    final results = await db.query(
      'section',
      where: 'version_id = ?',
      whereArgs: [versionId],
      orderBy: 'content_code',
    );

    final sections = <String, Section>{};
    for (var row in results) {
      sections[row['content_code'] as String] = Section.fromSqLite(row);
    }
    return sections;
  }

  // ===== UPDATE =====
  /// Replaces entire section
  Future<void> updateSection(Section section) async {
    final db = await _databaseHelper.database;
    await db.update(
      'section',
      section.toSqlite(),
      where: 'version_id = ? AND content_code = ?',
      whereArgs: [section.versionId, section.contentCode],
    );
  }

  // ===== DELETE =====
  /// Deletes section by its local ID
  Future<void> deleteSection(int id) async {
    final db = await _databaseHelper.database;
    await db.delete('section', where: 'id = ?', whereArgs: [id]);
  }
}
