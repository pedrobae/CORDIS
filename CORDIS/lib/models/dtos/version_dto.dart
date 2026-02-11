import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cordis/models/domain/cipher/section.dart';
import 'package:cordis/models/domain/cipher/version.dart';

/// DTO para metadados de version (camada de separação entre a nuvem e o armazenamento local).
class VersionDto {
  final String? firebaseId; // ID na nuvem (Firebase)
  final String title;
  final String author;
  final int bpm;
  final int duration;
  final String language;
  final List<String> tags;
  final String versionName;
  final String originalKey;
  final String? transposedKey;
  final List<String> songStructure;
  final Timestamp? updatedAt;
  final Map<String, Map<String, String>> sections;

  VersionDto({
    this.firebaseId,
    required this.versionName,
    required this.songStructure,
    this.updatedAt,
    required this.sections,
    required this.title,
    required this.author,
    required this.bpm,
    required this.duration,
    required this.language,
    this.tags = const [],
    required this.originalKey,
    this.transposedKey,
  });

  factory VersionDto.fromFirestore(Map<String, dynamic> map, String id) {
    return VersionDto(
      firebaseId: id,
      author: map['author'] as String,
      title: map['title'] as String,
      duration: map['duration'] as int? ?? 0,
      bpm: map['bpm'] as int? ?? 0,
      language: map['language'] as String,
      versionName: map['versionName'] as String,
      originalKey: map['originalKey'] as String,
      transposedKey: map['transposedKey'] as String?,
      tags: (map['tags'] as List<dynamic>).map((e) => e.toString()).toList(),
      songStructure: (map['songStructure'] as List<dynamic>)
          .map((e) => e.toString())
          .toList(),
      updatedAt: map['updatedAt'] as Timestamp?,
      sections: (map['sections'] as Map<String, dynamic>).map(
        (sectionsCode, section) =>
            MapEntry(sectionsCode, Map<String, String>.from(section)),
      ),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'author': author,
      'title': title,
      'duration': duration,
      'bpm': bpm,
      'language': language,
      'versionName': versionName,
      'originalKey': originalKey,
      'transposedKey': transposedKey,
      'tags': tags,
      'songStructure': songStructure,
      'updatedAt': updatedAt ?? Timestamp.now(),
      'sections': sections,
    };
  }

  factory VersionDto.fromCache(Map<String, dynamic> map) {
    return VersionDto(
      firebaseId: map['firebaseId'] as String?,
      author: map['author'] as String,
      title: map['title'] as String,
      duration: map['duration'] as int? ?? 0,
      bpm: map['bpm'] as int? ?? 0,
      language: map['language'] as String,
      versionName: map['versionName'] as String,
      originalKey: map['originalKey'] as String,
      transposedKey: map['transposedKey'] as String?,
      tags: (map['tags'] as List<dynamic>).map((e) => e.toString()).toList(),
      songStructure: (map['songStructure'] as List<dynamic>)
          .map((e) => e.toString())
          .toList(),
      updatedAt: map['updatedAt'] != null
          ? (Timestamp.fromMillisecondsSinceEpoch(map['updatedAt'] as int))
          : Timestamp.now(),
      sections: (map['sections'] as Map<String, dynamic>).map(
        (sectionsCode, section) =>
            MapEntry(sectionsCode, Map<String, String>.from(section)),
      ),
    );
  }

  /// To JSON for caching (weekly public versions)
  Map<String, dynamic> toCache() {
    return {
      'firebaseId': firebaseId,
      'author': author,
      'title': title,
      'duration': duration,
      'bpm': bpm,
      'language': language,
      'versionName': versionName,
      'originalKey': originalKey,
      'transposedKey': transposedKey,
      'tags': tags,
      'songStructure': songStructure,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
      'sections': sections,
    };
  }

  Version toDomain({int? cipherId}) {
    return Version(
      firebaseId: firebaseId,
      versionName: versionName,
      transposedKey: transposedKey,
      songStructure: songStructure,
      duration: Duration(seconds: duration),
      bpm: bpm,
      createdAt: updatedAt?.toDate() ?? DateTime.now(),
      sections: sections.map(
        (sectionsCode, section) =>
            MapEntry(sectionsCode, Section.fromFirestore(section)),
      ),
      cipherId: cipherId ?? -1,
    );
  }

  VersionDto copyWith({
    String? firebaseId,
    String? title,
    String? author,
    int? duration,
    int? bpm,
    String? language,
    List<String>? tags,
    String? versionName,
    String? originalKey,
    String? transposedKey,
    List<String>? songStructure,
    Timestamp? updatedAt,
    Map<String, Map<String, String>>? sections,
  }) {
    return VersionDto(
      firebaseId: firebaseId ?? this.firebaseId,
      title: title ?? this.title,
      author: author ?? this.author,
      duration: duration ?? this.duration,
      bpm: bpm ?? this.bpm,
      language: language ?? this.language,
      tags: tags ?? this.tags,
      versionName: versionName ?? this.versionName,
      originalKey: originalKey ?? this.originalKey,
      transposedKey: transposedKey ?? this.transposedKey,
      songStructure: songStructure ?? this.songStructure,
      updatedAt: updatedAt ?? this.updatedAt,
      sections: sections ?? this.sections,
    );
  }
}
