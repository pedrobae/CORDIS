import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/models/domain/cipher/cipher.dart';
import 'package:cordis/models/domain/cipher/version.dart';
import 'package:cordis/providers/cipher/cipher_provider.dart';
import 'package:cordis/providers/transposition_provider.dart';
import 'package:cordis/providers/version/local_version_provider.dart';
import 'package:cordis/providers/version/cloud_version_provider.dart';
import 'package:cordis/utils/date_utils.dart';
import 'package:cordis/widgets/ciphers/editor/metadata.dart/add_tag_sheet.dart';
import 'package:cordis/widgets/ciphers/editor/metadata.dart/select_key_sheet.dart';
import 'package:cordis/widgets/common/duration_picker.dart';
import 'package:cordis/widgets/common/filled_text_button.dart';
import 'package:cordis/widgets/common/labeled_text_field.dart';
import 'package:cordis/widgets/common/labeled_language_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum InfoField {
  title,
  author,
  versionName,
  key,
  bpm,
  duration,
  language,
  tags,
}

class MetadataTab extends StatefulWidget {
  final int? cipherID;
  final dynamic versionID;
  final VersionType versionType;
  final bool isEnabled;

  const MetadataTab({
    super.key,
    this.cipherID,
    this.versionID,
    required this.versionType,
    this.isEnabled = true,
  });

  @override
  State<MetadataTab> createState() => _MetadataTabState();
}

