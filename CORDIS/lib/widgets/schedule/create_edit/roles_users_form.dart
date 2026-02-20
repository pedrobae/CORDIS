import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/models/domain/schedule.dart';
import 'package:cordis/models/dtos/schedule_dto.dart';
import 'package:cordis/providers/schedule/cloud_schedule_provider.dart';
import 'package:cordis/providers/schedule/local_schedule_provider.dart';
import 'package:cordis/widgets/common/filled_text_button.dart';
import 'package:cordis/widgets/schedule/create_edit/role_card.dart';
import 'package:cordis/widgets/schedule/create_edit/sheet_edit_role.dart';
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
                            style: textTheme.headlineSmall,
                          ),
                          SizedBox(height: 16),
                          Text(
                            AppLocalizations.of(context)!.addRolesInstructions,
                            style: textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView(
                      children: (schedule is Schedule)
                          ? schedule.roles.map((role) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 16.0),
                                child: RoleCard(
                                  scheduleId: widget.scheduleId,
                                  role: role,
                                ),
                              );
                            }).toList()
                          : (schedule as ScheduleDto).roles.map((role) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 16.0),
                                child: RoleCard(
                                  scheduleId: widget.scheduleId,
                                  role: role,
                                ),
                              );
                            }).toList(),
                    ),
            ),
            // ADD ROLE BUTTON
            FilledTextButton(
              text: AppLocalizations.of(context)!.role,
              isDense: true,
              icon: Icons.add,
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (context) {
                  return EditRoleSheet(
                    scheduleId: widget.scheduleId,
                    role: null,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
