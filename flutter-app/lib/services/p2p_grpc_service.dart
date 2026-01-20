// lib/services/p2p_grpc_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:grpc/grpc.dart';
import '../generated/cotune.pbgrpc.dart';
import '../generated/cotune.pb.dart' as pb;

/// gRPC client for CoTune daemon IPC
/// Uses protobuf for communication instead of HTTP
class P2PGrpcService {
  final String address;
  ClientChannel? _channel;
  CotuneServiceClient? _stub;

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
      await connect();
      final request = pb.SearchRequest()
        ..query = query
        ..maxResults = max;
      final response = await _stub!.search(request);

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
      throw Exception('gRPC search error: $e');
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
    String? checksum,
  }) async {
    try {
      await connect();
      final request = pb.ShareRequest()
        ..trackId = trackId
        ..path = path
        ..recognized = recognized;
      if (title != null) request.title = title;
      if (artist != null) request.artist = artist;
      if (checksum != null) request.checksum = checksum;

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
  Future<void> ensureNodeRunning({
    String? proto,
    String? http,
    String listen = '/ip4/0.0.0.0/tcp/0',
    String relays = '',
    String? basePath,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    // Address will be used from constructor
    // The node should already be started by Kotlin bridge
    // Just check status
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

  /// Disconnect from the gRPC server
  Future<void> disconnect() async {
    await _channel?.shutdown();
    _channel = null;
    _stub = null;
  }

  /// Get peer info QR (compatibility with P2PService)
  Future<Uint8List?> getPeerInfoQr() async {
    // This should be handled by Kotlin bridge
    // Return null to indicate it should use native method
    return null;
  }
}
