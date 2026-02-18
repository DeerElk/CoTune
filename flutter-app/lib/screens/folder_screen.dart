import 'package:cotune_mobile/widgets/modal.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/playlist.dart';
import '../services/storage_service.dart';
import '../theme.dart';
import '../widgets/rounded_app_bar.dart';
import '../widgets/track_tile.dart';
import '../widgets/option_sheet.dart';

enum FolderType { artist, playlist }

class FolderScreen extends StatefulWidget {
  final FolderType type;
  final String idOrName;

  const FolderScreen({super.key, required this.type, required this.idOrName});

  @override
  State<FolderScreen> createState() => _FolderScreenState();
}

class _FolderScreenState extends State<FolderScreen> {
  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();
    final theme = Theme.of(context);

    final bool isPlaylist = widget.type == FolderType.playlist;

    final String title;
    final List tracks;
    PlaylistModel? playlist;

    if (isPlaylist) {
      playlist = storage.getPlaylist(widget.idOrName);
      title = playlist?.name ?? 'Плейлист';
      tracks = playlist == null
          ? []
          : playlist.trackIds
                .map((id) => storage.getTrack(id))
                .where((t) => t != null)
                .toList();
    } else {
      title = widget.idOrName;
      tracks = storage
          .allTracks()
          .where((t) => t.artist == widget.idOrName)
          .toList();
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: RoundedAppBar(
        centerTitle: false,
        title: Text(
          title,
          style: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: CotuneTheme.headerTextColor,
          ),
        ),
        actions: isPlaylist
            ? [
                IconButton(
                  icon: const Icon(
                    Icons.more_vert,
                    color: CotuneTheme.headerTextColor,
                  ),
                  onPressed: () => _openPlaylistOptions(context, playlist!),
                ),
              ]
            : null,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        itemCount: tracks.length,
        itemBuilder: (_, i) => TrackTile(track: tracks[i]),
      ),
    );
  }

  void _openPlaylistOptions(BuildContext context, PlaylistModel pl) {
    final theme = Theme.of(context);

    OptionSheet.show(context, [
      ListTile(
        leading: Icon(Icons.playlist_add, color: theme.colorScheme.primary),
        title: Text(
          'Добавить в плейлист',
          style: GoogleFonts.inter(color: theme.colorScheme.onSurface),
        ),
        onTap: () {
          Navigator.pop(context);
          _addFromLiked(context, pl);
        },
      ),
      ListTile(
        leading: Icon(Icons.edit, color: theme.colorScheme.primary),
        title: Text(
          'Переименовать плейлист',
          style: GoogleFonts.inter(color: theme.colorScheme.onSurface),
        ),
        onTap: () {
          Navigator.pop(context);
          _renamePlaylist(context, pl);
        },
      ),
      ListTile(
        leading: Icon(Icons.delete, color: theme.colorScheme.error),
        title: Text(
          'Удалить плейлист',
          style: GoogleFonts.inter(color: theme.colorScheme.onSurface),
        ),
        onTap: () {
          Navigator.pop(context);
          _deletePlaylist(context, pl);
        },
      ),
    ]);
  }

  Future<void> _renamePlaylist(BuildContext ctx, PlaylistModel pl) async {
    final ctl = TextEditingController(text: pl.name);

    final res = await showCotuneModal<bool?>(
      ctx,
      title: 'Переименовать плейлист',
      builder: (bctx) => [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ctl,
                decoration: const InputDecoration(labelText: 'Название'),
              ),
              const SizedBox(height: 12),
              CotuneModalActions(
                onCancel: () => Navigator.pop(bctx, false),
                onConfirm: () => Navigator.pop(bctx, true),
                confirmLabel: 'Сохранить',
              ),
            ],
          ),
        ),
      ],
    );

    if (res == true) {
      pl.name = ctl.text.trim();
      await Provider.of<StorageService>(ctx, listen: false).savePlaylist(pl);
      setState(() {});
    }
  }

  Future<void> _deletePlaylist(BuildContext ctx, PlaylistModel pl) async {
    final ok = await showCotuneModal<bool?>(
      ctx,
      title: 'Удалить плейлист?',
      builder: (bctx) => [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Плейлист "${pl.name}" будет удалён.',
                style: TextStyle(
                  color: Theme.of(
                    bctx,
                  ).colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 16),
              CotuneModalActions(
                onCancel: () => Navigator.pop(bctx, false),
                onConfirm: () => Navigator.pop(bctx, true),
                confirmLabel: 'Удалить',
                destructiveConfirm: true,
              ),
            ],
          ),
        ),
      ],
    );

    if (ok == true) {
      await Provider.of<StorageService>(
        ctx,
        listen: false,
      ).deletePlaylist(pl.id);
      Navigator.pop(ctx);
    }
  }

  Future<void> _addFromLiked(BuildContext ctx, PlaylistModel pl) async {
    final storage = Provider.of<StorageService>(ctx, listen: false);
    final liked = storage.allTracks().where((t) => t.liked).toList();
    if (liked.isEmpty) {
      ScaffoldMessenger.of(
        ctx,
      ).showSnackBar(const SnackBar(content: Text('Нет понравившихся треков')));
      return;
    }

    final chosen = await showCotuneModal<List<String>?>(
      // builder: (bctx) => [...]
      ctx,
      title: 'Добавить в плейлист',
      builder: (bctx) {
        final selected = <String>{};
        return [
          StatefulBuilder(
            builder: (sbCtx, setSb) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(ctx).size.height * 0.18,
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: liked.length,
                      itemBuilder: (_, i) {
                        final t = liked[i];
                        final sel = selected.contains(t.id);
                        return CheckboxListTile(
                          value: sel,
                          onChanged: (v) => setSb(() {
                            if (v == true) {
                              selected.add(t.id);
                            } else {
                              selected.remove(t.id);
                            }
                          }),
                          title: Text(
                            t.title,
                            style: TextStyle(
                              color: Theme.of(
                                sbCtx,
                              ).colorScheme.onSurface.withValues(alpha: 0.85),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  CotuneModalActions(
                    onCancel: () => Navigator.pop(bctx, <String>[]),
                    onConfirm: () => Navigator.pop(bctx, selected.toList()),
                    confirmLabel: 'Добавить',
                  ),
                ],
              );
            },
          ),
        ];
      },
    );

    if (chosen != null && chosen.isNotEmpty) {
      pl.trackIds.addAll(chosen.where((id) => !pl.trackIds.contains(id)));
      await storage.savePlaylist(pl);
      setState(() {});
      ScaffoldMessenger.of(
        ctx,
      ).showSnackBar(const SnackBar(content: Text('Треки добавлены')));
    }
  }
}
