import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
  ];

  /// Application title
  ///
  /// In en, this message translates to:
  /// **'CoTune'**
  String get appTitle;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @myMusic.
  ///
  /// In en, this message translates to:
  /// **'My Music'**
  String get myMusic;

  /// No description provided for @nothingPlaying.
  ///
  /// In en, this message translates to:
  /// **'Nothing playing'**
  String get nothingPlaying;

  /// No description provided for @playerNothingPlaying.
  ///
  /// In en, this message translates to:
  /// **'Nothing is playing'**
  String get playerNothingPlaying;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @scan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get scan;

  /// No description provided for @enterManually.
  ///
  /// In en, this message translates to:
  /// **'Enter manually'**
  String get enterManually;

  /// No description provided for @connectedHosts.
  ///
  /// In en, this message translates to:
  /// **'Connected hosts'**
  String get connectedHosts;

  /// No description provided for @noConnectedHosts.
  ///
  /// In en, this message translates to:
  /// **'No connected hosts'**
  String get noConnectedHosts;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// No description provided for @connectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to connect'**
  String get connectionFailed;

  /// No description provided for @connectionError.
  ///
  /// In en, this message translates to:
  /// **'Connection error'**
  String get connectionError;

  /// No description provided for @noPeerInfo.
  ///
  /// In en, this message translates to:
  /// **'No peer info'**
  String get noPeerInfo;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @russian.
  ///
  /// In en, this message translates to:
  /// **'Russian'**
  String get russian;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @systemTheme.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemTheme;

  /// No description provided for @darkTheme.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get darkTheme;

  /// No description provided for @lightTheme.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get lightTheme;

  /// No description provided for @searchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search tracks or artists'**
  String get searchPlaceholder;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get noResults;

  /// No description provided for @addMusic.
  ///
  /// In en, this message translates to:
  /// **'Add Music'**
  String get addMusic;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @artist.
  ///
  /// In en, this message translates to:
  /// **'Artist'**
  String get artist;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// No description provided for @peerInfoJson.
  ///
  /// In en, this message translates to:
  /// **'Peer info (JSON)'**
  String get peerInfoJson;

  /// No description provided for @copyAddress.
  ///
  /// In en, this message translates to:
  /// **'Copy address'**
  String get copyAddress;

  /// No description provided for @copyAddressTooltip.
  ///
  /// In en, this message translates to:
  /// **'Copy address'**
  String get copyAddressTooltip;

  /// No description provided for @searchFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get searchFilterAll;

  /// No description provided for @searchFilterTracks.
  ///
  /// In en, this message translates to:
  /// **'Tracks'**
  String get searchFilterTracks;

  /// No description provided for @searchFilterArtists.
  ///
  /// In en, this message translates to:
  /// **'Artists'**
  String get searchFilterArtists;

  /// No description provided for @searchSectionNetwork.
  ///
  /// In en, this message translates to:
  /// **'In network'**
  String get searchSectionNetwork;

  /// No description provided for @searchSectionLocal.
  ///
  /// In en, this message translates to:
  /// **'Local'**
  String get searchSectionLocal;

  /// No description provided for @searchRemoteAddedAndShared.
  ///
  /// In en, this message translates to:
  /// **'Track added to My Music, downloaded, and shared to network'**
  String get searchRemoteAddedAndShared;

  /// No description provided for @searchRemoteFetchFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to fetch track from network: {error}'**
  String searchRemoteFetchFailed(Object error);

  /// No description provided for @untitledTrack.
  ///
  /// In en, this message translates to:
  /// **'Untitled'**
  String get untitledTrack;

  /// No description provided for @unknownArtist.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknownArtist;

  /// No description provided for @myMusicFilterTracks.
  ///
  /// In en, this message translates to:
  /// **'Tracks'**
  String get myMusicFilterTracks;

  /// No description provided for @myMusicFilterArtists.
  ///
  /// In en, this message translates to:
  /// **'Artists'**
  String get myMusicFilterArtists;

  /// No description provided for @myMusicFilterPlaylists.
  ///
  /// In en, this message translates to:
  /// **'Playlists'**
  String get myMusicFilterPlaylists;

  /// No description provided for @myMusicFilterUnsigned.
  ///
  /// In en, this message translates to:
  /// **'Unsigned'**
  String get myMusicFilterUnsigned;

  /// No description provided for @myMusicNoLikedTracks.
  ///
  /// In en, this message translates to:
  /// **'No liked tracks yet'**
  String get myMusicNoLikedTracks;

  /// No description provided for @myMusicNoArtists.
  ///
  /// In en, this message translates to:
  /// **'No artists'**
  String get myMusicNoArtists;

  /// No description provided for @myMusicNoPlaylists.
  ///
  /// In en, this message translates to:
  /// **'No playlists yet'**
  String get myMusicNoPlaylists;

  /// No description provided for @myMusicNoUnsignedTracks.
  ///
  /// In en, this message translates to:
  /// **'No unsigned tracks'**
  String get myMusicNoUnsignedTracks;

  /// No description provided for @myMusicAddPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Add playlist'**
  String get myMusicAddPlaylist;

  /// No description provided for @myMusicAddPlaylistTitle.
  ///
  /// In en, this message translates to:
  /// **'Add playlist'**
  String get myMusicAddPlaylistTitle;

  /// No description provided for @myMusicPlaylistNameHint.
  ///
  /// In en, this message translates to:
  /// **'Playlist name'**
  String get myMusicPlaylistNameHint;

  /// No description provided for @myMusicCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get myMusicCreate;

  /// No description provided for @myMusicTracksCount.
  ///
  /// In en, this message translates to:
  /// **'{count} track(s)'**
  String myMusicTracksCount(Object count);

  /// No description provided for @profileQrScannerMobileOnly.
  ///
  /// In en, this message translates to:
  /// **'QR scanner is available only on mobile platforms'**
  String get profileQrScannerMobileOnly;

  /// No description provided for @profileNetworkStatus.
  ///
  /// In en, this message translates to:
  /// **'Network: peers={peers}, providers={providers}, rt={routing}, wan={wan}'**
  String profileNetworkStatus(
    Object peers,
    Object providers,
    Object routing,
    Object wan,
  );

  /// No description provided for @profileDiagMessage.
  ///
  /// In en, this message translates to:
  /// **'diag: {error}'**
  String profileDiagMessage(Object error);

  /// No description provided for @valueNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'n/a'**
  String get valueNotAvailable;

  /// No description provided for @valueOn.
  ///
  /// In en, this message translates to:
  /// **'on'**
  String get valueOn;

  /// No description provided for @valueOff.
  ///
  /// In en, this message translates to:
  /// **'off'**
  String get valueOff;

  /// No description provided for @trackPublishedToNetwork.
  ///
  /// In en, this message translates to:
  /// **'Published to network'**
  String get trackPublishedToNetwork;

  /// No description provided for @trackNotPublishedToNetwork.
  ///
  /// In en, this message translates to:
  /// **'Not published'**
  String get trackNotPublishedToNetwork;

  /// No description provided for @trackPublishedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Track published to P2P network'**
  String get trackPublishedSuccess;

  /// No description provided for @trackPublishError.
  ///
  /// In en, this message translates to:
  /// **'Track publish error: {error}'**
  String trackPublishError(Object error);

  /// No description provided for @trackMenuAddToPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Add to playlist'**
  String get trackMenuAddToPlaylist;

  /// No description provided for @trackMenuSaveToFiles.
  ///
  /// In en, this message translates to:
  /// **'Save to files'**
  String get trackMenuSaveToFiles;

  /// No description provided for @trackMenuGoToArtist.
  ///
  /// In en, this message translates to:
  /// **'Go to artist'**
  String get trackMenuGoToArtist;

  /// No description provided for @trackMenuManualTag.
  ///
  /// In en, this message translates to:
  /// **'Tag manually'**
  String get trackMenuManualTag;

  /// No description provided for @trackAddToPlaylistTitle.
  ///
  /// In en, this message translates to:
  /// **'Add to playlist'**
  String get trackAddToPlaylistTitle;

  /// No description provided for @trackAddToPlaylistConfirm.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get trackAddToPlaylistConfirm;

  /// No description provided for @trackAddedToPlaylists.
  ///
  /// In en, this message translates to:
  /// **'Track(s) added to playlists'**
  String get trackAddedToPlaylists;

  /// No description provided for @trackManualTagTitle.
  ///
  /// In en, this message translates to:
  /// **'Tag manually'**
  String get trackManualTagTitle;

  /// No description provided for @trackManualTagNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get trackManualTagNameLabel;

  /// No description provided for @trackManualTagArtistLabel.
  ///
  /// In en, this message translates to:
  /// **'Artist'**
  String get trackManualTagArtistLabel;

  /// No description provided for @trackManualTagSavedAndPublished.
  ///
  /// In en, this message translates to:
  /// **'Track metadata updated and published'**
  String get trackManualTagSavedAndPublished;

  /// No description provided for @trackManualTagSavePublishFailed.
  ///
  /// In en, this message translates to:
  /// **'Data updated, but publish failed: {error}'**
  String trackManualTagSavePublishFailed(Object error);

  /// No description provided for @trackSourceFileNotFound.
  ///
  /// In en, this message translates to:
  /// **'Source file not found'**
  String get trackSourceFileNotFound;

  /// No description provided for @trackSavedLocally.
  ///
  /// In en, this message translates to:
  /// **'Saved locally: {path}'**
  String trackSavedLocally(Object path);

  /// No description provided for @trackSaveError.
  ///
  /// In en, this message translates to:
  /// **'Save error: {error}'**
  String trackSaveError(Object error);

  /// No description provided for @folderDefaultPlaylistTitle.
  ///
  /// In en, this message translates to:
  /// **'Playlist'**
  String get folderDefaultPlaylistTitle;

  /// No description provided for @folderRenamePlaylistTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename playlist'**
  String get folderRenamePlaylistTitle;

  /// No description provided for @folderDeletePlaylistTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete playlist?'**
  String get folderDeletePlaylistTitle;

  /// No description provided for @folderDeletePlaylistMessage.
  ///
  /// In en, this message translates to:
  /// **'Playlist \"{name}\" will be deleted.'**
  String folderDeletePlaylistMessage(Object name);

  /// No description provided for @folderDeletePlaylistConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get folderDeletePlaylistConfirm;

  /// No description provided for @folderNoLikedTracks.
  ///
  /// In en, this message translates to:
  /// **'No liked tracks'**
  String get folderNoLikedTracks;

  /// No description provided for @folderTracksAdded.
  ///
  /// In en, this message translates to:
  /// **'Tracks added'**
  String get folderTracksAdded;

  /// No description provided for @addTracksNoFilesSelected.
  ///
  /// In en, this message translates to:
  /// **'No files selected'**
  String get addTracksNoFilesSelected;

  /// No description provided for @addTracksPick.
  ///
  /// In en, this message translates to:
  /// **'Pick'**
  String get addTracksPick;

  /// No description provided for @addTracksImport.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get addTracksImport;

  /// No description provided for @addTracksImporting.
  ///
  /// In en, this message translates to:
  /// **'Importing...'**
  String get addTracksImporting;

  /// No description provided for @addTracksSomeFilesNotImported.
  ///
  /// In en, this message translates to:
  /// **'Some files were not imported ({count})'**
  String addTracksSomeFilesNotImported(Object count);

  /// No description provided for @qrShareFallbackCopied.
  ///
  /// In en, this message translates to:
  /// **'Share failed - peer info copied to clipboard'**
  String get qrShareFallbackCopied;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
