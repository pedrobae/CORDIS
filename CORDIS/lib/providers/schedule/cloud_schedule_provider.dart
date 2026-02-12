import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cordis/models/dtos/schedule_dto.dart';
import 'package:cordis/repositories/cloud/schedule_repository.dart';
import 'package:cordis/services/schedule_sync.dart';
import 'package:flutter/material.dart';

class CloudScheduleProvider extends ChangeNotifier {
  final _repo = CloudScheduleRepository();
  final _syncService = ScheduleSyncService();

  CloudScheduleProvider();

  final Map<String, ScheduleDto> _schedules = {};

  String _searchTerm = '';

  String? _error;

  bool _isLoading = false;
  bool _isSaving = false;

  // ===== GETTERS =====
  Map<String, ScheduleDto> get schedules => _schedules;

  String? get error => _error;

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;

  List<String> get filteredScheduleIds {
    if (_searchTerm.isEmpty) {
      return _schedules.keys.toList();
    } else {
      final List<String> tempIds = [];
      for (var entry in _schedules.entries) {
        if (entry.value.name.toLowerCase().contains(_searchTerm) ||
            entry.value.location.toLowerCase().contains(_searchTerm)) {
          tempIds.add(entry.key);
        }
      }
      return tempIds;
    }
  }

  List<String> get futureScheduleIDs {
    final now = Timestamp.now();
    return filteredScheduleIds
        .where((id) => _schedules[id]!.datetime.compareTo(now) >= 0)
        .toList();
  }

  List<String> get pastScheduleIDs {
    final now = Timestamp.now();
    return filteredScheduleIds
        .where((id) => _schedules[id]!.datetime.compareTo(now) < 0)
        .toList();
  }

  ScheduleDto? getSchedule(String scheduleId) {
    return _schedules[scheduleId];
  }

  ScheduleDto? getNextSchedule() {
    final now = Timestamp.now();
    ScheduleDto? nextSchedule;
    for (var schedule in _schedules.values) {
      if (schedule.datetime.compareTo(now) >= 0) {
        if (nextSchedule == null ||
            schedule.datetime.compareTo(nextSchedule.datetime) < 0) {
          nextSchedule = schedule;
        }
      }
    }
    return nextSchedule;
  }

  // ===== CREATE =====
  // Returns a copy of the schedule for local insertion
  ScheduleDto duplicateSchedule(
    String scheduleId,
    String name,
    String date,
    String startTime,
    String location,
    String? roomVenue,
  ) {
    final original = _schedules[scheduleId];
    if (original == null) throw Exception('Schedule not found');

    final timestamp = Timestamp.fromDate(
      DateTime(
        int.parse(date.split('/')[0]),
        int.parse(date.split('/')[1]),
        int.parse(date.split('/')[2]),
        int.parse(startTime.split(':')[0]),
        int.parse(startTime.split(':')[1]),
      ),
    );

    return original.copyWith(
      name: name,
      datetime: timestamp,
      location: location,
      roomVenue: roomVenue,
    );
  }

  Future<void> publishSchedule(ScheduleDto schedule) async {
    if (_isSaving) return;

    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      final newScheduleId = await _repo.publishSchedule(schedule);
      _schedules[newScheduleId] = schedule.copyWith(firebaseId: newScheduleId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // ===== READ =====
  /// Fetches all schedules from the cloud repository (user has to be a collaborator)
  Future<void> loadSchedules(String userId, {bool forceFetch = false}) async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final schedules = await _repo.fetchSchedulesByUserId(
        userId,
        forceFetch: forceFetch,
      );

      _schedules.clear();

      for (var schedule in schedules) {
        if (schedule.ownerFirebaseId == userId) {
          // If the user is the owner, we want to make sure we have the latest version from the cloud (in case they made changes on another device)
          await _syncService.syncToLocal(schedule);
        } else {
          _schedules[schedule.firebaseId!] = schedule;
        }
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetches a schedule by its cloud ID
  Future<void> loadSchedule(String scheduleId) async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final schedule = await _repo.fetchScheduleById(scheduleId);
      if (schedule != null) {
        _schedules[scheduleId] = schedule;
      } else {
        throw Exception('Schedule not found');
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ===== UPDATE =====
  void cacheScheduleDetails(
    String scheduleId, {
    required String name,
    required String date,
    required String startTime,
    required String location,
    String? roomVenue,
    String? annotations,
  }) {
    final schedule = _schedules[scheduleId];
    if (schedule == null) throw Exception('Schedule not found');

    _schedules[scheduleId] = schedule.copyWith(
      name: name,
      datetime: Timestamp.fromDate(
        DateTime(
          int.parse(date.split('/')[0]),
          int.parse(date.split('/')[1]),
          int.parse(date.split('/')[2]),
          int.parse(startTime.split(':')[0]),
          int.parse(startTime.split(':')[1]),
        ),
      ),
      location: location,
      roomVenue: roomVenue,
      annotations: annotations,
    );

    notifyListeners();
  }

  Future<void> updateSchedule(String scheduleId, String ownerId) async {
    if (_isSaving) return;

    _isSaving = true;
    notifyListeners();

    try {
      final schedule = _schedules[scheduleId]!;
      await _repo.updateSchedule(ownerId, schedule);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // ===== DELETE =====
  /// Delete a schedule from the cache and in Firestore
  Future<void> deleteSchedule(String userId, String scheduleId) async {
    if (_isSaving) return;

    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      await _repo.deleteSchedule(userId, scheduleId);
      _schedules.remove(scheduleId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isSaving = false;
    }
    notifyListeners();
  }

  // ===== HELPERS =====
  void clearCache() {
    _schedules.clear();
    _searchTerm = '';
    _error = null;
    notifyListeners();
  }

  Future<bool> joinScheduleWithCode(String shareCode) async {
    if (_isLoading) return false;
    bool result = false;
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      result = await _repo.joinWithCode(shareCode);
    } catch (e) {
      _error = e.toString();
      result = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return result;
  }

  // ===== SEARCH & FILTER =====
  void setSearchTerm(String searchTerm) {
    _searchTerm = searchTerm.toLowerCase();
    notifyListeners();
  }
}
