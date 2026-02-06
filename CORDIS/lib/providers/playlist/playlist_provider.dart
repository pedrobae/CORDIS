import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cordis/models/domain/playlist/playlist.dart';
import 'package:cordis/models/domain/playlist/playlist_item.dart';
import 'package:cordis/repositories/local_playlist_repository.dart';

class PlaylistProvider extends ChangeNotifier {
  final PlaylistRepository _playlistRepository = PlaylistRepository();

  PlaylistProvider();

  final Map<int, Playlist> _playlists = {};

  bool _isLoading = false;
  bool _isSaving = false;
  bool _isDeleting = false;

  String? _error;

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

    await loadPlaylist(id); // Reload just this playlist
  }

  Future<int> upsertPlaylist(Playlist playlist) async {
    final playlistId = await _playlistRepository.upsertPlaylist(playlist);
    await loadPlaylist(playlistId);

    return playlistId;
  }

  // Update a Playlist with a version
  Future<void> addVersionToPlaylist(int playlistId, int versionId) async {
    await _playlistRepository.addVersionToPlaylist(playlistId, versionId);

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
    try {
      final items = playlist.items;

      final movedItem = items.removeAt(oldIndex);
      items.insert(newIndex, movedItem);

      for (int i = 0; i < items.length; i++) {
        items[i].position = i;
      }
      notifyListeners();

      await _playlistRepository.savePlaylistOrder(playlist.id, playlist.items);
    } catch (e) {
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

    await loadPlaylist(playlistId);
  }

  // ===== UTILITY =====
  // Clear cached data and reset state
  void clearCache() {
    _playlists.clear();
    _error = null;
    _isLoading = false;
    _isSaving = false;
    _isDeleting = false;
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
