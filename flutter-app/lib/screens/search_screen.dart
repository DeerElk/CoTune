import 'package:cotune_mobile/screens/folder_screen.dart';
import 'package:cotune_mobile/services/p2p_grpc_service.dart';
import 'package:cotune_mobile/widgets/folder_tile.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';
import '../services/storage_service.dart';
import '../models/track.dart';
import '../widgets/track_tile.dart';
import '../theme.dart';
import '../widgets/chips_row.dart';
import '../widgets/rounded_app_bar.dart';
import 'dart:async';
import 'package:path/path.dart' as p;
import 'player_fullscreen.dart';
import '../services/audio_player_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String _query = '';
  int _filter = 0;

  Timer? _debounce;
  List<dynamic> remoteResults = [];
  bool remoteLoading = false;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onQueryChanged(String v) {
    setState(() => _query = v);
    debugPrint('[SearchScreen] query changed="$v"');
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (_query.trim().length >= 3) {
        debugPrint(
          '[SearchScreen] trigger remote search query="${_query.trim()}"',
        );
        _doRemoteSearch(_query.trim());
      } else {
        debugPrint(
          '[SearchScreen] skip remote search: query too short len=${_query.trim().length}',
        );
        setState(() {
          remoteResults = [];
          remoteLoading = false;
        });
      }
    });
  }

  Future<void> _doRemoteSearch(String q) async {
    debugPrint('[SearchScreen] _doRemoteSearch start query="$q"');
    setState(() {
      remoteLoading = true;
      remoteResults = [];
    });
    final p2p = Provider.of<P2PGrpcService>(context, listen: false);
    try {
      final res = await p2p.search(q);
      String myPeerId = '';
      try {
        final info = await p2p.generatePeerInfo();
        myPeerId = (info['peerId'] as String? ?? '').trim();
      } catch (_) {}
      final filteredNetwork = res.where((r) {
        if (myPeerId.isEmpty) return true;
        final providers = r['providers'];
        if (providers is List) {
          return !providers.map((e) => e.toString()).contains(myPeerId);
        }
        return true;
      }).toList();
      debugPrint(
        '[SearchScreen] _doRemoteSearch success results=${filteredNetwork.length}',
      );
      setState(() {
        remoteResults = filteredNetwork;
      });
    } catch (e) {
      debugPrint('remote search error: $e');
    } finally {
      debugPrint('[SearchScreen] _doRemoteSearch done');
      if (mounted) setState(() => remoteLoading = false);
    }
  }

  Widget _buildSearchResults() {
    final storage = Provider.of<StorageService>(context);
    final localTracks = storage.allTracks();
    final localIds = localTracks.map((t) => t.id).toSet();
    final localCtids = localTracks
        .where((t) => (t.ctid ?? '').isNotEmpty)
        .map((t) => t.ctid!)
        .toSet();

    // Разделяем на локальные и удаленные
    final localResults = <Map<String, dynamic>>[];
    final remoteResultsFiltered = <Map<String, dynamic>>[];

    for (final item in remoteResults) {
      final id = item['id'] as String? ?? '';
      final ctid = item['ctid'] as String? ?? id;
      if (ctid.isNotEmpty && localCtids.contains(ctid)) {
        // This track is already local for this device.
        continue;
      }
      if (localIds.contains(id)) {
        localResults.add(item);
      } else {
        remoteResultsFiltered.add(item);
      }
    }

    // Также добавляем локальные треки, которые соответствуют запросу
    final filtered = _query.isEmpty
        ? localTracks
        : localTracks
              .where(
                (t) =>
                    t.title.toLowerCase().contains(_query.toLowerCase()) ||
                    t.artist.toLowerCase().contains(_query.toLowerCase()),
              )
              .toList();

    if (remoteLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (remoteResultsFiltered.isEmpty &&
        filtered.isEmpty &&
        localResults.isEmpty) {
      return Center(
        child: Text(
          'Ничего не найдено',
          style: GoogleFonts.inter(
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
      );
    }

    return ListView(
      children: [
        if (remoteResultsFiltered.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              'В сети',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ),
          ...remoteResultsFiltered.map((item) => _buildRemoteTrackTile(item)),
        ],
        if (filtered.isNotEmpty || localResults.isNotEmpty) ...[
          if (remoteResultsFiltered.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(
                'Локальные',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ),
          ...filtered.map((t) {
            // Проверяем, не дублируется ли с результатами из сети
            final inRemote = remoteResults.any(
              (r) => (r['id'] as String?) == t.id,
            );
            if (inRemote) return const SizedBox.shrink();
            return TrackTile(track: t);
          }),
        ],
      ],
    );
  }

  Widget _buildRemoteTrackTile(Map<String, dynamic> item) {
    final storage = Provider.of<StorageService>(context, listen: false);
    final theme = Theme.of(context);
    final title = item['title'] as String? ?? 'Без названия';
    final artist = item['artist'] as String? ?? 'Unknown';
    final ctid = item['ctid'] as String? ?? item['id'] as String? ?? '';
    final existing = ctid.isEmpty ? null : storage.findByCTID(ctid);
    final liked = existing?.liked ?? false;

    return InkWell(
      onTap: () => _playRemote(item),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(
          children: [
            Icon(Icons.music_note, color: CotuneTheme.highlight, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    artist,
                    style: GoogleFonts.inter(
                      color: theme.textTheme.bodyMedium?.color,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                liked ? Icons.favorite : Icons.favorite_border,
                color: CotuneTheme.highlight,
              ),
              onPressed: () => _likeRemoteTrack(item),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _playRemote(Map<String, dynamic> item) async {
    final storage = Provider.of<StorageService>(context, listen: false);
    final audio = Provider.of<AudioPlayerService>(context, listen: false);
    final ctid = item['ctid'] as String? ?? item['id'] as String? ?? '';
    final existing = ctid.isEmpty ? null : storage.findByCTID(ctid);
    if (existing != null && existing.path.isNotEmpty) {
      final file = File(existing.path);
      if (!await file.exists()) {
        await _likeRemoteTrack(item, autoplay: true);
        return;
      }
      audio.setQueueFromTracks(
        storage.allTracks().where((t) => t.liked).toList(),
        currentId: existing.id,
      );
      await audio.playUri(existing.path, trackId: existing.id);
      if (mounted) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const PlayerFullScreenSheet(),
        );
      }
      return;
    }
    await _likeRemoteTrack(item, autoplay: true);
  }

  Future<void> _likeRemoteTrack(
    Map<String, dynamic> item, {
    bool autoplay = false,
  }) async {
    final p2p = Provider.of<P2PGrpcService>(context, listen: false);
    final storage = Provider.of<StorageService>(context, listen: false);
    final audio = Provider.of<AudioPlayerService>(context, listen: false);
    final ctid = item['ctid'] as String? ?? item['id'] as String? ?? '';

    if (ctid.isEmpty) return;

    try {
      await p2p.ensureBootstrapConnected();
      final existing = storage.findByCTID(ctid);
      if (existing != null) {
        existing.liked = true;
        await storage.updateTrack(existing);
        if (autoplay) {
          audio.setQueueFromTracks(
            storage.allTracks().where((t) => t.liked).toList(),
            currentId: existing.id,
          );
          await audio.playUri(existing.path, trackId: existing.id);
          if (mounted) {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const PlayerFullScreenSheet(),
            );
          }
        }
        return;
      }

      final providersRaw = item['providers'];
      String? preferredPeer;
      if (providersRaw is List && providersRaw.isNotEmpty) {
        preferredPeer = providersRaw.first.toString();
      }

      final outputPath = await _buildRemoteOutputPath(ctid);
      String path;
      try {
        path = await p2p.fetchFromNetwork(
          ctid,
          preferredPeer: preferredPeer,
          outputPath: outputPath,
          maxProviders: 5,
        );
      } catch (_) {
        // Retry without preferred peer when provided peer is stale/unreachable.
        path = await p2p.fetchFromNetwork(
          ctid,
          outputPath: outputPath,
          maxProviders: 5,
        );
      }
      final id = ctid;
      final t = Track(
        id: id,
        title: item['title'] ?? p.basename(path),
        artist: item['artist'] ?? 'Unknown',
        path: path,
        liked: true,
        recognized: true,
        sharedToNetwork: false,
        ctid: ctid,
      );
      await storage.saveTrack(t);

      try {
        await p2p.shareTrack(
          t.id,
          t.path,
          title: t.title,
          artist: t.artist,
          recognized: t.recognized,
        );
        t.sharedToNetwork = true;
        await storage.updateTrack(t);
      } catch (_) {
        t.sharedToNetwork = false;
        await storage.updateTrack(t);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Трек добавлен в мою музыку, скачан и опубликован в сети',
            ),
          ),
        );
      }

      if (autoplay) {
        audio.setQueueFromTracks(
          storage.allTracks().where((tr) => tr.liked).toList(),
          currentId: t.id,
        );
        await audio.playUri(t.path, trackId: t.id);
        if (mounted) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const PlayerFullScreenSheet(),
          );
        }
      }
    } catch (e) {
      debugPrint('fetch error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось получить трек из сети: $e')),
        );
      }
    }
  }

  Future<String> _buildRemoteOutputPath(String ctid) async {
    final appDir = await getApplicationDocumentsDirectory();
    final tracksDir = Directory(p.join(appDir.path, 'cotune_tracks'));
    if (!await tracksDir.exists()) {
      await tracksDir.create(recursive: true);
    }
    return p.join(tracksDir.path, '$ctid.mp3');
  }

  @override
  Widget build(BuildContext context) {
    final storage = Provider.of<StorageService>(context);
    final tracks = storage.allTracks();
    final filtered = _query.isEmpty
        ? tracks
        : tracks
              .where(
                (t) =>
                    t.title.toLowerCase().contains(_query.toLowerCase()) ||
                    t.artist.toLowerCase().contains(_query.toLowerCase()),
              )
              .toList();
    final artists = tracks.map((t) => t.artist).toSet().toList()..sort();

    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final headerColor = CotuneTheme.highlight;
    final iconColor =
        theme.iconTheme.color ??
        (theme.brightness == Brightness.dark ? Colors.white : Colors.black);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: RoundedAppBar(
        toolbarHeight: 64,
        title: SizedBox(
          height: 44,
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    autofocus: false,
                    style: GoogleFonts.inter(
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                    textAlignVertical: TextAlignVertical.center,
                    decoration: InputDecoration(
                      hintText: l10n.searchPlaceholder,
                      hintStyle: GoogleFonts.inter(
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onChanged: _onQueryChanged,
                  ),
                ),
                Icon(Icons.search, color: iconColor),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            ChipsRow(
              chips: [
                ChoiceChip(
                  label: Text(
                    'Всё',
                    style: GoogleFonts.inter(
                      color: _filter == 0
                          ? Colors.black
                          : theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.visible,
                    softWrap: false,
                  ),
                  selected: _filter == 0,
                  showCheckmark: false,
                  selectedColor: headerColor,
                  backgroundColor: theme.colorScheme.surface,
                  onSelected: (_) => setState(() => _filter = 0),
                ),
                ChoiceChip(
                  label: Text(
                    'Треки',
                    style: GoogleFonts.inter(
                      color: _filter == 1
                          ? Colors.black
                          : theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.visible,
                    softWrap: false,
                  ),
                  selected: _filter == 1,
                  showCheckmark: false,
                  selectedColor: headerColor,
                  backgroundColor: theme.colorScheme.surface,
                  onSelected: (_) => setState(() => _filter = 1),
                ),
                ChoiceChip(
                  label: Text(
                    'Исполнители',
                    style: GoogleFonts.inter(
                      color: _filter == 2
                          ? Colors.black
                          : theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.visible,
                    softWrap: false,
                  ),
                  selected: _filter == 2,
                  showCheckmark: false,
                  selectedColor: headerColor,
                  backgroundColor: theme.colorScheme.surface,
                  onSelected: (_) => setState(() => _filter = 2),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _filter == 2
                  ? ListView.builder(
                      itemCount: artists.length,
                      itemBuilder: (_, i) => FolderTile(
                        name: artists[i],
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FolderScreen(
                              type: FolderType.artist,
                              idOrName: artists[i],
                            ),
                          ),
                        ),
                      ),
                    )
                  : _query.trim().length >= 3
                  ? _buildSearchResults()
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (_, i) => TrackTile(track: filtered[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
