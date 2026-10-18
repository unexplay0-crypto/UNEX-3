import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import '../models/media_item.dart';
import 'm3u_parser.dart';

class PlaylistService {
  PlaylistService({http.Client? client, M3uParser parser = const M3uParser()})
      : _client = client ?? http.Client(), _parser = parser;

  final http.Client _client;
  final M3uParser _parser;

  Future<List<MediaItem>> fromUrl(String value) async {
    final uri = Uri.tryParse(value.trim());
    if (uri == null || !uri.hasScheme || (uri.scheme != 'http' && uri.scheme != 'https')) {
      throw const FormatException('Informe uma URL HTTP ou HTTPS válida para a playlist.');
    }
    final response = await _client.get(uri).timeout(const Duration(seconds: 25));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('O servidor respondeu com status ${response.statusCode}.');
    }
    return _parseBytes(response.bodyBytes);
  }

  Future<List<MediaItem>> fromFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['m3u', 'm3u8', 'txt'], withData: true);
    if (result == null || result.files.isEmpty) return <MediaItem>[];
    final bytes = result.files.single.bytes;
    if (bytes == null) throw Exception('Não foi possível ler o arquivo selecionado.');
    return _parseBytes(bytes);
  }

  List<MediaItem> fromText(String text) => _parser.parse(text);

  List<MediaItem> _parseBytes(List<int> bytes) {
    // UTF-8 with replacement for malformed bytes; many M3U lists use UTF-8.
    return _parser.parse(utf8.decode(bytes, allowMalformed: true));
  }
}
