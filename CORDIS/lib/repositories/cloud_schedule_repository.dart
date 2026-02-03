import 'package:cloud_functions/cloud_functions.dart';
import 'package:cordis/helpers/guard.dart';
import 'package:cordis/models/dtos/schedule_dto.dart';
import 'package:cordis/services/cache_service.dart';
import 'package:cordis/services/firestore_service.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class CloudScheduleRepository {
  final FirestoreService _firestoreService = FirestoreService();
  final GuardHelper _guardHelper = GuardHelper();

  final CacheService _cacheService = CacheService();
  final List<ScheduleDto> _repoCache = [];
  DateTime? _lastCloudLoad;

  CloudScheduleRepository() {
    _initializeCloudCache();
  }
  // ===== CREATE =====

  /// Publish a new schedule to Firestore
  /// Returns the generated document ID
  Future<String> publishSchedule(ScheduleDto scheduleDto) async {
    return await _withErrorHandling('publish_schedule', () async {
      await _guardHelper.requireAuth();
      await _guardHelper.requireOwnership(scheduleDto.ownerFirebaseId);

      final docId = await _firestoreService.createDocument(
        collectionPath: 'schedules',
        data: scheduleDto.toFirestore(),
      );

      await FirebaseAnalytics.instance.logEvent(
        name: 'created_schedule',
        parameters: {'scheduleId': docId},
      );

      return docId;
    });
  }

  // ===== READ =====

  /// Fetch schedules of a specific user ID
  /// Used when fetching schedules for a user
  Future<List<ScheduleDto>> fetchSchedulesByUserId(
    String firebaseUserId, {
    bool forceFetch = false,
  }) async {
    final now = DateTime.now();
    if (!forceFetch &&
        now.isBefore(
          (_lastCloudLoad ?? DateTime(2000)).add(
            Duration(days: 7),
          ), // CHECK FOR NEW SCHEDULES WEEKLY
        )) {
      final cachedSchedules = await _cacheService.loadCloudSchedules();
      if (cachedSchedules.isNotEmpty) {
        debugPrint('LOADING CACHED SCHEDULES FOR USER $firebaseUserId.');
        return cachedSchedules;
      }
    }
    return await _withErrorHandling('fetch_schedules_by_user_id', () async {
      final querySnapshot = await _firestoreService
          .fetchDocumentsContainingValue(
            collectionPath: 'schedules',
            field: 'collaborators',
            orderField: 'createdAt',
            value: firebaseUserId,
          );

      final schedules = querySnapshot
          .map(
            (doc) => ScheduleDto.fromFirestore(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList();

      debugPrint(
        'FETCHED ${schedules.length} SCHEDULES FOR USER $firebaseUserId FROM CLOUD.',
      );

      await _cacheService.saveCloudSchedules(schedules);
      await _cacheService.saveLastScheduleLoad(now);
      _repoCache.clear();
      _repoCache.addAll(schedules);
      _lastCloudLoad = now;

      return schedules;
    });
  }

  /// Fetches a schedule by its ID
  /// Returns null if not found
  /// Used after successfully inserting a share code
  Future<ScheduleDto?> fetchScheduleById(String scheduleId) async {
    return await _withErrorHandling('fetch_schedule_by_id', () async {
      final docSnapshot = await _firestoreService.fetchDocumentById(
        collectionPath: 'schedules',
        documentId: scheduleId,
      );

      if (docSnapshot == null) {
        throw Exception('No schedule found with the provided schedule ID.');
      }

      return ScheduleDto.fromFirestore(
        docSnapshot.data() as Map<String, dynamic>,
        docSnapshot.id,
      );
    });
  }

  // ===== UPDATE =====

  /// Update an existing schedule in Firestore on the changes map
  Future<void> updateSchedule(String ownerId, ScheduleDto schedule) async {
    return await _withErrorHandling('update_schedule', () async {
      await _guardHelper.requireAuth();
      await _guardHelper.requireOwnership(ownerId);

      await _firestoreService.updateDocument(
        collectionPath: 'schedules',
        documentId: schedule.firebaseId!,
        data: schedule.toFirestore(),
      );

      await FirebaseAnalytics.instance.logEvent(
        name: 'updated_schedule',
        parameters: {'scheduleId': schedule.firebaseId!},
      );
    });
  }

  /// Enter Schedule via Share Code by adding the user as a collaborator
  Future<bool> joinWithCode(String shareCode) async {
    return await _withErrorHandling('join_schedule_via_share_code', () async {
      await _guardHelper.requireAuth();

      final functions = FirebaseFunctions.instance;

      final result = await functions.httpsCallable('joinScheduleWithCode').call(
        <String, dynamic>{'shareCode': shareCode},
      );

      // After successfully joining load the schedule
      if (result.data['success'] == true) {
        return true;
      } else {
        throw Exception(
          'Failed to join schedule with the provided share code.',
        );
      }
    });
  }

  // ===== DELETE =====
  /// Delete a schedule from Firestore
  Future<void> deleteSchedule(String firebaseId, String ownerId) async {
    return await _withErrorHandling('delete_schedule', () async {
      await _guardHelper.requireAuth();
      await _guardHelper.requireOwnership(ownerId);

      await _firestoreService.deleteDocument(
        collectionPath: 'schedules',
        documentId: firebaseId,
      );

      await FirebaseAnalytics.instance.logEvent(
        name: 'deleted_schedule',
        parameters: {'scheduleId': firebaseId},
      );
    });
  }

  // ===== ERROR HANDLING =====
  Future<T> _withErrorHandling<T>(
    String actionDescription,
    Future<T> Function() action,
  ) async {
    try {
      return await action();
    } catch (e) {
      // Log error to analytics
      await FirebaseAnalytics.instance.logEvent(
        name: 'error_during_$actionDescription',
        parameters: {'error': e.toString()},
      );

      if (kDebugMode) {
        print('Error during $actionDescription: $e');
      }

      rethrow;
    }
  }

  // ===== CACHE INITIALIZATION =====
  Future<void> _initializeCloudCache() async {
    _repoCache.addAll(await _cacheService.loadCloudSchedules());
    _lastCloudLoad = await _cacheService.loadLastScheduleLoad();
  }
}
