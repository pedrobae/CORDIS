import 'package:cordeos/providers/navigation_provider.dart';
import 'package:cordeos/screens/admin/user_management_screen.dart';
import 'package:cordeos/widgets/common/filled_text_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final nav = context.read<NavigationProvider>();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        spacing: 16,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Admin Panel',
            style: textTheme.titleMedium,
          ),
          FilledTextButton(
            onPressed: () {
              nav.push(
                () => UserManagementScreen(),
                showAppBar: true,
                showBottomNavBar: true,
                showDrawerIcon: true,
              );
            },
            icon: Icons.manage_accounts_outlined,
            trailingIcon: Icons.chevron_right,
            text: 'User Management',
          ),
        ],
      ),
    );
  }
}
