// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'CoTune';

  @override
  String get profile => 'Profile';

  @override
  String get search => 'Search';

  @override
  String get myMusic => 'My Music';

  @override
  String get nothingPlaying => 'Nothing playing';

  @override
  String get playerNothingPlaying => 'Nothing is playing';

  @override
  String get copy => 'Copy';

  @override
  String get share => 'Share';

  @override
  String get scan => 'Scan';

  @override
  String get enterManually => 'Enter manually';

  @override
  String get connectedHosts => 'Connected hosts';

  @override
  String get noConnectedHosts => 'No connected hosts';

  @override
  String get connected => 'Connected';

  @override
  String get connectionFailed => 'Failed to connect';

  @override
  String get connectionError => 'Connection error';

  @override
  String get noPeerInfo => 'No peer info';

  @override
  String get copied => 'Copied';

  @override
  String get theme => 'Theme';

  @override
  String get language => 'Language';

  @override
  String get russian => 'Russian';

  @override
  String get english => 'English';

  @override
  String get systemTheme => 'System';

  @override
  String get darkTheme => 'Dark';

  @override
  String get lightTheme => 'Light';

  @override
  String get searchPlaceholder => 'Search tracks or artists';

  @override
  String get noResults => 'No results';

  @override
  String get addMusic => 'Add Music';

  @override
  String get title => 'Title';

  @override
  String get artist => 'Artist';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get connect => 'Connect';

  @override
  String get peerInfoJson => 'Peer info (JSON)';

  @override
  String get copyAddress => 'Copy address';

  @override
  String get copyAddressTooltip => 'Copy address';

  @override
  String get searchFilterAll => 'All';

  @override
  String get searchFilterTracks => 'Tracks';

  @override
  String get searchFilterArtists => 'Artists';

  @override
  String get searchSectionNetwork => 'In network';

  @override
  String get searchSectionLocal => 'Local';

  @override
  String get searchRemoteAddedAndShared =>
      'Track added to My Music, downloaded, and shared to network';

  @override
  String searchRemoteFetchFailed(Object error) {
    return 'Failed to fetch track from network: $error';
  }

  @override
  String get untitledTrack => 'Untitled';

  @override
  String get unknownArtist => 'Unknown';

  @override
  String get myMusicFilterTracks => 'Tracks';

  @override
  String get myMusicFilterArtists => 'Artists';

  @override
  String get myMusicFilterPlaylists => 'Playlists';

  @override
  String get myMusicFilterUnsigned => 'Unsigned';

  @override
  String get myMusicNoLikedTracks => 'No liked tracks yet';

  @override
  String get myMusicNoArtists => 'No artists';

  @override
  String get myMusicNoPlaylists => 'No playlists yet';

  @override
  String get myMusicNoUnsignedTracks => 'No unsigned tracks';

  @override
  String get myMusicAddPlaylist => 'Add playlist';

  @override
  String get myMusicAddPlaylistTitle => 'Add playlist';

  @override
  String get myMusicPlaylistNameHint => 'Playlist name';

  @override
  String get myMusicCreate => 'Create';

  @override
  String myMusicTracksCount(Object count) {
    return '$count track(s)';
  }

  @override
  String get profileQrScannerMobileOnly =>
      'QR scanner is available only on mobile platforms';

  @override
  String profileNetworkStatus(
    Object peers,
    Object providers,
    Object routing,
    Object wan,
  ) {
    return 'Network: peers=$peers, providers=$providers, rt=$routing, wan=$wan';
  }

  @override
  String profileDiagMessage(Object error) {
    return 'diag: $error';
  }

  @override
  String get valueNotAvailable => 'n/a';

  @override
  String get valueOn => 'on';

  @override
  String get valueOff => 'off';

  @override
  String get trackPublishedToNetwork => 'Published to network';

  @override
  String get trackNotPublishedToNetwork => 'Not published';

  @override
  String get trackPublishedSuccess => 'Track published to P2P network';

  @override
  String trackPublishError(Object error) {
    return 'Track publish error: $error';
  }

  @override
  String get trackMenuAddToPlaylist => 'Add to playlist';

  @override
  String get trackMenuSaveToFiles => 'Save to files';

  @override
  String get trackMenuGoToArtist => 'Go to artist';

  @override
  String get trackMenuManualTag => 'Tag manually';

  @override
  String get trackAddToPlaylistTitle => 'Add to playlist';

  @override
  String get trackAddToPlaylistConfirm => 'Add';

  @override
  String get trackAddedToPlaylists => 'Track(s) added to playlists';

  @override
  String get trackManualTagTitle => 'Tag manually';

  @override
  String get trackManualTagNameLabel => 'Title';

  @override
  String get trackManualTagArtistLabel => 'Artist';

  @override
  String get trackManualTagSavedAndPublished =>
      'Track metadata updated and published';

  @override
  String trackManualTagSavePublishFailed(Object error) {
    return 'Data updated, but publish failed: $error';
  }

  @override
  String get trackSourceFileNotFound => 'Source file not found';

  @override
  String trackSavedLocally(Object path) {
    return 'Saved locally: $path';
  }

  @override
  String trackSaveError(Object error) {
    return 'Save error: $error';
  }

  @override
  String get folderDefaultPlaylistTitle => 'Playlist';

  @override
  String get folderRenamePlaylistTitle => 'Rename playlist';

  @override
  String get folderDeletePlaylistTitle => 'Delete playlist?';

  @override
  String folderDeletePlaylistMessage(Object name) {
    return 'Playlist \"$name\" will be deleted.';
  }

  @override
  String get folderDeletePlaylistConfirm => 'Delete';

  @override
  String get folderNoLikedTracks => 'No liked tracks';

  @override
  String get folderTracksAdded => 'Tracks added';

  @override
  String get addTracksNoFilesSelected => 'No files selected';

  @override
  String get addTracksPick => 'Pick';

  @override
  String get addTracksImport => 'Import';

  @override
  String get addTracksImporting => 'Importing...';

  @override
  String addTracksSomeFilesNotImported(Object count) {
    return 'Some files were not imported ($count)';
  }

  @override
  String get qrShareFallbackCopied =>
      'Share failed - peer info copied to clipboard';
}
