import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/models/domain/schedule.dart';
import 'package:cordis/providers/schedule/local_schedule_provider.dart';
import 'package:cordis/providers/user_provider.dart';
import 'package:cordis/widgets/filled_text_button.dart';
import 'package:cordis/widgets/schedule/create_edit/sheet_add_user.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UsersBottomSheet extends StatefulWidget {
  final dynamic scheduleId;
  final dynamic role; // Role or RoleDTO object

  const UsersBottomSheet({
    super.key,
    required this.scheduleId,
    required this.role,
  });

  @override
  State<UsersBottomSheet> createState() => _UsersBottomSheetState();
}

class _UsersBottomSheetState extends State<UsersBottomSheet> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Consumer2<UserProvider, LocalScheduleProvider>(
      builder: (context, userProvider, scheduleProvider, child) {
        final users = (widget.role is Role)
            ? userProvider.getUsersByIds(widget.role.memberIds)
            : userProvider.getUsersByFirebaseIds(widget.role.memberIds);

        return Container(
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
                    )!.assignMembersToRole(widget.role.name),
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 4,
                children: [
                  FilledTextButton(
                    text: AppLocalizations.of(
                      context,
                    )!.addPlaceholder(AppLocalizations.of(context)!.member),
                    onPressed: () =>
                        _openAddUserSheet(context, scheduleProvider),
                    icon: Icons.add,
                    isDense: true,
                  ),
                  FilledTextButton(
                    text: AppLocalizations.of(context)!.clear,
                    onPressed: () {},
                    isDense: true,
                  ),
                ],
              ),
              SizedBox(height: 24),
              // MEMBERS OF ROLE LIST
              ...users.map<Widget>((member) {
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(0),
                    border: Border.all(
                      color: colorScheme.surfaceContainerLowest,
                      width: 1.2,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              member.username,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              member.email,
                              style: TextStyle(
                                fontSize: 14,
                                color: colorScheme.shadow,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: Icon(Icons.remove_circle_outline),
                        color: colorScheme.error,
                      ),
                    ],
                  ),
                );
              }),
              SizedBox(height: 24),

              // SAVE BUTTON
              FilledTextButton(
                text: AppLocalizations.of(context)!.save,
                isDark: true,
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _openAddUserSheet(
    BuildContext context,
    LocalScheduleProvider scheduleProvider,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: AddUserSheet(scheduleId: widget.scheduleId, role: widget.role),
        );
      },
    );
  }
}
