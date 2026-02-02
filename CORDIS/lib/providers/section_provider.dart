import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:cordis/models/domain/cipher/section.dart';
import 'package:cordis/repositories/local_cipher_repository.dart';

class SectionProvider extends ChangeNotifier {
  final LocalCipherRepository _cipherRepository = LocalCipherRepository();

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
  // Add a new section
  void cacheAddSection(
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

    _sections[newSection.versionId] ??= {};
    _sections[newSection.versionId]![newSection.contentCode] = newSection;
    notifyListeners();
  }

  // Set new sections in cache (used when importing or on cloud load)
  void setNewSectionsInCache(
    dynamic versionKey,
    Map<String, Section> sections,
  ) {
    _sections[versionKey] = sections;
    notifyListeners();
  }

  ///Create sections for a new version from -1 cache
  Future<void> createSections(int newVersionId) async {
    final sections = _sections[-1];
    for (final code in sections!.keys) {
      await _cipherRepository.insertSection(
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
      _sections[versionId] = await _cipherRepository.getSections(versionId);
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
  void cacheSection(
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
      // For simplicity, delete all existing content and recreate
      // This could be optimized later to only update changed content
      await _cipherRepository.deleteAllVersionSections(versionID);

      // Insert new content
      if (kDebugMode) {
        print(
          'Saving ${_sections[versionID]!.length} sections for version $versionID',
        );
      }
      for (final entry in _sections[versionID]!.entries) {
        final sectionId = await _cipherRepository.insertSection(
          entry.value.copyWith(versionId: versionID),
        );

        if (kDebugMode) {
          print('Inserted section with code ${entry.key} and id $sectionId');
        }
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
