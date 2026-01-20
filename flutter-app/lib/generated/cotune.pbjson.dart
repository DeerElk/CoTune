// This is a generated file - do not edit.
//
// Generated from cotune.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use statusRequestDescriptor instead')
const StatusRequest$json = {
  '1': 'StatusRequest',
};

/// Descriptor for `StatusRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List statusRequestDescriptor =
    $convert.base64Decode('Cg1TdGF0dXNSZXF1ZXN0');

@$core.Deprecated('Use peerInfoRequestDescriptor instead')
const PeerInfoRequest$json = {
  '1': 'PeerInfoRequest',
  '2': [
    {'1': 'format', '3': 1, '4': 1, '5': 9, '10': 'format'},
  ],
};

/// Descriptor for `PeerInfoRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List peerInfoRequestDescriptor = $convert
    .base64Decode('Cg9QZWVySW5mb1JlcXVlc3QSFgoGZm9ybWF0GAEgASgJUgZmb3JtYXQ=');

@$core.Deprecated('Use connectRequestDescriptor instead')
const ConnectRequest$json = {
  '1': 'ConnectRequest',
  '2': [
    {'1': 'multiaddr', '3': 1, '4': 1, '5': 9, '9': 0, '10': 'multiaddr'},
    {
      '1': 'peer_info',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.cotune.PeerInfo',
      '9': 0,
      '10': 'peerInfo'
    },
  ],
  '8': [
    {'1': 'target'},
  ],
};

/// Descriptor for `ConnectRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List connectRequestDescriptor = $convert.base64Decode(
    'Cg5Db25uZWN0UmVxdWVzdBIeCgltdWx0aWFkZHIYASABKAlIAFIJbXVsdGlhZGRyEi8KCXBlZX'
    'JfaW5mbxgCIAEoCzIQLmNvdHVuZS5QZWVySW5mb0gAUghwZWVySW5mb0IICgZ0YXJnZXQ=');

@$core.Deprecated('Use searchRequestDescriptor instead')
const SearchRequest$json = {
  '1': 'SearchRequest',
  '2': [
    {'1': 'query', '3': 1, '4': 1, '5': 9, '10': 'query'},
    {'1': 'max_results', '3': 2, '4': 1, '5': 5, '10': 'maxResults'},
  ],
};

/// Descriptor for `SearchRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List searchRequestDescriptor = $convert.base64Decode(
    'Cg1TZWFyY2hSZXF1ZXN0EhQKBXF1ZXJ5GAEgASgJUgVxdWVyeRIfCgttYXhfcmVzdWx0cxgCIA'
    'EoBVIKbWF4UmVzdWx0cw==');

@$core.Deprecated('Use searchProvidersRequestDescriptor instead')
const SearchProvidersRequest$json = {
  '1': 'SearchProvidersRequest',
  '2': [
    {'1': 'ctid', '3': 1, '4': 1, '5': 9, '10': 'ctid'},
    {'1': 'max', '3': 2, '4': 1, '5': 5, '10': 'max'},
  ],
};

/// Descriptor for `SearchProvidersRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List searchProvidersRequestDescriptor =
    $convert.base64Decode(
        'ChZTZWFyY2hQcm92aWRlcnNSZXF1ZXN0EhIKBGN0aWQYASABKAlSBGN0aWQSEAoDbWF4GAIgAS'
        'gFUgNtYXg=');

@$core.Deprecated('Use fetchRequestDescriptor instead')
const FetchRequest$json = {
  '1': 'FetchRequest',
  '2': [
    {'1': 'ctid', '3': 1, '4': 1, '5': 9, '10': 'ctid'},
    {'1': 'peer_id', '3': 2, '4': 1, '5': 9, '10': 'peerId'},
    {'1': 'output_path', '3': 3, '4': 1, '5': 9, '10': 'outputPath'},
  ],
};

/// Descriptor for `FetchRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fetchRequestDescriptor = $convert.base64Decode(
    'CgxGZXRjaFJlcXVlc3QSEgoEY3RpZBgBIAEoCVIEY3RpZBIXCgdwZWVyX2lkGAIgASgJUgZwZW'
    'VySWQSHwoLb3V0cHV0X3BhdGgYAyABKAlSCm91dHB1dFBhdGg=');

