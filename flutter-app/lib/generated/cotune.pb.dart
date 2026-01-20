// This is a generated file - do not edit.
//
// Generated from cotune.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

/// Request messages
class StatusRequest extends $pb.GeneratedMessage {
  factory StatusRequest() => create();

  StatusRequest._();

  factory StatusRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory StatusRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StatusRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cotune'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StatusRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StatusRequest copyWith(void Function(StatusRequest) updates) =>
      super.copyWith((message) => updates(message as StatusRequest))
          as StatusRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StatusRequest create() => StatusRequest._();
  @$core.override
  StatusRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static StatusRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StatusRequest>(create);
  static StatusRequest? _defaultInstance;
}

class PeerInfoRequest extends $pb.GeneratedMessage {
  factory PeerInfoRequest({
    $core.String? format,
  }) {
    final result = create();
    if (format != null) result.format = format;
    return result;
  }

  PeerInfoRequest._();

  factory PeerInfoRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PeerInfoRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PeerInfoRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cotune'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'format')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PeerInfoRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PeerInfoRequest copyWith(void Function(PeerInfoRequest) updates) =>
      super.copyWith((message) => updates(message as PeerInfoRequest))
          as PeerInfoRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PeerInfoRequest create() => PeerInfoRequest._();
  @$core.override
  PeerInfoRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static PeerInfoRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PeerInfoRequest>(create);
  static PeerInfoRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get format => $_getSZ(0);
  @$pb.TagNumber(1)
  set format($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasFormat() => $_has(0);
  @$pb.TagNumber(1)
  void clearFormat() => $_clearField(1);
}

enum ConnectRequest_Target { multiaddr, peerInfo, notSet }

class ConnectRequest extends $pb.GeneratedMessage {
  factory ConnectRequest({
    $core.String? multiaddr,
    PeerInfo? peerInfo,
  }) {
    final result = create();
    if (multiaddr != null) result.multiaddr = multiaddr;
    if (peerInfo != null) result.peerInfo = peerInfo;
    return result;
  }

  ConnectRequest._();

