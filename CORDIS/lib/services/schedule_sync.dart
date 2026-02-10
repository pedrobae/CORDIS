import 'package:cordis/models/domain/cipher/cipher.dart';
import 'package:cordis/models/domain/cipher/section.dart';
import 'package:cordis/models/domain/playlist/flow_item.dart';
import 'package:cordis/models/domain/playlist/playlist_item.dart';
import 'package:cordis/models/domain/schedule.dart';
import 'package:cordis/models/dtos/schedule_dto.dart';
import 'package:cordis/models/dtos/version_dto.dart';
import 'package:cordis/repositories/cloud/schedule_repository.dart';
import 'package:cordis/repositories/local/flow_item_repository.dart';
import 'package:cordis/repositories/local/cipher_repository.dart';
import 'package:cordis/repositories/local/playlist_repository.dart';
import 'package:cordis/repositories/local/schedule_repository.dart';
import 'package:cordis/repositories/local/user_repository.dart';
import 'package:flutter/material.dart';

class ScheduleSyncService {
  final _localRepo = LocalScheduleRepository();
  final _cloudRepo = CloudScheduleRepository();
  final _playlistRepo = PlaylistRepository();
  final _userRepo = UserRepository();
  final _flowRepo = FlowItemRepository();
  final _versionRepo = LocalCipherRepository();

  /// Sync owner's schedule to SQLite, so it can be accessed offline and edited
  /// Priority is given to the local version, so cloud diff are discarded,
  /// But if the schedule doesn't exist locally, or there are empty fields, it will be created/updated with the cloud version
  Future<void> syncToLocal(ScheduleDto scheduleDto) async {
    final localUser = await _userRepo.getUserByFirebaseId(
      scheduleDto.ownerFirebaseId,
    );

    if (localUser == null) {
      throw Exception(
        'Owner user not found locally for schedule ${scheduleDto.firebaseId}',
      );
    }

    final playlistId = await _playlistRepo.upsertPlaylist(
      scheduleDto.playlist.toDomain(localUser.id!).copyWith(),
    );

    // Upsert each playlist Item in the playlist
    for (var item in scheduleDto.playlist.getPlaylistItems()) {
      switch (item.type) {
        case PlaylistItemType.flowItem:
          final flowItem =
              scheduleDto.playlist.flowItems[item.firebaseContentId]!;
          await _flowRepo.upsertFlowItem(
            FlowItem.fromFirestore(
              flowItem,
              firebaseId: item.firebaseContentId,
              playlistId: playlistId,
            ),
          );
          break;
        case PlaylistItemType.version:
          final versionDto =
              scheduleDto.playlist.versions[item.firebaseContentId]!;

          /// Ensure cipher exists and is up to date
          int? cipherId = await _versionRepo.getCipherIdByTitleAuthor(
            title: versionDto.title,
            author: versionDto.author,
          );

          if (cipherId == null) {
            // Cipher doesn't exist locally, insert it
            await _versionRepo.insertPrunedCipher(
              Cipher.fromVersionDto(versionDto),
            );
          } else {
            // Cipher exists, merge it
            final existingCipher = await _versionRepo.getCipherById(cipherId);
            final mergedCipher = existingCipher!.mergeWith(
              Cipher.fromVersionDto(versionDto).copyWith(id: cipherId),
            );
            await _versionRepo.updateCipher(mergedCipher);
          }

          // Ensure version exists and is up to date
          final existingVersion = await _versionRepo.getVersionWithFirebaseId(
            versionDto.firebaseId!,
          );

          if (existingVersion != null) {
            // Version exists, merge it
            final mergedVersion = existingVersion.mergeWith(
              versionDto.toDomain(cipherId: cipherId),
            );
            await _versionRepo.updateVersion(mergedVersion);

            // Sync sections (delete all and re-insert)
            await _versionRepo.deleteAllVersionSections(existingVersion.id!);
            for (final section in (mergedVersion.sections ?? {}).values) {
              await _versionRepo.insertSection(
                section.copyWith(versionId: existingVersion.id!),
              );
            }
          } else {
            // Version doesn't exist locally, insert it and add it
            final versionId = await _versionRepo.insertVersion(
              versionDto.toDomain(cipherId: cipherId),
            );

            for (final section in versionDto.sections.values) {
              await _versionRepo.insertSection(
                Section.fromFirestore(section).copyWith(versionId: versionId),
              );
            }
            await _playlistRepo.addVersionToPlaylist(playlistId, versionId);
          }
      }
    }

    final schedule = scheduleDto.toDomain(playlistLocalId: playlistId);

    final existing = await _localRepo.getScheduleByFirebaseId(
      scheduleDto.firebaseId!,
    );
    if (existing == null) {
      // Schedule doesn't exist locally, insert it
      await _localRepo.insertSchedule(schedule);
    } else {
      // Schedule exists, update it (this will keep local changes if there are any, but fill in any missing fields from the cloud version)
      final merged = existing.mergeWith(schedule);
      await _localRepo.updateSchedule(merged);
    }
  }

  /// Syncs changes to a published playlist into firestore
  Future<void> syncToCloud(Schedule schedule, String ownerFirebaseID) async {
    debugPrint(
      'Syncing schedule ${schedule.id} to cloud for owner $ownerFirebaseID',
    );

    final domainPlaylist = (await _playlistRepo.getPlaylistById(
      schedule.playlistId!,
    ))!;

    // Build Item DTOs
    final flowItems = <String, FlowItem>{};
    final versions = <String, VersionDto>{};
    for (var item in domainPlaylist.items) {
      switch (item.type) {
        case PlaylistItemType.version:
          final version = (await _versionRepo.getVersionWithId(
            item.contentId!,
          ));

          if (version == null) break;
          final cipher = (await _versionRepo.getCipherById(version.cipherId));

          if (cipher == null) break;
          versions[item.id.toString()] = version.toDto(cipher);
          break;
        case PlaylistItemType.flowItem:
          final flowItem = await (_flowRepo.getFlowItem(item.contentId!));
          if (flowItem != null) {
            flowItems[item.id.toString()] = flowItem;
          }
          break;
      }
    }

    await _cloudRepo.updateSchedule(
      ownerFirebaseID,
      schedule.toDto(
        domainPlaylist.toDto(flowItems: flowItems, versions: versions),
      ),
    );
  }
}
