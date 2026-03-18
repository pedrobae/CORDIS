import 'package:cordis/models/domain/playlist/playlist_item.dart';
import 'package:flutter/foundation.dart';

import 'package:cordis/utils/debug/build_trace.dart';

/// Lightweight provider for managing PlayScheduleScreen state
/// This allows item navigation without rebuilding expensive widget trees
class PlayScheduleStateProvider extends ChangeNotifier {
  int _currentItemIndex = 0;
  bool _showSettings = false;
  bool _isLoading = false;
  List<PlaylistItem> _items = [];

  int get currentItemIndex => _currentItemIndex;
  bool get showSettings => _showSettings;
  bool get isLoading => _isLoading;
  PlaylistItem? get currentItem =>
      _items.isNotEmpty ? _items[_currentItemIndex] : null;
  PlaylistItem? get nextItem => (_currentItemIndex < _items.length - 1)
      ? _items[_currentItemIndex + 1]
      : null;
  int get itemCount => _items.length;

  PlaylistItem? getItemAt(int index) {
    if (index < 0 || index >= _items.length) return null;
    return _items[index];
  }

  set currentItemIndex(int index) {
    if (index < 0 || index >= _items.length) return;
    if (_currentItemIndex == index) return;

    _currentItemIndex = index;
    _notify('currentItemIndex=$index');
  }

  void toggleSettings() {
    _showSettings = !_showSettings;
    _notify('toggleSettings showSettings=$_showSettings');
  }

  void setShowSettings(bool value) {
    if (_showSettings != value) {
      _showSettings = value;
      _notify('setShowSettings value=$value');
    }
  }

  void setItems(List<PlaylistItem> items) {
    _items = items;
    _currentItemIndex = 0;
    _isLoading = false;
    _notify('setItems count=${items.length}');
  }

  void reset() {
    _currentItemIndex = 0;
    _showSettings = false;
    _isLoading = true;
    _items = [];
  }

  void _notify(String reason) {
    BuildTrace.event('PlayScheduleStateProvider.notifyListeners', reason);
    notifyListeners();
  }
}
