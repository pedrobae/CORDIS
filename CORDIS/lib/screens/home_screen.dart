import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/models/domain/cipher/version.dart';
import 'package:cordis/models/domain/schedule.dart';
import 'package:cordis/providers/navigation_provider.dart';
import 'package:cordis/providers/schedule/cloud_schedule_provider.dart';
import 'package:cordis/providers/schedule/local_schedule_provider.dart';
import 'package:cordis/providers/selection_provider.dart';
import 'package:cordis/providers/version/cloud_version_provider.dart';
import 'package:cordis/screens/cipher/edit_cipher.dart';
import 'package:cordis/screens/playlist/edit_playlist.dart';
import 'package:cordis/screens/schedule/create_new_schedule.dart';
import 'package:cordis/screens/user/share_code_screen.dart';
import 'package:cordis/widgets/filled_text_button.dart';
import 'package:cordis/widgets/schedule/library/cloud_schedule_card.dart';
import 'package:cordis/widgets/schedule/library/schedule_card.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cordis/providers/my_auth_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadData();
    });
  }

  Future<void> _loadData() async {
    final authProvider = context.read<MyAuthProvider>();
    final localScheduleProvider = context.read<LocalScheduleProvider>();
    final cloudScheduleProvider = context.read<CloudScheduleProvider>();
    final cloudVersionProvider = context.read<CloudVersionProvider>();

    await localScheduleProvider.loadSchedules();
    await cloudScheduleProvider.loadSchedules(authProvider.id!);

    for (var schedule in cloudScheduleProvider.schedules.values) {
      for (var versionEntry in schedule.playlist.versions.entries) {
        cloudVersionProvider.setVersion(versionEntry.key, versionEntry.value);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child:
          Consumer5<
            MyAuthProvider,
            LocalScheduleProvider,
            CloudScheduleProvider,
            NavigationProvider,
            SelectionProvider
          >(
            builder:
                (
                  context,
                  authProvider,
                  localScheduleProvider,
                  cloudScheduleProvider,
                  navigationProvider,
                  selectionProvider,
                  child,
                ) {
                  final textTheme = Theme.of(context).textTheme;
                  final colorScheme = Theme.of(context).colorScheme;
                  final locale = Localizations.localeOf(context);

                  if (authProvider.isLoading) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(AppLocalizations.of(context)!.loading),
                        ],
                      ),
                    );
                  }

                  if (authProvider.error != null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.errorMessage(
                              AppLocalizations.of(context)!.authentication,
                              authProvider.error!,
                            ),
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => authProvider.signInAnonymously(),
                            child: Text(AppLocalizations.of(context)!.tryAgain),
                          ),
                        ],
                      ),
                    );
                  }

                  final nextLocalSchedule = localScheduleProvider
                      .getNextSchedule();
                  final nextCloudSchedule = cloudScheduleProvider
                      .getNextSchedule();

                  dynamic nextSchedule;
                  if (nextLocalSchedule != null && nextCloudSchedule != null) {
                    nextSchedule =
                        nextLocalSchedule.time.isBefore(
                          TimeOfDay.fromDateTime(
                            nextCloudSchedule.datetime.toDate(),
                          ),
                        )
                        ? nextLocalSchedule
                        : nextCloudSchedule;
                  } else {
                    nextSchedule = nextLocalSchedule ?? nextCloudSchedule;
                  }
                  // HOME SCREEN
                  return Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: 24,
                        children: [
                          // Current date
                          Text(
                            DateFormat(
                              'EEEE, MMM d',
                              locale.languageCode,
                            ).format(DateTime.now()),
                            style: textTheme.bodyMedium!.copyWith(
                              color: colorScheme.onSurface,
                              fontSize: 14,
                            ),
                          ),

                          _buildWelcomeMessage(
                            context,
                            authProvider,
                            textTheme,
                          ),

                          _buildNextSchedule(
                            context,
                            localScheduleProvider,
                            nextSchedule,
                            textTheme,
                            colorScheme,
                          ),
                        ],
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () => _showQuickActionsSheet(
                            context,
                            navigationProvider,
                            selectionProvider,
                          ),
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
                        ),
                      ),
                    ],
                  );
                },
          ),
    );
  }

  Widget _buildWelcomeMessage(
    BuildContext context,
    MyAuthProvider authProvider,
    TextTheme textTheme,
  ) {
    return Text(
      AppLocalizations.of(context)!.helloUser(
        authProvider.userName ?? AppLocalizations.of(context)!.guest,
      ),
      style: textTheme.headlineLarge!.copyWith(
        fontWeight: FontWeight.w700,
        fontSize: 24,
      ),
    );
  }

  Widget _buildNextSchedule(
    BuildContext context,
    LocalScheduleProvider scheduleProvider,
    dynamic nextSchedule,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    if (scheduleProvider.isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (nextSchedule == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        spacing: 16,
        children: [
          SizedBox(height: 32),
          Text(
            AppLocalizations.of(context)!.welcome,
            style: textTheme.titleMedium!.copyWith(
              color: colorScheme.onSurface,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            AppLocalizations.of(context)!.getStartedMessage,
            style: textTheme.bodyMedium!.copyWith(
              color: colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 16,
      children: [
        // SCHEDULE LABEL
        Text(
          AppLocalizations.of(context)!.nextUp,
          style: textTheme.titleMedium!.copyWith(
            color: colorScheme.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        // SCHEDULE CARD
        (nextSchedule is Schedule)
            ? ScheduleCard(scheduleId: nextSchedule.id)
            : CloudScheduleCard(scheduleId: nextSchedule.firebaseId),
      ],
    );
  }

  void _showQuickActionsSheet(
    BuildContext context,
    NavigationProvider navigationProvider,
    SelectionProvider selectionProvider,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(0),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            spacing: 8,
            children: [
              // HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context)!.quickAction,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      fontSize: 18,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),

              // ACTIONS
              // DIRECT CREATION BUTTONS
              FilledTextButton(
                trailingIcon: Icons.chevron_right,
                isDiscrete: true,
                text: AppLocalizations.of(
                  context,
                )!.createPlaceholder(AppLocalizations.of(context)!.playlist),
                onPressed: () {
                  Navigator.of(context).pop(); // Close the bottom sheet
                  navigationProvider.navigateToRoute(NavigationRoute.playlists);
                  navigationProvider.push(EditPlaylistScreen());
                },
              ),
              FilledTextButton(
                trailingIcon: Icons.chevron_right,
                isDiscrete: true,
                text: AppLocalizations.of(
                  context,
                )!.addPlaceholder(AppLocalizations.of(context)!.cipher),
                onPressed: () {
                  Navigator.of(context).pop(); // Close the bottom sheet
                  navigationProvider.navigateToRoute(NavigationRoute.library);
                  navigationProvider.push(
                    EditCipherScreen(
                      cipherID: -1,
                      versionID: -1,
                      versionType: VersionType.brandNew,
                    ),
                    showAppBar: false,
                    showDrawerIcon: false,
                  );
                },
              ),
              FilledTextButton(
                trailingIcon: Icons.chevron_right,
                isDiscrete: true,
                text: AppLocalizations.of(context)!.assignSchedule,
                onPressed: () {
                  Navigator.of(context).pop(); // Close the bottom sheet
                  navigationProvider.navigateToRoute(NavigationRoute.schedule);
                  selectionProvider.enableSelectionMode();
                  navigationProvider.push(
                    CreateScheduleScreen(creationStep: 1),
                    showAppBar: false,
                    showDrawerIcon: false,
                    onPopCallback: () {
                      selectionProvider.disableSelectionMode();
                    },
                  );
                },
              ),
              FilledTextButton(
                text: AppLocalizations.of(context)!.enterShareCode,
                trailingIcon: Icons.chevron_right,
                isDiscrete: true,
                onPressed: () {
                  Navigator.of(context).pop(); // Close the bottom sheet
                  navigationProvider.push(
                    ShareCodeScreen(
                      onBack: (_) {
                        navigationProvider.pop(); // Close the share code screen
                      },
                      onSuccess: (_) {
                        navigationProvider.pop(); // Close the share code screen
                      },
                    ),
                    showAppBar: true,
                    showDrawerIcon: true,
                  );
                },
              ),
              SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
