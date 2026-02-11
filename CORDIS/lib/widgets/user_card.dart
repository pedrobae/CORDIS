import 'package:cordis/providers/my_auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UserCard extends StatelessWidget {
  const UserCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer<MyAuthProvider>(
      builder: (context, authProvider, child) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          margin: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            spacing: 8,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: colorScheme.primaryContainer,
                // photoURL, Initials fallback, Person Icon fallback
                child: authProvider.photoURL != null
                    ? ClipOval(
                        child: Image.network(
                          authProvider.photoURL!,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                        ),
                      )
                    : (authProvider.userName != null &&
                          authProvider.userName!.isNotEmpty)
                    ? Text(
                        authProvider.userName!
                            .trim()
                            .split(' ')
                            .map((e) => e[0])
                            .take(2)
                            .join()
                            .toUpperCase(),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                        ),
                      )
                    : Icon(
                        Icons.person,
                        color: colorScheme.surfaceContainerLowest,
                      ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      authProvider.userName ?? 'Guest',
                      style: theme.textTheme.titleMedium,
                    ),
                    if (authProvider.userEmail != null)
                      Text(
                        authProvider.userEmail!,
                        style: theme.textTheme.bodySmall,
                        softWrap: false,
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.chevron_right,
                  color: colorScheme.onSurfaceVariant,
                ),
                onPressed: () {
                  // TODO:SideMenu - Profile/user settings page
                  Navigator.of(context).pop(); // Close drawer
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: Colors.amberAccent,
                      content: Text(
                        'Funcionalidade em desenvolvimento,',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
