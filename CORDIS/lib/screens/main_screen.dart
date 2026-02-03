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
  void didChangeDependencies() {
    super.didChangeDependencies();
    _authProvider = context.read<MyAuthProvider>();
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _authProvider.addListener(_authListener);
    });
  }

  void _authListener() {
    if (!_authProvider.isAuthenticated) {
      Navigator.of(context).pushNamed('/login');
    }
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

    return Consumer2<MyAuthProvider, NavigationProvider>(
      builder: (context, authProvider, navigationProvider, child) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            navigationProvider.pop();
          },
          child: Scaffold(
            appBar: navigationProvider.showAppBar
                ? AppBar(
                    backgroundColor: colorScheme.surface,
                    centerTitle: true,
                    title: Image.asset(
                      'assets/logos/app_icon_transparent.png',
                      height: 40,
                    ),
                  )
                : null,
            drawer: navigationProvider.showDrawerIcon ? SideMenu() : null,
            bottomNavigationBar: navigationProvider.showBottomNavBar
                ? Container(
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: colorScheme.surfaceContainerLowest,
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: BottomNavigationBar(
                      currentIndex: navigationProvider.currentRoute.index,
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
                          navigationProvider.navigateToRoute(
                            NavigationRoute.values[index],
                          );
                        }
                      },
                      items: navigationProvider
                          .getNavigationItems(
                            context,
                            iconSize: 28,
                            color: colorScheme.onSurface,
                            activeColor: theme.colorScheme.primary,
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
                  )
                : null,
            body: SafeArea(
              child: GestureDetector(
                onHorizontalDragEnd: (details) {
                  // iOS back gesture (swipe from left edge)
                  if (details.velocity.pixelsPerSecond.dx > 300) {
                    navigationProvider.pop();
                  }
                },
                child: Consumer<NavigationProvider>(
                  builder: (context, navProvider, _) {
                    final currentIndex = navProvider.currentRoute.index;
                    final direction = currentIndex > _previousIndex
                        ? -1.0
                        : 1.0;
                    _previousIndex = currentIndex;

                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      transitionBuilder: (child, animation) {
                        final isNewScreen =
                            child.key == ValueKey(navProvider.currentRoute);
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
                        key: ValueKey(navProvider.currentRoute),
                        child: navProvider.currentScreen,
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
}
