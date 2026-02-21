import 'package:cordis/models/dtos/user_dto.dart';
import 'package:cordis/utils/date_utils.dart';

class User {
  final int? id;
  final String? firebaseId;
  final String username;
  final String email;
  final String? profilePhoto;
  final String? googleId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isActive;

  const User({
    this.id,
    required this.firebaseId,
    required this.username,
    required this.email,
    this.profilePhoto,
    this.googleId,
    this.createdAt,
    this.updatedAt,
    this.isActive = true,
  });

  factory User.fromSqlite(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      firebaseId: json['firebase_id'] as String?,
      username: json['username'] as String,
      email: json['mail'] as String,
      profilePhoto: json['profile_photo'] as String?,
      googleId: json['google_id'] as String?,
      createdAt: DateTimeUtils.parseDateTime(json['created_at']),
      updatedAt: DateTimeUtils.parseDateTime(json['updated_at']),
      isActive: (json['is_active'] as int? ?? 1) == 1,
    );
  }

  Map<String, dynamic> toSQLite() {
    return {
      'username': username,
      'mail': email,
      'profile_photo': profilePhoto,
      'google_id': googleId,
      'firebase_id': firebaseId,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_active': isActive ? 1 : 0,
    };
  }

  UserDto toDto() {
    return UserDto(
      firebaseId: firebaseId,
      username: username,
      email: email,
      profilePhoto: profilePhoto,
      googleId: googleId,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isActive: isActive,
    );
  }

  User mergeWith(User other) {
    return User(
      id: id,
      firebaseId: firebaseId ?? other.firebaseId,
      username: username.isNotEmpty ? username : other.username,
      email: email.isNotEmpty ? email : other.email,
      profilePhoto: profilePhoto ?? other.profilePhoto,
      googleId: googleId ?? other.googleId,
      createdAt: createdAt ?? other.createdAt,
      updatedAt: updatedAt ?? other.updatedAt,
      isActive: isActive,
    );
  }

  User copyWith({
    int? id,
    String? firebaseId,
    String? username,
    String? email,
    String? profilePhoto,
    String? googleId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return User(
      id: id ?? this.id,
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
