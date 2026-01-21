import 'dart:io';
import 'package:cotune_mobile/services/p2p_grpc_service.dart';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';

import '../services/storage_service.dart';
import '../models/track.dart';
import '../widgets/rounded_app_bar.dart';

Future<String> _computeMd5(String path) async {
  final bytes = await File(path).readAsBytes();
  return crypto.md5.convert(bytes).toString();
}

class AddTracksScreen extends StatefulWidget {
  const AddTracksScreen({super.key});

  @override
  State<AddTracksScreen> createState() => _AddTracksScreenState();
}

class _AddTracksScreenState extends State<AddTracksScreen> {
  List<PlatformFile> picked = [];
  bool loading = false;

  Future<void> pickFiles() async {
    final res = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.audio,
    );
    if (res != null) {
      setState(() => picked = res.files);
    }
  }

  Future<String> copyToApp(String src, String filename) async {
    final doc = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(doc.path, 'cotune_tracks'));
    if (!await dir.exists()) await dir.create(recursive: true);
    String target = p.join(dir.path, filename);
    int i = 1;
    while (await File(target).exists()) {
      target = p.join(
        dir.path,
        '${p.basenameWithoutExtension(filename)}($i)${p.extension(filename)}',
      );
      i++;
    }
    await File(src).copy(target);
    return target;
  }

  Future<void> importAll() async {
    if (picked.isEmpty) return;
    setState(() => loading = true);

    final storage = Provider.of<StorageService>(context, listen: false);
    final p2p = Provider.of<P2PGrpcService>(context, listen: false);

    final errors = <String>[];

    for (final f in picked) {
      try {
        if (f.path == null) continue;

        final target = await copyToApp(
          f.path!,
          f.name,
        ); // IO — async, not on UI thread
        final sum = await compute(_computeMd5, target);
        final dup = storage.findByChecksum(sum) != null;
        if (dup) {
          try {
            await File(target).delete();
          } catch (_) {}
          continue;
        }
        final meta = null;
        final titleCandidate =
            meta?['title']?.toString() ?? p.basenameWithoutExtension(f.name);
        final artistCandidate = meta?['artist']?.toString() ?? 'Unknown Artist';
        final recognized =
            meta != null &&
            (meta['title'] != null) &&
            (meta['title'].toString().trim().isNotEmpty);

        // используем checksum как стабильный trackId для дедупликации в P2P
        final id = sum.isNotEmpty ? sum : await storage.createId();

        final track = Track(
          id: id,
          title: titleCandidate,
          artist: artistCandidate,
          path: target,
          liked: true,
          recognized: recognized,
          checksum: sum,
        );

        await storage.saveTrack(track);

        try {
          await p2p.shareTrack(
            track.id,
            track.path,
            title: track.title,
            artist: track.artist,
            recognized: track.recognized,
            checksum: track.checksum,
          );
        } catch (e) {
          // share не критичен — логируем и продолжаем
          debugPrint('shareTrack failed for ${track.id}: $e');
        }
      } catch (e) {
        debugPrint('Import error: $e');
        errors.add(e.toString());
      }
    }

    setState(() => loading = false);

    if (errors.isNotEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Некоторые файлы не импортированы (${errors.length})',
            ),
          ),
        );
      }
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: RoundedAppBar(title: Text(l10n.addMusic)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(
                child: picked.isEmpty
                    ? Center(
                        child: Text(
                          'Файлы не выбраны',
                          style: GoogleFonts.inter(
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: picked.length,
                        itemBuilder: (_, i) => ListTile(
                          title: Text(
                            picked[i].name,
                            style: GoogleFonts.inter(
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          subtitle: Text(
                            '${(picked[i].size / 1024).toStringAsFixed(1)} KB',
                            style: GoogleFonts.inter(
                              color: theme.textTheme.bodyMedium?.color,
                            ),
                          ),
                        ),
                      ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.attach_file),
                        label: Text(
                          'Выбрать',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
                        ),
                        onPressed: pickFiles,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: ElevatedButton(
                        onPressed: loading || picked.isEmpty ? null : importAll,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: Text(
                          loading ? 'Импорт...' : 'Импорт',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
