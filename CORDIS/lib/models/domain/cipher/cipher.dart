import 'package:cordis/models/domain/cipher/version.dart';
import 'package:cordis/models/dtos/version_dto.dart';
import 'package:cordis/utils/date_utils.dart';

class Cipher {
  final int id;
  final String title;
  final String author;
  final String musicKey;
  final String language;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isLocal;
  final List<String> tags;
  final List<Version> versions;

  const Cipher({
    required this.id,
    required this.title,
    required this.author,
    this.tags = const [],
    required this.musicKey,
    required this.language,
    required this.createdAt,
    this.updatedAt,
    required this.isLocal,
    this.versions = const [],
  });

  // From JSON constructor for database
  factory Cipher.fromSqLite(Map<String, dynamic> json) {
    return Cipher(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      author: json['author'] as String? ?? '',
      tags: json['tags'] != null ? List<String>.from(json['tags']) : const [],
      musicKey: json['music_key'] as String? ?? '',
      language: json['language'] as String? ?? 'por',
      createdAt:
          DateTimeUtils.parseDateTime(json['created_at']) ?? DateTime.now(),
      updatedAt: DateTimeUtils.parseDateTime(json['updated_at']),
      isLocal: json['isLocal'] as bool? ?? true, // Default to true for local DB
      versions: json['maps'] != null
          ? (json['maps'] as List).map((m) => Version.fromSqLite(m)).toList()
          : const [],
    );
  }

  factory Cipher.fromVersionDto(VersionDto version) {
    return Cipher(
      id: -1,
      title: version.title,
      author: version.author,
      musicKey: version.originalKey,
      language: version.language,
      createdAt: version.updatedAt?.toDate() ?? DateTime.now(),
      isLocal: false,
    );
  }

  bool get isNew => id == -1;

  // Empty Cipher factory
  factory Cipher.empty() {
    return Cipher(
      id: -1,
      title: '',
      author: '',
      musicKey: 'C',
      language: 'pt-BR',
      isLocal: true,
      tags: [],
      versions: [],
      createdAt: DateTime.now(),
    );
  }

  // To JSON for database
  Map<String, dynamic> toSqLite({bool isNew = false}) {
    return {
      'id': isNew ? null : id,
      'title': title,
      'author': author,
      'music_key': musicKey,
      'language': language,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // To JSON for caching
  Map<String, dynamic> toCache() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'music_key': musicKey,
      'language': language,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'isLocal': false,
      'tags': tags,
      'versions': versions,
    };
  }

  Map<String, dynamic> toMetadata() {
    return {
      'title': title,
      'author': author,
      'originalKey': musicKey,
      'language': language,
      'updatedAt': updatedAt,
      'tags': tags,
    };
  }

  Cipher copyWith({
    int? id,
    String? firebaseId,
    String? title,
    String? author,
    List<String>? tags,
    String? musicKey,
    String? language,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isLocal,
    List<Version>? versions,
    String? duration,
  }) {
    return Cipher(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      tags: tags ?? this.tags,
      musicKey: musicKey ?? this.musicKey,
      language: language ?? this.language,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isLocal: isLocal ?? this.isLocal,
      versions: versions ?? this.versions,
    );
  }
}
