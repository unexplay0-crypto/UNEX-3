import '../models/media_item.dart';

/// Parser tolerante a playlists M3U/M3U Plus. Não executa nem acessa URLs.
class M3uParser {
  const M3uParser();

  List<MediaItem> parse(String input) {
    final lines = input.replaceAll('\r\n', '\n').replaceAll('\r', '\n').split('\n');
    final items = <MediaItem>[];
    String? pendingInfo;

    for (final raw in lines) {
      final line = raw.trim();
      if (line.isEmpty || line == '#EXTM3U') continue;
      if (line.startsWith('#EXTINF:')) {
        pendingInfo = line;
        continue;
      }
      if (line.startsWith('#')) continue;

      final uri = Uri.tryParse(line);
      if (uri == null || !uri.hasScheme || !(uri.scheme == 'http' || uri.scheme == 'https' || uri.scheme == 'rtsp' || uri.scheme == 'rtmp' || uri.scheme == 'udp')) {
        pendingInfo = null;
        continue;
      }

      final info = pendingInfo ?? '';
      final comma = info.indexOf(',');
      final displayName = comma >= 0 && comma < info.length - 1
          ? info.substring(comma + 1).trim()
          : _attribute(info, 'tvg-name') ?? uri.host;
      final name = displayName.isEmpty ? uri.host : displayName;
      items.add(MediaItem(
        name: name,
        url: line,
        logo: _attribute(info, 'tvg-logo'),
        group: _attribute(info, 'group-title'),
        tvgId: _attribute(info, 'tvg-id'),
        tvgName: _attribute(info, 'tvg-name'),
      ));
      pendingInfo = null;
    }
    return items;
  }

  String? _attribute(String line, String key) {
    // Supports quoted values with spaces and unquoted values.
    final escaped = RegExp.escape(key);
    final match = RegExp('(?:^|\\s)$escaped="([^"]*)"|(?:^|\\s)$escaped=([^\\s,]*)', caseSensitive: false).firstMatch(line);
    final value = (match?.group(1) ?? match?.group(2))?.trim();
    return value == null || value.isEmpty ? null : value;
  }
}
