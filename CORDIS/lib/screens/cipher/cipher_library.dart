import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/models/domain/cipher/version.dart';
import 'package:cordis/providers/navigation_provider.dart';
import 'package:cordis/providers/playlist_provider.dart';
import 'package:cordis/providers/version/cloud_version_provider.dart';
import 'package:cordis/screens/cipher/edit_cipher.dart';
import 'package:cordis/widgets/ciphers/editor/create_cipher_sheet.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cordis/providers/cipher_provider.dart';
import 'package:cordis/providers/my_auth_provider.dart';
import 'package:cordis/providers/selection_provider.dart';
import 'package:cordis/providers/user_provider.dart';
import 'package:cordis/widgets/ciphers/library/cipher_scroll_view.dart';

class CipherLibraryScreen extends StatefulWidget {
  final int? playlistId;

  const CipherLibraryScreen({super.key, this.playlistId});

  @override
  State<CipherLibraryScreen> createState() => _CipherLibraryScreenState();
}

class _CipherLibraryScreenState extends State<CipherLibraryScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pre-load data with post-frame callback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cipherProvider = context.read<CipherProvider>();
      final cloudVersionProvider = context.read<CloudVersionProvider>();

      cipherProvider.loadCiphers();
      cloudVersionProvider.loadVersions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer6<
      CipherProvider,
      UserProvider,
      MyAuthProvider,
      SelectionProvider,
      CloudVersionProvider,
      PlaylistProvider
    >(
      builder:
          (
            context,
            cipherProvider,
            userProvider,
            authProvider,
            selectionProvider,
            cloudVersionProvider,
            playlistProvider,
            child,
          ) {
            return Scaffold(
              appBar: selectionProvider.isSelectionMode
                  ? AppBar(
                      leading: const BackButton(),
                      title: Text(
                        AppLocalizations.of(context)!.addToPlaylist,
                        style: theme.textTheme.titleLarge!.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : null,
              body: Padding(
                padding: const EdgeInsets.only(
                  top: 16.0,
                  left: 16.0,
                  right: 16.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 16,
                  children: [
                    // Search Bar
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.searchCiphers,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(0),
                          borderSide: BorderSide(
                            color: colorScheme.surfaceContainer,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(0),
                          borderSide: BorderSide(color: colorScheme.primary),
                        ),
                        suffixIcon: const Icon(Icons.search),
                        fillColor: colorScheme.surfaceContainerHighest,
                        visualDensity: VisualDensity.compact,
                      ),
                      onChanged: (value) {
                        cipherProvider.setSearchTerm(value);
                        cloudVersionProvider.setSearchTerm(value);
                      },
                    ),
                    Expanded(
                      child: CipherScrollView(playlistId: widget.playlistId),
                    ),
                  ],
                ),
              ),
              floatingActionButton: GestureDetector(
                onLongPress: () => _showCreateCipherSheet(secret: true),
                onTap: () {
                  context.read<NavigationProvider>().push(
                    EditCipherScreen(
                      versionID: -1,
                      cipherID: -1,
                      versionType: VersionType.brandNew,
                    ),
                    showAppBar: false,
                    showDrawerIcon: false,
                  );
                },
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.onSurface,
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.surfaceContainerLowest,
                        spreadRadius: 2,
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(Icons.add, color: colorScheme.surface),
                ),
              ),
            );
          },
    );
  }

  void _showCreateCipherSheet({bool secret = false}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return CreateCipherSheet(secret: secret);
      },
    );
  }
}
