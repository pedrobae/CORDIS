import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/models/domain/playlist/flow_item.dart';
import 'package:cordis/providers/playlist/flow_item_provider.dart';
import 'package:cordis/providers/navigation_provider.dart';
import 'package:cordis/providers/playlist/playlist_provider.dart';
import 'package:cordis/utils/date_utils.dart';
import 'package:cordis/widgets/common/duration_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FlowItemEditor extends StatefulWidget {
  final int? flowItemId;
  final int playlistId;

  const FlowItemEditor({super.key, this.flowItemId, required this.playlistId});

  @override
  State<FlowItemEditor> createState() => _FlowItemEditorState();
}

class _FlowItemEditorState extends State<FlowItemEditor> {
  late TextEditingController titleController;
  late TextEditingController contentController;
  late TextEditingController durationController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController();
    contentController = TextEditingController();
    durationController = TextEditingController();
    final flowItemProvider = context.read<FlowItemProvider>();

    if (widget.flowItemId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _syncFlowItem();
        flowItemProvider.loadFlowItem(widget.flowItemId!);
      });
    }
  }

  void _syncFlowItem() {
    if (widget.flowItemId != null) {
      final flowItemProvider = Provider.of<FlowItemProvider>(
        context,
        listen: false,
      );
      final flowItem = flowItemProvider.getFlowItem(widget.flowItemId!);
      if (flowItem != null) {
        titleController.text = flowItem.title;
        contentController.text = flowItem.contentText;
        final minutes = flowItem.duration.inMinutes.remainder(60).toString();
        final seconds = flowItem.duration.inSeconds
            .remainder(60)
            .toString()
            .padLeft(2, '0');
        durationController.text = '$minutes:$seconds';
      }
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Consumer3<FlowItemProvider, PlaylistProvider, NavigationProvider>(
      builder:
          (
            context,
            flowItemProvider,
            playlistProvider,
            navigationProvider,
            child,
          ) {
            return Scaffold(
              appBar: AppBar(
                title: Text(
                  widget.flowItemId != null
                      ? AppLocalizations.of(context)!.editPlaceholder(
                          AppLocalizations.of(context)!.flowItem,
                        )
                      : AppLocalizations.of(context)!.createPlaceholder(
                          AppLocalizations.of(context)!.flowItem,
                        ),
                  style: textTheme.titleMedium,
                ),
                leading: BackButton(
                  onPressed: () {
                    navigationProvider.pop();
                  },
                ),
                actions: [
                  IconButton(
                    onPressed: () {
                      if (!_formKey.currentState!.validate()) {
                        return;
                      }

                      final minSec = durationController.text.split(':');

                      // SAVE FLOW ITEM
                      flowItemProvider.upsertFlowItem(
                        FlowItem(
                          id: widget.flowItemId,
                          firebaseId: widget.flowItemId != null
                              ? flowItemProvider
                                    .getFlowItem(widget.flowItemId!)!
                                    .firebaseId
                              : '',
                          playlistId: widget.playlistId,
                          title: titleController.text,
                          contentText: contentController.text,
                          duration: Duration(
                            minutes: int.parse(minSec[0]),
                            seconds: int.parse(minSec[1]),
                          ),
                          position: 0,
                        ),
                      );

                      navigationProvider.pop();
                    },
                    icon: const Icon(Icons.save),
                  ),
                ],
              ),
              body: Form(
                key: _formKey,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 16,
                    children: [
                      _buildFormFieldLabel(
                        context,
                        controller: titleController,
                        label: AppLocalizations.of(context)!.title,
                        hint: AppLocalizations.of(context)!.titleHint,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppLocalizations.of(context)!.fieldRequired;
                          }
                          return null;
                        },
                      ),
                      _buildDurationPicker(
                        context,
                        controller: durationController,
                        label: AppLocalizations.of(context)!.estimatedTime,
                      ),
                      _buildFormFieldLabel(
                        context,
                        controller: contentController,
                        label: AppLocalizations.of(context)!
                            .optionalPlaceholder(
                              AppLocalizations.of(context)!.annotations,
                            ),
                        isMultiline: true,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
    );
  }

  Widget _buildDurationPicker(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4,
      children: [
        Text(label, style: textTheme.titleMedium),
        GestureDetector(
          onTap: () async {
            final initialDuration = controller.text.isNotEmpty
                ? DateTimeUtils.parseDuration(controller.text)
                : Duration.zero;

            final duration = await showModalBottomSheet<Duration>(
              context: context,
              builder: (context) =>
                  DurationPicker(initialDuration: initialDuration),
            );

            if (duration != null) {
              controller.text = DateTimeUtils.formatDuration(duration);
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
                  listenable: controller,
                  builder: (context, child) {
                    return Text(
                      controller.text.isEmpty
                          ? AppLocalizations.of(context)!.durationHint
                          : controller.text,
                      style: TextStyle(
                        color: controller.text.isEmpty
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

  Widget _buildFormFieldLabel(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    String? hint,
    bool isMultiline = false,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4,
      children: [
        Text(label, style: textTheme.titleMedium),
        TextFormField(
          validator: validator,
          autovalidateMode: AutovalidateMode.onUnfocus,
          controller: controller,
          maxLines: isMultiline ? null : 1,
          keyboardType: isMultiline
              ? TextInputType.multiline
              : TextInputType.text,
          decoration: InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 8),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: colorScheme.surfaceContainerLowest),
              borderRadius: BorderRadius.circular(0),
            ),
            hintText: hint,
            hintStyle: textTheme.bodyMedium?.copyWith(
              fontSize: 16,
              color: colorScheme.surfaceContainerLowest,
            ),
          ),
        ),
      ],
    );
  }
}
