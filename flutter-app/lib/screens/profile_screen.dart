import 'dart:async';
import 'dart:convert';
import 'package:cotune_mobile/widgets/modal.dart';
import 'package:flutter/foundation.dart';
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
  Map<String, dynamic>? _networkDiag;
  bool _loading = true;
  Timer? _diagTimer;
  bool get _qrScanSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void initState() {
    super.initState();
    _initPeer();
    _diagTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      _refreshDiagnostics();
    });
  }

  @override
  void dispose() {
    _diagTimer?.cancel();
    super.dispose();
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
      final networkDiag = await p2p.getNetworkDiagnostics();
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
          _networkDiag = networkDiag;
        });
      }
    } catch (e) {
      debugPrint('init peer error: $e');
      if (mounted) {
        setState(() {
          _peerInfo = null;
          _hosts = <String>[];
          _networkDiag = null;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refreshDiagnostics() async {
    if (!mounted) return;
    try {
      final p2p = Provider.of<P2PGrpcService>(context, listen: false);
      final networkDiag = await p2p.getNetworkDiagnostics();
      final hosts = await p2p.getKnownPeers().catchError((_) => <String>[]);
      if (!mounted) return;
      setState(() {
        _networkDiag = networkDiag;
        _hosts = hosts;
      });
    } catch (_) {
      // Ignore transient errors.
    }
  }

  Future<void> _shareQrImagePlusText() async {
    if (_peerInfo == null) return;
    final str = jsonEncode(_peerInfo); // ✅ кодируем здесь
    await QRService.shareQr(context, str, size: 1000);
  }

  void _scanQr() async {
    if (!_qrScanSupported) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('QR-сканер доступен только на мобильных платформах'),
          ),
        );
      }
      return;
    }
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return Consumer<AppSettings>(
          builder: (ctx, appSettings, _) {
            final theme = Theme.of(ctx);
            final l10n = AppLocalizations.of(ctx)!;
            final textColor = theme.colorScheme.onSurface;
            const dropdownWidth = 150.0;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                      SizedBox(
                        width: dropdownWidth,
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: appSettings.locale.languageCode,
                          dropdownColor: theme.colorScheme.surface,
                          style: GoogleFonts.inter(color: textColor),
                          items: [
                            DropdownMenuItem(
                              value: 'ru',
                              child: Text(
                                l10n.russian,
                                style: GoogleFonts.inter(color: textColor),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'en',
                              child: Text(
                                l10n.english,
                                style: GoogleFonts.inter(color: textColor),
                              ),
                            ),
                          ],
                          onChanged: (v) {
                            if (v != null) appSettings.setLocale(v);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.brightness_6, color: theme.iconTheme.color),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.theme,
                          style: GoogleFonts.inter(color: textColor),
                        ),
                      ),
                      SizedBox(
                        width: dropdownWidth,
                        child: DropdownButton<ThemeMode>(
                          isExpanded: true,
                          value: appSettings.themeMode,
                          dropdownColor: theme.colorScheme.surface,
                          style: GoogleFonts.inter(color: textColor),
                          items: [
                            DropdownMenuItem(
                              value: ThemeMode.system,
                              child: Text(
                                l10n.systemTheme,
                                style: GoogleFonts.inter(color: textColor),
                              ),
                            ),
                            DropdownMenuItem(
                              value: ThemeMode.dark,
                              child: Text(
                                l10n.darkTheme,
                                style: GoogleFonts.inter(color: textColor),
                              ),
                            ),
                            DropdownMenuItem(
                              value: ThemeMode.light,
                              child: Text(
                                l10n.lightTheme,
                                style: GoogleFonts.inter(color: textColor),
                              ),
                            ),
                          ],
                          onChanged: (v) {
                            if (v != null) appSettings.setThemeMode(v);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
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
                  _buildNetworkStatusCard(theme),
                  const SizedBox(height: 10),
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
                          onPressed: _qrScanSupported ? _scanQr : null,
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

  Widget _buildNetworkStatusCard(ThemeData theme) {
    final dynamic statusRaw = _networkDiag?['status'] ?? _networkDiag;
    final status = statusRaw is Map ? statusRaw.cast<String, dynamic>() : null;
    final connectedPeersRaw = status?['connected_peers'];
    final providersRaw = status?['provider_count'];
    final routingRaw = status?['routing_table_size'];
    final wanRaw = status?['wan_active'];
    final diagError = (_networkDiag?['error'] as String?)?.trim();

    int asInt(dynamic v) {
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    bool asBool(dynamic v) {
      if (v is bool) return v;
      if (v is num) return v != 0;
      if (v is String) {
        final s = v.toLowerCase().trim();
        return s == 'true' || s == '1' || s == 'on';
      }
      return false;
    }

    var connectedPeers = asInt(connectedPeersRaw);
    final providers = asInt(providersRaw);
    final routing = asInt(routingRaw);
    final wanActive = asBool(wanRaw);

    // Fallback so UI doesn't show false zeros when /status temporarily fails.
    if (connectedPeers == 0 && _hosts.isNotEmpty) {
      connectedPeers = _hosts.length;
    }

    final hasDiag = status != null && (diagError == null || diagError.isEmpty);
    final ok = connectedPeers > 0 && (hasDiag ? wanActive : true);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            ok ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
            color: ok ? Colors.lightGreenAccent : Colors.orangeAccent,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Сеть: peers=$connectedPeers, providers=${hasDiag ? providers : "n/a"}, rt=${hasDiag ? routing : "n/a"}, wan=${hasDiag ? (wanActive ? "on" : "off") : "n/a"}',
                  style: GoogleFonts.inter(
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                ),
                if (diagError != null && diagError.isNotEmpty)
                  Text(
                    'diag: $diagError',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: theme.textTheme.bodySmall?.color,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
