import 'package:flutter/material.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:cordis/l10n/app_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:provider/provider.dart';
import 'package:cordis/providers/admin_provider.dart';
import 'package:cordis/providers/my_auth_provider.dart';
import 'package:cordis/providers/cipher_provider.dart';
import 'package:cordis/providers/import_provider.dart';
import 'package:cordis/providers/layout_settings_provider.dart';
import 'package:cordis/providers/navigation_provider.dart';
import 'package:cordis/providers/parser_provider.dart';
import 'package:cordis/providers/playlist_provider.dart';
import 'package:cordis/providers/section_provider.dart';
import 'package:cordis/providers/selection_provider.dart';
import 'package:cordis/providers/settings_provider.dart';
import 'package:cordis/providers/schedule/local_schedule_provider.dart';
import 'package:cordis/providers/schedule/cloud_schedule_provider.dart';
import 'package:cordis/providers/flow_item_provider.dart';
import 'package:cordis/providers/user_provider.dart';
import 'package:cordis/providers/version/local_version_provider.dart';
import 'package:cordis/providers/version/cloud_version_provider.dart';

import 'package:cordis/routes/app_routes.dart';

import 'package:cordis/services/firebase_service.dart';
import 'package:cordis/services/settings_service.dart';

void main() async {
  // Ensure Flutter is initialized before database operations
  WidgetsFlutterBinding.ensureInitialized();

  await FirebaseService.initialize();

  await SettingsService.initialize();

  // Initialize date formatting for all locales
  await initializeDateFormatting();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => MyAuthProvider()),
        ChangeNotifierProvider(create: (_) => CipherProvider()),
        ChangeNotifierProvider(create: (_) => ImportProvider()),
        ChangeNotifierProvider(
          create: (_) => LayoutSettingsProvider()..loadSettings(),
        ),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => ParserProvider()),
        ChangeNotifierProvider(create: (_) => PlaylistProvider()),
        ChangeNotifierProvider(create: (_) => SectionProvider()),
        ChangeNotifierProvider(create: (_) => SelectionProvider()),
        ChangeNotifierProvider(
          create: (_) => SettingsProvider()..loadSettings(),
        ),
        ChangeNotifierProvider(create: (_) => CloudScheduleProvider()),
        ChangeNotifierProvider(create: (_) => LocalScheduleProvider()),
        ChangeNotifierProvider(create: (_) => FlowItemProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()..loadUsers()),
        ChangeNotifierProvider(create: (_) => CloudVersionProvider()),
        ChangeNotifierProvider(create: (_) => LocalVersionProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en', ''), Locale('pt', 'BR')],
            locale: settingsProvider.locale,
            title: AppLocalizations.of(context)?.appName,
            theme: settingsProvider.lightTheme,
            darkTheme: settingsProvider.darkTheme,
            themeMode: settingsProvider.themeMode,
            initialRoute: AppRoutes.main,
            routes: AppRoutes.routes,
          );
        },
      ),
    );
  }
}
