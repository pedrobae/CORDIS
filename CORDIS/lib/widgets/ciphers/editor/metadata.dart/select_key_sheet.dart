import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/models/domain/cipher/version.dart';
import 'package:cordis/providers/transposition_provider.dart';
import 'package:cordis/widgets/common/filled_text_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SelectKeySheet extends StatefulWidget {
  final int? cipherID;
  final dynamic versionID;
  final VersionType versionType;

  const SelectKeySheet({
    super.key,
    this.cipherID,
    this.versionID,
    required this.versionType,
  });

  @override
  State<SelectKeySheet> createState() => _SelectKeySheetState();
}

class _SelectKeySheetState extends State<SelectKeySheet> {
  String? selectedKey;

  @override
  void initState() {
    super.initState();
    final tp = context.read<TranspositionProvider>();
    selectedKey = tp.transposedKey;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer<TranspositionProvider>(
      builder: (context, tp, child) {
        return Container(
          padding: EdgeInsets.all(16),
          height: MediaQuery.of(context).size.height / 3,
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            color: colorScheme.surface,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 8,
            children: [
              // HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context)!.keyHint,
                    style: textTheme.titleMedium,
                  ),
                  CloseButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
              Expanded(
                child: GridView.builder(
                  itemCount: 12,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: 2,
                  ),
                  itemBuilder: (BuildContext context, int index) {
                    final key = tp.keyList[index];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (selectedKey == key) {
                            selectedKey = null;
                          } else {
                            selectedKey = key;
                          }
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: key == selectedKey
                              ? colorScheme.onSurface
                              : colorScheme.surface,
                          border: Border.all(
                            color: colorScheme.shadow,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(0),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: Center(
                          child: Text(
                            key,
                            style: textTheme.titleMedium?.copyWith(
                              color: key == selectedKey
                                  ? colorScheme.surface
                                  : colorScheme.onSurface,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              FilledTextButton(
                text: AppLocalizations.of(context)!.save,
                isDark: true,
                onPressed: () {
                  tp.setTransposedKey(selectedKey);
                  Navigator.of(context).pop();
                },
              ),
              SizedBox(),
            ],
          ),
        );
      },
    );
  }
}
