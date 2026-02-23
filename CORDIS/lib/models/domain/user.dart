import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cordis/models/dtos/user_dto.dart';

class User {
  final int? id;
  final String? firebaseId;
  final String username;
  final String email;
  final String? profilePhoto;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isActive;

  const User({
    this.id,
    required this.firebaseId,
    required this.username,
    required this.email,
    this.profilePhoto,
    this.createdAt,
    this.updatedAt,
    this.isActive = true,
  });

  factory User.fromSqlite(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      firebaseId: json['firebase_id'] as String?,
      username: json['username'] as String,
      email: json['email'] as String,
      profilePhoto: json['profile_photo'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['created_at'] as int)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['updated_at'] as int)
          : null,
      isActive: (json['is_active'] as int? ?? 1) == 1,
    );
  }

  Map<String, dynamic> toSQLite() {
    return {
      'username': username,
      'email': email,
      'profile_photo': profilePhoto,
      'firebase_id': firebaseId,
      'created_at': createdAt?.millisecondsSinceEpoch,
      'updated_at': updatedAt?.millisecondsSinceEpoch,
      'is_active': isActive ? 1 : 0,
    };
  }

  UserDto toDto() {
    return UserDto(
      firebaseId: firebaseId,
      username: username,
      email: email,
      profilePhoto: profilePhoto,
      createdAt: Timestamp.fromDate(createdAt ?? DateTime.now()),
      updatedAt: Timestamp.fromDate(updatedAt ?? DateTime.now()),
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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
