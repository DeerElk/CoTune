import 'package:cotune_mobile/screens/folder_screen.dart';
import 'package:cotune_mobile/services/p2p_service.dart';
import 'package:cotune_mobile/widgets/folder_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/storage_service.dart';
import '../models/track.dart';
import '../widgets/track_tile.dart';
import '../theme.dart';
import '../widgets/chips_row.dart';
import '../widgets/rounded_app_bar.dart';
import '../utils/hash_utils.dart';
import 'dart:async';
import 'package:path/path.dart' as p;

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

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
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (_query.trim().length >= 3) {
        _doRemoteSearch(_query.trim());
      } else {
        setState(() {
          remoteResults = [];
          remoteLoading = false;
        });
      }
    });
  }

  Future<void> _doRemoteSearch(String q) async {
    setState(() {
      remoteLoading = true;
      remoteResults = [];
    });
    final p2p = Provider.of<P2PService>(context, listen: false);
    try {
      final res = await p2p.search(q);
      setState(() {
        remoteResults = res;
      });
    } catch (e) {
      debugPrint('remote search error: $e');
    } finally {
      if (mounted) setState(() => remoteLoading = false);
    }
  }

  Widget _buildSearchResults() {
    final storage = Provider.of<StorageService>(context);
    final localTracks = storage.allTracks();
    final localIds = localTracks.map((t) => t.id).toSet();

    // Разделяем на локальные и удаленные
    final localResults = <Map<String, dynamic>>[];
    final remoteResultsFiltered = <Map<String, dynamic>>[];

    for (final item in remoteResults) {
      final id = item['id'] as String? ?? '';
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

    if (remoteResultsFiltered.isEmpty && filtered.isEmpty && localResults.isEmpty) {
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
            final inRemote = remoteResults.any((r) => (r['id'] as String?) == t.id);
            if (inRemote) return const SizedBox.shrink();
            return TrackTile(track: t);
          }),
        ],
      ],
    );
  }

  Widget _buildRemoteTrackTile(Map<String, dynamic> item) {
    final theme = Theme.of(context);
    final title = item['title'] as String? ?? 'Без названия';
    final artist = item['artist'] as String? ?? 'Unknown';
    final recognized = item['recognized'] as bool? ?? true;
    final unsigned = !recognized;

    return InkWell(
      onTap: () => _downloadRemote(item),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(
          children: [
            Icon(
              unsigned ? Icons.error_outline : Icons.cloud_download,
              color: unsigned ? Colors.orangeAccent : CotuneTheme.highlight,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onBackground,
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
                Icons.download,
                color: CotuneTheme.highlight,
              ),
              onPressed: () => _downloadRemote(item),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadRemote(Map<String, dynamic> item) async {
    final p2p = Provider.of<P2PService>(context, listen: false);
    final storage = Provider.of<StorageService>(context, listen: false);
    final trackId = item['id'] as String? ?? '';
    final peerId = item['owner'] as String? ?? '';
    // ProviderAddrs может быть как 'addrs', так и 'ProviderAddrs' в JSON
    final providerAddrs = ((item['addrs'] ?? item['ProviderAddrs']) as List?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    if (trackId.isEmpty) return;

    try {
      final path = await p2p.fetchFromNetwork(
        trackId,
        preferredPeer: peerId.isNotEmpty ? peerId : null,
        providerAddrs: providerAddrs,
      );
      final sum = await compute(computeMd5, path);

      // если уже есть трек с таким checksum — просто отмечаем лайк и выходим
      final existing = storage.findByChecksum(sum);
      if (existing != null) {
        existing.liked = true;
        await storage.updateTrack(existing);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Уже в библиотеке, отмечен как избранный')),
          );
        }
        return;
      }

      final id = trackId.isNotEmpty ? trackId : await storage.createId();
      final t = Track(
        id: id,
        title: item['title'] ?? p.basename(path),
        artist: item['artist'] ?? 'Unknown',
        path: path,
        liked: true,
        recognized: item['recognized'] ?? true,
        checksum: sum,
      );
      await storage.saveTrack(t);

      await p2p.shareTrack(
        t.id,
        t.path,
        title: t.title,
        artist: t.artist,
        recognized: t.recognized,
        checksum: t.checksum,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Скачано и сохранено')),
        );
      }
    } catch (e) {
      debugPrint('fetch error: $e');
    }
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
    final headerColor = CotuneTheme.highlight;
    final iconColor =
        theme.iconTheme.color ?? (theme.brightness == Brightness.dark ? Colors.white : Colors.black);

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
                      hintText: 'Поиск',
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
              leftPadding: 12,
              chips: [
                ChoiceChip(
                  label: const Text('Всё'),
                  selected: _filter == 0,
                  showCheckmark: false,
                  selectedColor: headerColor,
                  backgroundColor: theme.colorScheme.surface,
                  onSelected: (_) => setState(() => _filter = 0),
                ),
                ChoiceChip(
                  label: const Text('Треки'),
                  selected: _filter == 1,
                  showCheckmark: false,
                  selectedColor: headerColor,
                  backgroundColor: theme.colorScheme.surface,
                  onSelected: (_) => setState(() => _filter = 1),
                ),
                ChoiceChip(
                  label: const Text('Исполнители'),
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
              ) : _query.trim().length >= 3
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
