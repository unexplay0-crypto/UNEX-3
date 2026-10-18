import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../models/media_item.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key, required this.item});
  final MediaItem item;
  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  VideoPlayerController? _controller;
  bool _loading = true;
  String? _error;
  bool _controlsVisible = true;
  bool _isLive = true;

  @override
  void initState() { super.initState(); _initialize(); }

  Future<void> _initialize() async {
    final uri = Uri.tryParse(widget.item.url);
    if (uri == null || !uri.hasScheme) { setState(() { _loading = false; _error = 'O endereço deste conteúdo é inválido.'; }); return; }
    final controller = VideoPlayerController.networkUrl(uri);
    _controller = controller;
    controller.addListener(_onVideoUpdate);
    try {
      await controller.initialize().timeout(const Duration(seconds: 35));
      if (!mounted) return;
      final path = uri.path.toLowerCase();
      setState(() { _loading = false; _isLive = path.endsWith('.m3u8') || path.endsWith('.ts') || controller.value.duration == Duration.zero; });
      await controller.play();
    } catch (_) {
      if (!mounted) return;
      setState(() { _loading = false; _error = 'Não foi possível reproduzir este conteúdo. Verifique a URL, a conexão, o formato e as permissões do servidor.'; });
    }
  }

  void _onVideoUpdate() {
    final c = _controller;
    if (c != null && c.value.hasError && mounted) setState(() { _error = 'Ocorreu um erro durante a reprodução. Tente novamente ou escolha outro conteúdo.'; _loading = false; });
  }

  Future<void> _retry() async {
    final old = _controller;
    if (old != null) { old.removeListener(_onVideoUpdate); await old.dispose(); }
    if (!mounted) return;
    setState(() { _controller = null; _error = null; _loading = true; });
    await _initialize();
  }

  @override
  void dispose() {
    _controller?.removeListener(_onVideoUpdate);
    _controller?.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    return Scaffold(backgroundColor: Colors.black, body: Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{SingleActivator(LogicalKeyboardKey.escape): ActivateIntent(), SingleActivator(LogicalKeyboardKey.goBack): ActivateIntent()},
      child: Focus(autofocus: true, onKeyEvent: (node, event) { if (event is KeyDownEvent && (event.logicalKey == LogicalKeyboardKey.escape || event.logicalKey == LogicalKeyboardKey.goBack || event.logicalKey == LogicalKeyboardKey.browserBack)) { Navigator.maybePop(context); return KeyEventResult.handled; } return KeyEventResult.ignored; }, child: GestureDetector(
        onTap: () => setState(() => _controlsVisible = !_controlsVisible),
        child: Stack(fit: StackFit.expand, children: [
          if (c != null && c.value.isInitialized) Center(child: AspectRatio(aspectRatio: c.value.aspectRatio, child: VideoPlayer(c))),
          if (_loading) const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [CircularProgressIndicator(), SizedBox(height: 16), Text('Conectando à transmissão…')])),
          if (_error != null) Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.error_outline, size: 56, color: Colors.redAccent), const SizedBox(height: 16), Text(_error!, textAlign: TextAlign.center), const SizedBox(height: 20), FilledButton.icon(onPressed: _retry, icon: const Icon(Icons.refresh), label: const Text('Tentar novamente')), TextButton(onPressed: () => Navigator.maybePop(context), child: const Text('Voltar'))]))),
          if (_controlsVisible && !_loading && _error == null) Positioned(left: 0, right: 0, top: 0, child: Container(padding: const EdgeInsets.fromLTRB(12, 22, 12, 20), decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black87, Colors.transparent])), child: Row(children: [IconButton(autofocus: true, onPressed: () => Navigator.maybePop(context), icon: const Icon(Icons.arrow_back)), const SizedBox(width: 8), Expanded(child: Text(widget.item.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)), const Text('UNEX PLAY', style: TextStyle(color: Color(0xFF00D9FF), fontWeight: FontWeight.w800))]))),
          if (_controlsVisible && c != null && c.value.isInitialized && _error == null) Positioned(left: 0, right: 0, bottom: 0, child: Container(padding: const EdgeInsets.fromLTRB(20, 28, 20, 24), decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black87, Colors.transparent])), child: Column(mainAxisSize: MainAxisSize.min, children: [Row(mainAxisAlignment: MainAxisAlignment.center, children: [IconButton(iconSize: 42, autofocus: true, onPressed: () { c.value.isPlaying ? c.pause() : c.play(); setState(() {}); }, icon: Icon(c.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill)), if (!_isLive) IconButton(tooltip: 'Voltar 10 segundos', onPressed: () => c.seekTo(c.value.position - const Duration(seconds: 10)), icon: const Icon(Icons.replay_10)), if (!_isLive) IconButton(tooltip: 'Avançar 10 segundos', onPressed: () => c.seekTo(c.value.position + const Duration(seconds: 10)), icon: const Icon(Icons.forward_10))]), if (!_isLive) VideoProgressIndicator(c, allowScrubbing: true, padding: const EdgeInsets.symmetric(vertical: 8)), Align(alignment: Alignment.centerRight, child: Text(_isLive ? 'AO VIVO' : '${_format(c.value.position)} / ${_format(c.value.duration)}', style: const TextStyle(fontSize: 12, color: Colors.white70)))]))),
        ]),
      )),
    ));
  }

  String _format(Duration d) => '${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}';
}
