// lib/services/p2p_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

/// Управляет Go-нoдой через Kotlin bridge + HTTP API
class P2PService {
  static const MethodChannel _mc = MethodChannel('cotune_node');

  final String httpBase; // например: http://127.0.0.1:7777
  bool _started = false;

  P2PService({this.httpBase = 'http://127.0.0.1:7777'});

  /// Запускает ноду + ждёт /status
  Future<void> ensureNodeRunning({
    String http = 'http://127.0.0.1:7777',
    String listen = '/ip4/0.0.0.0/tcp/0',
    String relays = '',
    String? basePath,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    if (_started) {
      try {
        await status();
        return;
      } catch (_) {
        _started = false;
      }
    }

    final httpHostPort = http.replaceFirst(RegExp(r'^https?://'), '');

    try {
      await _mc.invokeMethod<String>(
        'startNode',
        {
          'http': httpHostPort,
          'listen': listen,
          'relays': relays,
          if (basePath != null) 'basePath': basePath,
        },
      );
    } catch (e) {
      debugPrint('startNode invokeMethod error: $e');
      // Продолжаем - возможно нода уже запущена
    }

    // Ждём запуска HTTP сервера с увеличенным таймаутом
    final end = DateTime.now().add(timeout);
    Exception? lastError;
    while (DateTime.now().isBefore(end)) {
      try {
        final st = await status();
        if (st['running'] == true) {
          _started = true;
          return;
        }
      } catch (e) {
        lastError = e is Exception ? e : Exception(e.toString());
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }

    // Если не удалось, но это не критично - продолжаем работу
    if (lastError != null) {
      debugPrint('Node startup timeout, but continuing: $lastError');
    }
    _started = false;
  }

  Future<String> stopNode() async {
    final res = await _mc.invokeMethod<String>('stopNode');
    _started = false;
    return res ?? 'stopped';
  }

  /// GET /status
  Future<Map<String, dynamic>> status() async {
    final r = await http
        .get(Uri.parse('$httpBase/status'))
        .timeout(const Duration(seconds: 2));

    if (r.statusCode == 200) {
      return jsonDecode(r.body) as Map<String, dynamic>;
    }
    throw Exception('status error ${r.statusCode}');
  }

  /// GET /peerinfo?format=json
  Future<Map<String, dynamic>> generatePeerInfo() async {
    // Пробуем несколько раз, если сервер еще не готов
    Exception? lastError;
    for (int i = 0; i < 3; i++) {
      try {
        final r = await http
            .get(Uri.parse('$httpBase/peerinfo?format=json'))
            .timeout(const Duration(seconds: 3));

        if (r.statusCode != 200) {
          throw Exception('peerinfo error ${r.statusCode}');
        }

        final j = jsonDecode(r.body) as Map<String, dynamic>;
        final List<String> addrs =
            (j['addrs'] as List? ?? []).map((e) => e.toString()).toList();
        final List<String> relays =
            (j['relays'] as List? ?? []).map((e) => e.toString()).toList();

        // fallback: если backend не вернул relays, подхватываем /relays вручную
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

  /// Получаем QR из Kotlin (PNG Uint8List)
  Future<Uint8List?> getPeerInfoQr() async {
    final data = await _mc.invokeMethod('getPeerInfoQrNative');
    if (data is Uint8List) return data;
    if (data is List<int>) return Uint8List.fromList(data);
    return null;
  }

  /// GET /known_peers
  Future<List<String>> getKnownPeers() async {
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
        // fall back to raw value or peer id
        out.add(val.toString());
      }
      // добавляем peer id если адресов нет
      if ((val is List && val.isEmpty) || val == null) {
        out.add(key);
      }
    }
    return out;
  }

  /// /connect
  Future<void> connectToPeer(String peerInfo) async {
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

  Future<List<dynamic>> search(String q) async {
    final r = await http
        .get(Uri.parse('$httpBase/search?q=${Uri.encodeComponent(q)}'))
        .timeout(const Duration(seconds: 3));

    if (r.statusCode == 200) return jsonDecode(r.body);
    throw Exception('search failed ${r.statusCode}');
  }

  Future<List<String>> searchProviders(String trackId,
      {int max = 12}) async {
    final r = await http
        .get(Uri.parse(
            '$httpBase/search_providers?id=${Uri.encodeComponent(trackId)}&max=$max'))
        .timeout(const Duration(seconds: 6));
    if (r.statusCode != 200) {
      throw Exception('search_providers failed ${r.statusCode}');
    }
    final data = jsonDecode(r.body) as List<dynamic>;
    return data.map((e) => e.toString()).toList();
  }

  Future<String> _fetchOnce(String peerId, String trackId) async {
    final r = await http
        .get(Uri.parse(
            '$httpBase/fetch?peer=${Uri.encodeComponent(peerId)}&id=${Uri.encodeComponent(trackId)}'))
        .timeout(const Duration(seconds: 60));

    if (r.statusCode != 200) {
      throw Exception('fetch failed ${r.statusCode}');
    }

    final j = jsonDecode(r.body) as Map<String, dynamic>;
    return j['path'];
  }

  Future<String> fetchFromNetwork(
    String trackId, {
    String? preferredPeer,
    List<String>? providerAddrs,
    int maxProviders = 12,
  }) async {
    final seen = <String>{};
    final candidates = <String>[];

    void addCandidate(String s) {
      final trimmed = s.trim();
      if (trimmed.isEmpty) return;
      if (seen.add(trimmed)) candidates.add(trimmed);
    }

    providerAddrs?.forEach(addCandidate);

    if (candidates.length < maxProviders) {
      try {
        final fromNetwork = await searchProviders(trackId, max: maxProviders);
        for (final a in fromNetwork) {
          addCandidate(a);
        }
      } catch (_) {
        // ignore - we'll try preferredPeer/DHT
      }
    }

    if (preferredPeer != null && preferredPeer.isNotEmpty) {
      addCandidate(preferredPeer);
    }

    for (final addr in candidates) {
      String? peerId = _extractPeerId(addr);
      if (addr.startsWith('/')) {
        try {
          await connectToPeer(addr).timeout(const Duration(seconds: 6));
        } catch (_) {}
      }
      peerId ??= _extractPeerId(addr);
      if (peerId == null || peerId.isEmpty) {
        continue;
      }
      try {
        final path = await _fetchOnce(peerId, trackId);
        return path;
      } catch (_) {
        // try next provider
      }
    }

    // last chance: try preferred peer directly via DHT lookup
    if (preferredPeer != null && preferredPeer.isNotEmpty) {
      return _fetchOnce(preferredPeer, trackId);
    }

    throw Exception('fetch failed: no providers responded');
  }

  // Deprecated compatibility shim
  Future<String> fetch(String peerId, String trackId) =>
      fetchFromNetwork(trackId, preferredPeer: peerId);

  Future<String> shareTrack(
    String trackId,
    String path, {
    String? title,
    String? artist,
    bool recognized = true,
    String? checksum,
  }) async {
    final r = await http
        .post(
          Uri.parse('$httpBase/share'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'id': trackId,
            'path': path,
            'title': title,
            'artist': artist,
            'recognized': recognized,
            'checksum': checksum,
          }),
        )
        .timeout(const Duration(seconds: 8));

    if (r.statusCode != 200) {
      throw Exception('share failed ${r.statusCode}');
    }

    final j = jsonDecode(r.body);
    return j['path'];
  }

  Future<void> announce() async {
    final r = await http
        .post(Uri.parse('$httpBase/announce'))
        .timeout(const Duration(seconds: 3));

    if (r.statusCode != 200 && r.statusCode != 204) {
      throw Exception('announce failed');
    }
  }

  /// ✅ УМНЫЙ CONNECT ЧЕРЕЗ JSON
  Future<bool> connectByPeerInfoJson(
      String peerinfoJson, {
        Duration perAddrTimeout = const Duration(seconds: 4),
      }) async {
    final j = jsonDecode(peerinfoJson);
    final peerId = j['peerId'];
    final List addrs = j['addrs'] ?? [];
    final List relayAddrs = j['relays'] ?? [];

    if (peerId == null || peerId.toString().isEmpty) {
      throw Exception('peerId missing');
    }

    final List<String> candidates = [
      ...addrs.map((e) => e.toString()),
      ...relayAddrs.map((e) => e.toString()),
    ];

    candidates.sort((a, b) {
      final aRelay = a.contains('/p2p-circuit/');
      final bRelay = b.contains('/p2p-circuit/');
      if (aRelay && !bRelay) return -1;
      if (!aRelay && bRelay) return 1;

      final aLocal =
          a.contains('127.0.0.1') || a.contains('0.0.0.0') || a.contains('::1');
      final bLocal =
          b.contains('127.0.0.1') || b.contains('0.0.0.0') || b.contains('::1');

      if (aLocal && !bLocal) return 1;
      if (!aLocal && bLocal) return -1;
      return 0;
    });

    // ✅ 1️⃣ ПЫТАЕМСЯ ПОДКЛЮЧИТЬСЯ НАПРЯМУЮ / ЧЕРЕЗ RELAY ИЗ QR
    for (final addr in candidates) {
      try {
        await connectToPeer(addr).timeout(perAddrTimeout);
        await Future.delayed(const Duration(milliseconds: 300));
        await announce().catchError((_) {});
        return true;
      } catch (_) {}
    }

    // ✅ 2️⃣ ЕСЛИ НЕ ПОЛУЧИЛОСЬ — ПРОСИМ СЕТЬ НАЙТИ RELAY
    try {
      final r = await http
          .post(
        Uri.parse('$httpBase/relay_request'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'target': peerId}),
      )
          .timeout(const Duration(seconds: 5));

      if (r.statusCode == 200) {
        final j = jsonDecode(r.body);
        final relayAddr = j['relay'];

        if (relayAddr != null && relayAddr.toString().isNotEmpty) {
          try {
            await connectToPeer(relayAddr.toString())
                .timeout(const Duration(seconds: 5));
            await Future.delayed(const Duration(milliseconds: 300));
            await announce().catchError((_) {});
            return true;
          } catch (_) {}
        }
      }
    } catch (_) {}

    // ❌ Всё перепробовали — не удалось
    return false;
  }

  Timer? _announceTimer;
  Timer? _reconnectTimer;
  Timer? _relayTimer;
  bool _autoEnabled = false;

  /// ✅ Включает автоживучесть сети
  Future<void> enableAutoNetwork() async {
    if (_autoEnabled) return;
    _autoEnabled = true;

    // 🔁 Переанонс
    _announceTimer?.cancel();
    _announceTimer = Timer.periodic(const Duration(minutes: 4), (_) async {
      try { await announce(); } catch (_) {}
    });

    // 🔁 Автопереподключение
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      try {
        final peers = await getKnownPeers();
        for (final p in peers) {
          try {
            await connectToPeer(p).timeout(const Duration(seconds: 5));
          } catch (_) {}
        }
      } catch (_) {}
    });

    // 🛜 Периодическая попытка стать relay
    _relayTimer?.cancel();
    _relayTimer = Timer.periodic(const Duration(minutes: 10), (_) async {
      try { await promoteToRelay(); } catch (_) {}
    });

    // стартовые триггеры
    try { await announce(); } catch (_) {}
    try { await promoteToRelay(); } catch (_) {}
  }

  /// ✅ Стать relay
  Future<void> promoteToRelay() async {
    try {
      await http.post(Uri.parse('$httpBase/relay/enable'))
          .timeout(const Duration(seconds: 3));
    } catch (_) {}
  }

  /// ❌ Выключить автосеть
  void disableAutoNetwork() {
    _announceTimer?.cancel();
    _reconnectTimer?.cancel();
    _relayTimer?.cancel();
    _autoEnabled = false;
  }

  Future<List<String>> getRelays() async {
    final r = await http
        .get(Uri.parse('$httpBase/relays'))
        .timeout(const Duration(seconds: 3));
    if (r.statusCode != 200) {
      throw Exception('relays error ${r.statusCode}');
    }
    final data = jsonDecode(r.body) as List<dynamic>;
    return data.map((e) => e.toString()).toList();
  }

  String? _extractPeerId(String addr) {
    if (addr.contains('/p2p/')) {
      final parts = addr.split('/p2p/');
      return parts.isNotEmpty ? parts.last.trim() : null;
    }
    if (addr.length > 10 && !addr.contains('/')) {
      return addr;
    }
    return null;
  }
}
