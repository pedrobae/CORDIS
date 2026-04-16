import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cordeos/models/domain/cipher/section.dart';
import 'package:cordeos/models/domain/cipher/version.dart';
import 'package:cordeos/utils/color.dart';

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
  final List<int> songStructure;
  final Timestamp? updatedAt;
  final Map<int, SectionDto> sections;
  final String? link;

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
    this.link,
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
      link: map['link'] as String?,
      tags: (map['tags'] as List<dynamic>).map((e) => e.toString()).toList(),
      songStructure: (map['songStructure'] as List<dynamic>)
          .map((e) => e as int)
          .toList(),
      updatedAt: map['updatedAt'] as Timestamp?,
      sections: (map['sections'] as Map<int, dynamic>).map(
        (sectionKey, section) => MapEntry(
          sectionKey,
          SectionDto.fromFirestore(Map<String, dynamic>.from(section)),
        ),
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
      'sections': sections.map(
        (key, value) => MapEntry(key, value.toFirestore()),
      ),
      'link': link,
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
      songStructure: (map['songStructure'] as List<int>).toList(),
      updatedAt: map['updatedAt'] != null
          ? (Timestamp.fromMillisecondsSinceEpoch(map['updatedAt'] as int))
          : Timestamp.now(),
      sections: (map['sections'] as Map<int, dynamic>).map(
        (sectionKey, section) => MapEntry(
          sectionKey,
          SectionDto.fromFirestore(Map<String, dynamic>.from(section)),
        ),
      ),
      link: map['link'] as String?,
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
      'sections': sections.map((key, value) => MapEntry(key, value.toCache())),
      'link': link,
    };
  }

  Version toDomain({int? cipherId}) {
    return Version(
      firebaseID: firebaseId,
      versionName: versionName,
      transposedKey: transposedKey,
      songStructure: songStructure,
      duration: Duration(seconds: duration),
      bpm: bpm,
      createdAt: updatedAt?.toDate() ?? DateTime.now(),
      cipherID: cipherId ?? -1,
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
    List<int>? songStructure,
    Timestamp? updatedAt,
    Map<int, SectionDto>? sections,
    String? link,
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
      link: link ?? this.link,
    );
  }
}

class SectionDto {
  final int key;
  final String contentType;
  final String contentText;
  final String color;

  SectionDto({
    required this.key,
    required this.contentType,
    required this.contentText,
    required this.color,
  });

  factory SectionDto.fromFirestore(Map<String, dynamic> map) {
    return SectionDto(
      key: map['key'] as int,
      contentType: map['contentType'] as String,
      contentText: map['contentText'] as String,
      color: map['contentColor'] as String,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'key': key,
      'contentType': contentType,
      'contentText': contentText,
      'contentColor': color,
    };
  }

  Map<String, dynamic> toCache() => toFirestore();

  Section toDomain({int? versionID}) {
    return Section(
      versionID: versionID ?? -1,
      key: key,
      contentType: contentType,
      contentText: contentText,
      contentColor: colorFromHex(color),
    );
  }
}
