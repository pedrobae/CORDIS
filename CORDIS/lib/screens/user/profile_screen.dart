import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/providers/my_auth_provider.dart';
import 'package:cordis/providers/navigation_provider.dart';
import 'package:cordis/providers/settings_provider.dart';
import 'package:cordis/widgets/common/labeled_text_field.dart';
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
                const SizedBox(height: 16),
                LabeledTextField(
                  label: AppLocalizations.of(context)!.timezone,
                  controller: timezoneController,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
