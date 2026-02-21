import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/providers/my_auth_provider.dart';
import 'package:cordis/providers/navigation_provider.dart';
import 'package:cordis/providers/settings_provider.dart';
import 'package:cordis/providers/user_provider.dart';
import 'package:cordis/widgets/common/filled_text_button.dart';
import 'package:cordis/widgets/common/labeled_text_field.dart';
import 'package:cordis/widgets/sheet_reauthenticate.dart';
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
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer3<NavigationProvider, MyAuthProvider, UserProvider>(
      builder: (context, navProvider, authProvider, userProvider, child) {
        if (authProvider.error != null &&
            authProvider.error!.contains('requires-recent-login')) {
          // If the error indicates that re-authentication is required, show the re-authentication sheet
          WidgetsBinding.instance.addPostFrameCallback((_) {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (context) {
                return BottomSheet(
                  onClosing: () {},
                  shape: ContinuousRectangleBorder(),
                  builder: (BuildContext context) {
                    return ReAuthSheet(
                      onReAuthSuccess: () {
                        authProvider.deleteAccount();
                        authProvider.clearError();
                        userProvider.deleteUserData(authProvider.id!);
                        Navigator.of(context).pop();
                      },
                    );
                  },
                );
              },
            );
          });
        }
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
              spacing: 16,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LabeledTextField(
                  label: AppLocalizations.of(context)!.username,
                  controller: userNameController,
                ),
                LabeledTextField(
                  label: AppLocalizations.of(context)!.country,
                  controller: countryController,
                ),
                LabeledTextField(
                  label: AppLocalizations.of(context)!.language,
                  controller: languageController,
                ),
                LabeledTextField(
                  label: AppLocalizations.of(context)!.timezone,
                  controller: timezoneController,
                ),
                Spacer(),
                FilledTextButton(
                  text: AppLocalizations.of(context)!.save,
                  isDark: true,
                  onPressed: () {
                    // TODO:user - Handle save action
                  },
                ),
                FilledTextButton(
                  text: AppLocalizations.of(context)!.changePassword,
                  onPressed: () {
                    // TODO:user - Handle change password action
                  },
                ),
                TextButton(
                  onPressed: () {
                    authProvider.deleteAccount();
                    userProvider.deleteUserData(authProvider.id!);
                  },
                  child: Text(
                    AppLocalizations.of(context)!.deleteAccountRequest,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.error,
                    ),
                  ),
                ),
                Text(
                  // TODO:appVersion - Show app version and other info
                  AppLocalizations.of(context)!.appVersion('TODO'),
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.surfaceContainerLow,
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
