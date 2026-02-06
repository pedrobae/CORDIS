import 'package:cordis/models/domain/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cordis/utils/date_utils.dart';

class UserDto {
  final String? firebaseId;
  final String username;
  final String email;
  final String? profilePhoto;
  final String? googleId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isActive;

  const UserDto({
    this.firebaseId,
    required this.username,
    required this.email,
    this.profilePhoto,
    this.googleId,
    this.createdAt,
    this.updatedAt,
    this.isActive = true,
  });

  factory UserDto.fromFirestore(Map<String, dynamic> json, String id) {
    return UserDto(
      firebaseId: id,
      username: json['username'] as String,
      email: json['email'] as String,
      profilePhoto: json['profilePhoto'] as String?,
      googleId: json['googleId'] as String?,
      createdAt: DateTimeUtils.parseDateTime(json['createdAt']),
      updatedAt: DateTimeUtils.parseDateTime(json['updatedAt']),
      isActive: (json['isActive'] as bool?) ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'username': username,
      'mail': email,
      'profilePhoto': profilePhoto,
      'googleId': googleId,
      'createdAt': DateTimeUtils.formatDate(createdAt ?? DateTime.now()),
      'updatedAt':
          FieldValue.serverTimestamp(), // Server timestamp to avoid client clock issues
      'isActive': isActive,
    };
  }

  factory UserDto.fromSchedule(Map<String, dynamic> json) {
    return UserDto(
      firebaseId: json['id'] as String?,
      username: json['username'] as String,
      email: json['email'] as String,
    );
  }

  Map<String, String> toSchedule() {
    return {'id': firebaseId ?? '', 'username': username, 'email': email};
  }

  User toDomain() {
    return User(
      firebaseId: firebaseId!,
      username: username,
      email: email,
      profilePhoto: profilePhoto,
      googleId: googleId,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isActive: isActive,
    );
  }

  UserDto copyWith({
    String? firebaseId,
    String? username,
    String? email,
    String? profilePhoto,
    String? googleId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return UserDto(
      firebaseId: firebaseId ?? this.firebaseId,
      username: username ?? this.username,
      email: email ?? this.email,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      googleId: googleId ?? this.googleId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
