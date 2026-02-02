import 'package:cordis/models/domain/playlist/flow_item.dart';
import 'package:cordis/repositories/flow_item_repository.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

class FlowItemProvider extends ChangeNotifier {
  final FlowItemRepository _flowItemRepo = FlowItemRepository();

  FlowItemProvider();

  final Map<int, FlowItem> _flowItems = {};
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isDeleting = false;
  String? _error;

  // Getters
  Map<int, FlowItem> get flowItems => _flowItems;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isDeleting => _isDeleting;
  String? get error => _error;

  // ===== READ =====

  Future<String?> getFirebaseIdByLocalId(int localId) async {
    // Check cache first
    if (_flowItems.containsKey(localId)) {
      return _flowItems[localId]!.firebaseId;
    }
    // Not in cache, query repository
    final flowItem = await _flowItemRepo.getFlowItem(localId);
    return flowItem?.firebaseId;
  }

  Future<int?> getLocalIdByFirebaseId(String firebaseId) async {
    if (firebaseId.isEmpty) return null;
    // Check cache first
    for (final entry in _flowItems.entries) {
      if (entry.value.firebaseId == firebaseId) {
        return entry.key;
      }
    }
    // Not in cache, query repository
    final flowItem = await _flowItemRepo.getFlowItemByFirebaseId(firebaseId);
    return flowItem?.id;
  }

  FlowItem? getFlowItem(int id) {
    // Check cache first
    if (_flowItems.containsKey(id)) {
      return _flowItems[id];
    }
    return null;
  }

  Future<void> loadFlowItem(int id) async {
    // Not in cache, query repository
    final flowItem = await _flowItemRepo.getFlowItem(id);
    if (flowItem != null) {
      _flowItems[id] = flowItem;
    }
    notifyListeners();
  }

  // ===== CREATE =====
  // Create a new FlowItem from scratch
  Future<void> createFlowItem(FlowItem flowItem) async {
    if (_isSaving) return;

    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      int id = await _flowItemRepo.createFlowItem(flowItem);
      await loadFlowItem(id);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Upserts a Flow Item (create or update)
  Future<void> upsertFlowItem(FlowItem flowItem) async {
    if (_isSaving) return;

    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      // Check if exists
      bool exists = false;
      int? localId;
      if (flowItem.id != null) {
        exists = _flowItems.containsKey(flowItem.id!);
        localId = flowItem.id;
      } else {
        localId = await getLocalIdByFirebaseId(flowItem.firebaseId);
        exists = localId != null;
      }

      if (!exists) {
        // Create new
        localId = await _flowItemRepo.createFlowItem(flowItem);
      } else {
        // Update existing
        await _flowItemRepo.updateFlowItem(
          localId!,
          title: flowItem.title,
          content: flowItem.contentText,
          position: flowItem.position,
          duration: flowItem.duration.inSeconds,
        );
      }

      await loadFlowItem(localId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Duplicate a Flow Item by ID
  Future<void> duplicateFlowItem(
    int id,
    String titleSuffix,
    int position,
  ) async {
    if (_isSaving) return;

    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      final original = _flowItems[id];
      if (original == null) {
        throw Exception('Flow Item with ID $id not found for duplication.');
      }

      final duplicate = FlowItem(
        firebaseId: '', // Dont copy Firebase ID for new item
        playlistId: original.playlistId,
        title: '${original.title} $titleSuffix',
        contentText: original.contentText,
        position: position,
        duration: original.duration,
      );

      int newId = await _flowItemRepo.createFlowItem(duplicate);
      await loadFlowItem(newId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // ===== UPDATE =====
  // Update a Flow Item with new data (title/content)
  Future<void> updateFlowItem(
    int id,
    String? title,
    String? content,
    int? position,
  ) async {
    if (_isSaving) return;

    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      await _flowItemRepo.updateFlowItem(
        id,
        title: title,
        content: content,
        position: position,
      );

      // Force reload the updated text section to get fresh data
      await loadFlowItem(id);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // ===== DELETE =====
  // Delete a Flow Item by ID
  Future<void> deleteFlowItem(int id) async {
    if (_isDeleting) return;

    _isDeleting = true;
    _error = null;
    notifyListeners();

    try {
      await _flowItemRepo.deleteFlowItem(id);
      _flowItems.remove(id); // Remove from local cache
    } catch (e) {
      _error = e.toString();
    } finally {
      _isDeleting = false;
      notifyListeners();
    }
  }

  // ===== UTILITY =====
  // Clear cached data and reset state
  void clearCache() {
    _flowItems.clear();
    _error = null;
    _isLoading = false;
    _isSaving = false;
    _isDeleting = false;
    notifyListeners();
  }
}
