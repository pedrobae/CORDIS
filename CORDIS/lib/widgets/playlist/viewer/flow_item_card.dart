import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/providers/playlist/flow_item_provider.dart';
import 'package:cordis/providers/navigation_provider.dart';
import 'package:cordis/utils/date_utils.dart';
import 'package:cordis/widgets/custom_reorderable_delayed.dart';
import 'package:cordis/widgets/filled_text_button.dart';
import 'package:cordis/widgets/playlist/viewer/flow_item_editor.dart';
import 'package:cordis/widgets/playlist/viewer/flow_item_card_actions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FlowItemCard extends StatelessWidget {
  final int flowItemId;
  final int playlistId;
  final int index;

  const FlowItemCard({
    super.key,
    required this.flowItemId,
    required this.playlistId,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer2<FlowItemProvider, NavigationProvider>(
      builder: (context, flowItemProvider, navigationProvider, child) {
        final flowItem = flowItemProvider.getFlowItem(flowItemId);

        // Loading state
        if (flowItem == null) {
          return Center(
            child: CircularProgressIndicator(color: colorScheme.primary),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(0),
            border: Border.all(color: colorScheme.surfaceContainerLowest),
          ),
          padding: const EdgeInsets.only(left: 8),
          margin: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: 8,
            children: [
              CustomReorderableDelayed(
                key: key,
                delay: Duration(milliseconds: 100),
                index: index,
                child: Icon(Icons.drag_indicator),
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: BorderDirectional(
                      start: BorderSide(
                        color: colorScheme.surfaceContainerLowest,
                        width: 1,
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  flowItem.title,
                                  style: textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  DateTimeUtils.formatDuration(
                                    flowItem.duration,
                                  ),
                                  style: textTheme.bodyLarge,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              _openFlowActionsSheet(context);
                            },
                            icon: Icon(Icons.more_vert_rounded, size: 30),
                          ),
                        ],
                      ),
                      FilledTextButton(
                        text: AppLocalizations.of(context)!.viewPlaceholder(
                          AppLocalizations.of(context)!.flowItem,
                        ),
                        isDense: true,
                        onPressed: () {
                          navigationProvider.push(
                            FlowItemEditor(
                              playlistId: playlistId,
                              flowItemId: flowItemId,
                            ),
                            showBottomNavBar: true,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openFlowActionsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return BottomSheet(
          shape: LinearBorder(),
          onClosing: () {},
          builder: (context) {
            return FlowItemCardActionsSheet(
              flowItemId: flowItemId,
              playlistId: playlistId,
            );
          },
        );
      },
    );
  }
}
