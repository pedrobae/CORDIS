import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/screens/home_screen.dart';
import 'package:cordis/screens/cipher/cipher_library.dart';
import 'package:cordis/screens/playlist/playlist_library.dart';
import 'package:cordis/screens/schedule/schedule_library.dart';
import 'package:flutter/material.dart';

enum NavigationRoute { home, library, playlists, schedule }

class NavigationProvider extends ChangeNotifier {
  NavigationRoute _currentRoute = NavigationRoute.home;

  static final List<Widget> _screenStack = [];
  static final List<bool> _showAppBarStack = [];
  static final List<bool> _showDrawerIconStack = [];
  static final List<bool> _showBottomNavBarStack = [];

  static final List<VoidCallback> _onPopCallbacks = [];

  Widget?
  screenOnForeground; // Screen that can be placed on top of the current stack without affecting it

  bool _isLoading = false;
  String? _error;

  // Getters
  NavigationRoute get currentRoute => _currentRoute;

  Widget get currentScreen => Stack(
    children: [
      _screenStack.isNotEmpty
          ? _screenStack.last
          : _getScreenForRoute(_currentRoute),
      if (screenOnForeground != null) screenOnForeground!,
    ],
  );
  bool get showAppBar =>
      _showAppBarStack.isNotEmpty ? _showAppBarStack.last : true;
  bool get showDrawerIcon =>
      _showDrawerIconStack.isNotEmpty ? _showDrawerIconStack.last : true;
  bool get showBottomNavBar =>
      _showBottomNavBarStack.isNotEmpty ? _showBottomNavBarStack.last : true;

  bool get isLoading => _isLoading;
  String? get error => _error;

  /// USED BY THE MAIN SCREEN TO NAVIGATE BETWEEN CONTENT TABS

  // Navigation methods following your provider pattern
  void navigateToRoute(NavigationRoute route) {
    _currentRoute = route;
    _screenStack.clear();
    _showAppBarStack.clear();
    _showDrawerIconStack.clear();
    _showBottomNavBarStack.clear();

    // Clear onPop callbacks
    while (_onPopCallbacks.isNotEmpty) {
      _onPopCallbacks.last();
      _onPopCallbacks.removeLast();
    }

    _error = null; // Clear any previous errors
    notifyListeners();
  }

  void push(
    Widget screen, {
    bool showAppBar = true,
    bool showDrawerIcon = true,
    bool showBottomNavBar = true,
    VoidCallback? onPopCallback,
  }) {
    _screenStack.add(screen);
    _showAppBarStack.add(showAppBar);
    _showDrawerIconStack.add(showDrawerIcon);
    _showBottomNavBarStack.add(showBottomNavBar);
    _onPopCallbacks.add(onPopCallback ?? () {});
    notifyListeners();
  }

  void pushForeground(Widget screen) {
    screenOnForeground = screen;
    notifyListeners();
  }

  void pushReplacement(
    Widget screen, {
    bool showAppBar = true,
    bool showDrawerIcon = true,
    bool showBottomNavBar = true,
    VoidCallback? onPopCallback,
  }) {
    if (_screenStack.isNotEmpty) {
      _screenStack.removeLast();
      _showAppBarStack.removeLast();
      _showDrawerIconStack.removeLast();
      _showBottomNavBarStack.removeLast();
      _onPopCallbacks.removeLast();
    }
    push(
      screen,
      showAppBar: showAppBar,
      showDrawerIcon: showDrawerIcon,
      showBottomNavBar: showBottomNavBar,
      onPopCallback: onPopCallback,
    );
  }

  void pop() {
    if (_screenStack.isNotEmpty) {
      try {
        _onPopCallbacks.last();
      } catch (e) {
        // Silently catch callback errors during pop to avoid deactivated widget issues
        debugPrint('Error in onPopCallback: $e');
      }
      _onPopCallbacks.removeLast();
      _screenStack.removeLast();
      _showAppBarStack.removeLast();
      _showDrawerIconStack.removeLast();
      _showBottomNavBarStack.removeLast();
      notifyListeners();
    }
  }

  void popForeground() {
    if (screenOnForeground != null) {
      screenOnForeground = null;
      notifyListeners();
    }
  }

  // Error handling following your provider pattern
  void setError(String error) {
    _error = error;
    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Loading state management
  void setLoading(bool loading) {
    _isLoading = loading;
    if (loading) {
      _error = null; // Clear errors when starting to load
    }
    notifyListeners();
  }

  Widget _getScreenForRoute(NavigationRoute route) {
    switch (route) {
      case NavigationRoute.home:
        return HomeScreen();
      case NavigationRoute.library:
        return CipherLibraryScreen();
      case NavigationRoute.playlists:
        return PlaylistLibraryScreen();
      case NavigationRoute.schedule:
        return ScheduleLibraryScreen();
    }
  }

  NavigationItem getNavigationItem(
    BuildContext context,
    NavigationRoute route, {
    Color? color,
    Color? activeColor,
    double iconSize = 64,
  }) {
    return NavigationItem(
      route: route,
      title: _getTitleForRoute(context, route),
      icon: _getIconForRoute(route, iconColor: color, iconSize: iconSize),
      activeIcon: _getIconForRoute(
        route,
        iconColor: activeColor,
        iconSize: iconSize,
      ),
      index: route.index,
    );
  }

  String _getTitleForRoute(BuildContext context, NavigationRoute route) {
    switch (route) {
      case NavigationRoute.home:
        return AppLocalizations.of(context)!.home;
      case NavigationRoute.library:
        return AppLocalizations.of(context)!.library;
      case NavigationRoute.playlists:
        return AppLocalizations.of(context)!.playlists;
      case NavigationRoute.schedule:
        return AppLocalizations.of(context)!.schedule;
    }
  }

  Icon _getIconForRoute(
    NavigationRoute route, {
    Color? iconColor,
    double iconSize = 64,
  }) {
    switch (route) {
      case NavigationRoute.home:
        return Icon(Icons.home, color: iconColor, size: iconSize);
      case NavigationRoute.library:
        return Icon(Icons.library_music, color: iconColor, size: iconSize);
      case NavigationRoute.playlists:
        return Icon(
          Icons.playlist_play_rounded,
          color: iconColor,
          size: iconSize,
        );
      case NavigationRoute.schedule:
        return Icon(
          Icons.calendar_month_sharp,
          color: iconColor,
          size: iconSize,
        );
    }
  }

  // Compose navigation lists as needed
  List<NavigationItem> getNavigationItems(
    BuildContext context, {
    Color? color,
    Color? activeColor,
    double iconSize = 64,
  }) {
    return [
      for (var route in NavigationRoute.values)
        getNavigationItem(
          context,
          route,
          color: color,
          activeColor: activeColor,
          iconSize: iconSize,
        ),
    ];
  }
}

// Helper class for navigation items
class NavigationItem {
  final NavigationRoute route;
  final String title;
  final Icon icon;
  final Icon activeIcon;
  final int index;

  NavigationItem({
    required this.route,
    required this.title,
    required this.icon,
    required this.activeIcon,
    required this.index,
  });
}

class AdminNavigationItem {
  final String title;
  final Icon icon;

  AdminNavigationItem({required this.title, required this.icon});
}

extension NavigationProviderAdmin on NavigationProvider {
  List<AdminNavigationItem> getAdminItems({
    Color? iconColor,
    double iconSize = 64,
  }) {
    return [
      AdminNavigationItem(
        title: 'Gerenciamento de Usuários',
        icon: Icon(Icons.manage_accounts, color: iconColor, size: iconSize),
      ),
      // Add more admin items here as needed
    ];
  }
}