@$core.Deprecated('Use shareRequestDescriptor instead')
const ShareRequest$json = {
  '1': 'ShareRequest',
  '2': [
    {'1': 'track_id', '3': 1, '4': 1, '5': 9, '10': 'trackId'},
    {'1': 'path', '3': 2, '4': 1, '5': 9, '10': 'path'},
    {'1': 'title', '3': 3, '4': 1, '5': 9, '10': 'title'},
    {'1': 'artist', '3': 4, '4': 1, '5': 9, '10': 'artist'},
    {'1': 'recognized', '3': 5, '4': 1, '5': 8, '10': 'recognized'},
    {'1': 'checksum', '3': 6, '4': 1, '5': 9, '10': 'checksum'},
  ],
};

/// Descriptor for `ShareRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List shareRequestDescriptor = $convert.base64Decode(
    'CgxTaGFyZVJlcXVlc3QSGQoIdHJhY2tfaWQYASABKAlSB3RyYWNrSWQSEgoEcGF0aBgCIAEoCV'
    'IEcGF0aBIUCgV0aXRsZRgDIAEoCVIFdGl0bGUSFgoGYXJ0aXN0GAQgASgJUgZhcnRpc3QSHgoK'
    'cmVjb2duaXplZBgFIAEoCFIKcmVjb2duaXplZBIaCghjaGVja3N1bRgGIAEoCVIIY2hlY2tzdW'
    '0=');

@$core.Deprecated('Use announceRequestDescriptor instead')
const AnnounceRequest$json = {
  '1': 'AnnounceRequest',
};

/// Descriptor for `AnnounceRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List announceRequestDescriptor =
    $convert.base64Decode('Cg9Bbm5vdW5jZVJlcXVlc3Q=');

@$core.Deprecated('Use relaysRequestDescriptor instead')
const RelaysRequest$json = {
  '1': 'RelaysRequest',
};

/// Descriptor for `RelaysRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List relaysRequestDescriptor =
    $convert.base64Decode('Cg1SZWxheXNSZXF1ZXN0');

@$core.Deprecated('Use relayEnableRequestDescriptor instead')
const RelayEnableRequest$json = {
  '1': 'RelayEnableRequest',
};

/// Descriptor for `RelayEnableRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List relayEnableRequestDescriptor =
    $convert.base64Decode('ChJSZWxheUVuYWJsZVJlcXVlc3Q=');

@$core.Deprecated('Use relayRequestRequestDescriptor instead')
const RelayRequestRequest$json = {
  '1': 'RelayRequestRequest',
  '2': [
    {'1': 'peer_id', '3': 1, '4': 1, '5': 9, '10': 'peerId'},
  ],
};

/// Descriptor for `RelayRequestRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List relayRequestRequestDescriptor =
    $convert.base64Decode(
        'ChNSZWxheVJlcXVlc3RSZXF1ZXN0EhcKB3BlZXJfaWQYASABKAlSBnBlZXJJZA==');

@$core.Deprecated('Use statusResponseDescriptor instead')
const StatusResponse$json = {
  '1': 'StatusResponse',
  '2': [
    {'1': 'running', '3': 1, '4': 1, '5': 8, '10': 'running'},
    {'1': 'version', '3': 2, '4': 1, '5': 9, '10': 'version'},
  ],
};

/// Descriptor for `StatusResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List statusResponseDescriptor = $convert.base64Decode(
    'Cg5TdGF0dXNSZXNwb25zZRIYCgdydW5uaW5nGAEgASgIUgdydW5uaW5nEhgKB3ZlcnNpb24YAi'
    'ABKAlSB3ZlcnNpb24=');

@$core.Deprecated('Use peerInfoDescriptor instead')
const PeerInfo$json = {
  '1': 'PeerInfo',
  '2': [
    {'1': 'peer_id', '3': 1, '4': 1, '5': 9, '10': 'peerId'},
    {'1': 'addresses', '3': 2, '4': 3, '5': 9, '10': 'addresses'},
  ],
};

