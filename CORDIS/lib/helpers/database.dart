import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      String path = join(await getDatabasesPath(), 'cipher_app.db');

      final db = await openDatabase(
        path,
        version: 15,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade, // Handle migrations
      );

      // Enable foreign key constraints to enforce CASCADE delete
      await db.execute('PRAGMA foreign_keys = ON');

      return db;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create tag table
    await db.execute('''
      CREATE TABLE tag (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Create cipher table
    await db.execute('''
      CREATE TABLE cipher (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        author TEXT,
        music_key TEXT,
        language TEXT DEFAULT 'por',
        firebase_id TEXT,
        is_deleted BOOLEAN DEFAULT 0,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Create cipher_tags junction table
    await db.execute('''
      CREATE TABLE cipher_tags (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tag_id INTEGER NOT NULL,
        cipher_id INTEGER NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (tag_id) REFERENCES tag (id) ON DELETE CASCADE,
        FOREIGN KEY (cipher_id) REFERENCES cipher (id) ON DELETE CASCADE,
        UNIQUE(tag_id, cipher_id)
      )
    ''');

    // Create version table (renamed from cipher_map)
    await db.execute('''
      CREATE TABLE version (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cipher_id INTEGER NOT NULL,
        song_structure TEXT NOT NULL,
        duration INTEGER DEFAULT 0,
        bpm INTEGER DEFAULT 0,
        transposed_key TEXT,
        version_name TEXT,
        firebase_cipher_id TEXT,
        firebase_id TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (cipher_id) REFERENCES cipher (id) ON DELETE CASCADE
      )
    ''');

    // Create section table (renamed from map_content)
    await db.execute('''
      CREATE TABLE section (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        version_id INTEGER NOT NULL,
        content_type TEXT NOT NULL,
        content_code VARCHAR NOT NULL,
        content_text TEXT NOT NULL,
        content_color TEXT,
        FOREIGN KEY (version_id) REFERENCES version (id) ON DELETE CASCADE
      )
    ''');

    // Create user table
    await db.execute('''
      CREATE TABLE user (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        email TEXT UNIQUE NOT NULL,
        profile_photo TEXT,
        firebase_id TEXT UNIQUE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        is_active BOOLEAN DEFAULT 1
      )
    ''');

    // Create playlist table
    await db.execute('''
      CREATE TABLE playlist (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        author_id STRING NOT NULL,
        firebase_id TEXT UNIQUE,
        FOREIGN KEY (author_id) REFERENCES user (id) ON DELETE CASCADE
      )
    ''');

    // Create playlist_version table (playlists contain specific cipher versions)
    await db.execute('''
      CREATE TABLE playlist_version (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        version_id INTEGER NOT NULL,
        playlist_id INTEGER NOT NULL,
        firebase_content_id TEXT,
        position INTEGER NOT NULL,
        included_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (version_id) REFERENCES version (id) ON DELETE CASCADE,
        FOREIGN KEY (playlist_id) REFERENCES playlist (id) ON DELETE CASCADE,
        UNIQUE(playlist_id, position)
      )
    ''');

    // Create user_playlist table for collaborators
    await db.execute('''
      CREATE TABLE user_playlist (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        playlist_id INTEGER NOT NULL,
        role TEXT NOT NULL DEFAULT 'collaborator',
        added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        added_by INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES user (id) ON DELETE CASCADE,
        FOREIGN KEY (playlist_id) REFERENCES playlist (id) ON DELETE CASCADE,
        FOREIGN KEY (added_by) REFERENCES user (id) ON DELETE CASCADE,
        UNIQUE(user_id, playlist_id)
      )
    ''');

    // Create flow_item table, for written playlist Items
    await db.execute('''
      CREATE TABLE flow_item (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        playlist_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        firebase_id TEXT,
        position INTEGER NOT NULL DEFAULT 0,
        duration INTEGER DEFAULT 0,
        added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (playlist_id) REFERENCES playlist (id) ON DELETE CASCADE
      )
    ''');

    // Create schedule table
    await db.execute('''
      CREATE TABLE schedule (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        playlist_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        date TEXT NOT NULL,
        time TEXT NOT NULL,
        location TEXT,
        room_venue TEXT,
        annotations TEXT,
        firebase_id TEXT UNIQUE,
        owner_firebase_id TEXT NOT NULL,
        share_code TEXT,
        is_public BOOLEAN DEFAULT 0,
        FOREIGN KEY (playlist_id) REFERENCES playlist (id) ON DELETE CASCADE
      )
    ''');

    // Create role table
    await db.execute('''  
      CREATE TABLE role (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        schedule_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        FOREIGN KEY (schedule_id) REFERENCES schedule (id) ON DELETE CASCADE
      ) 
    ''');

    // Create role_member table
    await db.execute('''  
      CREATE TABLE role_member (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        role_id INTEGER NOT NULL,
        member_id INTEGER NOT NULL,
        FOREIGN KEY (role_id) REFERENCES role (id) ON DELETE CASCADE,
        FOREIGN KEY (member_id) REFERENCES user (id) ON DELETE CASCADE
      ) 
    ''');

    // Create indexes for better performance
    await db.execute(
      'CREATE INDEX idx_cipher_tags_cipher_id ON cipher_tags(cipher_id)',
    );
    await db.execute(
      'CREATE INDEX idx_cipher_tags_tag_id ON cipher_tags(tag_id)',
    );
    await db.execute(
      'CREATE INDEX idx_version_cipher_id ON version(cipher_id)',
    );
    await db.execute(
      'CREATE INDEX idx_section_version_id ON section(version_id)',
    );
    await db.execute(
      'CREATE INDEX idx_playlist_author_id ON playlist(author_id)',
    );
    await db.execute(
      'CREATE INDEX idx_playlist_version_playlist_id ON playlist_version(playlist_id)',
    );
    await db.execute(
      'CREATE INDEX idx_playlist_version_version_id ON playlist_version(version_id)',
    );
    await db.execute(
      'CREATE INDEX idx_user_playlist_user_id ON user_playlist(user_id)',
    );
    await db.execute(
      'CREATE INDEX idx_user_playlist_playlist_id ON user_playlist(playlist_id)',
    );
    // For user lookups
    await db.execute('CREATE INDEX idx_user_google_id ON user(google_id)');
    await db.execute('CREATE INDEX idx_user_mail ON user(mail)');
    await db.execute(
      'CREATE UNIQUE INDEX idx_user_firebase_id ON user(firebase_id)',
    );
    // For cipher lookups
    await db.execute(
      'CREATE UNIQUE INDEX idx_cipher_firebase_id ON cipher(firebase_id)',
    );
    // For version lookups
    await db.execute(
      'CREATE UNIQUE INDEX idx_version_firebase_id ON version(firebase_id)',
    );
    await db.execute(
      'CREATE INDEX idx_version_firebase_cipher_id ON version(firebase_cipher_id)',
    );
    // For content queries
    await db.execute(
      'CREATE INDEX idx_section_content_type ON section(content_type)',
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle migrations between database versions
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE cipher ADD COLUMN duration TEXT');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE cipher RENAME COLUMN tempo TO bpm');
    }
    if (oldVersion < 4) {
      await db.execute(
        ''' CREATE TABLE schedule (
          id INTEGER PRIMARY KEY AUTOINCREMENT, 
          playlist_id INTEGER NOT NULL, 
          date TEXT NOT NULL, 
          time TEXT NOT NULL, 
          location TEXT, 
          firebase_id TEXT UNIQUE, 
          FOREIGN KEY (playlist_id) REFERENCES playlist (id) ON DELETE CASCADE)''',
      );
    }
    if (oldVersion < 5) {
      // REMOVE time control from playlist table
      await db.execute('ALTER TABLE playlist DROP COLUMN is_public');
      await db.execute('ALTER TABLE playlist DROP COLUMN share_code');
      await db.execute('ALTER TABLE playlist DROP COLUMN created_at');
      await db.execute('ALTER TABLE playlist DROP COLUMN updated_at');
    }
    if (oldVersion < 6) {
      // CREATE ROLE AND ROLE_MEMBER TABLES
      await db.execute(
        ''' CREATE TABLE role (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          schedule_id INTEGER NOT NULL,
          name TEXT NOT NULL,
          FOREIGN KEY (schedule_id) REFERENCES schedule (id) ON DELETE CASCADE) ''',
      );
      await db.execute(''' CREATE TABLE role_member (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          role_id INTEGER NOT NULL,
          member_id INTEGER NOT NULL,
          FOREIGN KEY (role_id) REFERENCES role (id) ON DELETE CASCADE,
          FOREIGN KEY (member_id) REFERENCES user (id) ON DELETE CASCADE) ''');
    }
    if (oldVersion < 7) {
      // CHANGE BPM TYPE FROM TEXT TO INTEGER IN CIPHER TABLE
      await db.execute(
        'ALTER TABLE cipher ADD COLUMN bpm_temp INTEGER DEFAULT 0',
      );

      // Copy and convert existing data
      final List<Map<String, Object?>> rows = await db.rawQuery(
        'SELECT id, bpm FROM cipher',
      );
      for (final row in rows) {
        final int id = row['id'] as int;
        final String? bpmString = row['bpm'] as String?;
        final int bpmValue = int.tryParse(bpmString ?? '') ?? 0;

        await db.rawUpdate('UPDATE cipher SET bpm_temp = ? WHERE id = ?', [
          bpmValue,
          id,
        ]);
      }

      // Remove old bpm column
      await db.execute('ALTER TABLE cipher DROP COLUMN bpm');

      // Rename temp column to bpm
      await db.execute('ALTER TABLE cipher RENAME COLUMN bpm_temp TO bpm');
    }
    if (oldVersion < 8) {
      // REMOVE DESCRIPTION COLUMN FROM PLAYLIST TABLE
      await db.execute("ALTER TABLE playlist DROP COLUMN description");
    }
    if (oldVersion < 9) {
      // CHANGE BPM FROM CIPHER TABLE TO VERSION TABLE
      await db.execute('ALTER TABLE version ADD COLUMN bpm INTEGER DEFAULT 0');
      // DROP EXISTING DATA IN CIPHER TABLE AND DROP COLUMN
      await db.execute('ALTER TABLE cipher DROP COLUMN bpm');
    }
    if (oldVersion < 10) {
      // ADD DURATION COLUMN TO PLAYLIST_TEXT TABLE
      await db.execute(
        'ALTER TABLE playlist_text ADD COLUMN duration INTEGER DEFAULT 0',
      );
    }
    if (oldVersion < 11) {
      // ADD NAME COLUMN TO SCHEDULE TABLE
      await db.execute(
        'ALTER TABLE schedule ADD COLUMN name TEXT NOT NULL DEFAULT ""',
      );

      // ADD ANNOTATIONS COLUMN TO SCHEDULE TABLE
      await db.execute('ALTER TABLE schedule ADD COLUMN annotations TEXT');

      // ADD OWNER_FIREBASE_ID COLUMN TO SCHEDULE TABLE
      await db.execute(
        'ALTER TABLE schedule ADD COLUMN owner_firebase_id TEXT NOT NULL DEFAULT ""',
      );
    }
    if (oldVersion < 12) {
      // ADD ROOM_VENUE COLUMN TO SCHEDULE TABLE
      await db.execute('ALTER TABLE schedule ADD COLUMN room_venue TEXT');
    }
    if (oldVersion < 13) {
      // RENAME PLAYLIST_TEXT TABLE TO FLOW_ITEM
      await db.execute('ALTER TABLE playlist_text RENAME TO flow_item');
    }
    if (oldVersion < 14) {
      // ADD SHARE_CODE AND IS_PUBLIC COLUMNS TO SCHEDULE TABLE
      await db.execute('ALTER TABLE schedule ADD COLUMN share_code TEXT');
      await db.execute(
        'ALTER TABLE schedule ADD COLUMN is_public BOOLEAN DEFAULT 0',
      );
    }
    if (oldVersion < 15) {
      // RENAMED mail TO email IN USER TABLE
      await db.execute('ALTER TABLE user RENAME COLUMN mail TO email');
    }
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }

  // Helper method to reset database (for development)
  Future<void> resetDatabase() async {
    try {
      // First close any existing database connection
      if (_database != null) {
        await _database!.close();
        _database = null;
      }

      // Get the database path
      String path = join(await getDatabasesPath(), 'cipher_app.db');

      // Delete the database file completely
      await databaseFactory.deleteDatabase(path);

      // Re-initialize database
      await database;
    } catch (e) {
      rethrow;
    }
  }
}
