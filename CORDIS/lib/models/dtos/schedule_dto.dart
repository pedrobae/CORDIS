import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cordis/helpers/codes.dart';
import 'package:cordis/models/domain/schedule.dart';
import 'package:cordis/models/dtos/playlist_dto.dart';
import 'package:cordis/models/dtos/user_dto.dart';
import 'package:flutter/material.dart';

class ScheduleDto {
  final String? firebaseId;
  final String ownerFirebaseId;
  final String name;
  final Timestamp datetime;
  final String location;
  final String? roomVenue;
  final String? annotations;
  final PlaylistDto playlist;
  final List<RoleDto> roles;
  final String shareCode;

  ScheduleDto({
    this.firebaseId,
    required this.ownerFirebaseId,
    required this.name,
    required this.datetime,
    required this.location,
    this.roomVenue,
    this.annotations,
    required this.playlist,
    required this.roles,
    required this.shareCode,
  });

  factory ScheduleDto.fromFirestore(Map<String, dynamic> json, String id) {
    return ScheduleDto(
      firebaseId: id,
      ownerFirebaseId: json['ownerId'] as String,
      name: json['name'] as String,
      datetime: json['datetime'] as Timestamp,
      location: json['location'] as String,
      roomVenue: json['roomVenue'] as String?,
      annotations: json['annotations'] as String?,
      playlist: PlaylistDto.fromFirestore(
        json['playlist'] as Map<String, dynamic>,
      ),
      roles: (json['roles'] as List<dynamic>)
          .map((role) => RoleDto.fromFirestore(role as Map<String, dynamic>))
          .toList(),
      shareCode: json['shareCode'] as String? ?? generateShareCode(),
    );
  }

  Map<String, dynamic> toFirestore() {
    final collaborators = roles
        .expand((role) => role.users.expand((user) => [user.firebaseId ?? '']))
        .toSet()
        .toList();

    collaborators.remove(''); // Remove any empty IDs

    return {
      'ownerId': ownerFirebaseId,
      'name': name,
      'datetime': datetime,
      'location': location,
      'roomVenue': roomVenue,
      'annotations': annotations,
      'playlist': playlist.toFirestore(),
      'roles': roles.map((role) => role.toFirestore()).toList(),
      'shareCode': shareCode,
      'collaborators': collaborators,
    };
  }

  Map<String, dynamic> toCache() {
    return {
      'firebaseId': firebaseId,
      'ownerId': ownerFirebaseId,
      'name': name,
      'datetime': datetime.millisecondsSinceEpoch,
      'location': location,
      'roomVenue': roomVenue,
      'annotations': annotations,
      'playlist': playlist.toCache(),
      'roles': roles.map((role) => role.toFirestore()).toList(),
      'shareCode': shareCode,
    };
  }

  factory ScheduleDto.fromCache(Map<String, dynamic> json) {
    return ScheduleDto(
      firebaseId: json['firebaseId'] as String?,
      ownerFirebaseId: json['ownerId'] as String,
      name: json['name'] as String,
      datetime: Timestamp.fromMillisecondsSinceEpoch(json['datetime'] as int),
      location: json['location'] as String,
      roomVenue: json['roomVenue'] as String?,
      annotations: json['annotations'] as String?,
      playlist: PlaylistDto.fromCache(json['playlist'] as Map<String, dynamic>),
      roles: (json['roles'] as List)
          .map((role) => RoleDto.fromFirestore(role))
          .toList(),
      shareCode: json['shareCode'] as String? ?? generateShareCode(),
    );
  }

  Schedule toDomain({required int playlistLocalId}) {
    final dateTime = datetime.toDate();
    final schedule = Schedule(
      id: -1, // ID will be set by local database
      ownerFirebaseId: ownerFirebaseId,
      name: name,
      date: DateTime(dateTime.year, dateTime.month, dateTime.day),
      time: TimeOfDay(hour: dateTime.hour, minute: dateTime.minute),
      location: location,
      roomVenue: roomVenue,
      playlistId: playlistLocalId,
      roles: roles
          .asMap()
          .map((index, role) => MapEntry(index, role.toDomain()))
          .values
          .toList(),
      shareCode: shareCode,
    );

    // Adiciona os papéis ao agendamento
    for (var roleDto in roles) {
      final role = roleDto.toDomain();
      schedule.roles.add(role);
    }

    return schedule;
  }

  ScheduleDto copyWith({
    String? firebaseId,
    String? name,
    Timestamp? datetime,
    String? location,
    String? roomVenue,
    String? annotations,
    PlaylistDto? playlist,
    List<RoleDto>? roles,
    String? shareCode,
  }) {
    return ScheduleDto(
      firebaseId: this.firebaseId ?? firebaseId,
      ownerFirebaseId: ownerFirebaseId,
      name: name ?? this.name,
      datetime: datetime ?? this.datetime,
      location: location ?? this.location,
      roomVenue: roomVenue ?? this.roomVenue,
      annotations: annotations ?? this.annotations,
      playlist: playlist ?? this.playlist,
      roles: roles ?? this.roles,
      shareCode: shareCode ?? this.shareCode,
    );
  }
}

class RoleDto {
  String name;
  final List<UserDto> users;

  RoleDto({required this.name, required this.users});

  factory RoleDto.fromFirestore(Map<String, dynamic> json) {
    return RoleDto(
      name: json['name'] as String,
      users: (json['users'] as List<dynamic>)
          .map((userJson) => UserDto.fromSchedule(userJson))
          .toList(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'users': users.map((user) => user.toSchedule()).toList(),
    };
  }

  Role toDomain() {
    final role = Role(
      id: -1,
      name: name,
      users: users.map((user) => user.toDomain()).toList(),
    );
    return role;
  }
}
