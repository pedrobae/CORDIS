import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/models/domain/cipher/version.dart';
import 'package:cordis/models/domain/parsing_cipher.dart';
import 'package:cordis/providers/navigation_provider.dart';
import 'package:cordis/providers/parser_provider.dart';
import 'package:cordis/screens/cipher/edit_cipher.dart';
import 'package:cordis/widgets/filled_text_button.dart';
import 'package:flutter/material.dart';
import 'package:cordis/providers/import_provider.dart';
import 'package:provider/provider.dart';

class ImportTextScreen extends StatefulWidget {
  final int? cipherId;

  const ImportTextScreen({super.key, this.cipherId});

  @override
  State<ImportTextScreen> createState() => _ImportTextScreenState();
}

class _ImportTextScreenState extends State<ImportTextScreen> {
  final TextEditingController _importTextController = TextEditingController();

  @override
  void initState() {
    super.initState();

    context.read<ImportProvider>().setImportType(ImportType.text);
  }

  @override
  void dispose() {
    _importTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<ImportProvider, NavigationProvider, ParserProvider>(
      builder:
          (context, importProvider, navigationProvider, parserProvider, child) {
            return Scaffold(
              appBar: AppBar(
                title: Text(AppLocalizations.of(context)!.importFromText),
                leading: BackButton(
                  onPressed: () {
                    navigationProvider.pop();
                  },
                ),
              ),
              body:
                  // Handle Error State
                  (importProvider.error != null)
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.errorMessage(
                              AppLocalizations.of(context)!.importFromText,
                              importProvider.error!,
                            ),
                            style: const TextStyle(color: Colors.red),
                          ),
                          FilledButton.icon(
                            label: Text(AppLocalizations.of(context)!.tryAgain),
                            onPressed: () {
                              importProvider.clearError();
                            },
                            icon: const Icon(Icons.refresh),
                          ),
                        ],
                      ),
                    )
                  // Loading State
                  : importProvider.isImporting
                  ? const Center(child: CircularProgressIndicator())
                  // Default State
                  : Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          spacing: 16.0,
                          mainAxisSize: MainAxisSize.max,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: TextField(
                                expands: true,
                                maxLines: null,
                                selectAllOnFocus: true,
                                onTapOutside: (event) =>
                                    FocusScope.of(context).unfocus(),
                                textAlignVertical: TextAlignVertical(y: -1),
                                controller: _importTextController,
                                decoration: InputDecoration(
                                  hintText: AppLocalizations.of(
                                    context,
                                  )!.pasteTextPrompt,
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(0),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(0),
                                    borderSide: BorderSide(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  AppLocalizations.of(context)!.parsingStrategy,
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                DropdownButton<ParsingStrategy>(
                                  value: importProvider.parsingStrategy,
                                  items:
                                      importTypeToParsingStrategies[ImportType
                                              .text]!
                                          .map((ParsingStrategy strategy) {
                                            return DropdownMenuItem<
                                              ParsingStrategy
                                            >(
                                              value: strategy,
                                              child: Text(
                                                strategy.getName(context),
                                              ),
                                            );
                                          })
                                          .toList(),
                                  onChanged: (ParsingStrategy? newStrategy) {
                                    if (newStrategy != null) {
                                      importProvider.setParsingStrategy(
                                        newStrategy,
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                            FilledTextButton(
                              text: AppLocalizations.of(context)!.import,
                              isDark: true,
                              onPressed: () async {
                                final text = _importTextController.text;
                                if (text.isNotEmpty) {
                                  await importProvider.importText(data: text);

                                  parserProvider.parseCipher(
                                    importProvider.importedCipher!,
                                  );

                                  // Navigate to parsing screen
                                  navigationProvider.push(
                                    EditCipherScreen(
                                      versionType: VersionType.import,
                                      versionID: -1,
                                      cipherID: -1,
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
            );
          },
    );
  }
}
