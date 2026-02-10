import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/models/domain/cipher/version.dart';
import 'package:cordis/providers/cipher/cipher_provider.dart';
import 'package:cordis/providers/selection_provider.dart';
import 'package:cordis/providers/version/local_version_provider.dart';
import 'package:cordis/providers/version/cloud_version_provider.dart';
import 'package:cordis/utils/date_utils.dart';
import 'package:cordis/widgets/ciphers/editor/metadata.dart/add_tag_sheet.dart';
import 'package:cordis/widgets/ciphers/editor/metadata.dart/select_key_sheet.dart';
import 'package:cordis/widgets/duration_picker.dart';
import 'package:cordis/widgets/filled_text_button.dart';
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
      controllers[InfoField.values[i]] = TextEditingController();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncWithProviderData();
    });
  }

  void _syncWithProviderData() {
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
          final version = versionProvider.getVersion(
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

  Text _getLabel(InfoField field) {
    return Text(
      switch (field) {
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
      },
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurface,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
    );
  }

  String _getHintText(InfoField field) {
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

  bool _isEnabled(SelectionProvider selectionProvider, InfoField field) {
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
  void dispose() {
    switch (widget.versionType) {
      case VersionType.cloud:
        final cloudVersionProvider = context.read<CloudVersionProvider>();
        cacheCloudUpdates(cloudVersionProvider);
        break;
      case VersionType.local:
      case VersionType.import:
      case VersionType.playlist:
      case VersionType.brandNew:
        final versionProvider = context.read<LocalVersionProvider>();
        final cipherProvider = context.read<CipherProvider>();
        cacheLocalUpdates(versionProvider, cipherProvider);
        break;
    }

    for (var controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
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
                    InfoField.duration => _buildDurationPicker(
                      context: context,
                      cipherProvider: cipherProvider,
                      versionProvider: versionProvider,
                      cloudVersionProvider: cloudVersionProvider,
                      field: field,
                    ),
                    InfoField.tags => _buildTags(
                      context: context,
                      cipherProvider: cipherProvider,
                      versionProvider: versionProvider,
                      cloudVersionProvider: cloudVersionProvider,
                      field: field,
                    ),
                    InfoField.bpm => _buildTextField(
                      context: context,
                      cipherProvider: cipherProvider,
                      versionProvider: versionProvider,
                      cloudVersionProvider: cloudVersionProvider,
                      field: field,
                      maxLines: 1,
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
                    _ => _buildTextField(
                      context: context,
                      cipherProvider: cipherProvider,
                      versionProvider: versionProvider,
                      cloudVersionProvider: cloudVersionProvider,
                      field: field,
                      maxLines: 1,
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
        _getLabel(field),
        GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (context) {
                return SelectKeySheet(controller: _getController(field));
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

  Widget _buildTextField({
    required BuildContext context,
    required CipherProvider cipherProvider,
    required LocalVersionProvider versionProvider,
    required CloudVersionProvider cloudVersionProvider,
    required InfoField field,
    String? Function(String?)? validator,
    int? maxLines = 1,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        _getLabel(field),
        TextFormField(
          validator: validator,
          autovalidateMode: AutovalidateMode.onUnfocus,
          controller: _getController(field),
          maxLines: maxLines,
          enabled: _isEnabled(context.read<SelectionProvider>(), field),
          decoration: InputDecoration(
            visualDensity: VisualDensity.compact,
            hintText: _getHintText(field),
            hintStyle: TextStyle(color: colorScheme.shadow, fontSize: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(0),
              borderSide: BorderSide(
                color: colorScheme.surfaceContainerLowest,
                width: 1.2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(0),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
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
        _getLabel(field),
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

  Widget _buildDurationPicker({
    required BuildContext context,
    required CipherProvider cipherProvider,
    required LocalVersionProvider versionProvider,
    required CloudVersionProvider cloudVersionProvider,
    required InfoField field,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        _getLabel(field),
        GestureDetector(
          onTap: () async {
            final initialDuration = _getController(field).text.isNotEmpty
                ? DateTimeUtils.parseDuration(_getController(field).text)
                : Duration.zero;

            final duration = await showModalBottomSheet<Duration>(
              context: context,
              builder: (context) =>
                  DurationPicker(initialDuration: initialDuration),
            );

            if (duration != null) {
              _getController(field).text = DateTimeUtils.formatDuration(
                duration,
              );

              switch (widget.versionType) {
                case VersionType.cloud:
                  cloudVersionProvider.cacheUpdates(
                    widget.versionID!,
                    duration: duration.inSeconds,
                  );
                  break;
                case VersionType.local:
                case VersionType.import:
                case VersionType.playlist:
                case VersionType.brandNew:
                  versionProvider.cacheUpdates(
                    (widget.versionID as int?) ?? -1,
                    duration: duration,
                  );
                  break;
              }
            }
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
                          ? AppLocalizations.of(context)!.durationHint
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
                Icon(Icons.access_time, color: colorScheme.shadow),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void cacheCloudUpdates(CloudVersionProvider cloudVersionProvider) {
    final bpm = int.tryParse(_getController(InfoField.bpm).text) ?? 0;
    final duration = DateTimeUtils.parseDuration(
      _getController(InfoField.duration).text,
    );

    cloudVersionProvider.cacheUpdates(
      widget.versionID!,
      title: _getController(InfoField.title).text,
      author: _getController(InfoField.author).text,
      versionName: _getController(InfoField.versionName).text,
      transposedKey: _getController(InfoField.key).text,
      language: _getController(InfoField.language).text,
      bpm: bpm,
      duration: duration.inSeconds,
    );
  }

  void cacheLocalUpdates(
    LocalVersionProvider versionProvider,
    CipherProvider cipherProvider,
  ) {
    cipherProvider.cacheCipherUpdates(
      widget.cipherID!,
      title: _getController(InfoField.title).text,
      author: _getController(InfoField.author).text,
      musicKey: _getController(InfoField.key).text,
      language: _getController(InfoField.language).text,
    );

    final bpm = int.tryParse(_getController(InfoField.bpm).text) ?? 0;
    final duration = DateTimeUtils.parseDuration(
      _getController(InfoField.duration).text,
    );

    versionProvider.cacheUpdates(
      widget.versionID,
      bpm: bpm,
      versionName: _getController(InfoField.versionName).text,
      duration: duration,
    );
  }
}
