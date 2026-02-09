import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/providers/my_auth_provider.dart';
import 'package:cordis/providers/navigation_provider.dart';
import 'package:cordis/providers/schedule/cloud_schedule_provider.dart';
import 'package:cordis/providers/schedule/local_schedule_provider.dart';
import 'package:cordis/providers/selection_provider.dart';
import 'package:cordis/providers/version/cloud_version_provider.dart';
import 'package:cordis/screens/schedule/create_new_schedule.dart';
import 'package:cordis/screens/user/share_code_screen.dart';
import 'package:cordis/widgets/filled_text_button.dart';
import 'package:cordis/widgets/schedule/library/schedule_scroll_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ScheduleLibraryScreen extends StatefulWidget {
  const ScheduleLibraryScreen({super.key});

  @override
  State<ScheduleLibraryScreen> createState() => _ScheduleLibraryScreenState();
}

class _ScheduleLibraryScreenState extends State<ScheduleLibraryScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final localScheduleProvider = context.read<LocalScheduleProvider>();
      final cloudScheduleProvider = context.read<CloudScheduleProvider>();
      final cloudVersionProvider = context.read<CloudVersionProvider>();

      if (mounted) {
        await cloudScheduleProvider.loadSchedules(
          context.read<MyAuthProvider>().id!,
        );
        await localScheduleProvider.loadSchedules();
      }
      for (var schedule in cloudScheduleProvider.schedules.values) {
        for (var versionEntry in schedule.playlist.versions.entries) {
          cloudVersionProvider.setVersion(versionEntry.key, versionEntry.value);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer4<
      LocalScheduleProvider,
      CloudScheduleProvider,
      NavigationProvider,
      SelectionProvider
    >(
      builder:
          (
            context,
            localScheduleProvider,
            cloudScheduleProvider,
            navigationProvider,
            selectionProvider,
            child,
          ) {
            return Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    top: 16.0,
                    left: 16.0,
                    right: 16.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 16,
                    children: [
                      // Search Bar
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(
                            context,
                          )!.searchSchedule,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(0),
                            borderSide: BorderSide(
                              color: colorScheme.surfaceContainer,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(0),
                            borderSide: BorderSide(color: colorScheme.primary),
                          ),
                          suffixIcon: const Icon(Icons.search),
                          fillColor: colorScheme.surfaceContainerHighest,
                          visualDensity: VisualDensity.compact,
                        ),
                        onChanged: (value) {
                          localScheduleProvider.setSearchTerm(value);
                          cloudScheduleProvider.setSearchTerm(value);
                        },
                      ),

                      // Loading state
                      if (localScheduleProvider.isLoading ||
                          cloudScheduleProvider.isLoading) ...[
                        Expanded(
                          child: Center(
                            child: CircularProgressIndicator(
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                        // Error state
                      ] else if (localScheduleProvider.error != null ||
                          cloudScheduleProvider.error != null) ...[
                        Expanded(
                          child: Center(
                            child: Text(
                              localScheduleProvider.error ??
                                  cloudScheduleProvider.error ??
                                  '',
                              style: theme.textTheme.bodyMedium!.copyWith(
                                color: colorScheme.error,
                              ),
                            ),
                          ),
                        ),
                        // Schedule list
                      ] else ...[
                        Expanded(child: ScheduleScrollView()),
                      ],
                    ],
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _openCreateScheduleSheet,
                    child: Container(
                      width: 56,
                      height: 56,
                      margin: const EdgeInsets.all(16.0),
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
    );
  }

  void _openCreateScheduleSheet() {
    final navigationProvider = context.read<NavigationProvider>();
    final selectionProvider = context.read<SelectionProvider>();

    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(0),
          ),
          child: Column(
            spacing: 16,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(
                      context,
                    )!.addPlaceholder(AppLocalizations.of(context)!.schedule),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  CloseButton(onPressed: () => Navigator.of(context).pop()),
                ],
              ),

              // ACTIONS
              Column(
                spacing: 8,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // CREATE FROM SCRATCH BUTTON
                  FilledTextButton(
                    text: AppLocalizations.of(context)!.createPlaceholder(
                      AppLocalizations.of(context)!.schedule,
                    ),
                    isDark: true,
                    onPressed: () {
                      Navigator.of(context).pop(); // Close the bottom sheet
                      selectionProvider
                          .enableSelectionMode(); // For playlist assignment
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

                  // IMPORT FROM SHARE CODE BUTTON
                  FilledTextButton(
                    text: AppLocalizations.of(context)!.shareCode,
                    onPressed: () {
                      Navigator.of(context).pop(); // Close the bottom sheet
                      navigationProvider.push(
                        ShareCodeScreen(
                          onBack: (_) {
                            navigationProvider.pop();
                          },
                          onSuccess: (_) {
                            navigationProvider
                                .pop(); // Close the share code screen
                          },
                        ),
                        showAppBar: true,
                        showDrawerIcon: true,
                      );
                    },
                  ),
                ],
              ),
              SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
