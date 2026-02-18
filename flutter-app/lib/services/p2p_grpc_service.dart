// lib/services/p2p_grpc_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:grpc/grpc.dart';
import '../generated/cotune.pbgrpc.dart';
import '../generated/cotune.pb.dart' as pb;

/// gRPC client for CoTune daemon IPC
/// Uses protobuf for communication instead of HTTP
class P2PGrpcService {
  static const String _fallbackBootstrapAddrs =
      '/ip4/84.201.172.91/udp/4001/quic-v1/p2p/12D3KooWN9yd5yKtJkAitShdz6CSD71cJ666JFEargFMWX6SaanY,'
      '/ip4/84.201.172.91/tcp/4001/p2p/12D3KooWN9yd5yKtJkAitShdz6CSD71cJ666JFEargFMWX6SaanY';

  final String address;
  ClientChannel? _channel;
  CotuneServiceClient? _stub;
  Process? _desktopDaemonProcess;

  P2PGrpcService({this.address = '127.0.0.1:7777'});

  /// Connect to the gRPC server
  Future<void> connect() async {
    if (_channel == null) {
      final parts = address.split(':');
      final host = parts[0];
      final port = int.tryParse(parts[1]) ?? 7777;

      _channel = ClientChannel(
        host,
        port: port,
        options: ChannelOptions(
          credentials: ChannelCredentials.insecure(), // Localhost only
        ),
      );
      _stub = CotuneServiceClient(_channel!);
    }
  }

  /// Check if daemon is running
  Future<Map<String, dynamic>> status() async {
    try {
      await connect();
      final request = pb.StatusRequest();
      final response = await _stub!.status(request);
      return {'running': response.running, 'version': response.version};
    } catch (e) {
      throw Exception('gRPC status error: $e');
    }
  }

  /// Get peer information
  Future<Map<String, dynamic>> generatePeerInfo({
    String format = 'json',
  }) async {
    try {
      await connect();
      final request = pb.PeerInfoRequest()..format = format;
      final response = await _stub!.peerInfo(request);
      return {
        'peerId': response.peerInfo.peerId,
        'addrs': response.peerInfo.addresses,
        'pubkey': '',
        'ts': DateTime.now().millisecondsSinceEpoch,
      };
    } catch (e) {
      throw Exception('gRPC peerInfo error: $e');
    }
  }

  /// Get known peers
  Future<List<String>> getKnownPeers() async {
    try {
      await connect();
      final request = pb.StatusRequest();
      final response = await _stub!.knownPeers(request);
      final peers = <String>[];
      for (final peer in response.peers) {
        peers.add(peer.peerId);
        peers.addAll(peer.addresses);
      }
      return peers;
    } catch (e) {
      throw Exception('gRPC knownPeers error: $e');
    }
  }

