import 'package:flutter/material.dart';
import '../models/media_item.dart';
import '../services/playlist_service.dart';
import '../services/preferences_service.dart';
import 'player_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _playlistService = PlaylistService();
  final _preferences = PreferencesService();
  final _urlController = TextEditingController();
  final _searchController = TextEditingController();
  List<MediaItem> _items = [];
  Set<String> _favorites = {};
  bool _loading = false;
  String? _error;
  int _tab = 0;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    final url = await _preferences.getPlaylistUrl();
    final favorites = await _preferences.getFavorites();
    if (!mounted) return;
    _urlController.text = url ?? '';
    setState(() => _favorites = favorites);
    if (url != null && url.isNotEmpty) await _loadUrl(url, save: false);
  }

  Future<void> _loadUrl(String url, {bool save = true}) async {
    setState(() { _loading = true; _error = null; });
    try {
      final items = await _playlistService.fromUrl(url);
      if (!mounted) return;
      setState(() { _items = items; _tab = 0; });
      if (save) await _preferences.setPlaylistUrl(url);
      if (items.isEmpty) setState(() => _error = 'A playlist foi lida, mas nenhum endereço de conteúdo válido foi encontrado.');
    } catch (e) {
      if (mounted) setState(() => _error = _friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendlyError(Object e) {
    final message = e.toString();
    if (message.contains('SocketException') || message.contains('Failed host lookup')) return 'Não foi possível conectar ao servidor. Verifique a internet e a URL.';
    if (message.contains('TimeoutException')) return 'O servidor demorou demais para responder. Tente novamente.';
    return message.replaceFirst('Exception: ', '');
  }

  Future<void> _loadFile() async {
    setState(() { _loading = true; _error = null; });
    try {
      final items = await _playlistService.fromFile();
      if (!mounted || items.isEmpty) return;
      setState(() { _items = items; _tab = 0; });
    } catch (e) {
      if (mounted) setState(() => _error = _friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleFavorite(MediaItem item) async {
    setState(() { _favorites.contains(item.stableId) ? _favorites.remove(item.stableId) : _favorites.add(item.stableId); });
    await _preferences.setFavorites(_favorites);
  }

  List<MediaItem> get _visibleItems {
    var list = _items;
    if (_tab == 1) list = list.where((e) => _favorites.contains(e.stableId)).toList();
    if (_search.trim().isNotEmpty) {
      final q = _search.toLowerCase().trim();
      list = list.where((e) => e.name.toLowerCase().contains(q) || (e.group ?? '').toLowerCase().contains(q)).toList();
    }
    return list;
  }

  @override
  void dispose() {
    _urlController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 700;
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [const Icon(Icons.play_circle_fill, color: Color(0xFF00D9FF), size: 30), const SizedBox(width: 10), const Text('UNEX PLAY', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.1))]),
        actions: [IconButton(tooltip: 'Configurar playlist', onPressed: _showPlaylistDialog, icon: const Icon(Icons.add_link)), const SizedBox(width: 8)],
      ),
      body: Row(children: [
        if (isWide) NavigationRail(
          selectedIndex: _tab,
          onDestinationSelected: (v) => setState(() => _tab = v),
          labelType: NavigationRailLabelType.all,
          destinations: const [NavigationRailDestination(icon: Icon(Icons.live_tv_outlined), selectedIcon: Icon(Icons.live_tv), label: Text('Conteúdo')), NavigationRailDestination(icon: Icon(Icons.favorite_border), selectedIcon: Icon(Icons.favorite), label: Text('Favoritos'))],
        ),
        Expanded(child: Column(children: [
          Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 12), child: Column(children: [
            TextField(controller: _searchController, onChanged: (v) => setState(() => _search = v), textInputAction: TextInputAction.search, decoration: InputDecoration(hintText: 'Buscar canais e categorias', prefixIcon: const Icon(Icons.search), suffixIcon: _search.isEmpty ? null : IconButton(onPressed: () { _searchController.clear(); setState(() => _search = ''); }, icon: const Icon(Icons.clear)), filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none))),
            if (!isWide) Align(alignment: Alignment.centerLeft, child: Padding(padding: const EdgeInsets.only(top: 8), child: SegmentedButton<int>(segments: const [ButtonSegment(value: 0, icon: Icon(Icons.live_tv), label: Text('Conteúdo')), ButtonSegment(value: 1, icon: Icon(Icons.favorite), label: Text('Favoritos'))], selected: {_tab}, onSelectionChanged: (v) => setState(() => _tab = v.first)))),
          ])),
          if (_loading) const LinearProgressIndicator(minHeight: 2),
          if (_error != null) Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Material(color: const Color(0xFF3A2025), borderRadius: BorderRadius.circular(12), child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [const Icon(Icons.error_outline), const SizedBox(width: 10), Expanded(child: Text(_error!)), IconButton(onPressed: () => _loadUrl(_urlController.text.trim()), icon: const Icon(Icons.refresh))])))),
          Expanded(child: _visibleItems.isEmpty ? _emptyState() : _contentList(_visibleItems, isWide)),
        ])),
      ]),
      floatingActionButton: FloatingActionButton.extended(onPressed: _showPlaylistDialog, icon: const Icon(Icons.playlist_add), label: const Text('Adicionar lista')),
    );
  }

  Widget _emptyState() => Center(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(_tab == 1 ? Icons.favorite_border : Icons.playlist_play, size: 64, color: Colors.white38), const SizedBox(height: 16), Text(_tab == 1 ? 'Você ainda não tem favoritos' : 'Adicione sua playlist IPTV', style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center), const SizedBox(height: 8), Text(_tab == 1 ? 'Marque canais como favoritos para encontrá-los aqui.' : 'Importe um arquivo M3U ou informe a URL da playlist fornecida pelo seu serviço.', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white60)), const SizedBox(height: 18), if (_tab == 0) FilledButton.icon(onPressed: _showPlaylistDialog, icon: const Icon(Icons.add), label: const Text('Configurar playlist'))])));

  Widget _contentList(List<MediaItem> items, bool isWide) {
    if (isWide) {
      return GridView.builder(padding: const EdgeInsets.fromLTRB(18, 8, 18, 96), gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 260, mainAxisExtent: 104, crossAxisSpacing: 12, mainAxisSpacing: 12), itemCount: items.length, itemBuilder: (context, index) => _itemCard(items[index]));
    }
    return ListView.separated(padding: const EdgeInsets.fromLTRB(16, 4, 16, 100), itemCount: items.length, separatorBuilder: (_, __) => const SizedBox(height: 8), itemBuilder: (context, index) => _itemCard(items[index]));
  }

  Widget _itemCard(MediaItem item) => Card(child: InkWell(
    borderRadius: BorderRadius.circular(12), onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => PlayerScreen(item: item))),
    child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), child: Row(children: [
      ClipRRect(borderRadius: BorderRadius.circular(9), child: Container(width: 54, height: 54, color: const Color(0xFF252B36), child: item.logo != null ? Image.network(item.logo!, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.live_tv, size: 28)) : const Icon(Icons.live_tv, size: 28, color: Color(0xFF00D9FF)))),
      const SizedBox(width: 12), Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)), if ((item.group ?? '').isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text(item.group!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white60, fontSize: 12)))])),
      IconButton(tooltip: _favorites.contains(item.stableId) ? 'Remover dos favoritos' : 'Adicionar aos favoritos', onPressed: () => _toggleFavorite(item), icon: Icon(_favorites.contains(item.stableId) ? Icons.favorite : Icons.favorite_border, color: _favorites.contains(item.stableId) ? const Color(0xFFFF5C7A) : Colors.white70)),
      const Icon(Icons.play_circle_outline, size: 28, color: Color(0xFF00D9FF)),
    ])),
  ));

  Future<void> _showPlaylistDialog() async {
    await showDialog<void>(context: context, builder: (dialogContext) => AlertDialog(
      title: const Text('Adicionar playlist'),
      content: SizedBox(width: 480, child: Column(mainAxisSize: MainAxisSize.min, children: [const Text('Use uma URL M3U/M3U Plus HTTP ou HTTPS, ou importe um arquivo do dispositivo.'), const SizedBox(height: 16), TextField(controller: _urlController, keyboardType: TextInputType.url, decoration: const InputDecoration(labelText: 'URL da playlist', hintText: 'https://servidor/lista.m3u', border: OutlineInputBorder()), onSubmitted: (_) { Navigator.pop(dialogContext); _loadUrl(_urlController.text.trim()); }), const SizedBox(height: 12), OutlinedButton.icon(onPressed: () { Navigator.pop(dialogContext); _loadFile(); }, icon: const Icon(Icons.folder_open), label: const Text('Importar arquivo M3U'))])),
      actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')), FilledButton(onPressed: () { Navigator.pop(dialogContext); _loadUrl(_urlController.text.trim()); }, child: const Text('Carregar'))],
    ));
  }
}
