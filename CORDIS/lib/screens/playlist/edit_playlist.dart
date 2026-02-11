import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/providers/my_auth_provider.dart';
import 'package:cordis/providers/navigation_provider.dart';
import 'package:cordis/providers/playlist/playlist_provider.dart';
import 'package:cordis/providers/user_provider.dart';
import 'package:cordis/widgets/filled_text_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EditPlaylistScreen extends StatefulWidget {
  final int? playlistId;

  const EditPlaylistScreen({super.key, this.playlistId});

  @override
  State<EditPlaylistScreen> createState() => _EditPlaylistScreenState();
}

class _EditPlaylistScreenState extends State<EditPlaylistScreen> {
  TextEditingController playlistNameController = TextEditingController();
  late bool isEditing;

  @override
  void initState() {
    super.initState();
    if (widget.playlistId != null) {
      isEditing = true;

      final playlistProvider = Provider.of<PlaylistProvider>(
        context,
        listen: false,
      );
      final playlist = playlistProvider.getPlaylistById(widget.playlistId!)!;
      playlistNameController.text = playlist.name;
    } else {
      isEditing = false;
    }
  }

  @override
  void dispose() {
    playlistNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer4<
      NavigationProvider,
      PlaylistProvider,
      UserProvider,
      MyAuthProvider
    >(
      builder:
          (
            context,
            navigationProvider,
            playlistProvider,
            userProvider,
            authProvider,
            child,
          ) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                spacing: 32,
                children: [
                  // HEADER
                  Column(
                    spacing: 8,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.namePlaylistPrompt,
                        style: theme.textTheme.headlineSmall!.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (!isEditing)
                        Text(
                          AppLocalizations.of(
                            context,
                          )!.createPlaylistInstructions,
                          style: theme.textTheme.titleMedium!.copyWith(
                            fontSize: 15,
                          ),
                        ),
                    ],
                  ),
                  // FORM
                  Column(
                    spacing: 8,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.playlistNameLabel,
                        style: theme.textTheme.titleMedium!.copyWith(
                          fontSize: 15,
                        ),
                      ),
                      TextField(
                        controller: playlistNameController,
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(
                            context,
                          )!.playlistNameHint,
                        ),
                      ),
                    ],
                  ),
                  // ACTIONS
                  Column(
                    spacing: 16,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FilledTextButton(
                        text: AppLocalizations.of(context)!.create,
                        isDark: true,
                        onPressed: () async {
                          isEditing
                              ? await playlistProvider.updateName(
                                  widget.playlistId!,
                                  playlistNameController.text,
                                )
                              : await playlistProvider.createPlaylist(
                                  playlistNameController.text,
                                  userProvider.getLocalIdByFirebaseId(
                                    authProvider.id!,
                                  )!,
                                );
                          navigationProvider.pop();
                        },
                      ),
                      FilledTextButton(
                        text: AppLocalizations.of(context)!.cancel,
                        onPressed: () {
                          navigationProvider.pop();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
    );
  }
}
