import 'package:cordis/providers/version/local_version_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class VersionSelectorBottomSheet extends StatelessWidget {
  final List<int> versionIds;
  final int currentVersionId;
  final Function(int) onVersionSelected;
  final VoidCallback onNewVersion;

  const VersionSelectorBottomSheet({
    super.key,
    required this.versionIds,
    required this.currentVersionId,
    required this.onVersionSelected,
    required this.onNewVersion,
  });

  @override
  Widget build(BuildContext context) {
    final version = context.watch<LocalVersionProvider>().getVersion(
      currentVersionId,
    )!;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      color: colorScheme.surfaceContainerHighest,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: const Icon(Icons.library_music),
              ),
              Text(
                'Versões da Cifra',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const Spacer(),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  onNewVersion();
                },
                icon: const Icon(Icons.add),
                label: const Text('Nova'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (versionIds.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Nenhuma versão encontrada',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              itemCount: versionIds.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final versionId = versionIds[index];
                final isSelected = versionId == currentVersionId;
                return ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isSelected ? Icons.check : Icons.music_note,
                      color: isSelected
                          ? colorScheme.onPrimary
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                  title: Text(
                    version.versionName,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Criada em ${_formatDate(version.createdAt)}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  trailing: isSelected
                      ? Icon(
                          Icons.radio_button_checked,
                          color: colorScheme.primary,
                        )
                      : const Icon(Icons.radio_button_unchecked),
                  onTap: () {
                    Navigator.pop(context);
                    // Add a small delay to ensure the pop completes before callback
                    Future.microtask(() {
                      if (version.id != null) {
                        onVersionSelected(version.id!);
                      }
                    });
                  },
                );
              },
            ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
