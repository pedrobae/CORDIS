import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cordis/models/domain/schedule.dart';
import 'package:cordis/models/dtos/playlist_dto.dart';
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
  });

  factory ScheduleDto.fromFirestore(Map<String, dynamic> json) {
    return ScheduleDto(
      firebaseId: json['firebaseId'] as String?,
      ownerFirebaseId: json['ownerFirebaseId'] as String,
      name: json['name'] as String,
      datetime: json['datetime'] as Timestamp,
      location: json['location'] as String,
      roomVenue: json['roomVenue'] as String?,
      annotations: json['annotations'] as String?,
      playlist: PlaylistDto.fromFirestore(
        json['playlist'] as Map<String, dynamic>,
      ),
      roles: (json['roles'] as List)
          .map((role) => RoleDto.fromFirestore(role))
          .toList(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'ownerFirebaseId': ownerFirebaseId,
      'name': name,
      'datetime': datetime,
      'location': location,
      'roomVenue': roomVenue,
      'annotations': annotations,
      'playlist': playlist.toFirestore(),
      'roles': roles.map((role) => role.toFirestore()).toList(),
    };
  }

  Schedule toDomain(
    int ownerLocalId,
    List<List<int>> roleMemberIds,
    int playlistLocalId,
  ) {
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
          .map(
            (index, role) =>
                MapEntry(index, role.toDomain(roleMemberIds[index])),
          )
          .values
          .toList(),
    );

    // Adiciona os papéis ao agendamento
    for (var roleDto in roles) {
      final role = roleDto.toDomain([]);
      schedule.roles.add(role);
    }

    return schedule;
  }

  ScheduleDto copyWith({
    String? name,
    Timestamp? datetime,
    String? location,
    String? roomVenue,
    String? annotations,
    PlaylistDto? playlist,
    List<RoleDto>? roles,
  }) {
    return ScheduleDto(
      firebaseId: firebaseId,
      ownerFirebaseId: ownerFirebaseId,
      name: name ?? this.name,
      datetime: datetime ?? this.datetime,
      location: location ?? this.location,
      roomVenue: roomVenue ?? this.roomVenue,
      annotations: annotations ?? this.annotations,
      playlist: playlist ?? this.playlist,
      roles: roles ?? this.roles,
    );
  }
}

class RoleDto {
  String name;
  final List<String> memberIds;

  RoleDto({required this.name, required this.memberIds});

  factory RoleDto.fromFirestore(Map<String, dynamic> json) {
    return RoleDto(
      name: json['name'] as String,
      memberIds: List<String>.from(json['memberIds'] as List<dynamic>),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {'name': name, 'memberIds': memberIds};
  }

  Role toDomain(List<int> memberLocalIds) {
    final role = Role(id: -1, name: name, memberIds: memberLocalIds);
    return role;
  }
}
