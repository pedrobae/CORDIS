import 'dart:convert';
import 'package:cordis/models/dtos/schedule_dto.dart';
import 'package:cordis/models/dtos/version_dto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  static const _versionKey = 'cloudVersions';
  static const _lastVersionLoad = 'lastVersionLoad';

  static const _scheduleKey = 'cloudSchedules';
  static const _lastScheduleLoad = 'lastScheduleLoad';

  Future<void> saveCloudVersions(List<VersionDto> versions) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = versions.map((v) => v.toCache()).toList();
    await prefs.setString(_versionKey, json.encode(jsonList));
  }

  Future<void> saveCloudSchedules(List<ScheduleDto> schedules) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = schedules.map((s) => s.toCache()).toList();
    await prefs.setString(_scheduleKey, json.encode(jsonList));
  }

  Future<List<VersionDto>> loadCloudVersions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_versionKey);
      if (jsonString == null) return [];
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((j) => VersionDto.fromCache(j)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<ScheduleDto>> loadCloudSchedules() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_scheduleKey);
      if (jsonString == null) return [];
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((j) => ScheduleDto.fromCache(j)).toList();
    } catch (e) {
      // If there's an error (e.g., corrupted data), return empty list
      return [];
    }
  }

  Future<void> saveLastCloudLoad(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastVersionLoad, time.millisecondsSinceEpoch);
  }

  Future<void> saveLastScheduleLoad(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastScheduleLoad, time.millisecondsSinceEpoch);
  }

  Future<DateTime?> loadLastCloudLoad() async {
    final prefs = await SharedPreferences.getInstance();
    final millis = prefs.getInt(_lastVersionLoad);
    if (millis != null) {
      return DateTime.fromMillisecondsSinceEpoch(millis);
    }
    return null;
  }

  Future<DateTime?> loadLastScheduleLoad() async {
    final prefs = await SharedPreferences.getInstance();
    final millis = prefs.getInt(_lastScheduleLoad);
    if (millis != null) {
      return DateTime.fromMillisecondsSinceEpoch(millis);
    }
    return null;
  }
}
