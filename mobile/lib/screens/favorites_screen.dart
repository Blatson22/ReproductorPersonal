import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/track.dart';
import '../services/api_service.dart';
import '../services/player_service.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/track_tile.dart';
import 'player_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  late Future<List<Track>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<ApiService>().getFavorites();
  }

  void _reload() {
    setState(() => _future = context.read<ApiService>().getFavorites());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favoritos')),
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
                  'No se pudieron cargar tus favoritos:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            );
          }
          final tracks = snapshot.data ?? [];
          if (tracks.isEmpty) {
            return const EmptyState(
              icon: Icons.favorite_border_rounded,
              message: 'Todavía no tienes canciones favoritas.\nMarca el corazón en el reproductor.',
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
