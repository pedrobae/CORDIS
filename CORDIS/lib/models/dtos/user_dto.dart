import 'package:cordis/models/domain/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserDto {
  final String? firebaseId;
  final String username;
  final String email;
  final String? profilePhoto;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;
  final bool isActive;

  const UserDto({
    this.firebaseId,
    required this.username,
    required this.email,
    this.profilePhoto,
    this.createdAt,
    this.updatedAt,
    this.isActive = true,
  });

  factory UserDto.fromFirestore(Map<String, dynamic> json) {
    return UserDto(
      firebaseId: json['uid'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      profilePhoto: json['profilePhoto'] as String?,
      createdAt: json['createdAt'] as Timestamp?,
      updatedAt: json['updatedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': firebaseId,
      'username': username,
      'email': email,
      'profilePhoto': profilePhoto,
      'createdAt':
          createdAt ??
          Timestamp.fromDate(DateTime.now()), // Use current time if not set
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
      createdAt: createdAt?.toDate(),
      updatedAt: updatedAt?.toDate(),
      isActive: isActive,
    );
  }

  UserDto copyWith({
    String? firebaseId,
    String? username,
    String? email,
    String? profilePhoto,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    bool? isActive,
  }) {
    return UserDto(
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
