import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/providers/my_auth_provider.dart';
import 'package:cordis/providers/navigation_provider.dart';
import 'package:cordis/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final userNameController = TextEditingController();
  final countryController = TextEditingController();
  final languageController = TextEditingController();
  final timezoneController = TextEditingController();
  bool hasChanges = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<MyAuthProvider>();
      final settingsProvider = context.read<SettingsProvider>();

      userNameController.text =
          authProvider.userName ?? AppLocalizations.of(context)!.guest;
      countryController.text = settingsProvider.locale.countryCode ?? '';
      languageController.text = settingsProvider.locale.toLanguageTag();
      timezoneController.text = settingsProvider.timeZone;
    });
  }

  @override
  void dispose() {
    userNameController.dispose();
    countryController.dispose();
    languageController.dispose();
    timezoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NavigationProvider>(
      builder: (context, navProvider, child) {
        return Scaffold(
          appBar: AppBar(
            leading: BackButton(
              onPressed: () {
                navProvider.pop();
              },
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: userNameController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.username,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: countryController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.country,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: languageController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.language,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: timezoneController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.timezone,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
