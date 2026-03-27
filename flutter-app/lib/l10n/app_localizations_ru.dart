// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'CoTune';

  @override
  String get profile => 'Профиль';

  @override
  String get search => 'Поиск';

  @override
  String get myMusic => 'Моя музыка';

  @override
  String get nothingPlaying => 'Ничего не играет';

  @override
  String get playerNothingPlaying => 'Ничего не играет';

  @override
  String get copy => 'Копировать';

  @override
  String get share => 'Поделиться';

  @override
  String get scan => 'Сканировать';

  @override
  String get enterManually => 'Ввести вручную';

  @override
  String get connectedHosts => 'Подключённые хосты';

  @override
  String get noConnectedHosts => 'Нет подключённых хостов';

  @override
  String get connected => 'Подключено';

  @override
  String get connectionFailed => 'Не удалось подключиться';

  @override
  String get connectionError => 'Ошибка подключения';

  @override
  String get noPeerInfo => 'Нет peer info';

  @override
  String get copied => 'Скопировано';

  @override
  String get theme => 'Тема';

  @override
  String get language => 'Язык';

  @override
  String get russian => 'Русский';

  @override
  String get english => 'Английский';

  @override
  String get systemTheme => 'Системная';

  @override
  String get darkTheme => 'Тёмная';

  @override
  String get lightTheme => 'Светлая';

  @override
  String get searchPlaceholder => 'Поиск треков или исполнителей';

  @override
  String get noResults => 'Нет результатов';

  @override
  String get addMusic => 'Добавить музыку';

  @override
  String get title => 'Название';

  @override
  String get artist => 'Исполнитель';

  @override
  String get save => 'Сохранить';

  @override
  String get cancel => 'Отмена';

  @override
  String get connect => 'Подключить';

  @override
  String get peerInfoJson => 'Данные узла (JSON)';

  @override
  String get copyAddress => 'Скопировать адрес';

  @override
  String get copyAddressTooltip => 'Скопировать адрес';

  @override
  String get searchFilterAll => 'Всё';

  @override
  String get searchFilterTracks => 'Треки';

  @override
  String get searchFilterArtists => 'Исполнители';

  @override
  String get searchSectionNetwork => 'В сети';

  @override
  String get searchSectionLocal => 'Локальные';

  @override
  String get searchRemoteAddedAndShared =>
      'Трек добавлен в мою музыку, скачан и опубликован в сети';

  @override
  String searchRemoteFetchFailed(Object error) {
    return 'Не удалось получить трек из сети: $error';
  }

  @override
  String get untitledTrack => 'Без названия';

  @override
  String get unknownArtist => 'Неизвестный';

  @override
  String get myMusicFilterTracks => 'Треки';

  @override
  String get myMusicFilterArtists => 'Исполнители';

  @override
  String get myMusicFilterPlaylists => 'Плейлисты';

  @override
  String get myMusicFilterUnsigned => 'Не подписаны';

  @override
  String get myMusicNoLikedTracks => 'Понравившихся треков пока нет';

  @override
  String get myMusicNoArtists => 'Нет исполнителей';

  @override
  String get myMusicNoPlaylists => 'Плейлистов пока нет';

  @override
  String get myMusicNoUnsignedTracks => 'Нет неподписанных треков';

  @override
  String get myMusicAddPlaylist => 'Добавить плейлист';

  @override
  String get myMusicAddPlaylistTitle => 'Добавить плейлист';

  @override
  String get myMusicPlaylistNameHint => 'Название плейлиста';

  @override
  String get myMusicCreate => 'Создать';

  @override
  String myMusicTracksCount(Object count) {
    return '$count трек(ов)';
  }

  @override
  String get profileQrScannerMobileOnly =>
      'QR-сканер доступен только на мобильных платформах';

  @override
  String profileNetworkStatus(
    Object peers,
    Object providers,
    Object routing,
    Object wan,
  ) {
    return 'Сеть: peers=$peers, providers=$providers, rt=$routing, wan=$wan';
  }

  @override
  String profileDiagMessage(Object error) {
    return 'диаг: $error';
  }

  @override
  String get valueNotAvailable => 'н/д';

  @override
  String get valueOn => 'вкл';

  @override
  String get valueOff => 'выкл';

  @override
  String get trackPublishedToNetwork => 'Опубликован в сети';

  @override
  String get trackNotPublishedToNetwork => 'Не опубликован';

  @override
  String get trackPublishedSuccess => 'Трек опубликован в P2P сети';

  @override
  String trackPublishError(Object error) {
    return 'Ошибка публикации трека: $error';
  }

  @override
  String get trackMenuAddToPlaylist => 'Добавить в плейлист';

  @override
  String get trackMenuSaveToFiles => 'Сохранить в файлы';

  @override
  String get trackMenuGoToArtist => 'Перейти к артисту';

  @override
  String get trackMenuManualTag => 'Подписать вручную';

  @override
  String get trackAddToPlaylistTitle => 'Добавить в плейлист';

  @override
  String get trackAddToPlaylistConfirm => 'Добавить';

  @override
  String get trackAddedToPlaylists => 'Трек(и) добавлены в плейлисты';

  @override
  String get trackManualTagTitle => 'Подписать вручную';

  @override
  String get trackManualTagNameLabel => 'Название';

  @override
  String get trackManualTagArtistLabel => 'Исполнитель';

  @override
  String get trackManualTagSavedAndPublished =>
      'Данные трека обновлены и опубликованы';

  @override
  String trackManualTagSavePublishFailed(Object error) {
    return 'Данные обновлены, но публикация не удалась: $error';
  }

  @override
  String get trackSourceFileNotFound => 'Исходный файл не найден';

  @override
  String trackSavedLocally(Object path) {
    return 'Сохранено локально: $path';
  }

  @override
  String trackSaveError(Object error) {
    return 'Ошибка при сохранении: $error';
  }

  @override
  String get folderDefaultPlaylistTitle => 'Плейлист';

  @override
  String get folderRenamePlaylistTitle => 'Переименовать плейлист';

  @override
  String get folderDeletePlaylistTitle => 'Удалить плейлист?';

  @override
  String folderDeletePlaylistMessage(Object name) {
    return 'Плейлист \"$name\" будет удалён.';
  }

  @override
  String get folderDeletePlaylistConfirm => 'Удалить';

  @override
  String get folderNoLikedTracks => 'Нет понравившихся треков';

  @override
  String get folderTracksAdded => 'Треки добавлены';

  @override
  String get addTracksNoFilesSelected => 'Файлы не выбраны';

  @override
  String get addTracksPick => 'Выбрать';

  @override
  String get addTracksImport => 'Импорт';

  @override
  String get addTracksImporting => 'Импорт...';

  @override
  String addTracksSomeFilesNotImported(Object count) {
    return 'Некоторые файлы не импортированы ($count)';
  }

  @override
  String get qrShareFallbackCopied =>
      'Не удалось поделиться - peer info скопирован в буфер';
}
