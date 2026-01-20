// lib/services/p2p_service.dart
// DEPRECATED: Use P2PGrpcService for new code
// This service is kept for backward compatibility
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'p2p_grpc_service.dart';

/// Управляет Go-нoдой через Kotlin bridge + gRPC API
/// This service now uses gRPC by default, but can fall back to HTTP
class P2PService {
  static const MethodChannel _mc = MethodChannel('cotune_node');

  final String httpBase; // например: http://127.0.0.1:7777
  bool _started = false;
  final bool useGrpc;
  P2PGrpcService? _grpcService;

  P2PService({this.httpBase = 'http://127.0.0.1:7777', this.useGrpc = true}) {
    if (useGrpc) {
      final addr = httpBase.replaceFirst(RegExp(r'^https?://'), '');
      _grpcService = P2PGrpcService(address: addr);
    }
  }

  /// Запускает ноду + ждёт /status
  Future<void> ensureNodeRunning({
    String? http,
    String? proto,
    String listen = '/ip4/0.0.0.0/tcp/0',
    String relays = '',
    String? basePath,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    if (useGrpc && _grpcService != null) {
      // Extract proto address from http or use provided proto
      final protoAddr = proto ?? (http != null ? http.replaceFirst(RegExp(r'^https?://'), '') : '127.0.0.1:7777');
      _grpcService = P2PGrpcService(address: protoAddr);
      return await _grpcService!.ensureNodeRunning(
        proto: protoAddr,
        listen: listen,
        relays: relays,
        basePath: basePath,
        timeout: timeout,
      );
    }

    // Fallback to HTTP
    if (_started) {
      try {
        await status();
        return;
      } catch (_) {
        _started = false;
      }
    }

    final httpHostPort = (http ?? httpBase).replaceFirst(RegExp(r'^https?://'), '');

    try {
      await _mc.invokeMethod<String>('startNode', {
        'proto': proto ?? httpHostPort,
        'listen': listen,
        'relays': relays,
        if (basePath != null) 'basePath': basePath,
      });
    } catch (e) {
      debugPrint('startNode invokeMethod error: $e');
    }

    final end = DateTime.now().add(timeout);
    Exception? lastError;
    while (DateTime.now().isBefore(end)) {
      try {
        await status();
        _started = true;
        return;
      } catch (e) {
        lastError = e is Exception ? e : Exception(e.toString());
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
    throw lastError ?? Exception('Node not ready');
  }

  Future<Map<String, dynamic>> status() async {
    if (useGrpc && _grpcService != null) {
      return await _grpcService!.status();
    }

    final r = await http.get(Uri.parse('$httpBase/status')).timeout(const Duration(seconds: 2));
    if (r.statusCode != 200) {
      throw Exception('status error ${r.statusCode}');
    }
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> generatePeerInfo({String format = 'json'}) async {
    if (useGrpc && _grpcService != null) {
      return await _grpcService!.generatePeerInfo(format: format);
    }

    Exception? lastError;
    for (int i = 0; i < 3; i++) {
      try {
        final r = await http
            .get(Uri.parse('$httpBase/peerinfo?format=$format'))
            .timeout(const Duration(seconds: 2));

        if (r.statusCode != 200) {
          throw Exception('peerinfo error ${r.statusCode}');
        }

        final j = jsonDecode(r.body) as Map<String, dynamic>;
        final List<String> addrs = (j['addrs'] as List? ?? [])
            .map((e) => e.toString())
            .toList();
        final List<String> relays = (j['relays'] as List? ?? [])
            .map((e) => e.toString())
            .toList();

        List<String> relaysSnapshot = relays;
        if (relaysSnapshot.isEmpty) {
          try {
            relaysSnapshot = await getRelays();
          } catch (_) {}
        }

        return {
          'peerId': j['peerId'] ?? j['id'] ?? '',
          'addrs': addrs,
          'relays': relaysSnapshot,
          'pubkey': j['pubkey'],
          'ts': DateTime.now().millisecondsSinceEpoch,
        };
      } catch (e) {
        lastError = e is Exception ? e : Exception(e.toString());
        if (i < 2) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }
    }
    throw lastError ?? Exception('peerinfo failed');
  }

  Future<Map<String, dynamic>> getPeerInfo() => generatePeerInfo();

  Future<Uint8List?> getPeerInfoQr() async {
    if (useGrpc && _grpcService != null) {
      final qr = await _grpcService!.getPeerInfoQr();
      if (qr != null) return qr;
    }

    final data = await _mc.invokeMethod('getPeerInfoQrNative');
    if (data is Uint8List) return data;
    if (data is List<int>) return Uint8List.fromList(data);
    return null;
  }

  Future<List<String>> getKnownPeers() async {
    if (useGrpc && _grpcService != null) {
      return await _grpcService!.getKnownPeers();
    }

    final r = await http
        .get(Uri.parse('$httpBase/known_peers'))
        .timeout(const Duration(seconds: 2));

    if (r.statusCode != 200) {
      throw Exception('known_peers error ${r.statusCode}');
    }

    final map = jsonDecode(r.body) as Map<String, dynamic>;
    final out = <String>[];
    for (final entry in map.entries) {
      final key = entry.key;
      final val = entry.value;
      if (val is List) {
        for (final v in val) {
          out.add(v.toString());
        }
      } else {
        out.add(val.toString());
      }
      if ((val is List && val.isEmpty) || val == null) {
        out.add(key);
      }
    }
    return out;
  }

  Future<void> connectToPeer(String peerInfo) async {
    if (useGrpc && _grpcService != null) {
      return await _grpcService!.connectToPeer(peerInfo);
    }

    peerInfo = peerInfo.trim();

    if (peerInfo.startsWith('{')) {
      final ok = await connectByPeerInfoJson(peerInfo);
      if (!ok) throw Exception('connectByPeerInfoJson failed');
      return;
    }

    if (peerInfo.startsWith('/')) {
      final r = await http
          .post(Uri.parse('$httpBase/connect'), body: peerInfo)
          .timeout(const Duration(seconds: 6));

      if (r.statusCode != 200 && r.statusCode != 204) {
        throw Exception('connect failed ${r.statusCode}');
      }
      return;
    }

    throw Exception('Unknown peer format');
  }

  Future<bool> connectByPeerInfoJson(String peerInfoJson) async {
    if (useGrpc && _grpcService != null) {
      await _grpcService!.connectToPeer(peerInfoJson);
      return true;
    }

    final j = jsonDecode(peerInfoJson) as Map<String, dynamic>;
    final peerId = j['peerId'] ?? j['id'] as String?;
    final addrs = j['addrs'] as List? ?? [];

    if (peerId == null || peerId.isEmpty) return false;

    for (final addr in addrs) {
      try {
        await connectToPeer(addr.toString());
        return true;
      } catch (_) {}
    }
    return false;
  }

  Future<List<Map<String, dynamic>>> search(String query, {int max = 20}) async {
    if (useGrpc && _grpcService != null) {
      return await _grpcService!.search(query, max: max);
    }

    final r = await http
        .get(Uri.parse('$httpBase/search?q=${Uri.encodeComponent(query)}&max=$max'))
        .timeout(const Duration(seconds: 10));

    if (r.statusCode != 200) {
      throw Exception('search error ${r.statusCode}');
    }

    final j = jsonDecode(r.body) as Map<String, dynamic>;
    final results = j['results'] as List? ?? [];
    return results.map((e) => e as Map<String, dynamic>).toList();
  }

  Future<List<String>> searchProviders(String ctid, {int max = 12}) async {
    if (useGrpc && _grpcService != null) {
      return await _grpcService!.searchProviders(ctid, max: max);
    }

    final r = await http
        .get(Uri.parse('$httpBase/search_providers?id=${Uri.encodeComponent(ctid)}&max=$max'))
        .timeout(const Duration(seconds: 5));

    if (r.statusCode != 200) {
      throw Exception('search_providers error ${r.statusCode}');
    }

    final j = jsonDecode(r.body) as Map<String, dynamic>;
    return (j['provider_ids'] as List? ?? []).map((e) => e.toString()).toList();
  }

  Future<String> fetchFromNetwork(
    String ctid, {
    String? preferredPeer,
    String outputPath = '',
    int maxProviders = 5,
  }) async {
    if (useGrpc && _grpcService != null) {
      return await _grpcService!.fetchFromNetwork(
        ctid,
        preferredPeer: preferredPeer,
        outputPath: outputPath,
        maxProviders: maxProviders,
      );
    }

    if (preferredPeer == null || preferredPeer.isEmpty) {
      final providers = await searchProviders(ctid, max: maxProviders);
      if (providers.isEmpty) {
        throw Exception('No providers found for CTID: $ctid');
      }
      preferredPeer = providers.first;
    }

    final uri = Uri.parse('$httpBase/fetch').replace(queryParameters: {
      'peer': preferredPeer,
      'id': ctid,
      if (outputPath.isNotEmpty) 'output': outputPath,
    });

    final r = await http.get(uri).timeout(const Duration(seconds: 30));
    if (r.statusCode != 200) {
      throw Exception('fetch error ${r.statusCode}');
    }

    final j = jsonDecode(r.body) as Map<String, dynamic>;
    final path = j['path'] as String?;
    if (path == null || path.isEmpty) {
      throw Exception('fetch failed: no path');
    }
    return path;
  }

  Future<void> shareTrack(
    String trackId,
    String path, {
    String? title,
    String? artist,
    bool recognized = false,
    String? checksum,
  }) async {
    if (useGrpc && _grpcService != null) {
      return await _grpcService!.shareTrack(
        trackId,
        path,
        title: title,
        artist: artist,
        recognized: recognized,
        checksum: checksum,
      );
    }

    final body = jsonEncode({
      'track_id': trackId,
      'path': path,
      if (title != null) 'title': title,
      if (artist != null) 'artist': artist,
      'recognized': recognized,
      if (checksum != null) 'checksum': checksum,
    });

    final r = await http
        .post(Uri.parse('$httpBase/share'),
            headers: {'Content-Type': 'application/json'}, body: body)
        .timeout(const Duration(seconds: 10));

    if (r.statusCode != 200 && r.statusCode != 204) {
      throw Exception('share error ${r.statusCode}');
    }
  }

  Future<void> announce() async {
    if (useGrpc && _grpcService != null) {
      return await _grpcService!.announce();
    }

    final r = await http.post(Uri.parse('$httpBase/announce')).timeout(const Duration(seconds: 5));
    if (r.statusCode != 200 && r.statusCode != 204) {
      throw Exception('announce error ${r.statusCode}');
    }
  }

  Future<List<String>> getRelays() async {
    if (useGrpc && _grpcService != null) {
      return await _grpcService!.getRelays();
    }

    final r = await http.get(Uri.parse('$httpBase/relays')).timeout(const Duration(seconds: 2));
    if (r.statusCode != 200) {
      throw Exception('relays error ${r.statusCode}');
    }

    final j = jsonDecode(r.body) as Map<String, dynamic>;
    return (j['relay_addresses'] as List? ?? []).map((e) => e.toString()).toList();
  }

  Future<void> relayEnable() async {
    if (useGrpc && _grpcService != null) {
      return await _grpcService!.relayEnable();
    }

    final r = await http.post(Uri.parse('$httpBase/relay/enable')).timeout(const Duration(seconds: 5));
    if (r.statusCode != 200 && r.statusCode != 204) {
      throw Exception('relay/enable error ${r.statusCode}');
    }
  }

  Future<void> relayRequest(String peerId) async {
    if (useGrpc && _grpcService != null) {
      return await _grpcService!.relayRequest(peerId);
    }

    final body = jsonEncode({'peer_id': peerId});
    final r = await http
        .post(Uri.parse('$httpBase/relay_request'),
            headers: {'Content-Type': 'application/json'}, body: body)
        .timeout(const Duration(seconds: 5));

    if (r.statusCode != 200 && r.statusCode != 204) {
      throw Exception('relay_request error ${r.statusCode}');
    }
  }

  Future<void> disconnect() async {
    if (useGrpc && _grpcService != null) {
      await _grpcService!.disconnect();
    }
    _started = false;
  }
}
