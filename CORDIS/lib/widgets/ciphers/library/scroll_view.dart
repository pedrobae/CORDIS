import 'package:cordis/providers/cipher/cipher_provider.dart';
import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/providers/version/cloud_version_provider.dart';
import 'package:cordis/providers/version/local_version_provider.dart';
import 'package:cordis/widgets/ciphers/library/card.dart';
import 'package:cordis/widgets/ciphers/library/card_cloud.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CipherScrollView extends StatefulWidget {
  const CipherScrollView({super.key});

  @override
  State<CipherScrollView> createState() => _CipherScrollViewState();
}

class _CipherScrollViewState extends State<CipherScrollView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _loadData(context, isInitiating: true),
    );
  }

  void _loadData(
    BuildContext context, {
    bool forceReload = false,
    bool isInitiating = false,
  }) async {
    final cipherProvider = context.read<CipherProvider>();
    final cloudVersionProvider = context.read<CloudVersionProvider>();
    final localVersionProvider = context.read<LocalVersionProvider>();

    localVersionProvider.clearCache();
    await cipherProvider.loadCiphers(forceReload: forceReload);
    await cloudVersionProvider.loadVersions(
      forceReload: forceReload,
      localCiphers: cipherProvider.ciphers.values.toList(),
    );

    for (var cipher in cipherProvider.ciphers.values) {
      await localVersionProvider.loadVersionsOfCipher(cipher.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Selector3<
      CipherProvider,
      CloudVersionProvider,
      LocalVersionProvider,
      (List<dynamic>, int, List<int?>)
    >(
      selector: (context, ciph, cloudVer, localVer) {
        final filteredCipherIds = ciph.filteredCipherIds;
        final filteredCloudVersionIds = cloudVer.filteredCloudVersionIds;
        final localVersionIds = filteredCipherIds
            .map((id) => localVer.getIdOfOldestVersionOfCipher(id))
            .whereType<int>()
            .toList();

        return (
          [...filteredCipherIds, ...filteredCloudVersionIds],
          filteredCipherIds.length,
          localVersionIds,
        );
      },
      builder: (context, data, child) {
        final filteredIDs = data.$1;
        final localIDsCount = data.$2;

        return RefreshIndicator(
          onRefresh: () async {
            _loadData(context, forceReload: true);
          },
          child: (filteredIDs.isEmpty)
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: 64),
                    Text(
                      AppLocalizations.of(context)!.emptyCipherLibrary,
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                  ],
                )
              : ListView.builder(
                  cacheExtent: 500,
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: filteredIDs.length,
                  itemBuilder: (context, index) {
                    if (index >= localIDsCount) {
                      return Padding(
                        padding: const EdgeInsets.only(
                          bottom: 8.0,
                        ), // Spacing between cards
                        child: CloudCipherCard(versionId: filteredIDs[index]),
                      );
                    }

                    if (index >= data.$3.length) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final versionID = data.$3[index];
                    if (versionID == null) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return CipherCard(versionID: versionID);
                  },
                ),
        );
      },
    );
  }
}
