import 'package:cordis/screens/admin/admin_screen.dart';
import 'package:cordis/screens/admin/user_management_screen.dart';
import 'package:cordis/screens/user/login_screen.dart';
import 'package:cordis/screens/settings_screen.dart';
import 'package:cordis/screens/user/register_screen.dart';
import 'package:cordis/screens/main_screen.dart';
import 'package:flutter/material.dart';

class AppRoutes {
  static const String main = '/';
  static const String register = '/register';
  static const String login = '/login';
  static const String admin = '/admin';
  static const String adminUserManagement = '/admin/user-management';
  static const String settings = '/settings';

  static Map<String, WidgetBuilder> routes = {
    main: (context) => const MainScreen(),
    register: (context) => const RegisterScreen(),
    login: (context) => const LoginScreen(),
    admin: (context) => const AdminScreen(),
    adminUserManagement: (context) => const UserManagementScreen(),
    settings: (context) => const SettingsScreen(),
  };
}