  factory ConnectRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ConnectRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, ConnectRequest_Target>
      _ConnectRequest_TargetByTag = {
    1: ConnectRequest_Target.multiaddr,
    2: ConnectRequest_Target.peerInfo,
    0: ConnectRequest_Target.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ConnectRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cotune'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOS(1, _omitFieldNames ? '' : 'multiaddr')
    ..aOM<PeerInfo>(2, _omitFieldNames ? '' : 'peerInfo',
        subBuilder: PeerInfo.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ConnectRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ConnectRequest copyWith(void Function(ConnectRequest) updates) =>
      super.copyWith((message) => updates(message as ConnectRequest))
          as ConnectRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ConnectRequest create() => ConnectRequest._();
  @$core.override
  ConnectRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ConnectRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ConnectRequest>(create);
  static ConnectRequest? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  ConnectRequest_Target whichTarget() =>
      _ConnectRequest_TargetByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearTarget() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $core.String get multiaddr => $_getSZ(0);
  @$pb.TagNumber(1)
  set multiaddr($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMultiaddr() => $_has(0);
  @$pb.TagNumber(1)
  void clearMultiaddr() => $_clearField(1);

  @$pb.TagNumber(2)
  PeerInfo get peerInfo => $_getN(1);
  @$pb.TagNumber(2)
  set peerInfo(PeerInfo value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasPeerInfo() => $_has(1);
  @$pb.TagNumber(2)
  void clearPeerInfo() => $_clearField(2);
  @$pb.TagNumber(2)
  PeerInfo ensurePeerInfo() => $_ensure(1);
}

class SearchRequest extends $pb.GeneratedMessage {
  factory SearchRequest({
    $core.String? query,
    $core.int? maxResults,
  }) {
    final result = create();
    if (query != null) result.query = query;
    if (maxResults != null) result.maxResults = maxResults;
    return result;
  }

  SearchRequest._();

  factory SearchRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SearchRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SearchRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cotune'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'query')
    ..aI(2, _omitFieldNames ? '' : 'maxResults')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SearchRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SearchRequest copyWith(void Function(SearchRequest) updates) =>
      super.copyWith((message) => updates(message as SearchRequest))
          as SearchRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SearchRequest create() => SearchRequest._();
  @$core.override
  SearchRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SearchRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SearchRequest>(create);
  static SearchRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get query => $_getSZ(0);
  @$pb.TagNumber(1)
  set query($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasQuery() => $_has(0);
  @$pb.TagNumber(1)
  void clearQuery() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get maxResults => $_getIZ(1);
  @$pb.TagNumber(2)
  set maxResults($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMaxResults() => $_has(1);
  @$pb.TagNumber(2)
  void clearMaxResults() => $_clearField(2);
}

class SearchProvidersRequest extends $pb.GeneratedMessage {
  factory SearchProvidersRequest({
    $core.String? ctid,
    $core.int? max,
  }) {
    final result = create();
    if (ctid != null) result.ctid = ctid;
    if (max != null) result.max = max;
    return result;
  }

  SearchProvidersRequest._();

  factory SearchProvidersRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SearchProvidersRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SearchProvidersRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cotune'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'ctid')
    ..aI(2, _omitFieldNames ? '' : 'max')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SearchProvidersRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SearchProvidersRequest copyWith(
          void Function(SearchProvidersRequest) updates) =>
      super.copyWith((message) => updates(message as SearchProvidersRequest))
          as SearchProvidersRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SearchProvidersRequest create() => SearchProvidersRequest._();
  @$core.override
  SearchProvidersRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SearchProvidersRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SearchProvidersRequest>(create);
  static SearchProvidersRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get ctid => $_getSZ(0);
  @$pb.TagNumber(1)
  set ctid($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCtid() => $_has(0);
  @$pb.TagNumber(1)
  void clearCtid() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get max => $_getIZ(1);
  @$pb.TagNumber(2)
  set max($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMax() => $_has(1);
  @$pb.TagNumber(2)
  void clearMax() => $_clearField(2);
}

class FetchRequest extends $pb.GeneratedMessage {
  factory FetchRequest({
    $core.String? ctid,
    $core.String? peerId,
    $core.String? outputPath,
  }) {
    final result = create();
    if (ctid != null) result.ctid = ctid;
    if (peerId != null) result.peerId = peerId;
    if (outputPath != null) result.outputPath = outputPath;
    return result;
  }

  FetchRequest._();

  factory FetchRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FetchRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FetchRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cotune'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'ctid')
    ..aOS(2, _omitFieldNames ? '' : 'peerId')
    ..aOS(3, _omitFieldNames ? '' : 'outputPath')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FetchRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FetchRequest copyWith(void Function(FetchRequest) updates) =>
      super.copyWith((message) => updates(message as FetchRequest))
          as FetchRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FetchRequest create() => FetchRequest._();
  @$core.override
  FetchRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static FetchRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FetchRequest>(create);
  static FetchRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get ctid => $_getSZ(0);
  @$pb.TagNumber(1)
  set ctid($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCtid() => $_has(0);
  @$pb.TagNumber(1)
  void clearCtid() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get peerId => $_getSZ(1);
  @$pb.TagNumber(2)
  set peerId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPeerId() => $_has(1);
  @$pb.TagNumber(2)
  void clearPeerId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get outputPath => $_getSZ(2);
  @$pb.TagNumber(3)
  set outputPath($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasOutputPath() => $_has(2);
  @$pb.TagNumber(3)
  void clearOutputPath() => $_clearField(3);
}

class ShareRequest extends $pb.GeneratedMessage {
  factory ShareRequest({
    $core.String? trackId,
    $core.String? path,
    $core.String? title,
    $core.String? artist,
    $core.bool? recognized,
    $core.String? checksum,
  }) {
    final result = create();
    if (trackId != null) result.trackId = trackId;
    if (path != null) result.path = path;
    if (title != null) result.title = title;
    if (artist != null) result.artist = artist;
    if (recognized != null) result.recognized = recognized;
    if (checksum != null) result.checksum = checksum;
    return result;
  }

  ShareRequest._();

  factory ShareRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ShareRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ShareRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cotune'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'trackId')
    ..aOS(2, _omitFieldNames ? '' : 'path')
    ..aOS(3, _omitFieldNames ? '' : 'title')
    ..aOS(4, _omitFieldNames ? '' : 'artist')
    ..aOB(5, _omitFieldNames ? '' : 'recognized')
    ..aOS(6, _omitFieldNames ? '' : 'checksum')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ShareRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ShareRequest copyWith(void Function(ShareRequest) updates) =>
      super.copyWith((message) => updates(message as ShareRequest))
          as ShareRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ShareRequest create() => ShareRequest._();
  @$core.override
  ShareRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ShareRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ShareRequest>(create);
  static ShareRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get trackId => $_getSZ(0);
  @$pb.TagNumber(1)
  set trackId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTrackId() => $_has(0);
  @$pb.TagNumber(1)
  void clearTrackId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get path => $_getSZ(1);
  @$pb.TagNumber(2)
  set path($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPath() => $_has(1);
  @$pb.TagNumber(2)
  void clearPath() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get title => $_getSZ(2);
  @$pb.TagNumber(3)
  set title($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTitle() => $_has(2);
  @$pb.TagNumber(3)
  void clearTitle() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get artist => $_getSZ(3);
  @$pb.TagNumber(4)
  set artist($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasArtist() => $_has(3);
  @$pb.TagNumber(4)
  void clearArtist() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get recognized => $_getBF(4);
  @$pb.TagNumber(5)
  set recognized($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasRecognized() => $_has(4);
  @$pb.TagNumber(5)
  void clearRecognized() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get checksum => $_getSZ(5);
  @$pb.TagNumber(6)
  set checksum($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasChecksum() => $_has(5);
  @$pb.TagNumber(6)
  void clearChecksum() => $_clearField(6);
}

class AnnounceRequest extends $pb.GeneratedMessage {
  factory AnnounceRequest() => create();

  AnnounceRequest._();

  factory AnnounceRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AnnounceRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AnnounceRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cotune'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AnnounceRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AnnounceRequest copyWith(void Function(AnnounceRequest) updates) =>
      super.copyWith((message) => updates(message as AnnounceRequest))
          as AnnounceRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AnnounceRequest create() => AnnounceRequest._();
  @$core.override
  AnnounceRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AnnounceRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AnnounceRequest>(create);
  static AnnounceRequest? _defaultInstance;
}

class RelaysRequest extends $pb.GeneratedMessage {
  factory RelaysRequest() => create();

  RelaysRequest._();

  factory RelaysRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RelaysRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RelaysRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cotune'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RelaysRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RelaysRequest copyWith(void Function(RelaysRequest) updates) =>
      super.copyWith((message) => updates(message as RelaysRequest))
          as RelaysRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RelaysRequest create() => RelaysRequest._();
  @$core.override
  RelaysRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RelaysRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RelaysRequest>(create);
  static RelaysRequest? _defaultInstance;
}

class RelayEnableRequest extends $pb.GeneratedMessage {
  factory RelayEnableRequest() => create();

  RelayEnableRequest._();

  factory RelayEnableRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RelayEnableRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RelayEnableRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cotune'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RelayEnableRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RelayEnableRequest copyWith(void Function(RelayEnableRequest) updates) =>
      super.copyWith((message) => updates(message as RelayEnableRequest))
          as RelayEnableRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RelayEnableRequest create() => RelayEnableRequest._();
  @$core.override
  RelayEnableRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RelayEnableRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RelayEnableRequest>(create);
  static RelayEnableRequest? _defaultInstance;
}

class RelayRequestRequest extends $pb.GeneratedMessage {
  factory RelayRequestRequest({
    $core.String? peerId,
  }) {
    final result = create();
    if (peerId != null) result.peerId = peerId;
    return result;
  }

  RelayRequestRequest._();

  factory RelayRequestRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RelayRequestRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RelayRequestRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cotune'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'peerId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RelayRequestRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RelayRequestRequest copyWith(void Function(RelayRequestRequest) updates) =>
      super.copyWith((message) => updates(message as RelayRequestRequest))
          as RelayRequestRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RelayRequestRequest create() => RelayRequestRequest._();
  @$core.override
  RelayRequestRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RelayRequestRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RelayRequestRequest>(create);
  static RelayRequestRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get peerId => $_getSZ(0);
  @$pb.TagNumber(1)
  set peerId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPeerId() => $_has(0);
  @$pb.TagNumber(1)
  void clearPeerId() => $_clearField(1);
}

/// Response messages
class StatusResponse extends $pb.GeneratedMessage {
  factory StatusResponse({
    $core.bool? running,
    $core.String? version,
  }) {
    final result = create();
    if (running != null) result.running = running;
    if (version != null) result.version = version;
    return result;
  }

  StatusResponse._();

  factory StatusResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory StatusResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StatusResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cotune'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'running')
    ..aOS(2, _omitFieldNames ? '' : 'version')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StatusResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StatusResponse copyWith(void Function(StatusResponse) updates) =>
      super.copyWith((message) => updates(message as StatusResponse))
          as StatusResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StatusResponse create() => StatusResponse._();
  @$core.override
  StatusResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static StatusResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StatusResponse>(create);
  static StatusResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get running => $_getBF(0);
  @$pb.TagNumber(1)
  set running($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRunning() => $_has(0);
  @$pb.TagNumber(1)
  void clearRunning() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get version => $_getSZ(1);
  @$pb.TagNumber(2)
  set version($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasVersion() => $_has(1);
  @$pb.TagNumber(2)
  void clearVersion() => $_clearField(2);
}

class PeerInfo extends $pb.GeneratedMessage {
  factory PeerInfo({
    $core.String? peerId,
    $core.Iterable<$core.String>? addresses,
  }) {
    final result = create();
    if (peerId != null) result.peerId = peerId;
    if (addresses != null) result.addresses.addAll(addresses);
    return result;
  }

  PeerInfo._();

  factory PeerInfo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PeerInfo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PeerInfo',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cotune'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'peerId')
    ..pPS(2, _omitFieldNames ? '' : 'addresses')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PeerInfo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PeerInfo copyWith(void Function(PeerInfo) updates) =>
      super.copyWith((message) => updates(message as PeerInfo)) as PeerInfo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PeerInfo create() => PeerInfo._();
  @$core.override
  PeerInfo createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static PeerInfo getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PeerInfo>(create);
  static PeerInfo? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get peerId => $_getSZ(0);
  @$pb.TagNumber(1)
  set peerId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPeerId() => $_has(0);
  @$pb.TagNumber(1)
  void clearPeerId() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<$core.String> get addresses => $_getList(1);
}

class PeerInfoResponse extends $pb.GeneratedMessage {
  factory PeerInfoResponse({
    PeerInfo? peerInfo,
  }) {
    final result = create();
    if (peerInfo != null) result.peerInfo = peerInfo;
    return result;
  }

  PeerInfoResponse._();

  factory PeerInfoResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PeerInfoResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PeerInfoResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cotune'),
      createEmptyInstance: create)
    ..aOM<PeerInfo>(1, _omitFieldNames ? '' : 'peerInfo',
        subBuilder: PeerInfo.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PeerInfoResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PeerInfoResponse copyWith(void Function(PeerInfoResponse) updates) =>
      super.copyWith((message) => updates(message as PeerInfoResponse))
          as PeerInfoResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PeerInfoResponse create() => PeerInfoResponse._();
  @$core.override
  PeerInfoResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static PeerInfoResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PeerInfoResponse>(create);
  static PeerInfoResponse? _defaultInstance;

  @$pb.TagNumber(1)
  PeerInfo get peerInfo => $_getN(0);
  @$pb.TagNumber(1)
  set peerInfo(PeerInfo value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasPeerInfo() => $_has(0);
  @$pb.TagNumber(1)
  void clearPeerInfo() => $_clearField(1);
  @$pb.TagNumber(1)
  PeerInfo ensurePeerInfo() => $_ensure(0);
}

class KnownPeersResponse extends $pb.GeneratedMessage {
  factory KnownPeersResponse({
    $core.Iterable<PeerInfo>? peers,
  }) {
    final result = create();
    if (peers != null) result.peers.addAll(peers);
    return result;
  }

  KnownPeersResponse._();

  factory KnownPeersResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory KnownPeersResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'KnownPeersResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cotune'),
      createEmptyInstance: create)
    ..pPM<PeerInfo>(1, _omitFieldNames ? '' : 'peers',
        subBuilder: PeerInfo.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  KnownPeersResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  KnownPeersResponse copyWith(void Function(KnownPeersResponse) updates) =>
      super.copyWith((message) => updates(message as KnownPeersResponse))
          as KnownPeersResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static KnownPeersResponse create() => KnownPeersResponse._();
  @$core.override
  KnownPeersResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static KnownPeersResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<KnownPeersResponse>(create);
  static KnownPeersResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<PeerInfo> get peers => $_getList(0);
}

class ConnectResponse extends $pb.GeneratedMessage {
  factory ConnectResponse({
    $core.bool? success,
    $core.String? error,
  }) {
    final result = create();
    if (success != null) result.success = success;
    if (error != null) result.error = error;
    return result;
  }

  ConnectResponse._();

  factory ConnectResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ConnectResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ConnectResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cotune'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'error')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ConnectResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ConnectResponse copyWith(void Function(ConnectResponse) updates) =>
      super.copyWith((message) => updates(message as ConnectResponse))
          as ConnectResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ConnectResponse create() => ConnectResponse._();
  @$core.override
  ConnectResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ConnectResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ConnectResponse>(create);
  static ConnectResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get error => $_getSZ(1);
  @$pb.TagNumber(2)
  set error($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => $_clearField(2);
}

class SearchResult extends $pb.GeneratedMessage {
  factory SearchResult({
    $core.String? ctid,
    $core.String? title,
    $core.String? artist,
    $core.bool? recognized,
    $core.Iterable<$core.String>? providers,
  }) {
    final result = create();
    if (ctid != null) result.ctid = ctid;
    if (title != null) result.title = title;
    if (artist != null) result.artist = artist;
    if (recognized != null) result.recognized = recognized;
    if (providers != null) result.providers.addAll(providers);
    return result;
  }

  SearchResult._();

  factory SearchResult.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SearchResult.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SearchResult',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cotune'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'ctid')
    ..aOS(2, _omitFieldNames ? '' : 'title')
    ..aOS(3, _omitFieldNames ? '' : 'artist')
    ..aOB(4, _omitFieldNames ? '' : 'recognized')
    ..pPS(5, _omitFieldNames ? '' : 'providers')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SearchResult clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SearchResult copyWith(void Function(SearchResult) updates) =>
      super.copyWith((message) => updates(message as SearchResult))
          as SearchResult;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SearchResult create() => SearchResult._();
  @$core.override
  SearchResult createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SearchResult getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SearchResult>(create);
  static SearchResult? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get ctid => $_getSZ(0);
  @$pb.TagNumber(1)
  set ctid($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCtid() => $_has(0);
  @$pb.TagNumber(1)
  void clearCtid() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get title => $_getSZ(1);
  @$pb.TagNumber(2)
  set title($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTitle() => $_has(1);
  @$pb.TagNumber(2)
  void clearTitle() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get artist => $_getSZ(2);
  @$pb.TagNumber(3)
  set artist($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasArtist() => $_has(2);
  @$pb.TagNumber(3)
  void clearArtist() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get recognized => $_getBF(3);
  @$pb.TagNumber(4)
  set recognized($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasRecognized() => $_has(3);
  @$pb.TagNumber(4)
  void clearRecognized() => $_clearField(4);

  @$pb.TagNumber(5)
  $pb.PbList<$core.String> get providers => $_getList(4);
}

class SearchResponse extends $pb.GeneratedMessage {
  factory SearchResponse({
    $core.Iterable<SearchResult>? results,
  }) {
    final result = create();
    if (results != null) result.results.addAll(results);
    return result;
  }

  SearchResponse._();

  factory SearchResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SearchResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SearchResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cotune'),
      createEmptyInstance: create)
    ..pPM<SearchResult>(1, _omitFieldNames ? '' : 'results',
        subBuilder: SearchResult.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SearchResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SearchResponse copyWith(void Function(SearchResponse) updates) =>
      super.copyWith((message) => updates(message as SearchResponse))
          as SearchResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SearchResponse create() => SearchResponse._();
  @$core.override
  SearchResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SearchResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SearchResponse>(create);
  static SearchResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<SearchResult> get results => $_getList(0);
}

class SearchProvidersResponse extends $pb.GeneratedMessage {
  factory SearchProvidersResponse({
    $core.Iterable<$core.String>? providerIds,
  }) {
    final result = create();
    if (providerIds != null) result.providerIds.addAll(providerIds);
    return result;
  }

  SearchProvidersResponse._();

  factory SearchProvidersResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SearchProvidersResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SearchProvidersResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cotune'),
      createEmptyInstance: create)
    ..pPS(1, _omitFieldNames ? '' : 'providerIds')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SearchProvidersResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SearchProvidersResponse copyWith(
          void Function(SearchProvidersResponse) updates) =>
      super.copyWith((message) => updates(message as SearchProvidersResponse))
          as SearchProvidersResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SearchProvidersResponse create() => SearchProvidersResponse._();
  @$core.override
  SearchProvidersResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SearchProvidersResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SearchProvidersResponse>(create);
  static SearchProvidersResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get providerIds => $_getList(0);
}

class FetchResponse extends $pb.GeneratedMessage {
  factory FetchResponse({
    $core.bool? success,
    $core.String? path,
    $core.String? error,
  }) {
    final result = create();
    if (success != null) result.success = success;
    if (path != null) result.path = path;
    if (error != null) result.error = error;
    return result;
  }

  FetchResponse._();

  factory FetchResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FetchResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FetchResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cotune'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'path')
    ..aOS(3, _omitFieldNames ? '' : 'error')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FetchResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FetchResponse copyWith(void Function(FetchResponse) updates) =>
      super.copyWith((message) => updates(message as FetchResponse))
          as FetchResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FetchResponse create() => FetchResponse._();
  @$core.override
  FetchResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static FetchResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FetchResponse>(create);
  static FetchResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get path => $_getSZ(1);
  @$pb.TagNumber(2)
  set path($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPath() => $_has(1);
  @$pb.TagNumber(2)
  void clearPath() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get error => $_getSZ(2);
  @$pb.TagNumber(3)
  set error($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasError() => $_has(2);
  @$pb.TagNumber(3)
  void clearError() => $_clearField(3);
}

class ShareResponse extends $pb.GeneratedMessage {
  factory ShareResponse({
    $core.bool? success,
    $core.String? path,
    $core.String? error,
  }) {
    final result = create();
    if (success != null) result.success = success;
    if (path != null) result.path = path;
    if (error != null) result.error = error;
    return result;
  }

  ShareResponse._();

  factory ShareResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ShareResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ShareResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cotune'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'path')
    ..aOS(3, _omitFieldNames ? '' : 'error')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ShareResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ShareResponse copyWith(void Function(ShareResponse) updates) =>
      super.copyWith((message) => updates(message as ShareResponse))
          as ShareResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ShareResponse create() => ShareResponse._();
  @$core.override
  ShareResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ShareResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ShareResponse>(create);
  static ShareResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get path => $_getSZ(1);
  @$pb.TagNumber(2)
  set path($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPath() => $_has(1);
  @$pb.TagNumber(2)
  void clearPath() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get error => $_getSZ(2);
  @$pb.TagNumber(3)
  set error($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasError() => $_has(2);
  @$pb.TagNumber(3)
  void clearError() => $_clearField(3);
}

class AnnounceResponse extends $pb.GeneratedMessage {
  factory AnnounceResponse({
    $core.bool? success,
  }) {
    final result = create();
    if (success != null) result.success = success;
    return result;
  }

  AnnounceResponse._();

  factory AnnounceResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AnnounceResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AnnounceResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cotune'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AnnounceResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AnnounceResponse copyWith(void Function(AnnounceResponse) updates) =>
      super.copyWith((message) => updates(message as AnnounceResponse))
          as AnnounceResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AnnounceResponse create() => AnnounceResponse._();
  @$core.override
  AnnounceResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AnnounceResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AnnounceResponse>(create);
  static AnnounceResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);
}

class RelaysResponse extends $pb.GeneratedMessage {
  factory RelaysResponse({
    $core.Iterable<$core.String>? relayAddresses,
  }) {
    final result = create();
    if (relayAddresses != null) result.relayAddresses.addAll(relayAddresses);
    return result;
  }

  RelaysResponse._();

  factory RelaysResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RelaysResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RelaysResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cotune'),
      createEmptyInstance: create)
    ..pPS(1, _omitFieldNames ? '' : 'relayAddresses')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RelaysResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RelaysResponse copyWith(void Function(RelaysResponse) updates) =>
      super.copyWith((message) => updates(message as RelaysResponse))
          as RelaysResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RelaysResponse create() => RelaysResponse._();
  @$core.override
  RelaysResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RelaysResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RelaysResponse>(create);
  static RelaysResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get relayAddresses => $_getList(0);
}

class RelayEnableResponse extends $pb.GeneratedMessage {
  factory RelayEnableResponse({
    $core.bool? success,
  }) {
    final result = create();
    if (success != null) result.success = success;
    return result;
  }

  RelayEnableResponse._();

  factory RelayEnableResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RelayEnableResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RelayEnableResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cotune'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RelayEnableResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RelayEnableResponse copyWith(void Function(RelayEnableResponse) updates) =>
      super.copyWith((message) => updates(message as RelayEnableResponse))
          as RelayEnableResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RelayEnableResponse create() => RelayEnableResponse._();
  @$core.override
  RelayEnableResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RelayEnableResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RelayEnableResponse>(create);
  static RelayEnableResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);
}

class RelayRequestResponse extends $pb.GeneratedMessage {
  factory RelayRequestResponse({
    $core.bool? success,
    $core.String? error,
  }) {
    final result = create();
    if (success != null) result.success = success;
    if (error != null) result.error = error;
    return result;
  }

  RelayRequestResponse._();

  factory RelayRequestResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RelayRequestResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RelayRequestResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cotune'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'error')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RelayRequestResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RelayRequestResponse copyWith(void Function(RelayRequestResponse) updates) =>
      super.copyWith((message) => updates(message as RelayRequestResponse))
          as RelayRequestResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RelayRequestResponse create() => RelayRequestResponse._();
  @$core.override
  RelayRequestResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RelayRequestResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RelayRequestResponse>(create);
  static RelayRequestResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get error => $_getSZ(1);
  @$pb.TagNumber(2)
  set error($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => $_clearField(2);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
