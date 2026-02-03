import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/models/domain/cipher/cipher.dart';
import 'package:cordis/models/domain/cipher/version.dart';
import 'package:cordis/providers/navigation_provider.dart';
import 'package:cordis/providers/section_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cordis/providers/cipher/cipher_provider.dart';
import 'package:cordis/providers/layout_settings_provider.dart';
import 'package:cordis/providers/version/cloud_version_provider.dart';
import 'package:cordis/providers/version/local_version_provider.dart';
import 'package:cordis/screens/cipher/edit_cipher.dart';
import 'package:cordis/widgets/settings/layout_settings.dart';
import 'package:cordis/widgets/ciphers/viewer/content_view.dart';

class ViewCipherScreen extends StatefulWidget {
  final int? cipherId;
  final dynamic versionId;
  final VersionType versionType;

  const ViewCipherScreen({
    super.key,
    required this.cipherId,
    this.versionId,
    required this.versionType,
  });

  @override
  State<ViewCipherScreen> createState() => _ViewCipherScreenState();
}

class _ViewCipherScreenState extends State<ViewCipherScreen>
    with SingleTickerProviderStateMixin {
  bool _hasSetOriginalKey = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    final sectionProvider = context.read<SectionProvider>();
    final cloudVersionProvider = context.read<CloudVersionProvider>();

    switch (widget.versionType) {
      case VersionType.import:
      case VersionType.brandNew:
        break;
      case VersionType.local:
        if (widget.versionId != null) {
          await sectionProvider.loadLocalSections(widget.versionId);
        }
        break;
      case VersionType.cloud:
        if (widget.versionId != null) {
          final version = cloudVersionProvider.getVersion(widget.versionId);
          sectionProvider.setNewSectionsInCache(
            widget.versionId,
            version!.toDomain().sections!,
          );
        }
        break;
      case VersionType.playlist:
        // THROW EXCEPTION. YOU CANNOT OPEN THE VIEWER FOR A PLAYLIST VERSION
        throw Exception('Cannot open CipherViewer for a playlist version.');
    }
  }

  void _editCurrentVersion(NavigationProvider navigationProvider) {
    navigationProvider.push(
      EditCipherScreen(
        cipherID: widget.cipherId,
        versionID: widget.versionId,
        versionType: widget.versionType,
      ),
      showAppBar: false,
      showDrawerIcon: false,
    );
  }

  void _showLayoutSettings() {
    showModalBottomSheet(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: LayoutSettings(
              includeTransposer: true,
              includeFilters: true,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer6<
      CipherProvider,
      LocalVersionProvider,
      CloudVersionProvider,
      SectionProvider,
      LayoutSettingsProvider,
      NavigationProvider
    >(
      builder:
          (
            context,
            cipherProvider,
            versionProvider,
            cloudVersionProvider,
            sectionProvider,
            settings,
            navigationProvider,
            child,
          ) {
            // Handle loading states
            if (cipherProvider.isLoading || versionProvider.isLoading) {
              return Scaffold(
                appBar: AppBar(title: const Text('Carregando...')),
                body: const Center(child: CircularProgressIndicator()),
              );
            }

            // Handle error states
            if (cipherProvider.error != null ||
                versionProvider.error != null ||
                sectionProvider.error != null) {
              return Scaffold(
                appBar: AppBar(title: const Text('Erro')),
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Erro: ${cipherProvider.error ?? versionProvider.error ?? sectionProvider.error}',
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Tentar Novamente'),
                      ),
                    ],
                  ),
                ),
              );
            }

            Cipher? cipher;
            if (widget.cipherId != null) {
              cipher = cipherProvider.getCipherById(widget.cipherId!);
            }

            dynamic version;

            // Set original key for transposer
            if (widget.versionType == VersionType.cloud) {
              version = cloudVersionProvider.getVersion(widget.versionId);
              if (!_hasSetOriginalKey) {
                settings.setOriginalKey(version.originalKey ?? '');
                _hasSetOriginalKey = true;
              }
            } else {
              version = versionProvider.getVersion(widget.versionId);
              if (!_hasSetOriginalKey) {
                settings.setOriginalKey(cipher!.musicKey);
                _hasSetOriginalKey = true;
              }
            }

            return Scaffold(
              appBar: AppBar(
                title: Column(
                  children: [
                    Text(
                      cipher?.title ?? version.title,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${AppLocalizations.of(context)!.by} ${cipher?.author ?? version.author}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                centerTitle: true,
                actions: [
                  IconButton(
                    onPressed: _showLayoutSettings,
                    icon: const Icon(Icons.remove_red_eye),
                    tooltip: 'Layout Settings',
                  ),
                  if (widget.versionType != VersionType.cloud)
                    IconButton(
                      icon: const Icon(Icons.edit),
                      tooltip: 'Edit',
                      onPressed: () => _editCurrentVersion(navigationProvider),
                    ),
                ],
              ),
              body: ContentView(versionId: widget.versionId),
            );
          },
    );
  }
}
