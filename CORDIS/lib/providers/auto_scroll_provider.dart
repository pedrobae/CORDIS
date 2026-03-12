import 'dart:async';

import 'package:cordis/services/settings_service.dart';
import 'package:flutter/material.dart';

class AutoScrollProvider extends ChangeNotifier {
  AutoScrollProvider() {
    _loadSettings();
  }
  bool scrollModeEnabled = false;
  double scrollSpeed = 1.0; // 0.5 = slow, 1 = normal, 1.5 = fast

  bool isAutoScrolling = false;

  static const int _millisecondsPerLine = 1500; // Base timing: 1000ms per line

  late final ValueNotifier<int> currentSectionIndex = ValueNotifier(
    0,
  ); // 0-based index of current section

  late final ValueNotifier<int> currentItemIndex = ValueNotifier(
    0,
  ); // 0-based index of current item for vert play

  int get _totalSections => sectionKeys.length;

   Map<int, GlobalKey> get currentSectionKeys =>
      itemSectionKeys[currentItemIndex.value] ?? {};

  Timer? autoScrollTimer;
  Timer? _updateTimer; // Separate timer for UI updates
  DateTime? _timerStartTime;

  Map<int, GlobalKey> sectionKeys = {}; // Maps section index to its GlobalKey
  Map<int, Map<int, GlobalKey>> itemSectionKeys = {}; // Maps item index, Section index to its GlobalKey
  Map<int, int> sectionLineCounts = {}; // Maps section index to its number of lines

  // ===== SETTINGS METHODS =====
  /// Gets settings from SettingsService and updates provider state
  Future<void> _loadSettings() async {
    currentSectionIndex.value = 0;
    currentItemIndex.value = 0;
    scrollModeEnabled = SettingsService.getAutoScrollEnabled();
    scrollSpeed = SettingsService.getAutoScrollSpeed();
    notifyListeners();
  }

  /// Updates scroll speed and saves to settings
  void setScrollSpeed(double value) {
    scrollSpeed = value;
    SettingsService.setAutoScrollSpeed(value);
    notifyListeners();
  }

  void toggleScrollMode() {
    scrollModeEnabled = !scrollModeEnabled;
    isAutoScrolling = false; // Stop scrolling when toggling mode
    SettingsService.setAutoScrollEnabled(scrollModeEnabled);
    notifyListeners();
  }

  // ===== AUTO SCROLL METHODS =====
  /// Toggles auto-scroll on/off and starts/stops timer accordingly
  void toggleAutoScrollTabs() {
    if (!scrollModeEnabled || isAutoScrolling) {
      stopAutoScroll();
    } else {
      startAutoScrollTabs();
    }
  }

  void stopAutoScroll() {
    autoScrollTimer?.cancel();
    autoScrollTimer = null;
    _updateTimer?.cancel();
    _updateTimer = null;
    _timerStartTime = null;
    isAutoScrolling = false;
    notifyListeners();
  }