/// Descriptor for `PeerInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List peerInfoDescriptor = $convert.base64Decode(
    'CghQZWVySW5mbxIXCgdwZWVyX2lkGAEgASgJUgZwZWVySWQSHAoJYWRkcmVzc2VzGAIgAygJUg'
    'lhZGRyZXNzZXM=');

@$core.Deprecated('Use peerInfoResponseDescriptor instead')
const PeerInfoResponse$json = {
  '1': 'PeerInfoResponse',
  '2': [
    {
      '1': 'peer_info',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.cotune.PeerInfo',
      '10': 'peerInfo'
    },
  ],
};

/// Descriptor for `PeerInfoResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List peerInfoResponseDescriptor = $convert.base64Decode(
    'ChBQZWVySW5mb1Jlc3BvbnNlEi0KCXBlZXJfaW5mbxgBIAEoCzIQLmNvdHVuZS5QZWVySW5mb1'
    'IIcGVlckluZm8=');

@$core.Deprecated('Use knownPeersResponseDescriptor instead')
const KnownPeersResponse$json = {
  '1': 'KnownPeersResponse',
  '2': [
    {
      '1': 'peers',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.cotune.PeerInfo',
      '10': 'peers'
    },
  ],
};

/// Descriptor for `KnownPeersResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List knownPeersResponseDescriptor = $convert.base64Decode(
    'ChJLbm93blBlZXJzUmVzcG9uc2USJgoFcGVlcnMYASADKAsyEC5jb3R1bmUuUGVlckluZm9SBX'
    'BlZXJz');

@$core.Deprecated('Use connectResponseDescriptor instead')
const ConnectResponse$json = {
  '1': 'ConnectResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'error', '3': 2, '4': 1, '5': 9, '10': 'error'},
  ],
};

/// Descriptor for `ConnectResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List connectResponseDescriptor = $convert.base64Decode(
    'Cg9Db25uZWN0UmVzcG9uc2USGAoHc3VjY2VzcxgBIAEoCFIHc3VjY2VzcxIUCgVlcnJvchgCIA'
    'EoCVIFZXJyb3I=');

@$core.Deprecated('Use searchResultDescriptor instead')
const SearchResult$json = {
  '1': 'SearchResult',
  '2': [
    {'1': 'ctid', '3': 1, '4': 1, '5': 9, '10': 'ctid'},
    {'1': 'title', '3': 2, '4': 1, '5': 9, '10': 'title'},
    {'1': 'artist', '3': 3, '4': 1, '5': 9, '10': 'artist'},
    {'1': 'recognized', '3': 4, '4': 1, '5': 8, '10': 'recognized'},
    {'1': 'providers', '3': 5, '4': 3, '5': 9, '10': 'providers'},
  ],
};

/// Descriptor for `SearchResult`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List searchResultDescriptor = $convert.base64Decode(
    'CgxTZWFyY2hSZXN1bHQSEgoEY3RpZBgBIAEoCVIEY3RpZBIUCgV0aXRsZRgCIAEoCVIFdGl0bG'
    'USFgoGYXJ0aXN0GAMgASgJUgZhcnRpc3QSHgoKcmVjb2duaXplZBgEIAEoCFIKcmVjb2duaXpl'
    'ZBIcCglwcm92aWRlcnMYBSADKAlSCXByb3ZpZGVycw==');

@$core.Deprecated('Use searchResponseDescriptor instead')
const SearchResponse$json = {
  '1': 'SearchResponse',
  '2': [
    {
      '1': 'results',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.cotune.SearchResult',
      '10': 'results'
    },
  ],
};

/// Descriptor for `SearchResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List searchResponseDescriptor = $convert.base64Decode(
    'Cg5TZWFyY2hSZXNwb25zZRIuCgdyZXN1bHRzGAEgAygLMhQuY290dW5lLlNlYXJjaFJlc3VsdF'
    'IHcmVzdWx0cw==');

