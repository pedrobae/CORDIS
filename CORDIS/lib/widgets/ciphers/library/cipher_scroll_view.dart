import 'package:cordis/providers/cipher_provider.dart';
import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/providers/version/cloud_version_provider.dart';
import 'package:cordis/widgets/ciphers/library/cipher_card.dart';
import 'package:cordis/widgets/ciphers/library/cloud_cipher_card.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CipherScrollView extends StatefulWidget {
  final int? playlistId;
  const CipherScrollView({super.key, this.playlistId});

  @override
  State<CipherScrollView> createState() => _CipherScrollViewState();
}

class _CipherScrollViewState extends State<CipherScrollView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadData();
      }
    });
  }

  void _loadData({bool forceReload = false}) {
    context.read<CipherProvider>().loadCiphers(forceReload: forceReload);
    context.read<CloudVersionProvider>().loadVersions(forceReload: forceReload);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<CipherProvider, CloudVersionProvider>(
      builder: (context, cipherProvider, cloudVersionProvider, child) {
        // Handle loading state
        if (cipherProvider.isLoading || cloudVersionProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        // Handle error state
        if (cipherProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.errorMessage(
                    AppLocalizations.of(context)!.loading,
                    cipherProvider.error!,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () =>
                      cipherProvider.loadCiphers(forceReload: true),
                  child: Text(AppLocalizations.of(context)!.tryAgain),
                ),
              ],
            ),
          );
        }

        return Stack(
          children: [
            // Display cipher list
            _buildCiphersList(cipherProvider, cloudVersionProvider),
          ],
        );
      },
    );
  }

  Widget _buildCiphersList(
    CipherProvider cipherProvider,
    CloudVersionProvider cloudVersionProvider,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final List<int> localIds = cipherProvider.filteredCiphers;
    final List<String> cloudIds = cloudVersionProvider.filteredCloudVersions;

    return RefreshIndicator(
      onRefresh: () async {
        _loadData(forceReload: true);
      },
      child: (localIds.isEmpty && cloudIds.isEmpty)
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 64),
                Text(
                  AppLocalizations.of(context)!.emptyCipherLibrary,
                  style: theme.textTheme.bodyLarge!.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            )
          : ListView.builder(
              cacheExtent: 500,
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: (localIds.length + cloudIds.length),
              itemBuilder: (context, index) {
                if (index >= localIds.length) {
                  return Padding(
                    padding: const EdgeInsets.only(
                      bottom: 8.0,
                    ), // Spacing between cards
                    child: CloudCipherCard(
                      versionId: cloudIds[index - localIds.length],
                      playlistId: widget.playlistId,
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.only(
                    bottom: 8.0,
                  ), // Spacing between cards
                  child: CipherCard(
                    cipherId: localIds[index],
                    playlistId: widget.playlistId,
                  ),
                );
              },
            ),
    );
  }
}
