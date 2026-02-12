import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/providers/schedule/local_schedule_provider.dart';
import 'package:cordis/widgets/common/filled_text_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EditRoleSheet extends StatefulWidget {
  final dynamic scheduleId;
  final dynamic role; // Role or RoleDTO object

  const EditRoleSheet({
    super.key,
    required this.scheduleId,
    required this.role,
  });

  @override
  State<EditRoleSheet> createState() => _EditRoleSheetState();
}

class _EditRoleSheetState extends State<EditRoleSheet> {
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
                    AppLocalizations.of(
                      context,
                    )!.editPlaceholder(AppLocalizations.of(context)!.role),
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
              // NAME FIELD
              TextFormField(
                initialValue: widget.role.name,
                decoration: InputDecoration(
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: colorScheme.surfaceContainerLowest,
                      width: 1.2,
                    ),
                  ),
                  labelText: AppLocalizations.of(context)!.roleNameHint,
                ),
                onChanged: (value) {
                  scheduleProvider.updateRoleName(
                    widget.scheduleId,
                    widget.role.name,
                    value,
                  );
                },
              ),
              // SAVE BUTTON
              FilledTextButton(
                text: AppLocalizations.of(context)!.save,
                isDark: true,
                onPressed: () {
                  Navigator.of(context).pop();
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
