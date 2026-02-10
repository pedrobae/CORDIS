import 'package:cordis/models/domain/cipher/version.dart';
import 'package:cordis/repositories/local/cipher_repository.dart';
import 'package:flutter/foundation.dart';

class LocalVersionProvider extends ChangeNotifier {
  final LocalCipherRepository _cipherRepository = LocalCipherRepository();

  final Map<int, Version> _versions = {}; // Cached versions localID -> Version

  bool _isLoading = false;
  bool _isSaving = false;

  String? _error;

  // Getters
  Map<int, Version> get versions => _versions;

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;

  String? get error => _error;

  int get localVersionCount {
    if (_versions[-1] != null) {
      return _versions.length - 1;
    }
    return _versions.length;
  }

  Version? getVersion(int versionID) => _versions[versionID];

  /// Checks if a version exists locally by its Firebase ID
  /// Returns the local id if found, otherwise null
  Future<int?> getLocalIdByFirebaseId(String firebaseId) async {
    for (var v in _versions.values) {
      if (v.firebaseId == firebaseId && v.id != null) {
        return v.id;
      }
    }
    // Not in cache, query repository
    final version = await _cipherRepository.getVersionWithFirebaseId(
      firebaseId,
    );

    return version?.id;
  }

  Future<String?> getFirebaseIdByLocalId(int localId) async {
    final id = _versions[localId]?.firebaseId;
    if (id != null) {
      return id;
    }
    // Not in cache, query repository
    final version = await _cipherRepository.getVersionWithId(localId);
    return version?.firebaseId;
  }

  // === Versions of a cipher ===
  List<int> getVersionsByCipherId(int cipherId) {
    return _versions.values
        .where((version) => version.cipherId == cipherId)
        .map((version) => version.id!)
        .toList();
  }

  int getVersionsOfCipherCount(int cipherId) {
    return _versions.values
        .where((version) => version.cipherId == cipherId)
        .length;
  }

  int? getIdOfOldestVersionOfCipher(int cipherId) {
    final versions = _versions.values
        .where((version) => version.cipherId == cipherId)
        .toList();
    versions.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return versions.isNotEmpty ? versions.first.id : null;
  }

