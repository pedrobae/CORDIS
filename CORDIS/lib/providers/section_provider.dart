import 'package:cordis/repositories/local/section_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:cordis/models/domain/cipher/section.dart';

class SectionProvider extends ChangeNotifier {
  final _repo = SectionRepository();

  SectionProvider();

  Map<dynamic, Map<String, Section>> _sections =
      {}; // versionId -> (sectionCode -> Section) -1 versionId for new/importing versions
  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;

  Map<String, Section> getSections(dynamic versionKey) {
    if (versionKey != null && _sections.containsKey(versionKey)) {
      return _sections[versionKey]!;
    }
    return {};
  }

  Section? getSection(dynamic versionKey, String contentCode) {
    switch (versionKey.runtimeType) {
      case const (String):
        return _sections[versionKey]?[contentCode];
      case const (int):
        return _sections[versionKey]?[contentCode];
      default:
        return _sections[-1]?[contentCode]; // For new/importing versions
    }
  }

  /// ===== CREATE =====
  // Add a new section, returns the new section code (with suffix if there was a conflict)
  String cacheAddSection(
    dynamic versionKey,
    String contentCode,
    Color color,
    String sectionType,
  ) {
    final newSection = Section(
      versionId: versionKey is String ? -1 : versionKey,
      contentCode: contentCode,
      contentColor: color,
      contentType: sectionType,
      contentText: '',
    );
    // CHECK IF ALREADY EXISTS
    bool exists = false;
    for (String key in _sections[newSection.versionId]?.keys ?? []) {
      // Strip numbering suffixes for comparison, remove numbers
      final strippedKey = key.toString().replaceAll(RegExp(r'\d+$'), '');
      if (strippedKey == contentCode) {
        exists = true;
        break;
      }
    }
    if (exists) {
      debugPrint(
        'Section with code ${newSection.contentCode} already exists in version ${newSection.versionId}.',
      );
      int suffix = 1;
      String newCode;
      do {
        newCode = '${newSection.contentCode}$suffix';
        suffix++;
      } while (_sections[newSection.versionId] != null &&
          _sections[newSection.versionId]!.containsKey(newCode));

      debugPrint('Renaming new section to $newCode to avoid conflict.');
      newSection.contentCode = newCode;
    }

    _sections[newSection.versionId] ??= {};
    _sections[newSection.versionId]![newSection.contentCode] = newSection;
    notifyListeners();
    return newSection.contentCode;
  }

  // Set new sections in cache (used when importing or on cloud load)
  void setNewSectionsInCache(
    dynamic versionKey,
    Map<String, Section> sections,
  ) {
    _sections[versionKey] = sections;
    notifyListeners();
  }

  void cacheSectionCopy(dynamic versionId) {
    final sections = _sections[versionId];
    if (sections == null) return;

    _sections[-1] ??= {};

    for (final code in sections.keys) {
      final originalSection = sections[code]!;
      final newSection = originalSection.copyWith(versionId: -1);
      _sections[-1]![newSection.contentCode] = newSection;
    }

    notifyListeners();
  }

  ///Create sections for a new version from -1 cache
  Future<void> createSections(int newVersionId) async {
    final sections = _sections[-1];
    for (final code in sections!.keys) {
      await _repo.insertSection(
        sections[code]!.copyWith(versionId: newVersionId),
      );
    }
    _sections.remove(-1);
    notifyListeners();
  }

  // ====== READ =====
  /// Load sections for a given version from the database
  Future<void> loadLocalSections(int versionId) async {
    if (_isLoading) return;

    _isLoading = true;
    notifyListeners();

    try {
      _sections[versionId] = await _repo.getSections(versionId);
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('⚠️ Failed to load sections: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// ===== UPDATE =====
  // Modify a section (content_text)
  void cacheUpdate(
    dynamic versionKey,
    String contentCode, {
    String? newContentCode,
    String? newContentType,
    String? newContentText,
    Color? newColor,
  }) {
    final section = _sections[versionKey]![contentCode];
    if (section == null) {
      // Create a new section if it doesn't exist
      final newSection = Section(
        versionId: versionKey is String ? -1 : versionKey,
        contentCode: newContentCode ?? contentCode,
        contentType: newContentType ?? 'default',
        contentText: newContentText ?? '',
        contentColor: newColor ?? Colors.grey,
      );

      _sections[newSection.versionId] ??= {};
      _sections[newSection.versionId]![newSection.contentCode] = newSection;
    } else {
      // Update existing section
      section.contentCode = newContentCode ?? section.contentCode;
      section.contentType = newContentType ?? section.contentType;
      section.contentText = newContentText ?? section.contentText;
      section.contentColor = newColor ?? section.contentColor;
    }
    notifyListeners();
  }

  void renameSectionKey(
    dynamic versionKey, {
    required String oldCode,
    required String newCode,
  }) {
    final section = _sections[versionKey]![oldCode];
    if (section == null) return;

    // Remove the old entry and add a new one with the updated code
    _sections[versionKey]!.remove(oldCode);
    _sections[versionKey]![newCode] = section;

    notifyListeners();
  }

  /// ===== DELETE =====
  // Remove all sections by its code
  void cacheDeleteSection(dynamic versionKey, String sectionCode) {
    _sections[versionKey]!.remove(sectionCode);
    notifyListeners();
  }

  // ===== SAVE =====
  /// Persist the data of the given version key to the database
  Future<void> saveSections({dynamic versionID}) async {
    if (_isSaving) return;

    _isSaving = true;
    notifyListeners();

    try {
      if (versionID == null) {
        throw Exception('No version key provided.');
      }

      if (versionID is String) {
        throw Exception('Cannot save sections for non-local version.');
      }

      for (final entry in _sections[versionID]!.entries) {
        await _repo.upsertSection(entry.value.copyWith(versionId: versionID));
      }
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('⚠️ Failed to save sections: $e');
      }
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Clear all sections from cache
  void clearCache() {
    _sections = {};
    _isLoading = false;
    _isSaving = false;
    notifyListeners();
  }
}
