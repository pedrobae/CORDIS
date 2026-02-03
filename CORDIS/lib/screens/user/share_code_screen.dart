import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/providers/my_auth_provider.dart';
import 'package:cordis/providers/schedule/cloud_schedule_provider.dart';
import 'package:cordis/routes/app_routes.dart';
import 'package:cordis/widgets/filled_text_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ShareCodeScreen extends StatefulWidget {
  const ShareCodeScreen({super.key});

  @override
  State<ShareCodeScreen> createState() => ShareCodeScreenState();
}

class ShareCodeScreenState extends State<ShareCodeScreen> {
  TextEditingController shareCodeController = TextEditingController();
  late MyAuthProvider _authProvider;
  late CloudScheduleProvider _cloudScheduleProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _authProvider = context.read<MyAuthProvider>();
    _cloudScheduleProvider = context.read<CloudScheduleProvider>();
  }

  @override
  void dispose() {
    shareCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () {
            _authProvider.signOut();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 156.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 8,
          children: [
            Text(
              AppLocalizations.of(context)!.joinSchedule,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                AppLocalizations.of(context)!.shareCodeInstructions,
                textAlign: TextAlign.center,
              ),
            ),
            TextField(
              controller: shareCodeController,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(0),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.surfaceContainerLowest,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(0),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.surfaceContainerLowest,
                  ),
                ),
                hintText: AppLocalizations.of(context)!.enterShareCode,
                hintStyle: TextStyle(
                  color: Theme.of(context).colorScheme.shadow,
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledTextButton(
              text: AppLocalizations.of(context)!.getStarted,
              isDark: true,
              onPressed: _joinViaShareCode,
            ),
          ],
        ),
      ),
    );
  }

  void _joinViaShareCode() async {
    final shareCode = shareCodeController.text.trim();

    if (shareCode.isEmpty) {
      // Show error if share code is empty
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.enterShareCode)),
        );
      }
      return;
    }

    try {
      final success = await _cloudScheduleProvider.joinScheduleWithCode(
        shareCode,
      );

      if (success) {
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRoutes.main,
            (route) => false,
          ); // Close the share code screen on success
        }
      } else if (mounted) {
        // Show error if joining fails
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to join schedule.')));
      }
    } catch (e) {
      // Show error if joining fails
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }
}
