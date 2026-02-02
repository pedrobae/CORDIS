import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/models/domain/cipher/version.dart';
import 'package:cordis/models/domain/parsing_cipher.dart';
import 'package:cordis/providers/navigation_provider.dart';
import 'package:cordis/providers/parser_provider.dart';
import 'package:cordis/screens/cipher/edit_cipher.dart';
import 'package:cordis/widgets/filled_text_button.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:cordis/providers/import_provider.dart';
import 'package:flutter/material.dart';

class ImportPdfScreen extends StatefulWidget {
  const ImportPdfScreen({super.key});

  @override
  State<ImportPdfScreen> createState() => _ImportPdfScreenState();
}

class _ImportPdfScreenState extends State<ImportPdfScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ImportProvider>().setImportType(ImportType.pdf);
  }

  /// Opens file picker and allows user to select a PDF file
  Future<void> _pickPdfFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
        allowMultiple: false,
      );

      // User selected a file
      if (result != null && result.files.isNotEmpty) {
        final path = result.files.first.path;

        if (mounted) {
          context.read<ImportProvider>().setSelectedFile(path!);
          context.read<ImportProvider>().setSelectedFileName(
            result.files.first.name,
          );
        }
      }
      // If result is null, user canceled - do nothing
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.errorMessage(
                AppLocalizations.of(context)!.selectPDFFile,
                e.toString(),
              ),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<ImportProvider, ParserProvider, NavigationProvider>(
      builder:
          (context, importProvider, parserProvider, navigationProvider, child) {
            final theme = Theme.of(context);
            final colorScheme = theme.colorScheme;

            return Scaffold(
              appBar: AppBar(
                title: Text(AppLocalizations.of(context)!.importFromPDF),
                leading: BackButton(
                  onPressed: () {
                    navigationProvider.pop();
                  },
                ),
              ),
              body: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  spacing: 16,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(0),
                        border: Border.all(
                          color: colorScheme.onSurface,
                          width: 1,
                        ),
                      ),
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        spacing: 8,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            spacing: 8,
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: colorScheme.primary,
                              ),
                              Text(
                                AppLocalizations.of(context)!.howToImport,
                                style: theme.textTheme.titleMedium!.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            AppLocalizations.of(context)!.importInstructions,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),

                    // File selection button
                    FilledTextButton(
                      onPressed: () {
                        importProvider.isImporting ? null : _pickPdfFile();
                      },
                      text: AppLocalizations.of(context)!.selectPDFFile,
                      isDark: true,
                    ),

                    const SizedBox(height: 16),

                    // Selected file display
                    if (importProvider.selectedFile != null)
                      Container(
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(0),
                          border: Border.all(
                            color: colorScheme.onSurface,
                            width: 1,
                          ),
                        ),
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          spacing: 16,
                          children: [
                            Icon(
                              Icons.picture_as_pdf,
                              color: colorScheme.onPrimaryContainer,
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppLocalizations.of(context)!.selectedFile,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                  Text(
                                    importProvider.selectedFileName!,
                                    style: Theme.of(context).textTheme.bodyLarge
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                // Clear selected file
                                importProvider.clearSelectedFile();
                                importProvider.clearSelectedFileName();
                                importProvider.clearError();
                              },
                            ),
                          ],
                        ),
                      ),

                    // Error display
                    if (importProvider.error != null)
                      Card(
                        color: colorScheme.errorContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: colorScheme.onErrorContainer,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  importProvider.error!,
                                  style: TextStyle(
                                    color: colorScheme.onErrorContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Import Variation Dropdown
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.importVariation,
                          style: theme.textTheme.titleMedium,
                        ),
                        DropdownButton<ImportVariation>(
                          value: importProvider.importVariation,
                          items: importTypeToVariations[ImportType.pdf]!.map((
                            ImportVariation variation,
                          ) {
                            return DropdownMenuItem<ImportVariation>(
                              value: variation,
                              child: Text(variation.getName(context)),
                            );
                          }).toList(),
                          onChanged: (ImportVariation? newVariation) {
                            if (newVariation != null) {
                              importProvider.setImportVariation(newVariation);
                            }
                          },
                        ),
                      ],
                    ),

                    const Spacer(),

                    // Process button
                    FilledTextButton(
                      isDisabled:
                          (importProvider.selectedFile == null ||
                          importProvider.isImporting ||
                          importProvider.importVariation == null),
                      onPressed: () async {
                        await importProvider.importText();

                        parserProvider.parseCipher(
                          importProvider.importedCipher!,
                        );

                        // Navigate to parsing screen
                        navigationProvider.push(
                          EditCipherScreen(
                            cipherID: -1,
                            versionType: VersionType.import,
                            versionID: -1,
                          ),
                        );
                      },
                      text: AppLocalizations.of(context)!.processPDF,
                    ),
                  ],
                ),
              ),
            );
          },
    );
  }
}
