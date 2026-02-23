import 'package:cordis/models/domain/cipher/version.dart';
import 'package:cordis/models/dtos/version_dto.dart';

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
      musicKey: json['music_key'] as String? ?? '',
      language: json['language'] as String? ?? 'Portugues',
      createdAt: json['created_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['created_at'] as int)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['updated_at'] as int)
          : null,
      isLocal: true,
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
      tags: version.tags,
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
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt?.millisecondsSinceEpoch,
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
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt?.millisecondsSinceEpoch,
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
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
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

  Cipher mergeWith(Cipher other) {
    return Cipher(
      id: id,
      title: title.isEmpty ? other.title : title,
      author: author.isEmpty ? other.author : author,
      tags: tags.isEmpty ? other.tags : tags,
      musicKey: musicKey.isEmpty ? other.musicKey : musicKey,
      language: language.isEmpty ? other.language : language,
      createdAt: createdAt,
      updatedAt: updatedAt ?? other.updatedAt,
      isLocal: isLocal,
      versions:
          versions, // We don't want to merge versions here, as they are managed separately in the schedule sync process
    );
  }
}
