import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/track.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/player_service.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/track_tile.dart';
import 'player_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  List<Track> _results = [];
  bool _loading = false;
  bool _searched = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
      _searched = true;
    });

    try {
      final results = await context.read<ApiService>().search(query);
      if (!mounted) return;
      setState(() => _results = results);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _play(int index) {
    context.read<PlayerService>().setQueue(_results, startIndex: index);
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PlayerScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final username = context.watch<AuthService>().username;

    return Scaffold(
      appBar: AppBar(
        title: Text(username != null ? 'Hola, $username' : 'Buscar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Cerrar sesión',
            onPressed: () => context.read<AuthService>().logout(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: TextField(
              controller: _controller,
              style: const TextStyle(color: AppColors.textPrimary),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Buscar una canción o artista...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _controller.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _controller.clear();
                          setState(() {
                            _results = [];
                            _searched = false;
                          });
                        },
                      ),
              ),
              onSubmitted: (_) => _search(),
              onChanged: (_) => setState(() {}),
            ),
          ),
          if (_loading) const LinearProgressIndicator(minHeight: 2),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(_error!, style: const TextStyle(color: AppColors.error)),
              ),
            ),
          Expanded(
            child: !_searched
                ? const EmptyState(
                    icon: Icons.graphic_eq_rounded,
                    message: 'Busca cualquier canción para empezar a escuchar.',
                  )
                : (_results.isEmpty && !_loading)
                    ? const EmptyState(
                        icon: Icons.search_off_rounded,
                        message: 'Sin resultados para esa búsqueda.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: _results.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 4),
                        itemBuilder: (context, index) {
                          final track = _results[index];
                          return TrackTile(track: track, onTap: () => _play(index));
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
