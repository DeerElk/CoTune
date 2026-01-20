// This is a generated file - do not edit.
//
// Generated from cotune.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'package:protobuf/protobuf.dart' as $pb;

import 'cotune.pb.dart' as $0;

export 'cotune.pb.dart';

/// Main IPC service
@$pb.GrpcServiceName('cotune.CotuneService')
class CotuneServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  CotuneServiceClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.StatusResponse> status(
    $0.StatusRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$status, request, options: options);
  }

  $grpc.ResponseFuture<$0.PeerInfoResponse> peerInfo(
    $0.PeerInfoRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$peerInfo, request, options: options);
  }

  $grpc.ResponseFuture<$0.KnownPeersResponse> knownPeers(
    $0.StatusRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$knownPeers, request, options: options);
  }

  $grpc.ResponseFuture<$0.ConnectResponse> connect(
    $0.ConnectRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$connect, request, options: options);
  }

  $grpc.ResponseFuture<$0.SearchResponse> search(
    $0.SearchRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$search, request, options: options);
  }

  $grpc.ResponseFuture<$0.SearchProvidersResponse> searchProviders(
    $0.SearchProvidersRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$searchProviders, request, options: options);
  }

  $grpc.ResponseFuture<$0.FetchResponse> fetch(
    $0.FetchRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$fetch, request, options: options);
  }

  $grpc.ResponseFuture<$0.ShareResponse> share(
    $0.ShareRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$share, request, options: options);
  }

  $grpc.ResponseFuture<$0.AnnounceResponse> announce(
    $0.AnnounceRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$announce, request, options: options);
  }

  $grpc.ResponseFuture<$0.RelaysResponse> relays(
    $0.RelaysRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$relays, request, options: options);
  }

  $grpc.ResponseFuture<$0.RelayEnableResponse> relayEnable(
    $0.RelayEnableRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$relayEnable, request, options: options);
  }

  $grpc.ResponseFuture<$0.RelayRequestResponse> relayRequest(
    $0.RelayRequestRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$relayRequest, request, options: options);
  }

  // method descriptors

  static final _$status =
      $grpc.ClientMethod<$0.StatusRequest, $0.StatusResponse>(
          '/cotune.CotuneService/Status',
          ($0.StatusRequest value) => value.writeToBuffer(),
          $0.StatusResponse.fromBuffer);
  static final _$peerInfo =
      $grpc.ClientMethod<$0.PeerInfoRequest, $0.PeerInfoResponse>(
          '/cotune.CotuneService/PeerInfo',
          ($0.PeerInfoRequest value) => value.writeToBuffer(),
          $0.PeerInfoResponse.fromBuffer);
  static final _$knownPeers =
      $grpc.ClientMethod<$0.StatusRequest, $0.KnownPeersResponse>(
          '/cotune.CotuneService/KnownPeers',
          ($0.StatusRequest value) => value.writeToBuffer(),
          $0.KnownPeersResponse.fromBuffer);
  static final _$connect =
      $grpc.ClientMethod<$0.ConnectRequest, $0.ConnectResponse>(
          '/cotune.CotuneService/Connect',
          ($0.ConnectRequest value) => value.writeToBuffer(),
          $0.ConnectResponse.fromBuffer);
  static final _$search =
      $grpc.ClientMethod<$0.SearchRequest, $0.SearchResponse>(
          '/cotune.CotuneService/Search',
          ($0.SearchRequest value) => value.writeToBuffer(),
          $0.SearchResponse.fromBuffer);
  static final _$searchProviders =
      $grpc.ClientMethod<$0.SearchProvidersRequest, $0.SearchProvidersResponse>(
          '/cotune.CotuneService/SearchProviders',
          ($0.SearchProvidersRequest value) => value.writeToBuffer(),
          $0.SearchProvidersResponse.fromBuffer);
  static final _$fetch = $grpc.ClientMethod<$0.FetchRequest, $0.FetchResponse>(
      '/cotune.CotuneService/Fetch',
      ($0.FetchRequest value) => value.writeToBuffer(),
      $0.FetchResponse.fromBuffer);
  static final _$share = $grpc.ClientMethod<$0.ShareRequest, $0.ShareResponse>(
      '/cotune.CotuneService/Share',
      ($0.ShareRequest value) => value.writeToBuffer(),
      $0.ShareResponse.fromBuffer);
  static final _$announce =
      $grpc.ClientMethod<$0.AnnounceRequest, $0.AnnounceResponse>(
          '/cotune.CotuneService/Announce',
          ($0.AnnounceRequest value) => value.writeToBuffer(),
          $0.AnnounceResponse.fromBuffer);
  static final _$relays =
      $grpc.ClientMethod<$0.RelaysRequest, $0.RelaysResponse>(
          '/cotune.CotuneService/Relays',
          ($0.RelaysRequest value) => value.writeToBuffer(),
          $0.RelaysResponse.fromBuffer);
  static final _$relayEnable =
      $grpc.ClientMethod<$0.RelayEnableRequest, $0.RelayEnableResponse>(
          '/cotune.CotuneService/RelayEnable',
          ($0.RelayEnableRequest value) => value.writeToBuffer(),
          $0.RelayEnableResponse.fromBuffer);
  static final _$relayRequest =
      $grpc.ClientMethod<$0.RelayRequestRequest, $0.RelayRequestResponse>(
          '/cotune.CotuneService/RelayRequest',
          ($0.RelayRequestRequest value) => value.writeToBuffer(),
          $0.RelayRequestResponse.fromBuffer);
}

@$pb.GrpcServiceName('cotune.CotuneService')
abstract class CotuneServiceBase extends $grpc.Service {
  $core.String get $name => 'cotune.CotuneService';

  CotuneServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.StatusRequest, $0.StatusResponse>(
        'Status',
        status_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.StatusRequest.fromBuffer(value),
        ($0.StatusResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.PeerInfoRequest, $0.PeerInfoResponse>(
        'PeerInfo',
        peerInfo_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.PeerInfoRequest.fromBuffer(value),
        ($0.PeerInfoResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.StatusRequest, $0.KnownPeersResponse>(
        'KnownPeers',
        knownPeers_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.StatusRequest.fromBuffer(value),
        ($0.KnownPeersResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ConnectRequest, $0.ConnectResponse>(
        'Connect',
        connect_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.ConnectRequest.fromBuffer(value),
        ($0.ConnectResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.SearchRequest, $0.SearchResponse>(
        'Search',
        search_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.SearchRequest.fromBuffer(value),
        ($0.SearchResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.SearchProvidersRequest,
            $0.SearchProvidersResponse>(
        'SearchProviders',
        searchProviders_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.SearchProvidersRequest.fromBuffer(value),
        ($0.SearchProvidersResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.FetchRequest, $0.FetchResponse>(
        'Fetch',
        fetch_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.FetchRequest.fromBuffer(value),
        ($0.FetchResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ShareRequest, $0.ShareResponse>(
        'Share',
        share_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.ShareRequest.fromBuffer(value),
        ($0.ShareResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.AnnounceRequest, $0.AnnounceResponse>(
        'Announce',
        announce_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.AnnounceRequest.fromBuffer(value),
        ($0.AnnounceResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.RelaysRequest, $0.RelaysResponse>(
        'Relays',
        relays_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.RelaysRequest.fromBuffer(value),
        ($0.RelaysResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.RelayEnableRequest, $0.RelayEnableResponse>(
            'RelayEnable',
            relayEnable_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.RelayEnableRequest.fromBuffer(value),
            ($0.RelayEnableResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.RelayRequestRequest, $0.RelayRequestResponse>(
            'RelayRequest',
            relayRequest_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.RelayRequestRequest.fromBuffer(value),
            ($0.RelayRequestResponse value) => value.writeToBuffer()));
  }

  $async.Future<$0.StatusResponse> status_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.StatusRequest> $request) async {
    return status($call, await $request);
  }

  $async.Future<$0.StatusResponse> status(
      $grpc.ServiceCall call, $0.StatusRequest request);

  $async.Future<$0.PeerInfoResponse> peerInfo_Pre($grpc.ServiceCall $call,
      $async.Future<$0.PeerInfoRequest> $request) async {
    return peerInfo($call, await $request);
  }

  $async.Future<$0.PeerInfoResponse> peerInfo(
      $grpc.ServiceCall call, $0.PeerInfoRequest request);

  $async.Future<$0.KnownPeersResponse> knownPeers_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.StatusRequest> $request) async {
    return knownPeers($call, await $request);
  }

  $async.Future<$0.KnownPeersResponse> knownPeers(
      $grpc.ServiceCall call, $0.StatusRequest request);

  $async.Future<$0.ConnectResponse> connect_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ConnectRequest> $request) async {
    return connect($call, await $request);
  }

  $async.Future<$0.ConnectResponse> connect(
      $grpc.ServiceCall call, $0.ConnectRequest request);

  $async.Future<$0.SearchResponse> search_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.SearchRequest> $request) async {
    return search($call, await $request);
  }

  $async.Future<$0.SearchResponse> search(
      $grpc.ServiceCall call, $0.SearchRequest request);

  $async.Future<$0.SearchProvidersResponse> searchProviders_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.SearchProvidersRequest> $request) async {
    return searchProviders($call, await $request);
  }

  $async.Future<$0.SearchProvidersResponse> searchProviders(
      $grpc.ServiceCall call, $0.SearchProvidersRequest request);

  $async.Future<$0.FetchResponse> fetch_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.FetchRequest> $request) async {
    return fetch($call, await $request);
  }

  $async.Future<$0.FetchResponse> fetch(
      $grpc.ServiceCall call, $0.FetchRequest request);

  $async.Future<$0.ShareResponse> share_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.ShareRequest> $request) async {
    return share($call, await $request);
  }

  $async.Future<$0.ShareResponse> share(
      $grpc.ServiceCall call, $0.ShareRequest request);

  $async.Future<$0.AnnounceResponse> announce_Pre($grpc.ServiceCall $call,
      $async.Future<$0.AnnounceRequest> $request) async {
    return announce($call, await $request);
  }

  $async.Future<$0.AnnounceResponse> announce(
      $grpc.ServiceCall call, $0.AnnounceRequest request);

  $async.Future<$0.RelaysResponse> relays_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.RelaysRequest> $request) async {
    return relays($call, await $request);
  }

  $async.Future<$0.RelaysResponse> relays(
      $grpc.ServiceCall call, $0.RelaysRequest request);

  $async.Future<$0.RelayEnableResponse> relayEnable_Pre($grpc.ServiceCall $call,
      $async.Future<$0.RelayEnableRequest> $request) async {
    return relayEnable($call, await $request);
  }

  $async.Future<$0.RelayEnableResponse> relayEnable(
      $grpc.ServiceCall call, $0.RelayEnableRequest request);

  $async.Future<$0.RelayRequestResponse> relayRequest_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.RelayRequestRequest> $request) async {
    return relayRequest($call, await $request);
  }

  $async.Future<$0.RelayRequestResponse> relayRequest(
      $grpc.ServiceCall call, $0.RelayRequestRequest request);
}