  /// Read daemon control diagnostics (local HTTP API).
  Future<Map<String, dynamic>> getNetworkDiagnostics() async {
    try {
      final status = await _getControlJson('/status');
      return {'status': status};
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _getControlJson(String path) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse('http://127.0.0.1:8080$path');
      final req = await client.getUrl(uri);
      final resp = await req.close();
      final body = await utf8.decodeStream(resp);
      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        throw Exception('HTTP ${resp.statusCode}: $path');
      }
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return {'raw': decoded};
    } finally {
      client.close(force: true);
    }
  }

  /// Connect to a peer
  Future<void> connectToPeer(String peerInfo) async {
    try {
      await connect();
      final request = pb.ConnectRequest();

      // Check if it's a multiaddr
      if (peerInfo.startsWith('/')) {
        request.multiaddr = peerInfo;
      } else if (peerInfo.startsWith('{')) {
        // Parse JSON peer info
        final json = jsonDecode(peerInfo) as Map<String, dynamic>;
        final peerId = json['peerId'] ?? json['id'] as String?;
        final addrs = json['addrs'] as List? ?? [];
        if (peerId != null && addrs.isNotEmpty) {
          final peerInfoObj = pb.PeerInfo()
            ..peerId = peerId
            ..addresses.addAll(addrs.map((e) => e.toString()));
          request.peerInfo = peerInfoObj;
        } else {
          throw Exception('Invalid peer info JSON');
        }
      } else {
        throw Exception('Unknown peer format');
      }

      final response = await _stub!.connect(request);
      if (!response.success) {
        throw Exception(response.error);
      }
    } catch (e) {
      throw Exception('gRPC connect error: $e');
    }
  }

  /// Search for tracks
  Future<List<Map<String, dynamic>>> search(
    String query, {
    int max = 20,
  }) async {
    try {
      debugPrint('[P2P search] start query="$query" max=$max');
      await ensureBootstrapConnected();
      await connect();
      final request = pb.SearchRequest()
        ..query = query
        ..maxResults = max;
      debugPrint(
        '[P2P search] grpc request sent query="${request.query}" max=${request.maxResults}',
      );
      final response = await _stub!.search(request);
      debugPrint(
        '[P2P search] grpc response results=${response.results.length}',
      );

      return response.results
          .map(
            (r) => {
              'id': r.ctid,
              'title': r.title,
              'artist': r.artist,
              'recognized': r.recognized,
              'providers': r.providers,
              'ctid': r.ctid,
            },
          )
          .toList();
    } catch (e) {
      debugPrint('[P2P search] error: $e');
      throw Exception('gRPC search error: $e');
    }
  }

  /// Best-effort bootstrap reconnect before network operations.
  Future<void> ensureBootstrapConnected() async {
    try {
      await connect();
      final bootstrapAddrs = _effectiveBootstrapAddrs();
      if (bootstrapAddrs.trim().isEmpty) {
        debugPrint('[P2P bootstrap] no bootstrap addrs configured');
        return;
      }

      debugPrint('[P2P bootstrap] reconnect start addrs="$bootstrapAddrs"');
      for (final addr in bootstrapAddrs.split(',')) {
        final trimmed = addr.trim();
        if (trimmed.isEmpty) continue;
        try {
          final request = pb.ConnectRequest()..multiaddr = trimmed;
          final response = await _stub!.connect(request);
          debugPrint(
            '[P2P bootstrap] connect addr="$trimmed" success=${response.success} error="${response.error}"',
          );
        } catch (_) {
          debugPrint('[P2P bootstrap] connect exception addr="$trimmed"');
          // Non-fatal: keep trying the rest.
        }
      }
    } catch (_) {
      debugPrint('[P2P bootstrap] reconnect skipped: stub/channel unavailable');
      // Non-fatal: caller operation will surface real failure if any.
    }
  }

  /// Search providers for a CTID
  Future<List<String>> searchProviders(String ctid, {int max = 12}) async {
    try {
      await connect();
      final request = pb.SearchProvidersRequest()
        ..ctid = ctid
        ..max = max;
      final response = await _stub!.searchProviders(request);
      return response.providerIds;
    } catch (e) {
      throw Exception('gRPC searchProviders error: $e');
    }
  }

  /// Fetch a track from network
  Future<String> fetchFromNetwork(
    String ctid, {
    String? preferredPeer,
    String outputPath = '',
    int maxProviders = 5,
  }) async {
    try {
      await connect();
      final request = pb.FetchRequest()
        ..ctid = ctid
        ..outputPath = outputPath;
      if (preferredPeer != null && preferredPeer.isNotEmpty) {
        request.peerId = preferredPeer;
      }

      final response = await _stub!.fetch(request);
      if (!response.success) {
        throw Exception(response.error);
      }
      return response.path;
    } catch (e) {
      throw Exception('gRPC fetch error: $e');
    }
  }

  /// Share a track (announce in DHT)
  Future<void> shareTrack(
    String trackId,
    String path, {
    String? title,
    String? artist,
    bool recognized = false,
  }) async {
    try {
      await connect();
      final request = pb.ShareRequest()
        ..trackId = trackId
        ..path = path
        ..recognized = recognized;
      if (title != null) request.title = title;
      if (artist != null) request.artist = artist;

      final response = await _stub!.share(request);
      if (!response.success) {
        throw Exception(response.error);
      }
    } catch (e) {
      throw Exception('gRPC share error: $e');
    }
  }

  /// Manually trigger announce
  Future<void> announce() async {
    try {
      await connect();
      final request = pb.AnnounceRequest();
      await _stub!.announce(request);
    } catch (e) {
      throw Exception('gRPC announce error: $e');
    }
  }

  /// Get relay addresses
  Future<List<String>> getRelays() async {
    try {
      await connect();
      final request = pb.RelaysRequest();
      final response = await _stub!.relays(request);
      return response.relayAddresses;
    } catch (e) {
      throw Exception('gRPC relays error: $e');
    }
  }

  /// Enable relay service
  Future<void> relayEnable() async {
    try {
      await connect();
      final request = pb.RelayEnableRequest();
      await _stub!.relayEnable(request);
    } catch (e) {
      throw Exception('gRPC relayEnable error: $e');
    }
  }

  /// Request relay connection
  Future<void> relayRequest(String peerId) async {
    try {
      await connect();
      final request = pb.RelayRequestRequest()..peerId = peerId;
      final response = await _stub!.relayRequest(request);
      if (!response.success) {
        throw Exception(response.error);
      }
    } catch (e) {
      throw Exception('gRPC relayRequest error: $e');
    }
  }

  /// Ensure node is running (compatibility with P2PService)
  ///
  /// According to architecture:
  /// 1. Flutter calls ensureNodeRunning()
  /// 2. Kotlin bridge starts Go daemon via CotuneNodePlugin
  /// 3. Go daemon initializes all services
  ///
  /// This method ensures the daemon is started and ready to accept connections.
  Future<void> ensureNodeRunning({
    String? proto,
    String? http,
    String listen = '/ip4/0.0.0.0/tcp/0',
    String relays = '',
    String? basePath,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final protoAddr = proto ?? http ?? address;
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _startViaAndroidBridge(
        protoAddr: protoAddr,
        listen: listen,
        relays: relays,
        basePath: basePath,
      );
    } else {
      await _startViaDesktopProcess(
        protoAddr: protoAddr,
        listen: listen,
        basePath: basePath,
      );
    }

    // Wait for node to be ready
    final end = DateTime.now().add(timeout);
    Exception? lastError;
    while (DateTime.now().isBefore(end)) {
      try {
        await status();
        return;
      } catch (e) {
        lastError = e is Exception ? e : Exception(e.toString());
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
    throw lastError ?? Exception('Node not ready');
  }

  Future<void> _startViaAndroidBridge({
    required String protoAddr,
    required String listen,
    required String relays,
    required String? basePath,
  }) async {
    const platform = MethodChannel('cotune_node');
    try {
      final result = await platform.invokeMethod('startNode', {
        'proto': protoAddr,
        'listen': listen,
        'relays': relays,
        'basePath': basePath,
      });
      if (result != 'started') {
        throw Exception('Failed to start node: $result');
      }
    } catch (e) {
      if (!e.toString().contains('already') &&
          !e.toString().contains('started')) {
        debugPrint(
          'Warning: startNode returned error (may be already running): $e',
        );
      }
    }
  }

  Future<void> _startViaDesktopProcess({
    required String protoAddr,
    required String listen,
    required String? basePath,
  }) async {
    // If already reachable, do not start another daemon process.
    try {
      await status();
      return;
    } catch (_) {}

    if (_desktopDaemonProcess != null) {
      return;
    }

    final daemonPath = await _resolveDesktopDaemonPath();
    final dataPath = basePath ?? p.join(Directory.current.path, 'cotune_data');
    final envListen = Platform.environment['COTUNE_LISTEN']?.trim() ?? '';
    final effectiveListen = envListen.isNotEmpty
        ? envListen
        : (listen == '/ip4/0.0.0.0/tcp/0'
              ? '/ip4/0.0.0.0/tcp/4002,/ip4/0.0.0.0/udp/4002/quic-v1'
              : listen);

    final args = <String>[
      '-mode',
      'server',
      '-proto',
      protoAddr,
      '-control',
      '127.0.0.1:8080',
      '-listen',
      effectiveListen,
      '-data',
      dataPath,
    ];

    final bootstrapAddrs = _effectiveBootstrapAddrs();
    if (bootstrapAddrs.isNotEmpty) {
      for (final addr in bootstrapAddrs.split(',')) {
        final trimmed = addr.trim();
        if (trimmed.isNotEmpty) {
          args.addAll(['-bootstrap', trimmed]);
        }
      }
    }

    final env = <String, String>{...Platform.environment};
    if ((env['COTUNE_ANNOUNCE_ADDRS'] ?? '').trim().isEmpty) {
      final autoAnnounce = await _autoAnnounceAddrs(effectiveListen);
      if (autoAnnounce.isNotEmpty) {
        env['COTUNE_ANNOUNCE_ADDRS'] = autoAnnounce;
      }
    }

    _desktopDaemonProcess = await Process.start(
      daemonPath,
      args,
      mode: ProcessStartMode.detachedWithStdio,
      runInShell: true,
      environment: env,
    );
    unawaited(_desktopDaemonProcess!.stdout.drain<void>());
    unawaited(_desktopDaemonProcess!.stderr.drain<void>());
  }

  Future<String> _resolveDesktopDaemonPath() async {
    final envPath = Platform.environment['COTUNE_DAEMON_PATH'];
    if (envPath != null && envPath.trim().isNotEmpty) {
      final f = File(envPath.trim());
      if (await f.exists()) {
        return f.path;
      }
    }

    final exeName = Platform.isWindows ? 'cotune-daemon.exe' : 'cotune-daemon';
    final exeDir = File(Platform.resolvedExecutable).parent.path;
    final candidates = <String>[
      p.join(exeDir, exeName),
      p.join(exeDir, 'data', exeName),
      p.join(Directory.current.path, exeName),
      p.join(Directory.current.path, 'bin', exeName),
      p.join(Directory.current.path, '..', 'go-backend', exeName),
      p.join(Directory.current.path, '..', 'go-backend', 'bin', exeName),
      p.join(Directory.current.path, '..', '..', 'go-backend', exeName),
      p.join(File(Platform.resolvedExecutable).parent.parent.path, exeName),
    ];

    for (final candidate in candidates) {
      final f = File(candidate);
      if (await f.exists()) {
        return f.path;
      }
    }

    throw Exception(
      'cotune-daemon not found for desktop. '
      'Set COTUNE_DAEMON_PATH or place $exeName near the app.',
    );
  }

  String _effectiveBootstrapAddrs() {
    const bootstrapFromDartDefine = String.fromEnvironment(
      'COTUNE_BOOTSTRAP_ADDRS',
      defaultValue: '',
    );
    final bootstrapFromEnv =
        Platform.environment['COTUNE_BOOTSTRAP_ADDRS']?.trim() ?? '';

    if (bootstrapFromEnv.isNotEmpty) {
      return bootstrapFromEnv;
    }
    if (bootstrapFromDartDefine.trim().isNotEmpty) {
      return bootstrapFromDartDefine.trim();
    }
    return _fallbackBootstrapAddrs;
  }

  Future<String> _autoAnnounceAddrs(String listenMultiaddr) async {
    final port = _extractTcpPort(listenMultiaddr);
    if (port == null) {
      return '';
    }

    final publicIp = await _detectPublicIPv4();
    if (publicIp == null || publicIp.isEmpty) {
      return '';
    }

    return '/ip4/$publicIp/tcp/$port,/ip4/$publicIp/udp/$port/quic-v1';
  }

  int? _extractTcpPort(String multiaddr) {
    final m = RegExp(r'/tcp/(\d+)').firstMatch(multiaddr);
    if (m == null) {
      return null;
    }
    return int.tryParse(m.group(1)!);
  }

  Future<String?> _detectPublicIPv4() async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 4);
    final endpoints = <String>[
      'https://api.ipify.org',
      'https://ipv4.icanhazip.com',
    ];

    try {
      for (final url in endpoints) {
        try {
          final req = await client.getUrl(Uri.parse(url));
          final resp = await req.close();
          if (resp.statusCode < 200 || resp.statusCode >= 300) {
            continue;
          }
          final body = (await utf8.decodeStream(resp)).trim();
          if (RegExp(r'^\d{1,3}(\.\d{1,3}){3}$').hasMatch(body)) {
            return body;
          }
        } catch (_) {
          // Try next endpoint.
        }
      }
      return null;
    } finally {
      client.close(force: true);
    }
  }

  /// Disconnect from the gRPC server
  Future<void> disconnect() async {
    await _channel?.shutdown();
    _channel = null;
    _stub = null;
    if (_desktopDaemonProcess != null) {
      _desktopDaemonProcess!.kill(ProcessSignal.sigterm);
      _desktopDaemonProcess = null;
    }
  }

  /// Get peer info QR (compatibility with P2PService)
  Future<Uint8List?> getPeerInfoQr() async {
    // This should be handled by Kotlin bridge
    // Return null to indicate it should use native method
    return null;
  }
}
