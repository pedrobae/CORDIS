import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cordis/models/domain/playlist/playlist.dart';
import 'package:cordis/models/domain/playlist/playlist_item.dart';
import 'package:cordis/models/dtos/playlist_dto.dart';
import 'package:cordis/repositories/local_playlist_repository.dart';

class PlaylistProvider extends ChangeNotifier {
  final PlaylistRepository _playlistRepository = PlaylistRepository();

  PlaylistProvider();

  final Map<int, Playlist> _playlists = {};

  bool _isLoading = false;
  bool _isSaving = false;
  bool _isDeleting = false;

  String? _error;

  // Track changes per playlist for efficient cloud syncing
  // Map<playlistId, changeMap>
  final Map<int, Map<String, dynamic>> _pendingChanges = {};

  // Getters
  Map<int, Playlist> get playlists => _playlists;
  List<int> get filteredPlaylists {
    if (_searchTerm.isEmpty) {
      return _playlists.keys.toList();
    } else {
      List<int> tempFiltered = [];
      for (var entry in _playlists.entries) {
        final playlist = entry.value;
        if (playlist.name.toLowerCase().contains(_searchTerm)) {
          tempFiltered.add(entry.key);
        }
      }
      return tempFiltered;
    }
  }

  String _searchTerm = '';

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isDeleting => _isDeleting;

  String? get error => _error;

  Playlist? getPlaylistById(int id) {
    return _playlists[id];
  }

  // Check if a playlist has pending changes to upload
  bool hasPendingChanges(int playlistId) {
    return _pendingChanges.containsKey(playlistId) &&
        _pendingChanges[playlistId]!.isNotEmpty;
  }

  // Get pending changes for a playlist
  Map<String, dynamic>? getPendingChanges(int playlistId) {
    return _pendingChanges[playlistId];
  }

