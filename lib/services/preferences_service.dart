import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const _playlistKey = 'playlist_url';
  static const _favoriteKey = 'favorite_ids';

  Future<String?> getPlaylistUrl() async => (await SharedPreferences.getInstance()).getString(_playlistKey);
  Future<void> setPlaylistUrl(String value) async => (await SharedPreferences.getInstance()).setString(_playlistKey, value);
  Future<Set<String>> getFavorites() async => (await SharedPreferences.getInstance()).getStringList(_favoriteKey)?.toSet() ?? <String>{};
  Future<void> setFavorites(Set<String> values) async => (await SharedPreferences.getInstance()).setStringList(_favoriteKey, values.toList());
}
