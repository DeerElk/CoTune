import 'dart:convert';
import 'package:cotune_mobile/widgets/modal.dart';
import 'package:cotune_mobile/widgets/option_sheet.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../l10n/app_localizations.dart';
import '../services/p2p_grpc_service.dart';
import '../services/qr_service.dart';
import '../theme.dart';
import '../app.dart';
import 'qr_scan_screen.dart';
import '../widgets/rounded_app_bar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _peerInfo;
  List<String> _hosts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initPeer();
  }

  Future<void> _initPeer() async {
    setState(() {
      _loading = true;
    });
    try {
      final p2p = Provider.of<P2PGrpcService>(context, listen: false);
      try {
        // Получаем путь к директории приложения для хранения данных
        final appDir = await getApplicationDocumentsDirectory();
        final basePath = p.join(appDir.path, 'cotune_data');
        await p2p.ensureNodeRunning(basePath: basePath);
        // AutoNetwork is automatically enabled by the daemon
      } catch (_) {}
      final info = await p2p.generatePeerInfo();
      List<String> hosts = <String>[];
      try {
        hosts = await p2p.getKnownPeers();
        // добавим список актуальных relay, если они не продублированы
        final relays = await p2p.getRelays().catchError((_) => <String>[]);
        hosts = {...hosts, ...relays}.toList();
      } catch (_) {
        hosts = <String>[];
      }
      if (mounted) {
        setState(() {
          _peerInfo = info;
          _hosts = hosts;
        });
      }
    } catch (e) {
      debugPrint('init peer error: $e');
      if (mounted) {
        setState(() {
          _peerInfo = null;
          _hosts = <String>[];
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _shareQrImagePlusText() async {
    if (_peerInfo == null) return;
    final str = jsonEncode(_peerInfo); // ✅ кодируем здесь
    await QRService.shareQr(context, str, size: 1000);
  }

  void _scanQr() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const QRScanScreen()),
    );
    if (result != null && result is String) {
      try {
        await Provider.of<P2PGrpcService>(
          context,
          listen: false,
        ).connectToPeer(result);
        final hosts = await Provider.of<P2PGrpcService>(
          context,
          listen: false,
        ).getKnownPeers().catchError((_) => <String>[]);
        if (mounted) setState(() => _hosts = hosts);
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.connected)));
        }
      } catch (e) {
        debugPrint('connect error: $e');
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.connectionFailed)));
        }
      }
    }
  }

  void _enterManual() {
    final ctl = TextEditingController();
    final l10n = AppLocalizations.of(context)!;

    showCotuneModal<void>(
      context,
      title: l10n.enterManually,
      builder: (ctx) => [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ctl,
                maxLines: null,
                decoration: InputDecoration(labelText: l10n.peerInfoJson),
              ),
              const SizedBox(height: 12),
              CotuneModalActions(
                onCancel: () => Navigator.of(ctx).pop(),
                onConfirm: () async {
                  final txt = ctl.text.trim();
                  if (txt.isNotEmpty) {
                    try {
                      await Provider.of<P2PGrpcService>(
                        context,
                        listen: false,
                      ).connectToPeer(txt);
                      final hosts = await Provider.of<P2PGrpcService>(
                        context,
                        listen: false,
                      ).getKnownPeers().catchError((_) => <String>[]);
                      if (mounted) setState(() => _hosts = hosts);
                      if (mounted) {
                        final l10n = AppLocalizations.of(context)!;
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(l10n.connected)));
                      }
                    } catch (e) {
                      if (mounted) {
                        final l10n = AppLocalizations.of(context)!;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.connectionError)),
                        );
                      }
                    }
                  }
                  Navigator.of(ctx).pop();
                },
                confirmLabel: l10n.connect,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _openSettingsSheet() {
    final appSettings = Provider.of<AppSettings>(context, listen: false);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final textColor = theme.colorScheme.onSurface;
    final dropdownTextColor = theme.colorScheme.onSurface;

    OptionSheet.show(context, [
      Row(
        children: [
          Icon(Icons.language, color: theme.iconTheme.color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.language,
              style: GoogleFonts.inter(color: textColor),
            ),
          ),
          DropdownButton<String>(
            value: appSettings.locale.languageCode,
            dropdownColor: theme.colorScheme.surface,
            style: GoogleFonts.inter(color: dropdownTextColor),
            items: [
              DropdownMenuItem(
                value: 'ru',
                child: Text(
                  l10n.russian,
                  style: GoogleFonts.inter(color: dropdownTextColor),
                ),
              ),
              DropdownMenuItem(
                value: 'en',
                child: Text(
                  l10n.english,
                  style: GoogleFonts.inter(color: dropdownTextColor),
                ),
              ),
            ],
            onChanged: (v) {
              if (v != null) appSettings.setLocale(v);
            },
          ),
        ],
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Icon(Icons.brightness_6, color: theme.iconTheme.color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(l10n.theme, style: GoogleFonts.inter(color: textColor)),
          ),
          DropdownButton<ThemeMode>(
            value: appSettings.themeMode,
            dropdownColor: theme.colorScheme.surface,
            style: GoogleFonts.inter(color: dropdownTextColor),
            items: [
              DropdownMenuItem(
                value: ThemeMode.system,
                child: Text(
                  l10n.systemTheme,
                  style: GoogleFonts.inter(color: dropdownTextColor),
                ),
              ),
              DropdownMenuItem(
                value: ThemeMode.dark,
                child: Text(
                  l10n.darkTheme,
                  style: GoogleFonts.inter(color: dropdownTextColor),
                ),
              ),
              DropdownMenuItem(
                value: ThemeMode.light,
                child: Text(
                  l10n.lightTheme,
                  style: GoogleFonts.inter(color: dropdownTextColor),
                ),
              ),
            ],
            onChanged: (v) {
              if (v != null) appSettings.setThemeMode(v);
            },
          ),
        ],
      ),
      const SizedBox(height: 8),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: RoundedAppBar(
        title: Text(l10n.profile),
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: CotuneTheme.headerTextColor),
            onPressed: _openSettingsSheet,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 14),
            Center(
              child: _loading
                  ? const SizedBox(
                      width: 220,
                      height: 220,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : _peerInfo == null
                  ? Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          l10n.noPeerInfo,
                          style: GoogleFonts.inter(
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                      ),
                    )
                  : QRService.qrWidget(
                      jsonEncode(_peerInfo!), // ✅ кодируем при показе QR
                      size: 220,
                    ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: CotuneTheme.highlight,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () {
                            if (_peerInfo != null) {
                              QRService.copyToClipboard(
                                context,
                                jsonEncode(_peerInfo!), // ✅ кодируем здесь
                                successMessage: l10n.copied,
                              );
                            }
                          },
                          icon: Icon(
                            Icons.copy,
                            color: CotuneTheme.headerTextColor,
                          ),
                          label: Text(
                            l10n.copy,
                            style: GoogleFonts.inter(
                              color: CotuneTheme.headerTextColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: CotuneTheme.highlight,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: _peerInfo == null
                              ? null
                              : _shareQrImagePlusText,
                          icon: Icon(
                            Icons.share,
                            color: CotuneTheme.headerTextColor,
                          ),
                          label: Text(
                            l10n.share,
                            style: GoogleFonts.inter(
                              color: CotuneTheme.headerTextColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: CotuneTheme.highlight,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: _scanQr,
                          icon: Icon(
                            Icons.qr_code_scanner,
                            color: CotuneTheme.headerTextColor,
                          ),
                          label: Text(
                            l10n.scan,
                            style: GoogleFonts.inter(
                              color: CotuneTheme.headerTextColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: CotuneTheme.highlight,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: _enterManual,
                          icon: Icon(
                            Icons.edit,
                            color: CotuneTheme.headerTextColor,
                          ),
                          label: Text(
                            l10n.enterManually,
                            style: GoogleFonts.inter(
                              color: CotuneTheme.headerTextColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.connectedHosts,
                  style: GoogleFonts.inter(
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _hosts.isEmpty
                  ? Center(
                      child: Text(
                        l10n.noConnectedHosts,
                        style: GoogleFonts.inter(
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      itemCount: _hosts.length,
                      itemBuilder: (_, i) => Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.device_hub,
                              color: theme.iconTheme.color,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _hosts[i],
                                style: GoogleFonts.inter(
                                  color: theme.textTheme.bodyLarge?.color,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: l10n.copyAddressTooltip,
                              icon: Icon(
                                Icons.copy,
                                color: theme.iconTheme.color,
                              ),
                              onPressed: () {
                                QRService.copyToClipboard(
                                  context,
                                  _hosts[i],
                                  successMessage: l10n.copied,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