@$core.Deprecated('Use searchProvidersResponseDescriptor instead')
const SearchProvidersResponse$json = {
  '1': 'SearchProvidersResponse',
  '2': [
    {'1': 'provider_ids', '3': 1, '4': 3, '5': 9, '10': 'providerIds'},
  ],
};

/// Descriptor for `SearchProvidersResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List searchProvidersResponseDescriptor =
    $convert.base64Decode(
        'ChdTZWFyY2hQcm92aWRlcnNSZXNwb25zZRIhCgxwcm92aWRlcl9pZHMYASADKAlSC3Byb3ZpZG'
        'VySWRz');

@$core.Deprecated('Use fetchResponseDescriptor instead')
const FetchResponse$json = {
  '1': 'FetchResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'path', '3': 2, '4': 1, '5': 9, '10': 'path'},
    {'1': 'error', '3': 3, '4': 1, '5': 9, '10': 'error'},
  ],
};

/// Descriptor for `FetchResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fetchResponseDescriptor = $convert.base64Decode(
    'Cg1GZXRjaFJlc3BvbnNlEhgKB3N1Y2Nlc3MYASABKAhSB3N1Y2Nlc3MSEgoEcGF0aBgCIAEoCV'
    'IEcGF0aBIUCgVlcnJvchgDIAEoCVIFZXJyb3I=');

@$core.Deprecated('Use shareResponseDescriptor instead')
const ShareResponse$json = {
  '1': 'ShareResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'path', '3': 2, '4': 1, '5': 9, '10': 'path'},
    {'1': 'error', '3': 3, '4': 1, '5': 9, '10': 'error'},
  ],
};

/// Descriptor for `ShareResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List shareResponseDescriptor = $convert.base64Decode(
    'Cg1TaGFyZVJlc3BvbnNlEhgKB3N1Y2Nlc3MYASABKAhSB3N1Y2Nlc3MSEgoEcGF0aBgCIAEoCV'
    'IEcGF0aBIUCgVlcnJvchgDIAEoCVIFZXJyb3I=');

@$core.Deprecated('Use announceResponseDescriptor instead')
const AnnounceResponse$json = {
  '1': 'AnnounceResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
  ],
};

/// Descriptor for `AnnounceResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List announceResponseDescriptor = $convert.base64Decode(
    'ChBBbm5vdW5jZVJlc3BvbnNlEhgKB3N1Y2Nlc3MYASABKAhSB3N1Y2Nlc3M=');

@$core.Deprecated('Use relaysResponseDescriptor instead')
const RelaysResponse$json = {
  '1': 'RelaysResponse',
  '2': [
    {'1': 'relay_addresses', '3': 1, '4': 3, '5': 9, '10': 'relayAddresses'},
  ],
};

/// Descriptor for `RelaysResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List relaysResponseDescriptor = $convert.base64Decode(
    'Cg5SZWxheXNSZXNwb25zZRInCg9yZWxheV9hZGRyZXNzZXMYASADKAlSDnJlbGF5QWRkcmVzc2'
    'Vz');

@$core.Deprecated('Use relayEnableResponseDescriptor instead')
const RelayEnableResponse$json = {
  '1': 'RelayEnableResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
  ],
};

/// Descriptor for `RelayEnableResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List relayEnableResponseDescriptor =
    $convert.base64Decode(
        'ChNSZWxheUVuYWJsZVJlc3BvbnNlEhgKB3N1Y2Nlc3MYASABKAhSB3N1Y2Nlc3M=');

@$core.Deprecated('Use relayRequestResponseDescriptor instead')
const RelayRequestResponse$json = {
  '1': 'RelayRequestResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'error', '3': 2, '4': 1, '5': 9, '10': 'error'},
  ],
};

/// Descriptor for `RelayRequestResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List relayRequestResponseDescriptor = $convert.base64Decode(
    'ChRSZWxheVJlcXVlc3RSZXNwb25zZRIYCgdzdWNjZXNzGAEgASgIUgdzdWNjZXNzEhQKBWVycm'
    '9yGAIgASgJUgVlcnJvcg==');
