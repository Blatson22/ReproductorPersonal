import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/track.dart';
import '../services/api_service.dart';
import '../services/player_service.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/track_tile.dart';
import 'player_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<Track>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<ApiService>().getHistory();
  }

  void _reload() {
    setState(() => _future = context.read<ApiService>().getHistory());
  }

  Future<void> _clear() async {
    final api = context.read<ApiService>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: const Text('Borrar historial'),
        content: const Text('Esta acción no se puede deshacer. ¿Continuar?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Borrar')),
        ],
      ),
    );
    if (confirmed != true) return;
    await api.clearHistory();
    if (!mounted) return;
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'Borrar historial',
            onPressed: _clear,
          ),
        ],
      ),
      body: FutureBuilder<List<Track>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No se pudo cargar el historial:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            );
          }
          final tracks = snapshot.data ?? [];
          if (tracks.isEmpty) {
            return const EmptyState(
              icon: Icons.history_rounded,
              message: 'Aún no has reproducido nada.\nLo que escuches aparecerá aquí.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: tracks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final track = tracks[index];
                return TrackTile(
                  track: track,
                  onTap: () {
                    context.read<PlayerService>().setQueue(tracks, startIndex: index);
                    Navigator.of(context)
                        .push(MaterialPageRoute(builder: (_) => const PlayerScreen()));
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