  // ===== CREATE =====
  // Create a new playlist from local cache
  Future<void> createPlaylist(String playlistName, int userLocalId) async {
    if (_isSaving) return;

    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      int id = await _playlistRepository.insertPlaylist(
        Playlist(name: playlistName, id: -1, createdBy: userLocalId),
      );

      // Add the created playlist with new ID directly to cache
      _playlists[id] = _playlists[id]!.copyWith(id: id);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // Create a new playlist from the Domain model
  Future<int> createPlaylistFromDomain(Playlist playlist) async {
    int playlistId;
    try {
      _isSaving = true;
      _error = null;
      notifyListeners();

      playlistId = await _playlistRepository.insertPlaylist(playlist);

      // Add the created playlist with new ID to cache
      _playlists[playlistId] = playlist.copyWith(id: playlistId);
    } catch (e) {
      _error = e.toString();
      playlistId = -1;
    } finally {
      _isSaving = false;
      notifyListeners();
    }

    return playlistId;
  }

  // ===== READ =====
  // Load Playlists from local SQLite database
  Future<void> loadPlaylists() async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final playlist = await _playlistRepository.getAllPlaylists();
      for (var p in playlist) {
        final items = await _playlistRepository.getItemsOfPlaylist(p.id);
        _playlists[p.id] = p.copyWith(items: items);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load Single Playlist by ID
  Future<void> loadPlaylist(int id) async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final Playlist playlist = (await _playlistRepository.getPlaylistById(
        id,
      ))!;

      final List<PlaylistItem> items = await _playlistRepository
          .getItemsOfPlaylist(playlist.id);

      _playlists[playlist.id] = playlist.copyWith(items: items);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ===== UPDATE =====
  // Update a Playlist with new data (name/description)
  Future<void> updateName(int id, String name) async {
    await _playlistRepository.updatePlaylist(id, {'name': name});

    // Track metadata changes
    trackChange('metadata', id);

    await loadPlaylist(id); // Reload just this playlist
  }

  Future<int> upsertPlaylist(Playlist playlist) async {
    final playlistId = await _playlistRepository.upsertPlaylist(playlist);
    await loadPlaylist(playlistId);

    return playlistId;
  }

  /// Sync entire playlist with all its items in a single transaction
  /// This prevents database locking issues during bulk sync operations
  Future<int> syncPlaylistWithTransaction(
    Playlist playlist,
    List<Map<String, dynamic>> versionSectionItems,
    List<Map<String, dynamic>> textSectionItems,
    List<int> textItemsToPrune,
    List<int> versionItemsToPrune,
  ) async {
    final playlistId = await _playlistRepository.syncPlaylistWithTransaction(
      playlist,
      versionSectionItems,
      textSectionItems,
      textItemsToPrune,
      versionItemsToPrune,
    );

    // Reload the playlist in the provider's cache
    await loadPlaylist(playlistId);

    return playlistId;
  }

  // Update a Playlist with a version
  Future<void> addVersionToPlaylist(int playlistId, int versionId) async {
    await _playlistRepository.addVersionToPlaylist(playlistId, versionId);

    // Track added version
    trackChange('versions', playlistId);

    await loadPlaylist(playlistId);
  }

  Future<void> upsertVersionOnPlaylist(
    int playlistId,
    int versionId,
    int position,
    int? addedBy,
  ) async {
    // Check if the version already exists in the playlist
    final playlistVersionId = await _playlistRepository.getPlaylistVersionId(
      playlistId,
      versionId,
    );

    if (playlistVersionId == null) {
      // Version isn't in the playlist, add it
      await _playlistRepository.addVersionToPlaylistAtPosition(
        playlistId,
        versionId,
        position,
      );
    } else {
      // Version exists, just update its position
      await _playlistRepository.updatePlaylistVersionPosition(
        playlistVersionId,
        position,
      );
    }

    await loadPlaylist(playlistId);
  }

  // Reorder playlist items with optimistic updates
  Future<void> reorderItems(
    int oldIndex,
    int newIndex,
    Playlist playlist,
  ) async {
    final originalItems = playlist.items
        .map(
          (item) => PlaylistItem(
            id: item.id,
            type: item.type,
            contentId: item.contentId,
            position: item.position,
            duration: item.duration,
          ),
        )
        .toList();

    try {
      _updateItemOrdersOptimistically(playlist, oldIndex, newIndex);
      notifyListeners();

      List<PlaylistItem> changedList = _getChangedItems(
        originalItems,
        playlist.items,
      );
      await _playlistRepository.savePlaylistOrder(playlist.id, changedList);

      // Track item reordering
      trackChange('itemsReordered', playlist.id);
    } catch (e) {
      _rollbackItemOrders(playlist, originalItems);
      notifyListeners();
      _error = 'Erro ao reordenar itens: $e';
      rethrow;
    }
  }

  Future<void> duplicateVersion(
    int playlistId,
    int versionId,
    int currentUserId,
  ) async {
    await _playlistRepository.addVersionToPlaylist(playlistId, versionId);
    await loadPlaylist(playlistId);
  }

  Future<void> upsertTextItem({
    required int addedBy,
    required int playlistId,
    required String firebaseTextId,
    required String title,
    required String content,
    required int position,
  }) async {
    await _playlistRepository.upsertTextItem(
      addedBy,
      firebaseTextId,
      playlistId,
      title,
      content,
      position,
    );

    await loadPlaylist(playlistId);
  }

  // ===== DELETE =====
  // Delete a playlist
  Future<void> deletePlaylist(int playlistId) async {
    if (_isSaving) return;

    _isDeleting = true;
    _error = null;
    notifyListeners();

    try {
      await _playlistRepository.deletePlaylist(playlistId);
      _playlists.remove(playlistId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isDeleting = false;
      notifyListeners();
    }
  }

  // Remove a Cipher Map from a Playlist
  Future<void> removeVersionFromPlaylist(int itemId, int playlistId) async {
    await _playlistRepository.removeVersionFromPlaylist(itemId, playlistId);

    // Track removed version
    trackChange('versions', playlistId);

    await loadPlaylist(playlistId);
  }

  /// Calculate which items need to be pruned before syncing
  /// Returns (textItemsToPrune, versionItemsToPrune)
  (List<int>, List<int>) calculateItemsToPrune(
    int playlistId,
    List<Map<String, dynamic>> versionSectionItems,
    List<Map<String, dynamic>> textSectionItems,
  ) {
    final playlist = _playlists[playlistId]!;

    List<int> textItemsToPrune = [];
    List<int> versionItemsToPrune = [];

    for (final item in playlist.items) {
      switch (item.type) {
        case PlaylistItemType.flowItem:
          if (!textSectionItems.any(
            (textItem) =>
                (textItem['firebaseContentId'] == item.firebaseContentId),
          )) {
            textItemsToPrune.add(item.id!);
          }
          break;
        case PlaylistItemType.version:
          if (!versionSectionItems.any(
            (versionItem) => (versionItem['contentId'] == item.contentId),
          )) {
            versionItemsToPrune.add(item.id!);
          }
          break;
      }
    }

    return (textItemsToPrune, versionItemsToPrune);
  }

  /// Prune playlist items to insert the items from the cloud version
  Future<void> prunePlaylistItems(
    int playlistId,
    List<Map<String, dynamic>> versionSectionItems,
    List<Map<String, dynamic>> textSectionItems,
  ) async {
    final (textItemsToPrune, versionItemsToPrune) = calculateItemsToPrune(
      playlistId,
      versionSectionItems,
      textSectionItems,
    );

    _playlistRepository.prunePlaylistItems(
      playlistId,
      textItemsToPrune,
      versionItemsToPrune,
    );
  }

  // ===== UTILITY =====
  void _updateItemOrdersOptimistically(
    Playlist playlist,
    int oldIndex,
    int newIndex,
  ) {
    final items = playlist.items;

    final movedItem = items.removeAt(oldIndex);
    items.insert(newIndex, movedItem);

    for (int i = 0; i < items.length; i++) {
      items[i].position = i;
    }
  }

  // Helper method to get items that changed order
  List<PlaylistItem> _getChangedItems(
    List<PlaylistItem> original,
    List<PlaylistItem> updated,
  ) {
    List<PlaylistItem> changed = [];

    for (int i = 0; i < updated.length; i++) {
      final updatedItem = updated[i];
      final originalItem = original.firstWhere(
        (item) =>
            item.contentId == updatedItem.contentId &&
            item.type == updatedItem.type,
      );

      if (originalItem.position != updatedItem.position) {
        changed.add(updatedItem);
      }
    }

    return changed;
  }

  void _rollbackItemOrders(
    Playlist playlist,
    List<PlaylistItem> originalItems,
  ) {
    for (int i = 0; i < playlist.items.length; i++) {
      final currentItem = playlist.items[i];
      final originalItem = originalItems.firstWhere(
        (item) =>
            item.contentId == currentItem.contentId &&
            item.type == currentItem.type,
      );
      currentItem.position = originalItem.position;
    }
    playlist.items.sort((a, b) => a.position.compareTo(b.position));
  }

  // Clear cached data and reset state
  void clearCache() {
    _playlists.clear();
    _error = null;
    _isLoading = false;
    _isSaving = false;
    _isDeleting = false;
    notifyListeners();
  }

  // ===== CHANGE TRACKING & CLOUD SYNC =====
  /// Track a change for later upload to cloud
  void trackChange(String changeType, int playlistId) {
    if (!_pendingChanges.containsKey(playlistId)) {
      _pendingChanges[playlistId] = {};
    }
    _pendingChanges[playlistId]![changeType] = true;

    if (kDebugMode) {
      print('Tracked change for playlist $playlistId: $changeType');
    }
  }

  /// Build map of changes to upload to cloud for a playlist
  Map<String, dynamic> buildUpdatePayload(
    int playlistLocalId,
    PlaylistDto playlistDto,
  ) {
    Map<String, dynamic> updatePayload = {};
    final changes = _pendingChanges[playlistLocalId];

    if (changes == null) return updatePayload; // No changes to upload

    // Build update payload based on pennding changes
    // Add metadata changes
    if (changes.containsKey('metadata')) {
      updatePayload.addAll({
        'updatedAt': DateTime.now(),
        'name': playlistDto.name,
      });
    }

    // Add items if reordered or changed versions or text sections
    if (changes.containsKey('itemsReordered')) {
      updatePayload['itemOrder'] = playlistDto.itemOrder;
    }

    if (changes.containsKey('versions')) {
      updatePayload['versions'] = [
        for (final version in playlistDto.versions.values) ...[
          version.toFirestore(),
        ],
      ];
    }
    return updatePayload;
  }

  /// Clear pending changes for a playlist (without uploading)
  void clearPendingChanges(int playlistId) {
    _pendingChanges.remove(playlistId);
    notifyListeners();
  }

  /// Clear all pending changes (without uploading)
  void clearAllPendingChanges() {
    _pendingChanges.clear();
    notifyListeners();
  }

  // ===== SEARCH =====
  void setSearchTerm(String searchTerm) {
    _searchTerm = searchTerm.toLowerCase();
    notifyListeners();
  }

  void clearSearch() {
    _searchTerm = '';
    notifyListeners();
  }
}
