import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cotune_mobile/screens/folder_screen.dart';
import 'package:cotune_mobile/widgets/modal.dart';
import 'package:cotune_mobile/widgets/option_sheet.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/track.dart';
import '../models/playlist.dart';
import '../services/storage_service.dart';
import '../services/p2p_grpc_service.dart';
import '../theme.dart';
import '../screens/player_fullscreen.dart';
import '../services/audio_player_service.dart';

class TrackTile extends StatelessWidget {
  final Track track;

  const TrackTile({super.key, required this.track});

  @override
  Widget build(BuildContext context) {
    final storage = Provider.of<StorageService>(context, listen: false);
    final audio = Provider.of<AudioPlayerService>(context, listen: false);
    final theme = Theme.of(context);

    final unsigned = !track.recognized;
    final published = track.recognized && track.sharedToNetwork;

    return InkWell(
      onTap: () {
        final queue = storage.allTracks();
        final likedQueue = queue.where((t) => t.liked).toList();
        audio.setQueueFromTracks(
          likedQueue.isNotEmpty ? likedQueue : queue,
          currentId: track.id,
        );
        audio.playUri(track.path, trackId: track.id);
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const PlayerFullScreenSheet(),
        );
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 0, 12),
        child: Row(
          children: [
            Icon(
              unsigned ? Icons.error_outline : Icons.music_note,
              color: unsigned ? Colors.orangeAccent : CotuneTheme.highlight,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title.isNotEmpty ? track.title : 'Без названия',
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    track.artist.isNotEmpty ? track.artist : '-',
                    style: GoogleFonts.inter(
                      color: theme.textTheme.bodyMedium?.color,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        published
                            ? Icons.cloud_done_outlined
                            : Icons.cloud_off_outlined,
                        size: 14,
                        color: published
                            ? Colors.lightGreenAccent
                            : Colors.orangeAccent,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        published ? 'Опубликован в сети' : 'Не опубликован',
                        style: GoogleFonts.inter(
                          color: theme.textTheme.bodySmall?.color,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                track.liked ? Icons.favorite : Icons.favorite_border,
                color: track.liked
                    ? CotuneTheme.highlight
                    : theme.iconTheme.color,
              ),
              onPressed: () async {
                track.liked = !track.liked;

                // If liking a remote track (has CTID but file doesn't exist locally), download it first
                if (track.liked &&
                    track.ctid != null &&
                    track.ctid!.isNotEmpty) {
                  final file = File(track.path);
                  if (!await file.exists() || track.path.isEmpty) {
                    // Remote track needs to be downloaded
                    try {
                      final p2p = P2PGrpcService();
                      final providers = await p2p.searchProviders(
                        track.ctid!,
                        max: 5,
                      );

                      if (providers.isNotEmpty) {
                        // Download track
                        final appDir = await getApplicationDocumentsDirectory();
                        final tracksDir = Directory(
                          '${appDir.path}/cotune_tracks',
                        );
                        if (!await tracksDir.exists()) {
                          await tracksDir.create(recursive: true);
                        }
                        final outputPath = '${tracksDir.path}/${track.id}.mp3';

                        final downloadedPath = await p2p.fetchFromNetwork(
                          track.ctid!,
                          preferredPeer: providers.first,
                          outputPath: outputPath,
                          maxProviders: 5,
                        );

                        if (downloadedPath.isNotEmpty) {
                          track.path = downloadedPath;
                        }
                      }
                    } catch (e) {
                      // If download fails, still update liked status
                      debugPrint('Failed to download remote track: $e');
                    }
                  }
                }

                await storage.updateTrack(track);
                if (track.liked && track.recognized) {
                  // Only share if file exists
                  final file = File(track.path);
                  if (await file.exists()) {
                    try {
                      await P2PGrpcService().shareTrack(
                        track.id,
                        track.path,
                        title: track.title,
                        artist: track.artist,
                        recognized: track.recognized,
                      );
                      track.sharedToNetwork = true;
                      await storage.updateTrack(track);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Трек опубликован в P2P сети'),
                          ),
                        );
                      }
                    } catch (e) {
                      track.sharedToNetwork = false;
                      await storage.updateTrack(track);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Ошибка публикации трека: $e'),
                          ),
                        );
                      }
                    }
                  }
                } else if (track.liked &&
                    !track.recognized &&
                    track.sharedToNetwork) {
                  track.sharedToNetwork = false;
                  await storage.updateTrack(track);
                }
              },
            ),
            IconButton(
              icon: Icon(Icons.more_vert, color: theme.iconTheme.color),
              onPressed: () => _showMenu(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showMenu(BuildContext context) {
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
          _addToPlaylist(context);
        },
      ),
      ListTile(
        leading: Icon(Icons.save_alt, color: theme.colorScheme.primary),
        title: Text(
          'Сохранить в файлы',
          style: GoogleFonts.inter(color: theme.colorScheme.onSurface),
        ),
        onTap: () {
          Navigator.pop(context);
          _saveToFiles(context, track.path);
        },
      ),
      ListTile(
        leading: Icon(Icons.person, color: theme.colorScheme.primary),
        title: Text(
          'Перейти к артисту',
          style: GoogleFonts.inter(color: theme.colorScheme.onSurface),
        ),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  FolderScreen(type: FolderType.artist, idOrName: track.artist),
            ),
          );
        },
      ),
      if (!track.recognized)
        ListTile(
          leading: Icon(Icons.edit, color: theme.colorScheme.primary),
          title: Text(
            'Подписать вручную',
            style: GoogleFonts.inter(color: theme.colorScheme.onSurface),
          ),
          onTap: () {
            Navigator.pop(context);
            _manualTag(context);
          },
        ),
    ]);
  }

  Future<void> _addToPlaylist(
    BuildContext ctx, {
    bool singleSelect = false,
  }) async {
    final storage = Provider.of<StorageService>(ctx, listen: false);
    List<PlaylistModel> playlists = storage.allPlaylists();

    final result = await showCotuneModal<List<String>?>(
      // -> List<Widget> Function(BuildContext)
      ctx,
      title: 'Добавить в плейлист',
      builder: (bctx) {
        // <-- selected объявлен здесь, вне StatefulBuilder
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
                      itemCount: playlists.length,
                      itemBuilder: (_, i) {
                        final p = playlists[i];
                        final sel = selected.contains(p.id);
                        return CheckboxListTile(
                          value: sel,
                          onChanged: (v) {
                            setSb(() {
                              if (singleSelect) {
                                // single select: если включили — очищаем и ставим; если выключили — убираем
                                if (v == true) {
                                  selected
                                    ..clear()
                                    ..add(p.id);
                                } else {
                                  selected.remove(p.id);
                                }
                              } else {
                                if (v == true) {
                                  selected.add(p.id);
                                } else {
                                  selected.remove(p.id);
                                }
                              }
                            });
                          },
                          title: Text(
                            p.name,
                            style: TextStyle(
                              color: Theme.of(sbCtx).colorScheme.onSurface,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  CotuneModalActions(
                    onCancel: () => Navigator.of(bctx).pop(<String>[]),
                    onConfirm: () => Navigator.of(bctx).pop(selected.toList()),
                    confirmLabel: 'Добавить',
                  ),
                ],
              );
            },
          ),
        ];
      },
    );

    if (result != null && result.isNotEmpty) {
      for (final pid in result) {
        final pl = storage.getPlaylist(pid);
        if (pl == null) continue;
        if (!pl.trackIds.contains(track.id)) {
          pl.trackIds.add(track.id);
          await storage.savePlaylist(pl);
        }
      }
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('Трек(и) добавлены в плейлисты')),
      );
    }
  }

  Future<void> _manualTag(BuildContext ctx) async {
    final storage = Provider.of<StorageService>(ctx, listen: false);
    final titleCtl = TextEditingController(text: track.title);
    final artistCtl = TextEditingController(text: track.artist);

    final res = await showCotuneModal<bool?>(
      ctx,
      title: 'Подписать вручную',
      builder: (bctx) => [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtl,
                decoration: const InputDecoration(labelText: 'Название'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: artistCtl,
                decoration: const InputDecoration(labelText: 'Исполнитель'),
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
      track.title = titleCtl.text.trim();
      track.artist = artistCtl.text.trim();
      track.recognized = true;
      await storage.updateTrack(track);
      try {
        await P2PGrpcService().shareTrack(
          track.id,
          track.path,
          title: track.title,
          artist: track.artist,
          recognized: true,
        );
        track.sharedToNetwork = true;
        await storage.updateTrack(track);
        if (ctx.mounted) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            const SnackBar(
              content: Text('Данные трека обновлены и опубликованы'),
            ),
          );
        }
      } catch (e) {
        track.sharedToNetwork = false;
        await storage.updateTrack(track);
        if (ctx.mounted) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(
              content: Text('Данные обновлены, но публикация не удалась: $e'),
            ),
          );
        }
      }
    }
  }

  Future<void> _saveToFiles(BuildContext ctx, String sourcePath) async {
    try {
      final src = File(sourcePath);
      if (!await src.exists()) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text('Исходный файл не найден')),
        );
        return;
      }

      final filename = p.basename(sourcePath);
      final bytes = await src.readAsBytes();

      // Сохраняем во внутреннюю пользовательскую директорию на всех платформах.
      final appDir = await getApplicationDocumentsDirectory();
      var dest = File(p.join(appDir.path, filename));
      var counter = 1;
      while (await dest.exists()) {
        dest = File(
          p.join(
            appDir.path,
            '${p.basenameWithoutExtension(filename)}_$counter${p.extension(filename)}',
          ),
        );
        counter++;
      }

      await dest.writeAsBytes(bytes);

      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text('Сохранено локально: ${dest.path}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        ctx,
      ).showSnackBar(SnackBar(content: Text('Ошибка при сохранении: $e')));
    }
  }
}
