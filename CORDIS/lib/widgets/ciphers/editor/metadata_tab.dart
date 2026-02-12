import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/models/domain/cipher/version.dart';
import 'package:cordis/providers/cipher/cipher_provider.dart';
import 'package:cordis/providers/selection_provider.dart';
import 'package:cordis/providers/version/local_version_provider.dart';
import 'package:cordis/providers/version/cloud_version_provider.dart';
import 'package:cordis/utils/date_utils.dart';
import 'package:cordis/widgets/ciphers/editor/metadata.dart/add_tag_sheet.dart';
import 'package:cordis/widgets/ciphers/editor/metadata.dart/select_key_sheet.dart';
import 'package:cordis/widgets/common/duration_picker.dart';
import 'package:cordis/widgets/common/filled_text_button.dart';
import 'package:cordis/widgets/common/labeled_text_field.dart';
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
  Map<InfoField, FocusNode> focusNodes = {};

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < InfoField.values.length; i++) {
      controllers[InfoField.values[i]] = TextEditingController();
      focusNodes[InfoField.values[i]] = FocusNode();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncWithProviderData();
    });
  }

  @override
  void dispose() {
    for (var controller in controllers.values) {
      controller.dispose();
    }
    for (var focusNode in focusNodes.values) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _syncWithProviderData() async {
    if (mounted) {
      final versionProvider = context.read<LocalVersionProvider>();
      final cloudVersionProvider = context.read<CloudVersionProvider>();
      final cipherProvider = context.read<CipherProvider>();

      switch (widget.versionType) {
        case VersionType.cloud:
          final version = cloudVersionProvider.getVersion(widget.versionID!)!;

          for (var field in InfoField.values) {
            switch (field) {
              case InfoField.title:
                controllers[field]!.text = version.title;
                break;
              case InfoField.author:
                controllers[field]!.text = version.author;
                break;
              case InfoField.versionName:
                controllers[field]!.text = version.versionName;
                break;
              case InfoField.bpm:
                controllers[field]!.text = version.bpm.toString();
                break;
              case InfoField.key:
                controllers[field]!.text =
                    version.transposedKey ?? version.originalKey;
                break;
              case InfoField.language:
                controllers[field]!.text = version.language;
                break;
              case InfoField.tags:
                // THIS CONTROLLER IS NOT USED, ADDING TAGS IS HANDLED BY A BOTTOM SHEET
                break;
              case InfoField.duration:
                controllers[field]!.text = DateTimeUtils.formatDuration(
                  Duration(seconds: version.duration),
                );
                break;
            }
          }
        case VersionType.local:
        case VersionType.import:
        case VersionType.playlist:
          final cipher = cipherProvider.getCipherById(widget.cipherID ?? -1)!;
          final version = versionProvider.cachedVersion(
            (widget.versionID is int) ? widget.versionID : -1,
          )!;

          for (var field in InfoField.values) {
            switch (field) {
              case InfoField.title:
                controllers[field]!.text = cipher.title;
                break;
              case InfoField.author:
                controllers[field]!.text = cipher.author;
                break;
              case InfoField.versionName:
                controllers[field]!.text = version.versionName;
                break;
              case InfoField.bpm:
                controllers[field]!.text = version.bpm.toString();
                break;
              case InfoField.key:
                controllers[field]!.text =
                    version.transposedKey ?? cipher.musicKey;
                break;
              case InfoField.language:
                controllers[field]!.text = cipher.language;
                break;
              case InfoField.duration:
                controllers[field]!.text = DateTimeUtils.formatDuration(
                  version.duration,
                );
              case InfoField.tags:
                // THIS CONTROLLER IS NOT USED, ADDING TAGS IS HANDLED BY A BOTTOM SHEET
                break;
            }
          }
        case VersionType.brandNew:
          // Do nothing for brand new versions
          break;
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

  bool _isEnabled(InfoField field) {
    final selectionProvider = context.read<SelectionProvider>();
    switch (field) {
      case InfoField.title:
      case InfoField.versionName:
      case InfoField.author:
      case InfoField.tags:
        if (!widget.isEnabled) return false;
        return !selectionProvider.isSelectionMode;
      case InfoField.bpm:
      case InfoField.duration:
      case InfoField.key:
      case InfoField.language:
        return true;
    }
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
                      isEnabled: _isEnabled(field),
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
                    _ => LabeledTextField(
                      label: _getLabel(field),
                      hint: _getHint(field),
                      controller: _getController(field),
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
        Text(
          _getLabel(field),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (context) {
                return SelectKeySheet(
                  controller: _getController(field),
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
              border: Border.all(
                color: colorScheme.surfaceContainerLowest,
                width: 1.2,
              ),
              borderRadius: BorderRadius.circular(0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ListenableBuilder(
                  listenable: _getController(field),
                  builder: (context, child) {
                    return Text(
                      _getController(field).text.isEmpty
                          ? AppLocalizations.of(context)!.keyHint
                          : _getController(field).text,
                      style: TextStyle(
                        color: _getController(field).text.isEmpty
                            ? colorScheme.shadow
                            : colorScheme.onSurface,
                        fontSize: 16,
                      ),
                    );
                  },
                ),
                Icon(Icons.arrow_drop_down, color: colorScheme.shadow),
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
        Text(
          _getLabel(field),
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
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
                child: Text(
                  tag,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
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