  /// Starts the auto-scroll timer
  /// Which scrolls through sections at intervals based on line count and scrollSpeed
  void startAutoScrollTabs() {
    if (!scrollModeEnabled) return; // Scroll mode must be enabled
    if (isAutoScrolling) return; // Already scrolling
    isAutoScrolling = true;
    notifyListeners();
    if (sectionKeys.isEmpty) return; // No sections available

    // Start update timer to refresh UI with new progress value (60fps)
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      notifyListeners();
    });

    // Schedule first section scroll with its line-count-based duration
    _scheduleNextSectionScroll();
  }

  /// Schedules the next section scroll based on current section's line count
  /// Uses a single-shot timer that recalculates duration for each section
  void _scheduleNextSectionScroll() {
    if (sectionKeys.isEmpty || !isAutoScrolling) return;

    // Calculate duration for current section based on its line count
    final lineCount = sectionLineCounts[currentSectionIndex.value];
    if (lineCount == null || lineCount <= 0) return;

    final durationPerSection = Duration(
      milliseconds: (_millisecondsPerLine * lineCount ~/ scrollSpeed).toInt(),
    );

    _timerStartTime = DateTime.now();

    // Cancel existing timer and schedule next section scroll
    autoScrollTimer?.cancel();
    autoScrollTimer = Timer(durationPerSection, () {
      if (sectionKeys.isEmpty || !isAutoScrolling) return;

      debugPrint(
        'Scrolling to ${currentSectionIndex.value + 1} / $_totalSections',
      );

      // Move to next section
      if (currentSectionIndex.value < _totalSections - 1) {
        currentSectionIndex.value++;
        scrollToSectionTabs(currentSectionIndex.value);
        _scheduleNextSectionScroll(); // Schedule next with its line count
      } else {
        // Stop at the end
        stopAutoScroll();
      }
    });
  }

  /// Scrolls to the section at the given index using its GlobalKey
  void scrollToSectionTabs(int index) {
    if (index >= _totalSections) return;

    final sectionKey = sectionKeys[index];
    final context = sectionKey!.currentContext;

    if (context != null && context.mounted) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: 0.2, // Position section 20% from top
      );
    }

    currentSectionIndex.value = index;
  }


  /// Scrolls to the section at the given indexes using its GlobalKey
  void scrollToItemSection(int itemIndex, int index) {
    if (itemSectionKeys[itemIndex] == null) return;
    if (itemSectionKeys[itemIndex]![index] == null) return;

    final sectionKey = itemSectionKeys[itemIndex]![index];
    final context = sectionKey!.currentContext;

    if (context != null && context.mounted) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: 0.2, // Position section 20% from top
      );
    }

    currentItemIndex.value = itemIndex;
    currentSectionIndex.value = index;
  }

  // ===== HELPER METHODS =====
  /// Returns a value between 0.0 and 1.0 representing progress to next section scroll
  double get timerProgress {
    if (autoScrollTimer == null ||
        !autoScrollTimer!.isActive ||
        _timerStartTime == null) {
      return 0.0;
    }

    final durationPerSection = Duration(
      milliseconds: (_millisecondsPerLine * sectionLineCounts[currentSectionIndex.value]! ~/ scrollSpeed).toInt(),
    );

    // Calculate elapsed time since timer started
    final elapsed = DateTime.now().difference(_timerStartTime!);
    final elapsedMs = elapsed.inMilliseconds;

    // Return progress within current interval (0.0 to 1.0)
    return (elapsedMs % durationPerSection.inMilliseconds) /
        durationPerSection.inMilliseconds;
  }

  /// Calculates the current section index based on the scroll offset
  void calcCurrentIndex(double viewportHeight) {
    for (final entry in sectionKeys.entries) {
      final sectionContext = entry.value.currentContext;
      if (sectionContext == null) continue;

      final box = sectionContext.findRenderObject() as RenderBox?;
      if (box == null) continue;

      // Get section's position relative to the scrollable
      final sectionTop = box.localToGlobal(Offset.zero).dy;

      // Check if section is in viewport (accounting for some buffer)
      if (sectionTop > viewportHeight * 0.10 &&
          sectionTop < viewportHeight * 0.30) {
        currentSectionIndex.value = entry.key;
      }
    }
  }

  /// Calculates the current section index based on the scroll offset VERT PLAY
  void calcCurrentItemSection(double viewportHeight) {
    for (final entry in itemSectionKeys.entries) {
      for (final subEntry in entry.value.entries) {
        final sectionContext = subEntry.value.currentContext;
        if (sectionContext == null) continue;

        final box = sectionContext.findRenderObject() as RenderBox?;
        if (box == null) continue;

        // Get section's position relative to the scrollable
        final sectionTop = box.localToGlobal(Offset.zero).dy;

        // Check if section is in viewport (accounting for some buffer)
        if (sectionTop > viewportHeight * 0.15 &&
            sectionTop < viewportHeight * 0.30) {
          currentSectionIndex.value = subEntry.key;
        }
      }
    }
  }

  /// Clears cache
  void clearCache() {
    sectionKeys.clear();
    currentSectionIndex.value = 0;
    currentItemIndex.value = 0;
    _updateTimer?.cancel();
    _timerStartTime = null;
    autoScrollTimer?.cancel();
    autoScrollTimer = null;
    isAutoScrolling = false;
    notifyListeners();
  }

  // ===== CLEANUP =====
  @override
  void dispose() {
    autoScrollTimer?.cancel();
    currentSectionIndex.dispose();
    currentItemIndex.dispose();
    _updateTimer?.cancel();
    super.dispose();
  }
}