  // ===== CREATE =====
  /// Creates a new version from the local cache (-1) to an existing cipher
  /// If no cipherId is provided, the version will use the cached cipherID or throw an error
  Future<int?> createVersion({int? cipherID}) async {
    if (_isSaving) return null;

    _isSaving = true;
    _error = null;
    notifyListeners();

    int? versionId;
    try {
      if (!_versions.containsKey(-1)) {
        throw Exception('No version cached to create a new version from.');
      }
      // Create version with the correct cipher ID
      final versionWithCipherId = _versions[-1]!.copyWith(
        cipherId: cipherID ?? _versions[-1]!.cipherId,
      );

      if (versionWithCipherId.cipherId == -1) {
        throw Exception(
          'Cannot create version: no cipherId provided and cached version has no cipherId.',
        );
      }

      versionId = await _cipherRepository.insertVersion(versionWithCipherId);

      _versions[versionId] = versionWithCipherId.copyWith(id: versionId);

      if (kDebugMode) {
        print(
          'Created a new version with id $versionId, for cipher ${cipherID ?? versionWithCipherId.cipherId}',
        );
      }
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error creating cipher version: $e');
      }
    } finally {
      _isSaving = false;
      notifyListeners();
    }
    return versionId;
  }

  /// Initialize cloud cache from domain object, with ID -1
  void setNewVersionInCache(Version version) {
    _versions[-1] = version;
    notifyListeners();
  }

  /// Inserts a new version into the local database and cache
  Future<int> insertVersion(Version version) async {
    int versionId = -1;
    if (_isSaving) return versionId;

    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      versionId = await _cipherRepository.insertVersion(version);
      _versions[versionId] = version.copyWith(id: versionId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isSaving = false;
      notifyListeners();
    }
    return versionId;
  }

  // ===== READ =====
  /// Load all versions of a cipher into cache, used for version selector and cipher expansion
  Future<void> loadVersionsOfCipher(int cipherId) async {
    if (_isLoading) return;

    try {
      _error = null;
      _isLoading = true;
      notifyListeners();

      final versionList = await _cipherRepository.getVersions(cipherId);
      for (final version in versionList) {
        _versions[version.id!] = version;
      }
      if (kDebugMode) {
        print('Loaded ${versionList.length} versions of cipher $cipherId');
      }
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error loading versions of cipher: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load a version into cache by its local ID
  Future<void> loadVersion(int versionId) async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final version = await _cipherRepository.getVersionWithId(versionId);
      if (version == null) {
        throw Exception('Version with id $versionId not found locally');
      }

      _versions[versionId] = version;
      _versions[versionId] = version;
      if (kDebugMode) {
        print(
          'Loaded the version: ${_versions[versionId]?.versionName} into cache',
        );
      }
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error loading cipher version by id: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetches a version directly from SQLite
  Future<Version?> fetchVersion(int versionID) async {
    if (_isLoading) return null;

    Version? version;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      version = await _cipherRepository.getVersionWithId(versionID);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    return version;
  }

  // ===== UPSERT =====
  /// Upsert a version into local db (add or update)
  Future<int> upsertVersion(Version version) async {
    int versionId = -1;
    if (_isSaving) return versionId;

    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      // Check if version exists by its firebaseId
      final versionId = await getLocalIdByFirebaseId(version.firebaseId!);

      if (versionId != null) {
        // Update existing version
        await _cipherRepository.updateVersion(version.copyWith(id: versionId));
        for (final section in version.sections!.values) {
          await _cipherRepository.updateSection(
            section.copyWith(versionId: versionId),
          );
        }
        if (kDebugMode) {
          print('Updated existing version with id: $versionId');
        }
      } else {
        // Insert new version
        final versionId = await _cipherRepository.insertVersion(version);
        for (final section in version.sections!.values) {
          await _cipherRepository.insertSection(
            section.copyWith(versionId: versionId),
          );
        }
        if (kDebugMode) {
          print('Inserted new version with id: $versionId');
        }
      }
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error upserting cipher version: $e');
      }
    } finally {
      _isSaving = false;
      notifyListeners();
    }
    return versionId;
  }

  // ===== UPDATE - update cipher version =====
  /// Updates a version in the local database (nothing to do with cache)
  Future<void> updateVersion(Version version) async {
    if (_isSaving) return;

    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      await _cipherRepository.updateVersion(version);
      loadVersion(version.id!);

      if (kDebugMode) {
        print('Updated version with id: ${version.id}');
      }
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error updating cipher version: $e');
      }
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // Saves a new structure of a version (playlist reordering)
  Future<void> saveUpdatedSongStructure(
    int versionId,
    List<String> songStructure,
  ) async {
    if (_isSaving) return;

    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      _cipherRepository.updateFieldOfVersion(versionId, {
        'song_structure': songStructure.join(','),
      });

      // Update cached version if it exists
      _versions[versionId] = _versions[versionId]!.copyWith(
        songStructure: songStructure,
      );

      if (kDebugMode) {
        print('Updated the songStructure of version: $versionId');
      }
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error updating cipher version song structure: $e');
      }
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // Cache changes to the version data (Version Name / Transposed Key)
  void cacheUpdates(
    int versionId, {
    String? versionName,
    String? transposedKey,
    List<String>? songStructure,
    Duration? duration,
    int? bpm,
  }) {
    _versions[versionId] = _versions[versionId]!.copyWith(
      versionName: versionName,
      transposedKey: transposedKey,
      songStructure: songStructure,
      duration: duration,
      bpm: bpm,
    );
    notifyListeners();
  }

  // Reorder and cache a new structure
  void reorderSongStructure(int versionId, int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;

    final item = _versions[versionId]!.songStructure.removeAt(oldIndex);
    _versions[versionId]!.songStructure.insert(newIndex, item);
    notifyListeners();
    return;
  }

  /// ===== DELETE - Version =====
  Future<void> deleteVersion(int versionId) async {
    if (_isSaving) return;

    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      await _cipherRepository.deleteVersion(versionId);
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error deleting cipher version: $e');
      }
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void clearVersionsOfCipher(int cipherId) {
    _versions.removeWhere((id, version) => version.cipherId == cipherId);
    notifyListeners();
  }

  // ===== SAVE =====
  /// Persist the cache of an ID to the database
  Future<void> saveVersion(int versionID) async {
    if (_isSaving) return;

    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      await _cipherRepository.updateVersion(_versions[versionID]!);
    } catch (e) {
      _error = e.toString();
      debugPrint('Error updating cipher version: $e');
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// ===== SONG STRUCTURE =====
  /// ===== CREATE =====
  // Add a new section
  void addSectionToStruct(int versionId, String contentCode) {
    _versions[versionId]!.songStructure.add(contentCode);
    notifyListeners();
  }

  // ===== UPDATE =====
  /// Update a section code in the song structure
  void updateSectionCodeInStruct(
    int versionId, {
    required String oldCode,
    required String newCode,
  }) {
    final songStructure = _versions[versionId]!.songStructure;

    // Iterate through the song structure and update the section code
    for (int i = 0; i < _versions[versionId]!.songStructure.length; i++) {
      if (songStructure[i] == oldCode) {
        songStructure[i] = newCode;
      }
    }

    notifyListeners();
  }

  /// ===== DELETE =====
  void removeSectionFromStructByCode(int versionId, String contentCode) {
    _versions[versionId]!.songStructure.removeWhere(
      (code) => code == contentCode,
    );
  }

  void clearCache() {
    _versions.clear();
    notifyListeners();
  }
}
