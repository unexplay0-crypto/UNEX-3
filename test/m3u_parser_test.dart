import 'package:flutter_test/flutter_test.dart';
import 'package:unex_play/services/m3u_parser.dart';

void main() {
  const parser = M3uParser();

  test('parses M3U Plus attributes regardless of their order', () {
    const input = '''#EXTM3U
#EXTINF:-1 group-title="Notícias e Atualidades" tvg-logo="https://example.com/logo.png" tvg-id="news.br",Canal Notícias
https://example.com/live/news.m3u8
''';
    final result = parser.parse(input);
    expect(result, hasLength(1));
    expect(result.single.name, 'Canal Notícias');
    expect(result.single.group, 'Notícias e Atualidades');
    expect(result.single.logo, 'https://example.com/logo.png');
    expect(result.single.tvgId, 'news.br');
    expect(result.single.url, 'https://example.com/live/news.m3u8');
  });

  test('ignores comments, blank lines and malformed addresses without failing', () {
    const input = '''#EXTM3U

# comentário
#EXTINF:-1,Canal válido
https://example.com/canal.ts
#EXTINF:-1,Endereço inválido
não-é-uma-url
''';
    final result = parser.parse(input);
    expect(result, hasLength(1));
    expect(result.single.name, 'Canal válido');
  });

  test('uses host as fallback when EXTINF has no display name', () {
    final result = parser.parse('#EXTM3U\nhttps://example.com/live.mp4\n');
    expect(result.single.name, 'example.com');
  });
}
