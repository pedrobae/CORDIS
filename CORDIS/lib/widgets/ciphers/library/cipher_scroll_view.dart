import 'package:cordis/providers/cipher/cipher_provider.dart';
import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/providers/version/cloud_version_provider.dart';
import 'package:cordis/providers/version/local_version_provider.dart';
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
  List<int> localIds = [];
  List<String> cloudIds = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData(context));
  }

  void _loadData(BuildContext context, {bool forceReload = false}) async {
    final cipherProvider = context.read<CipherProvider>();
    final cloudVersionProvider = context.read<CloudVersionProvider>();
    final localVersionProvider = context.read<LocalVersionProvider>();

    localVersionProvider.clearCache();
    await cipherProvider.loadCiphers(forceReload: forceReload);
    await cloudVersionProvider.loadVersions(forceReload: forceReload);

    setState(() {
      localIds = cipherProvider.filteredCiphers;
      cloudIds = cloudVersionProvider.filteredCloudVersions;
    });

    for (var cipherId in localIds) {
      await localVersionProvider.loadVersionsOfCipher(cipherId);
    }
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
            _buildCiphersList(context, cipherProvider, cloudVersionProvider),
          ],
        );
      },
    );
  }

  Widget _buildCiphersList(
    BuildContext context,
    CipherProvider cipherProvider,
    CloudVersionProvider cloudVersionProvider,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return RefreshIndicator(
      onRefresh: () async {
        _loadData(context, forceReload: true);
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