class _MetadataTabState extends State<MetadataTab> {
  Map<InfoField, TextEditingController> controllers = {};

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < InfoField.values.length; i++) {
      switch (InfoField.values[i]) {
        case InfoField.key:
        case InfoField.tags:
          // THESE FIELDS ARE HANDLED SEPARATELY, NOT USING TEXT CONTROLLERS
          break;
        default:
          controllers[InfoField.values[i]] = TextEditingController();
      }
    }
    _addListeners();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncWithProviderData();
    });
  }

  @override
  void dispose() {
    for (var controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _syncWithProviderData() {
    if (mounted) {
      final versionProvider = context.read<LocalVersionProvider>();
      final cloudVersionProvider = context.read<CloudVersionProvider>();
      final cipherProvider = context.read<CipherProvider>();

      switch (widget.versionType) {
        case VersionType.cloud:
          final version = cloudVersionProvider.getVersion(widget.versionID!)!;

          controllers[InfoField.title]!.text = version.title;
          controllers[InfoField.author]!.text = version.author;
          controllers[InfoField.versionName]!.text = version.versionName;
          controllers[InfoField.bpm]!.text = version.bpm.toString();
          controllers[InfoField.language]!.text = version.language;
          controllers[InfoField.duration]!.text = DateTimeUtils.formatDuration(
            Duration(seconds: version.duration),
          );
          // TAGS CONTROLLER IS NOT USED, ADDING TAGS IS HANDLED BY A BOTTOM SHEET
          break;

        case VersionType.local:
        case VersionType.import:
          final cipher = cipherProvider.getCipherById(widget.cipherID ?? -1)!;
          final version = versionProvider.cachedVersion(
            (widget.versionID is int) ? widget.versionID : -1,
          )!;
          _syncLocalVersion(cipher, version);
          break;
        case VersionType.playlist:
          final cipher = cipherProvider.getCipherById(widget.cipherID ?? -1)!;
          final version = versionProvider.cachedVersion(-1)!;
          _syncLocalVersion(cipher, version);
          break;
        case VersionType.brandNew:
          // Do nothing for brand new versions
          break;
      }
    }
  }

  void _syncLocalVersion(Cipher cipher, Version version) {
    controllers[InfoField.title]!.text = cipher.title;
    controllers[InfoField.author]!.text = cipher.author;
    controllers[InfoField.versionName]!.text = version.versionName;
    controllers[InfoField.bpm]!.text = version.bpm.toString();
    controllers[InfoField.language]!.text = cipher.language;
    controllers[InfoField.duration]!.text = DateTimeUtils.formatDuration(
      version.duration,
    );
    // KEY FIELD IS HANDLED BY TRANSPOSITION PROVIDER
    // TAGS CONTROLLER IS NOT USED, ADDING TAGS IS HANDLED BY A BOTTOM SHEET
  }

  void _addListeners() {
    final cipherProvider = context.read<CipherProvider>();
    final localVersionProvider = context.read<LocalVersionProvider>();
    final cloudVersionProvider = context.read<CloudVersionProvider>();

    for (var field in InfoField.values) {
      switch (field) {
        case InfoField.key:
        case InfoField.tags:
          // THESE FIELDS ARE HANDLED SEPARATELY, NOT USING TEXT CONTROLLERS
          break;
        default:
          controllers[field]!.addListener(() {
            final text = controllers[field]!.text;
            switch (field) {
              case InfoField.title:
                if (widget.versionType == VersionType.cloud) {
                  cloudVersionProvider.cacheUpdates(
                    widget.versionID,
                    title: text,
                  );
                } else {
                  cipherProvider.cacheUpdates(
                    widget.cipherID ?? -1,
                    title: text,
                  );
                }
                break;

              case InfoField.author:
                if (widget.versionType == VersionType.cloud) {
                  cloudVersionProvider.cacheUpdates(
                    widget.versionID,
                    author: text,
                  );
                } else {
                  cipherProvider.cacheUpdates(
                    widget.cipherID ?? -1,
                    author: text,
                  );
                }
                break;
              case InfoField.versionName:
                if (widget.versionType == VersionType.cloud) {
                  cloudVersionProvider.cacheUpdates(
                    widget.versionID,
                    versionName: text,
                  );
                } else {
                  localVersionProvider.cacheUpdates(
                    widget.versionID ?? -1,
                    versionName: text,
                  );
                }
                break;
              case InfoField.language:
                if (widget.versionType == VersionType.cloud) {
                  cloudVersionProvider.cacheUpdates(
                    widget.versionID,
                    language: text,
                  );
                } else {
                  cipherProvider.cacheUpdates(
                    widget.cipherID ?? -1,
                    language: text,
                  );
                }
                break;
              case InfoField.bpm:
                final bpm = int.tryParse(text) ?? 0;
                if (widget.versionType == VersionType.cloud) {
                  cloudVersionProvider.cacheUpdates(widget.versionID, bpm: bpm);
                } else {
                  localVersionProvider.cacheUpdates(
                    widget.versionID ?? -1,
                    bpm: bpm,
                  );
                }
                break;
              case InfoField.duration:
                final duration = DateTimeUtils.parseDuration(text);
                if (widget.versionType == VersionType.cloud) {
                  cloudVersionProvider.cacheUpdates(
                    widget.versionID,
                    duration: duration.inSeconds,
                  );
                } else {
                  localVersionProvider.cacheUpdates(
                    widget.versionID ?? -1,
                    duration: duration,
                  );
                }
                break;
              case InfoField.tags:
              case InfoField.key:
                // THESE FIELDS ARE HANDLED SEPARATELY, NOT USING TEXT CONTROLLERS
                break;
            }
          });
      }
    }
  }

  TextEditingController _getController(InfoField field) {
    return controllers[field]!;
  }

  String _getLabel(InfoField field) {
    return switch (field) {
      InfoField.title => AppLocalizations.of(context)!.title,
      InfoField.author => AppLocalizations.of(context)!.author,
      InfoField.versionName => AppLocalizations.of(context)!.versionName,
      InfoField.bpm => AppLocalizations.of(context)!.bpm,
      InfoField.duration => AppLocalizations.of(context)!.duration,
      InfoField.key => AppLocalizations.of(context)!.musicKey,
      InfoField.language => AppLocalizations.of(context)!.language,
      InfoField.tags => AppLocalizations.of(
        context,
      )!.pluralPlaceholder(AppLocalizations.of(context)!.tag),
    };
  }

  String _getHint(InfoField field) {
    return switch (field) {
      InfoField.title => AppLocalizations.of(context)!.titleHint,
      InfoField.author => AppLocalizations.of(context)!.authorHint,
      InfoField.versionName => AppLocalizations.of(context)!.versionNameHint,
      InfoField.bpm => AppLocalizations.of(context)!.bpmHint,
      InfoField.duration => AppLocalizations.of(context)!.durationHint,
      InfoField.key => AppLocalizations.of(context)!.keyHint,
      InfoField.language => AppLocalizations.of(context)!.languageHint,
      InfoField.tags => AppLocalizations.of(context)!.tagHint,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<
      CipherProvider,
      LocalVersionProvider,
      CloudVersionProvider
    >(
      builder:
          (
            context,
            cipherProvider,
            versionProvider,
            cloudVersionProvider,
            child,
          ) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 16.0,
              children: [
                for (var field in InfoField.values)
                  switch (field) {
                    InfoField.duration => DurationPickerField(
                      controller: _getController(field),
                      label: _getLabel(field),
                    ),
                    InfoField.tags => _buildTags(
                      context: context,
                      cipherProvider: cipherProvider,
                      versionProvider: versionProvider,
                      cloudVersionProvider: cloudVersionProvider,
                      field: field,
                    ),
                    InfoField.bpm => LabeledTextField(
                      label: _getLabel(field),
                      hint: _getHint(field),
                      controller: _getController(field),
                      isEnabled: widget.isEnabled,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return null;
                        }
                        final bpm = int.tryParse(value);
                        if (bpm == null || bpm <= 0) {
                          return AppLocalizations.of(
                            context,
                          )!.intValidationError;
                        }
                        return null;
                      },
                    ),
                    InfoField.key => _buildKeySelector(
                      context: context,
                      cipherProvider: cipherProvider,
                      versionProvider: versionProvider,
                      field: field,
                    ),
                    InfoField.language => LabeledLanguagePicker(
                      language: _getController(field).text,
                      onLanguageChanged: (value) {
                        _getController(field).text = value;
                      },
                    ),
                    _ => LabeledTextField(
                      label: _getLabel(field),
                      hint: _getHint(field),
                      controller: _getController(field),
                      isEnabled: widget.isEnabled,
                    ),
                  },
              ],
            );
          },
    );
  }

  Widget _buildKeySelector({
    required BuildContext context,
    required CipherProvider cipherProvider,
    required LocalVersionProvider versionProvider,
    required InfoField field,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Text(_getLabel(field), style: theme.textTheme.labelLarge),
        GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (context) {
                return SelectKeySheet(
                  versionType: widget.versionType,
                  cipherID: widget.cipherID,
                  versionID: widget.versionID,
                );
              },
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.shadow, width: 1),
              borderRadius: BorderRadius.circular(0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Consumer<TranspositionProvider>(
                  builder: (context, tp, child) {
                    return Text(
                      tp.transposedKey,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 16,
                      ),
                    );
                  },
                ),
                Icon(Icons.arrow_drop_down, color: colorScheme.onSurface),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTags({
    required BuildContext context,
    required CipherProvider cipherProvider,
    required LocalVersionProvider versionProvider,
    required CloudVersionProvider cloudVersionProvider,
    required InfoField field,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final tags = widget.versionType == VersionType.cloud
        ? cloudVersionProvider.getVersion(widget.versionID!)?.tags ?? []
        : cipherProvider.getCipherById(widget.cipherID ?? -1)?.tags ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(_getLabel(field), style: textTheme.labelLarge),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 0,
          children: [
            for (var tag in tags)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(tag, style: textTheme.labelMedium),
              ),
          ],
        ),
        FilledTextButton(
          text: AppLocalizations.of(
            context,
          )!.addPlaceholder(AppLocalizations.of(context)!.tag),
          icon: Icons.add,
          isDense: true,
          onPressed: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (context) {
              return AddTagSheet(
                cipherID: widget.cipherID,
                versionID: widget.versionID,
                versionType: widget.versionType,
              );
            },
          ),
        ),
      ],
    );
  }
}
