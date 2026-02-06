import 'package:cordis/models/domain/playlist/flow_item.dart';
import 'package:cordis/models/domain/playlist/playlist_item.dart';
import 'package:cordis/models/dtos/schedule_dto.dart';
import 'package:cordis/repositories/flow_item_repository.dart';
import 'package:cordis/repositories/local_cipher_repository.dart';
import 'package:cordis/repositories/local_playlist_repository.dart';
import 'package:cordis/repositories/local_schedule_repository.dart';
import 'package:cordis/repositories/local_user_repository.dart';

class ScheduleSyncService {
  final _localRepo = LocalScheduleRepository();
  final _playlistRepo = PlaylistRepository();
  final _userRepo = UserRepository();
  final _flowRepo = FlowItemRepository();
  final _versionRepo = LocalCipherRepository();

  /// Sync owner's schedule to SQLite, so it can be accessed offline and edited
  /// Priority is given to the local version, so cloud diff are discarded,
  /// But if the schedule doesn't exist locally, or there are empty fields, it will be created/updated with the cloud version
  Future<void> syncSchedule(ScheduleDto scheduleDto) async {
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
    final versionIDs = <int>[];
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
          final versionID = await _versionRepo.upsertVersionDto(versionDto);
          versionIDs.add(versionID);
          break;
      }
    }

    for (final versionID in versionIDs) {
      await _playlistRepo.addVersionToPlaylist(playlistId, versionID);
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
}
