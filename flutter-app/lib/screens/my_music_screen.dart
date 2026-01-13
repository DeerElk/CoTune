import 'package:cotune_mobile/models/playlist.dart';
import 'package:cotune_mobile/screens/folder_screen.dart';
import 'package:cotune_mobile/widgets/modal.dart';
import 'package:cotune_mobile/widgets/folder_tile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/storage_service.dart';
import '../widgets/track_tile.dart';
import '../theme.dart';
import '../widgets/chips_row.dart';
import 'add_tracks_screen.dart';
import '../widgets/rounded_app_bar.dart';

class MyMusicScreen extends StatefulWidget {
  const MyMusicScreen({Key? key}) : super(key: key);

  @override
  State<MyMusicScreen> createState() => _MyMusicScreenState();
}

class _MyMusicScreenState extends State<MyMusicScreen> {
  int _filter = 0;

  Future<void> _refresh() async {
    await Future.delayed(const Duration(milliseconds: 200));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final storage = Provider.of<StorageService>(context);
    final all = storage.allTracks();
    final liked = all.where((t) => t.liked).toList();
    final artists = all.map((t) => t.artist).toSet().toList()..sort();
    final playlists = storage.allPlaylists();
    final unsub = all.where((t) => !t.recognized).toList();
    final theme = Theme.of(context);

    // Отступ внизу списка, чтобы кнопка не перекрывала возможности нажатия на последний элемент.
    final double bottomListPadding = _filter == 2 ? 120.0 : 24.0;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: RoundedAppBar(
        title: Text('Моя музыка'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: CotuneTheme.headerTextColor),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddTracksScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              // Используем Stack, чтобы поверх ListView разместить плавающую кнопку на вкладке "Плейлисты".
              child: Stack(
                children: [
                  RefreshIndicator(
                    onRefresh: _refresh,
                    color: CotuneTheme.highlight,
                    child: ListView(
                      padding: EdgeInsets.symmetric(
                        vertical: 12,
                      ).copyWith(bottom: bottomListPadding),
                      children: [
                        ChipsRow(
                          chips: [
                            ChoiceChip(
                              label: Text('Треки'),
                              selected: _filter == 0,
                              showCheckmark: false,
                              selectedColor: CotuneTheme.highlight,
                              backgroundColor: theme.colorScheme.surface,
                              onSelected: (_) => setState(() => _filter = 0),
                            ),
                            ChoiceChip(
                              label: Text('Исполнители'),
                              selected: _filter == 1,
                              showCheckmark: false,
                              selectedColor: CotuneTheme.highlight,
                              backgroundColor: theme.colorScheme.surface,
                              onSelected: (_) => setState(() => _filter = 1),
                            ),
                            ChoiceChip(
                              label: Text('Плейлисты'),
                              selected: _filter == 2,
                              showCheckmark: false,
                              selectedColor: CotuneTheme.highlight,
                              backgroundColor: theme.colorScheme.surface,
                              onSelected: (_) => setState(() => _filter = 2),
                            ),
                            ChoiceChip(
                              label: Text('Не подписаны'),
                              selected: _filter == 3,
                              showCheckmark: false,
                              selectedColor: CotuneTheme.highlight,
                              backgroundColor: theme.colorScheme.surface,
                              onSelected: (_) => setState(() => _filter = 3),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        if (_filter == 0)
                          liked.isEmpty
                              ? SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.5,
                                  child: Center(
                                    child: Text(
                                      'Понравившихся треков пока нет',
                                      style: GoogleFonts.inter(
                                        color:
                                            theme.textTheme.bodyMedium?.color,
                                      ),
                                    ),
                                  ),
                                )
                              : Column(
                                  children: liked
                                      .map((t) => TrackTile(track: t))
                                      .toList(),
                                ),
                        if (_filter == 1)
                          artists.isEmpty
                              ? SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.5,
                                  child: Center(
                                    child: Text(
                                      'Нет исполнителей',
                                      style: GoogleFonts.inter(
                                        color:
                                            theme.textTheme.bodyMedium?.color,
                                      ),
                                    ),
                                  ),
                                )
                              : Column(
                                  children: artists.map((a) {
                                    final cnt = all
                                        .where((t) => t.artist == a)
                                        .length;
                                    return FolderTile(
                                      name: a,
                                      subtitle: '$cnt трек(ов)',
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => FolderScreen(
                                            type: FolderType.artist,
                                            idOrName: a,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                        if (_filter == 2)
                          playlists.isEmpty ? SizedBox(
                            height:
                            MediaQuery.of(context).size.height * 0.5,
                            child: Center(
                              child: Text(
                                'Плейлистов пока нет',
                                style: GoogleFonts.inter(
                                  color:
                                  theme.textTheme.bodyMedium?.color,
                                ),
                              ),
                            ),
                          ) : Column(
                            children: playlists.map((p) => FolderTile(
                              name: p.name,
                              subtitle: '${p.trackIds.length} трек(ов)',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => FolderScreen(
                                    type: FolderType.playlist,
                                    idOrName: p.id,
                                  ),
                                ),
                              ),
                            ),
                            ).toList(),
                          ),
                        if (_filter == 3)
                          unsub.isEmpty ? SizedBox(
                            height: MediaQuery.of(context).size.height * 0.5,
                            child: Center(
                              child: Text(
                                'Нет неподписанных треков',
                                style: GoogleFonts.inter(
                                  color:
                                  theme.textTheme.bodyMedium?.color,
                                ),
                              ),
                            ),
                          ) : Column(
                            children: unsub.map((t) => TrackTile(track: t)).toList(),
                          ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                  if (_filter == 2)
                    Positioned(
                      bottom: 20,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: ElevatedButton(
                          onPressed: () async {
                            final ctl = TextEditingController();
                            final res = await showCotuneModal<String?>(
                              context,
                              title: 'Добавить плейлист',
                              builder: (bctx) => [
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TextField(controller: ctl, decoration: const InputDecoration(hintText: 'Название плейлиста')),
                                      const SizedBox(height: 12),
                                      CotuneModalActions(
                                        onCancel: () => Navigator.pop(bctx),
                                        onConfirm: () => Navigator.pop(bctx, ctl.text.trim()),
                                        confirmLabel: 'Создать',
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );

                            if (res != null && res.isNotEmpty) {
                              final id = await storage.createId();
                              final p = PlaylistModel(id: id, name: res, trackIds: []);
                              await storage.savePlaylist(p);
                              setState(() {});
                              Navigator.push(context, MaterialPageRoute(builder: (_) => FolderScreen(type: FolderType.playlist, idOrName: p.id)));
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            elevation: 6,
                            backgroundColor: CotuneTheme.highlight,
                          ),
                          child: Text(
                            'Добавить плейлист',
                            style: GoogleFonts.inter(color: CotuneTheme.headerTextColor, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
