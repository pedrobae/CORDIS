import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/providers/schedule/local_schedule_provider.dart';
import 'package:cordis/widgets/common/filled_text_button.dart';
import 'package:cordis/widgets/common/labeled_text_field.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EditRoleSheet extends StatefulWidget {
  final dynamic scheduleId;
  final dynamic role; // Role or RoleDTO object or Null for new role

  const EditRoleSheet({
    super.key,
    required this.scheduleId,
    required this.role,
  });

  @override
  State<EditRoleSheet> createState() => _EditRoleSheetState();
}

class _EditRoleSheetState extends State<EditRoleSheet> {
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.role != null) {
      _nameController.text = widget.role.name;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Consumer<LocalScheduleProvider>(
      builder: (context, scheduleProvider, child) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(0)),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 16,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.role == null
                        ? AppLocalizations.of(context)!.createPlaceholder(
                            AppLocalizations.of(context)!.role,
                          )
                        : AppLocalizations.of(context)!.editPlaceholder(
                            AppLocalizations.of(context)!.role,
                          ),
                    style: textTheme.titleMedium,
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              // NAME FIELD
              LabeledTextField(
                label: AppLocalizations.of(context)!.name,
                controller: _nameController,
                hint: AppLocalizations.of(context)!.roleNameHint,
              ),
              // SAVE BUTTON
              FilledTextButton(
                text: widget.role == null
                    ? AppLocalizations.of(context)!.create
                    : AppLocalizations.of(context)!.save,
                isDark: true,
                onPressed: () {
                  if (widget.role == null) {
                    // CREATE NEW ROLE
                    scheduleProvider.addRoleToSchedule(
                      widget.scheduleId,
                      _nameController.text,
                    );
                  } else {
                    // UPDATE EXISTING ROLE
                    scheduleProvider.updateRoleName(
                      widget.scheduleId,
                      widget.role.name,
                      _nameController.text,
                    );
                  }
                  Navigator.of(context).pop();
                },
              ),

              SizedBox(),
            ],
          ),
        );
      },
    );
  }
}
