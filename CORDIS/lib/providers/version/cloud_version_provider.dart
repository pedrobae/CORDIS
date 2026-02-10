import 'package:cordis/models/dtos/version_dto.dart';
import 'package:cordis/repositories/cloud_version_repository.dart';
import 'package:flutter/foundation.dart';

class CloudVersionProvider extends ChangeNotifier {
  final CloudVersionRepository _repo = CloudVersionRepository();

  final Map<String, VersionDto> _versions =
      {}; // Cached cloud versions firebaseID -> Version

  bool _isSaving = false;
  bool _isLoading = false;

  String _searchTerm = '';

  String? _error;

  // ===== GETTERS =====
  Map<String, VersionDto> get versions => _versions;

  VersionDto? getVersion(String firebaseId) {
    return _versions[firebaseId];
  }

  List<String> get filteredCloudVersions {
    if (_searchTerm.isEmpty) {
      return _versions.keys.toList();
    } else {
      final List<String> tempList = [];
      for (var entry in _versions.entries) {
        if (entry.value.title.toLowerCase().contains(_searchTerm) ||
            entry.value.author.toLowerCase().contains(_searchTerm) ||
            entry.value.tags.any(
              (tag) => tag.toLowerCase().contains(_searchTerm),
            )) {
          tempList.add(entry.key);
        }
      }
      return tempList;
    }
  }

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;

  // ===== CREATE =====
  /// Persist the cache of an ID to the database
  Future<void> saveVersion(String versionID) async {
    if (_isSaving) return;

    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      await _repo.updatePersonalVersion(_versions[versionID]!);
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error updating cloud version: $e');
      }
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void setVersion(String firebaseId, VersionDto version) {
    _versions[firebaseId] = version;
    notifyListeners();
  }
  // ===== READ =====

  /// Loads public versions from Firestore
  Future<void> loadVersions({bool forceReload = false}) async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final cloudVersions = await _repo.getPublicVersions(
        forceReload: forceReload,
      );

      for (final version in cloudVersions) {
        _versions[version.firebaseId!] = version;
      }

      if (kDebugMode) {
        print('LOADED ${cloudVersions.length} PUBLIC CIPHERS FROM FIRESTORE');
      }
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error loading cloud versions: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> ensureVersionIsLoaded(String firebaseId) async {
    if (_versions.containsKey(firebaseId)) {
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final version = await _repo.getUserVersionById(firebaseId);
      if (version != null) {
        _versions[firebaseId] = version;
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error ensuring cloud version in cache: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load a version into cache by its Firebase ID
  Future<void> loadUserVersionsByFirebaseId(String firebaseId) async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final version = await _repo.getUserVersionById(firebaseId);
      if (version == null) {
        throw Exception('Version with id $firebaseId not found in cloud');
      }

      _versions[firebaseId] = version;
      if (kDebugMode) {
        print(
          'Loaded the cloud version: ${_versions[firebaseId]?.versionName} into cache',
        );
      }
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error loading cloud cipher version by id: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ===== UPDATE =====
  void cacheUpdates(
    String versionId, {
    String? versionName,
    String? transposedKey,
    String? title,
    String? author,
    int? bpm,
    int? duration,
    String? language,
    List<String>? tags,
  }) {
    _versions[versionId] = _versions[versionId]!.copyWith(
      versionName: versionName,
      transposedKey: transposedKey,
      title: title,
      author: author,
      bpm: bpm,
      duration: duration,
      language: language,
      tags: tags,
    );
    notifyListeners();
  }

  void reorderSongStructure(String versionID, int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;

    final item = _versions[versionID]!.songStructure.removeAt(oldIndex);
    _versions[versionID]!.songStructure.insert(newIndex, item);
    notifyListeners();
  }

  void addTagToCloudCache(String versionID, String newTag) {
    final currentTags = _versions[versionID]!.tags;
    if (!currentTags.contains(newTag)) {
      currentTags.add(newTag);
    }
    notifyListeners();
  }

  // ===== DELETE =====

  // ===== HELPER METHODS =====
  void clearCache() {
    _versions.clear();
    _error = null;
    _isLoading = false;
    _isSaving = false;
    _searchTerm = '';

    notifyListeners();
  }

  /// Search cached cloud versions
  Future<void> setSearchTerm(String term) async {
    _searchTerm = term.toLowerCase();
    notifyListeners();
  }
}
