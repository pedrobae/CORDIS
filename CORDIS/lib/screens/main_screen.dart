import 'package:cordis/models/domain/cipher/version.dart';
import 'package:cordis/providers/cipher/cipher_provider.dart';
import 'package:cordis/screens/cipher/edit_cipher.dart';
import 'package:cordis/screens/playlist/edit_playlist.dart';
import 'package:cordis/widgets/ciphers/editor/sections/sheet_new_section.dart';
import 'package:cordis/widgets/home/quick_action_sheet.dart';
import 'package:cordis/widgets/schedule/library/schedule_actions_sheet.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:cordis/providers/navigation_provider.dart';
import 'package:cordis/providers/my_auth_provider.dart';

import 'package:cordis/widgets/side_menu.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  int _previousIndex = 0;
  late MyAuthProvider _authProvider;

  @override
  void initState() {
    super.initState();

    _authProvider = context.read<MyAuthProvider>();
    _authProvider.addListener(_authListener);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _redirectIfNeeded();
    });
  }

  void _authListener() {
    _redirectIfNeeded();
  }

  void _redirectIfNeeded() {
    if (_authProvider.isAuthenticated) return;

    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
  }

  @override
  void dispose() {
    _authProvider.removeListener(_authListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer3<MyAuthProvider, NavigationProvider, CipherProvider>(
      builder:
          (context, authProvider, navigationProvider, cipherProvider, child) {
            return PopScope(
              canPop: false,
              onPopInvokedWithResult: (didPop, _) async {
                if (didPop) return;
                await navigationProvider.attemptPop(context);
              },
              child: Scaffold(
                appBar: navigationProvider.showAppBar
                    ? _buildAppBar(colorScheme)
                    : null,
                drawer: navigationProvider.showDrawerIcon
                    ? SideMenu() //
                    : null,
                bottomNavigationBar: navigationProvider.showBottomNavBar
                    ? _buildBottomNavigationBar(colorScheme, navigationProvider)
                    : null,
                floatingActionButton: navigationProvider.showFAB
                    ? _buildFAB(colorScheme, navigationProvider, cipherProvider)
                    : null,
                body: SafeArea(
                  child: GestureDetector(
                    onHorizontalDragEnd: (details) {
                      // iOS back gesture (swipe from left edge)
                      if (details.velocity.pixelsPerSecond.dx > 300) {
                        navigationProvider.attemptPop(context);
                      }
                    },
                    child: Builder(
                      builder: (context) {
                        final currentIndex =
                            navigationProvider.currentRoute.index;
                        final direction = currentIndex > _previousIndex
                            ? -1.0
                            : 1.0;
                        _previousIndex = currentIndex;

                        return AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          transitionBuilder: (child, animation) {
                            final isNewScreen =
                                child.key ==
                                ValueKey(navigationProvider.currentRoute);
                            final slideDirection = isNewScreen
                                ? -direction
                                : direction;

                            return SlideTransition(
                              position:
                                  Tween<Offset>(
                                    begin: Offset(slideDirection, 0),
                                    end: Offset.zero,
                                  ).animate(
                                    CurvedAnimation(
                                      parent: animation,
                                      curve: Curves.easeInOutCubic,
                                    ),
                                  ),
                              child: child,
                            );
                          },
                          layoutBuilder: (currentChild, previousChildren) {
                            return Stack(
                              children: <Widget>[
                                ...previousChildren,
                                currentChild ?? const SizedBox.shrink(),
                              ],
                            );
                          },
                          child: KeyedSubtree(
                            key: ValueKey(navigationProvider.currentRoute),
                            child: navigationProvider.buildCurrentScreen(
                              context,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            );
          },
    );
  }

  AppBar _buildAppBar(ColorScheme colorScheme) {
    return AppBar(
      backgroundColor: colorScheme.surface,
      centerTitle: true,
      title: Image.asset('assets/logos/app_icon_transparent.png', height: 40),
    );
  }

  Container _buildBottomNavigationBar(
    ColorScheme colorScheme,
    NavigationProvider navProvider,
  ) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: colorScheme.surfaceContainerLowest,
            width: 0.5,
          ),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: navProvider.currentRoute.index,
        selectedLabelStyle: TextStyle(
          color: colorScheme.primary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 2,
        onTap: (index) {
          if (mounted) {
            navProvider.attemptPop(
              context,
              route: NavigationRoute.values[index],
            );
          }
        },
        items: navProvider
            .getNavigationItems(
              context,
              iconSize: 28,
              color: colorScheme.onSurface,
              activeColor: colorScheme.primary,
            )
            .map(
              (navItem) => BottomNavigationBarItem(
                icon: navItem.icon,
                label: navItem.title,
                backgroundColor: colorScheme.surface,
                activeIcon: navItem.activeIcon,
              ),
            )
            .toList(),
      ),
    );
  }

  GestureDetector _buildFAB(
    ColorScheme colorScheme,
    NavigationProvider navProvider,
    CipherProvider cipherProvider,
  ) {
    return GestureDetector(
      onLongPress: () {
        if (navProvider.currentRoute == NavigationRoute.library) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (context) {
              return NewSectionSheet(secret: true);
            },
          );
        }
      },
      onTap: () {
        switch (navProvider.currentRoute) {
          case NavigationRoute.library:
            navProvider.push(
              EditCipherScreen(
                versionID: -1,
                cipherID: -1,
                versionType: VersionType.brandNew,
              ),
              showBottomNavBar: true,
              onPopCallback: () => cipherProvider.clearNewCipherFromCache(),
            );
            break;
          case NavigationRoute.playlists:
            navProvider.push(EditPlaylistScreen(), showBottomNavBar: true);
            break;
          case NavigationRoute.home:
          case NavigationRoute.schedule:
            _showBottomSheetForCurrentRoute(navProvider.currentRoute);
            break;
        }
      },
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colorScheme.onSurface,
          boxShadow: [
            BoxShadow(
              color: colorScheme.surfaceContainerLowest,
              spreadRadius: 2,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(Icons.add, color: colorScheme.surface),
      ),
    );
  }

  void _showBottomSheetForCurrentRoute(NavigationRoute route) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        switch (route) {
          case NavigationRoute.home:
            return QuickActionSheet();
          case NavigationRoute.schedule:
            return ScheduleActionsSheet();
          case NavigationRoute.library:
          case NavigationRoute.playlists:
            throw Exception("These routes' FABs don't open a bottom sheet");
        }
      },
    );
  }
}
