import 'package:cordis/helpers/database.dart';
import 'package:cordis/providers/schedule/cloud_schedule_provider.dart';
import 'package:cordis/providers/schedule/local_schedule_provider.dart';
import 'package:cordis/providers/version/cloud_version_provider.dart';

import 'package:cordis/utils/app_theme.dart';

import 'package:cordis/l10n/app_localizations.dart';

import 'package:cordis/providers/cipher/cipher_provider.dart';
import 'package:cordis/providers/playlist/playlist_provider.dart';
import 'package:cordis/providers/settings_provider.dart';
import 'package:cordis/providers/my_auth_provider.dart';
import 'package:cordis/providers/section_provider.dart';
import 'package:cordis/providers/playlist/flow_item_provider.dart';
import 'package:cordis/providers/selection_provider.dart';
import 'package:cordis/providers/user_provider.dart';
import 'package:cordis/providers/version/local_version_provider.dart';

import 'package:cordis/widgets/delete_confirmation.dart';
import 'package:cordis/widgets/filled_text_button.dart';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqlite_api.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        spacing: 8,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // App Settings Section
          _buildSectionHeader(
            AppLocalizations.of(context)!.settings,
            Icons.settings,
          ),
          FilledTextButton(
            icon: Icons.palette,
            text: AppLocalizations.of(context)!.theme,
            tooltip: AppLocalizations.of(context)!.themeSubtitle,
            trailingIcon: Icons.chevron_right,
            onPressed: () {
              _showThemeDialog(context);
            },
            isDiscrete: true,
          ),
          FilledTextButton(
            icon: Icons.language,
            text: AppLocalizations.of(context)!.changeLanguage,
            tooltip: AppLocalizations.of(context)!.changeLanguageSubtitle,
            trailingIcon: Icons.chevron_right,
            onPressed: () {
              _showLanguageDialog(context);
            },
            isDiscrete: true,
          ),

          const SizedBox(height: 32),

          // Development Tools Section (only in debug mode)
          if (kDebugMode) ...[
            _buildSectionHeader(
              AppLocalizations.of(context)!.developmentTools,
              Icons.build,
            ),

            FilledTextButton(
              icon: Icons.refresh,
              text: AppLocalizations.of(context)!.resetDatabase,
              tooltip: AppLocalizations.of(context)!.resetDatabaseSubtitle,
              trailingIcon: Icons.chevron_right,
              onPressed: () => showModalBottomSheet(
                context: context,
                builder: (context) {
                  return DeleteConfirmationSheet(
                    itemType: AppLocalizations.of(context)!.database,
                    onConfirm: () {
                      _resetDatabase();
                    },
                  );
                },
              ),
              isDangerous: true,
              isDiscrete: true,
            ),
            FilledTextButton(
              icon: Icons.cached,
              text: AppLocalizations.of(context)!.reloadInterface,
              tooltip: AppLocalizations.of(context)!.reloadInterfaceSubtitle,
              trailingIcon: Icons.chevron_right,
              onPressed: _reloadAllData,
              isDiscrete: true,
            ),

            FilledTextButton(
              icon: Icons.storage,
              text: AppLocalizations.of(context)!.databaseInformation,
              tooltip: AppLocalizations.of(context)!.databaseInfoSubtitle,
              onPressed: () => _showDatabaseInfo(),
              trailingIcon: Icons.chevron_right,
              isDiscrete: true,
            ),

            const SizedBox(height: 32),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      spacing: 16,
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
            fontSize: 20,
          ),
        ),
      ],
    );
  }

  Future<void> _resetDatabase() async {
    try {
      final dbHelper = DatabaseHelper();
      await dbHelper.resetDatabase();

      // Check if widget is still mounted before using context
      if (mounted) {
        await context.read<CloudVersionProvider>().loadVersions(
          forceReload: true,
        );
      }

      if (mounted) {
        await context.read<UserProvider>().ensureUsersExist([
          context.read<MyAuthProvider>().id!,
        ]);
      }

      // Check mounted again after async operations
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Banco de dados resetado com sucesso!'),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao resetar banco: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _reloadAllData() async {
    try {
      // Clear all provider caches first
      context.read<CipherProvider>().clearCache();
      context.read<PlaylistProvider>().clearCache();
      context.read<LocalVersionProvider>().clearCache();
      context.read<SectionProvider>().clearCache();
      context.read<UserProvider>().clearCache();
      context.read<FlowItemProvider>().clearCache();
      context.read<LocalScheduleProvider>().clearCache();
      context.read<SelectionProvider>().disableSelectionMode();
      context.read<CloudScheduleProvider>().clearCache();

      // Force reload all providers from database
      await Future.wait([
        context.read<CipherProvider>().loadCiphers(forceReload: true),
        context.read<CloudVersionProvider>().loadVersions(),
        context.read<PlaylistProvider>().loadPlaylists(),
        context.read<UserProvider>().loadUsers(),
        context.read<LocalScheduleProvider>().loadSchedules(),
        context.read<CloudScheduleProvider>().loadSchedules(
          context.read<MyAuthProvider>().id!,
          forceFetch: true,
        ),
      ]);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Interface e dados recarregados completamente!'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao recarregar: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _showDatabaseInfo() async {
    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;

      // Get table counts
      final tables = [
        'tag',
        'cipher',
        'version',
        'section',
        'user',
        'playlist',
        'flow_item',
        'schedule',
        'role',
      ];
      final Map<String, int> tableCounts = {};

      for (final table in tables) {
        try {
          final result = await db.rawQuery(
            'SELECT COUNT(*) as count FROM $table',
          );
          tableCounts[table] = result.first['count'] as int;
        } catch (e) {
          tableCounts[table] = -1; // Error indicator
        }
      }

      final int dbVersion = await db.getVersion();

      // Check mounted after async operations
      if (!mounted) return;

      final colorScheme = Theme.of(context).colorScheme;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: colorScheme.surface,
          shape: ContinuousRectangleBorder(
            borderRadius: BorderRadius.circular(0),
          ),
          title: Text('${AppLocalizations.of(context)!.database}_v.$dbVersion'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.recordsPerTable,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...tableCounts.entries.map((entry) {
                  final count = entry.value;
                  return GestureDetector(
                    onTap: count > 0
                        ? () {
                            _showTableData(entry.key);
                          }
                        : null,
                    child: Container(
                      margin: EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        border: Border.all(
                          color: colorScheme.surfaceContainerHigh,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(0),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              entry.key,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                          Text(
                            count == -1 ? 'Erro' : count.toString(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: count == -1
                                  ? colorScheme.error
                                  : (count > 0
                                        ? colorScheme.primary
                                        : colorScheme.surfaceContainerLow),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: count > 0
                                ? colorScheme.primary
                                : colorScheme.surfaceContainerLow,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.errorMessage(
              AppLocalizations.of(context)!.databaseInformation,
              e.toString(),
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _showTableData(String tableName) async {
    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;

      final rows = await db.query(tableName, limit: 100);

      if (!mounted) return;

      final colorScheme = Theme.of(context).colorScheme;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: ContinuousRectangleBorder(
            borderRadius: BorderRadius.circular(0),
          ),
          backgroundColor: colorScheme.surface,
          title: Text(AppLocalizations.of(context)!.tableData(tableName)),
          content: SingleChildScrollView(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: colorScheme.surfaceContainer,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(0),
              ),
              width: double.maxFinite,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 8,
                  columns: rows.first.keys
                      .map(
                        (column) =>
                            DataColumn(label: Text(column.toUpperCase())),
                      )
                      .toList(),
                  rows: rows
                      .map(
                        (row) => DataRow(
                          cells: row.values
                              .map(
                                (value) => DataCell(
                                  Text(
                                    value?.toString() ?? 'null',
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.errorMessage(
              AppLocalizations.of(context)!.tableData(tableName),
              e.toString(),
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) => AlertDialog.adaptive(
          title: const Text('Escolher Tema'),
          content: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Color palette selection
                const Text(
                  'Cor do Tema:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildColorPalette(settingsProvider),
                const SizedBox(height: 24),

                // Theme mode selection
                const Text(
                  'Modo:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildThemeModeSelection(settingsProvider),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Concluído'),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) => AlertDialog.adaptive(
          title: Text(AppLocalizations.of(context)!.chooseLanguage),
          content: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.selectAppLanguage,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                DropdownButton<Locale>(
                  onChanged: (value) {
                    if (value != null) {
                      settingsProvider.setLocale(value);
                      Navigator.pop(context);
                    }
                  },
                  items: [
                    DropdownMenuItem(
                      value: const Locale('pt', 'BR'),
                      child: Text(AppLocalizations.of(context)!.portuguese),
                    ),
                    DropdownMenuItem(
                      value: const Locale('en', ''),
                      child: Text(AppLocalizations.of(context)!.english),
                    ),
                  ],
                  value: settingsProvider.locale,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildColorPalette(SettingsProvider settingsProvider) {
    final colors = [
      {
        'name': 'Verde',
        'value': ThemeColor.green,
        'preview': const Color(0xFF145550),
      },
      {
        'name': 'Dourado',
        'value': ThemeColor.gold,
        'preview': const Color(0xFFE6B428),
      },
      {
        'name': 'Laranja',
        'value': ThemeColor.orange,
        'preview': const Color(0xFFE66423),
      },
      {
        'name': 'Vinho',
        'value': ThemeColor.burgundy,
        'preview': const Color(0xFF5A002D),
      },
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: colors.map((colorData) {
        final isSelected = settingsProvider.themeColor == colorData['value'];

        return GestureDetector(
          onTap: () =>
              settingsProvider.setThemeColor(colorData['value'] as ThemeColor),
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: colorData['preview'] as Color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.secondary
                    : Colors.transparent,
                width: 3,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 4,
              children: [
                if (isSelected)
                  Icon(Icons.check, color: Colors.white, size: 20)
                else
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                Text(
                  colorData['name'] as String,
                  style: isSelected
                      ? const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        )
                      : const TextStyle(color: Colors.white70, fontSize: 10),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildThemeModeSelection(SettingsProvider settingsProvider) {
    final modes = [
      {'name': 'Claro', 'value': ThemeMode.light, 'icon': Icons.light_mode},
      {'name': 'Escuro', 'value': ThemeMode.dark, 'icon': Icons.dark_mode},
      {
        'name': 'Sistema',
        'value': ThemeMode.system,
        'icon': Icons.brightness_auto,
      },
    ];

    return RadioGroup<ThemeMode>(
      onChanged: (value) => settingsProvider.setThemeMode(value!),
      groupValue: settingsProvider.themeMode,
      child: Column(
        children: modes.map((modeData) {
          final isSelected = settingsProvider.themeMode == modeData['value'];

          return RadioListTile<ThemeMode>(
            value: modeData['value'] as ThemeMode,
            title: Row(
              children: [
                Icon(
                  modeData['icon'] as IconData,
                  size: 20,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 12),
                Text(modeData['name'] as String),
              ],
            ),
            contentPadding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          );
        }).toList(),
      ),
    );
  }

  void showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.amberAccent,
        content: Text(
          AppLocalizations.of(context)!.comingSoon,
          style: TextStyle(color: Colors.black),
        ),
      ),
    );
  }
}
