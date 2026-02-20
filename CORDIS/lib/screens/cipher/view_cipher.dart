import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/models/domain/cipher/cipher.dart';
import 'package:cordis/models/domain/cipher/version.dart';
import 'package:cordis/models/dtos/version_dto.dart';
import 'package:cordis/providers/navigation_provider.dart';
import 'package:cordis/providers/section_provider.dart';
import 'package:cordis/utils/date_utils.dart';
import 'package:cordis/utils/section_constants.dart';
import 'package:cordis/widgets/ciphers/viewer/annotation_card.dart';
import 'package:cordis/widgets/ciphers/viewer/section_card.dart';
import 'package:cordis/widgets/ciphers/viewer/structure_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';
import 'package:cordis/providers/cipher/cipher_provider.dart';
import 'package:cordis/providers/layout_settings_provider.dart';
import 'package:cordis/providers/version/cloud_version_provider.dart';
import 'package:cordis/providers/version/local_version_provider.dart';
import 'package:cordis/screens/cipher/edit_cipher.dart';
import 'package:cordis/widgets/settings/layout_settings.dart';

class ViewCipherScreen extends StatefulWidget {
  final int? cipherID;
  final dynamic versionID;
  final VersionType versionType;

  const ViewCipherScreen({
    super.key,
    required this.cipherID,
    this.versionID,
    required this.versionType,
  });

  @override
  State<ViewCipherScreen> createState() => _ViewCipherScreenState();
}

class _ViewCipherScreenState extends State<ViewCipherScreen>
    with SingleTickerProviderStateMixin {
  bool _hasSetOriginalKey = false;
  final List<GlobalKey> sectionKeys = [];
  late ScrollController scrollController;

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
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
            if (widget.cipherID != null) {
              cipher = cipherProvider.getCipherById(widget.cipherID!);
            }

            dynamic version;
            final String key;
            final Duration duration;
            // Set original key for transposer
            if (widget.versionType == VersionType.cloud) {
              version = cloudVersionProvider.getVersion(widget.versionID);
              key = version.originalKey ?? '';
              duration = Duration(seconds: version.duration);
              if (!_hasSetOriginalKey) {
                settings.setOriginalKey(version.originalKey ?? '');
                _hasSetOriginalKey = true;
              }
            } else {
              version = versionProvider.cachedVersion(widget.versionID);
              key = cipher!.musicKey;
              duration = version.duration;
              if (!_hasSetOriginalKey) {
                settings.setOriginalKey(cipher.musicKey);

                _hasSetOriginalKey = true;
              }
            }

            final List<String> songStructure;

            if (widget.versionID is String) {
              songStructure = cloudVersionProvider
                  .getVersion(widget.versionID)!
                  .songStructure;
            } else {
              songStructure = versionProvider
                  .cachedVersion(widget.versionID)!
                  .songStructure;
            }

            final filteredStructure = <String>[];
            for (var sectionCode in songStructure) {
              if (!settings.showAnnotations && isAnnotation(sectionCode)) {
                continue;
              }
              if (!settings.showTransitions && isTransition(sectionCode)) {
                continue;
              }
              filteredStructure.add(sectionCode);
            }

            final sectionCardList = filteredStructure.asMap().entries.map((
              entry,
            ) {
              String trimmedCode = entry.value.trim();

              final section = sectionProvider.getSection(
                widget.versionID,
                trimmedCode,
              );

              if (section == null) {
                return const Center(child: CircularProgressIndicator());
              }

              sectionKeys.add(GlobalKey());

              if (section.contentText.isEmpty) {
                return const SizedBox.shrink();
              }

              if (isAnnotation(trimmedCode)) {
                return AnnotationCard(
                  key: sectionKeys[entry.key],
                  sectionText: section.contentText,
                  sectionType: section.contentType,
                );
              } else {
                return SectionCard(
                  key: sectionKeys[entry.key],
                  sectionType: section.contentType,
                  sectionCode: trimmedCode,
                  sectionText: section.contentText,
                  sectionColor: section.contentColor,
                );
              }
            }).toList();

            // Add space at the end of the list for better scrolling
            sectionCardList.add(SizedBox(height: 200));

            return Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 16,
              children: [
                // ACTIONS
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.tune),
                      onPressed: _showLayoutSettings,
                    ),
                    if (widget.versionType == VersionType.local)
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          navigationProvider.push(
                            EditCipherScreen(
                              cipherID: widget.cipherID,
                              versionID: widget.versionID,
                              versionType: widget.versionType,
                            ),
                            showBottomNavBar: true,
                          );
                        },
                      ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: navigationProvider.pop,
                    ),
                  ],
                ),

                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Column(
                        spacing: 16,
                        children: [
                          // HEADER
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cipher?.title ?? version.title,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                '${AppLocalizations.of(context)!.by} ${cipher?.author ?? (version as VersionDto).author}',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(fontStyle: FontStyle.italic),
                              ),
                              SizedBox(height: 8.0),
                              // info
                              Row(
                                spacing: 16.0,
                                children: [
                                  Text(
                                    key.isNotEmpty
                                        ? AppLocalizations.of(
                                            context,
                                          )!.keyWithPlaceholder(key)
                                        : AppLocalizations.of(
                                            context,
                                          )!.keyWithPlaceholder('-'),
                                    style: textTheme.bodySmall,
                                  ),
                                  version.bpm != 0
                                      ? Text(
                                          AppLocalizations.of(
                                            context,
                                          )!.bpmWithPlaceholder(
                                            version.bpm.toString(),
                                          ),
                                          style: textTheme.bodySmall,
                                        )
                                      : Text('-'),
                                  duration != Duration.zero
                                      ? Text(
                                          AppLocalizations.of(
                                            context,
                                          )!.durationWithPlaceholder(
                                            DateTimeUtils.formatDuration(
                                              duration,
                                            ),
                                          ),
                                          style: textTheme.bodySmall,
                                        )
                                      : Text('-'),
                                ],
                              ),
                            ],
                          ),

                          // SONG STRUCTURE
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.songStructure,
                                style: textTheme.titleMedium,
                              ),
                              StructureList(
                                versionId: widget.versionID,
                                filteredStructure: filteredStructure,
                                scrollController: scrollController,
                                sectionKeys: sectionKeys,
                              ),
                            ],
                          ),

                          // SECTIONS
                          MasonryGridView.count(
                            crossAxisCount: settings.columnCount,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            itemCount: sectionCardList.length,
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemBuilder: (context, index) =>
                                sectionCardList[index],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
    );
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
      case VersionType.playlist:
        if (widget.versionID != null) {
          await sectionProvider.loadLocalSections(widget.versionID);
        }
        break;
      case VersionType.cloud:
        if (widget.versionID != null) {
          final version = cloudVersionProvider.getVersion(widget.versionID);
          sectionProvider.setNewSectionsInCache(
            widget.versionID,
            version!.toDomain().sections!,
          );
        }
        break;
    }
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
}
