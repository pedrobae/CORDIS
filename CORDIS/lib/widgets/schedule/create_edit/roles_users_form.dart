import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/models/domain/schedule.dart';
import 'package:cordis/models/dtos/schedule_dto.dart';
import 'package:cordis/providers/schedule/cloud_schedule_provider.dart';
import 'package:cordis/providers/schedule/local_schedule_provider.dart';
import 'package:cordis/widgets/filled_text_button.dart';
import 'package:cordis/widgets/schedule/create_edit/role_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RolesAndUsersForm extends StatefulWidget {
  final dynamic scheduleId;

  const RolesAndUsersForm({super.key, this.scheduleId});

  @override
  State<RolesAndUsersForm> createState() => _RolesAndUsersFormState();
}

class _RolesAndUsersFormState extends State<RolesAndUsersForm> {
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Consumer2<LocalScheduleProvider, CloudScheduleProvider>(
      builder: (context, scheduleProvider, cloudScheduleProvider, child) {
        final dynamic schedule = widget.scheduleId is String
            ? cloudScheduleProvider.getSchedule(widget.scheduleId)
            : scheduleProvider.getSchedule(widget.scheduleId);

        if (schedule == null) {
          return Center(child: Text('Schedule not found'));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ROLES LIST
            Expanded(
              child: schedule.roles.isEmpty
                  ? Center(
                      child: Column(
                        children: [
                          Text(
                            AppLocalizations.of(context)!.noRoles,
                            style: textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            AppLocalizations.of(context)!.addRolesInstructions,
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView(
                      children: (schedule is Schedule)
                          ? schedule.roles.map((role) {
                              return RoleCard(
                                scheduleId: widget.scheduleId,
                                role: role,
                              );
                            }).toList()
                          : (schedule as ScheduleDto).roles.map((role) {
                              return RoleCard(
                                scheduleId: widget.scheduleId,
                                role: role,
                              );
                            }).toList(),
                    ),
            ),
            // ADD ROLE BUTTON
            FilledTextButton(
              text: AppLocalizations.of(context)!.role,
              icon: Icons.add,
              onPressed: () =>
                  _openNewRoleSheet(context, schedule, scheduleProvider),
              isDense: true,
            ),
          ],
        );
      },
    );
  }

  void _openNewRoleSheet(
    BuildContext context,
    dynamic schedule,
    LocalScheduleProvider scheduleProvider,
  ) {
    final TextEditingController roleNameController = TextEditingController();

    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(0)),
            ),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(
                        context,
                      )!.createPlaceholder(AppLocalizations.of(context)!.role),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                TextField(
                  controller: roleNameController,
                  decoration: InputDecoration(
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: colorScheme.surfaceContainerLowest,
                        width: 1.2,
                      ),
                    ),
                    labelText: AppLocalizations.of(context)!.roleNameHint,
                  ),
                ),
                SizedBox(height: 16),
                FilledTextButton(
                  text: AppLocalizations.of(context)!.save,
                  isDark: true,
                  onPressed: () {
                    final roleName = roleNameController.text.trim();
                    if (roleName.isNotEmpty) {
                      scheduleProvider.addRoleToSchedule(
                        widget.scheduleId,
                        roleName,
                      );
                      Navigator.pop(context);
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
