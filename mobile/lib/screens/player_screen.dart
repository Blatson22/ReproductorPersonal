import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

import '../models/track.dart';
import '../services/api_service.dart';
import '../services/player_service.dart';
import '../theme/app_theme.dart';
import '../widgets/track_tile.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  bool? _isFavorite;
  String? _favoriteForTrackId;
  List<Track> _recommendations = [];

  Future<void> _syncFavoriteState(String trackId) async {
    if (_favoriteForTrackId == trackId) return;
    _favoriteForTrackId = trackId;
    try {
      final fav = await context.read<ApiService>().isFavorite(trackId);
      if (mounted && _favoriteForTrackId == trackId) {
        setState(() => _isFavorite = fav);
      }
    } catch (_) {
      // Sin conexión o sin sesión: se deja el corazón sin marcar.
    }
  }

  Future<void> _loadRecommendations(String trackId) async {
    try {
      final recs = await context.read<ApiService>().getRecommendations(trackId, limit: 8);
      if (mounted) setState(() => _recommendations = recs);
    } catch (_) {
      if (mounted) setState(() => _recommendations = []);
    }
  }

  Future<void> _toggleFavorite(Track track) async {
    final api = context.read<ApiService>();
    final wasFavorite = _isFavorite ?? false;
    setState(() => _isFavorite = !wasFavorite);
    try {
      if (wasFavorite) {
        await api.removeFavorite(track.id);
      } else {
        await api.addFavorite(track);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isFavorite = wasFavorite);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo actualizar favoritos: $e')),
      );
    }
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final playerService = context.watch<PlayerService>();
    final track = playerService.current;

    if (track == null) {
      return const Scaffold(body: Center(child: Text('No hay nada en cola')));
    }

    _syncFavoriteState(track.id);
    if (_recommendations.isEmpty) {
      _loadRecommendations(track.id);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Reproduciendo')),
      body: Stack(
        children: [
          // Fondo con la carátula difuminada de telón de fondo.
          if (track.thumbnail != null)
            Positioned.fill(
              child: Opacity(
                opacity: 0.18,
                child: Image.network(track.thumbnail!, fit: BoxFit.cover),
              ),
            ),
          const Positioned.fill(
            child: DecoratedBox(decoration: BoxDecoration(gradient: AppColors.playerScrim)),
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              children: [
                Center(
                  child: Hero(
                    tag: 'art-${track.id}',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: track.thumbnail != null
                          ? Image.network(
                              track.thumbnail!,
                              height: 260,
                              width: 260,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _artPlaceholder(),
                            )
                          : _artPlaceholder(),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            track.title,
                            style: Theme.of(context).textTheme.titleLarge,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (track.uploader != null) ...[
                            const SizedBox(height: 4),
                            Text(track.uploader!, style: const TextStyle(color: AppColors.textSecondary)),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      iconSize: 28,
                      icon: Icon(
                        (_isFavorite ?? false) ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: (_isFavorite ?? false) ? AppColors.primary : AppColors.textSecondary,
                      ),
                      onPressed: () => _toggleFavorite(track),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (playerService.error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      playerService.error!,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                StreamBuilder<Duration>(
                  stream: playerService.player.positionStream,
                  builder: (context, snapshot) {
                    final position = snapshot.data ?? Duration.zero;
                    final duration = playerService.player.duration ?? Duration.zero;
                    final maxSeconds = duration.inSeconds > 0 ? duration.inSeconds.toDouble() : 1.0;
                    final posSeconds = position.inSeconds.toDouble().clamp(0.0, maxSeconds).toDouble();
                    return Column(
                      children: [
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackShape: const RoundedRectSliderTrackShape(),
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          ),
                          child: Slider(
                            value: posSeconds,
                            max: maxSeconds,
                            onChanged: (value) =>
                                playerService.seek(Duration(seconds: value.toInt())),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_fmt(position), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                              Text(_fmt(duration), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      iconSize: 36,
                      icon: const Icon(Icons.skip_previous_rounded),
                      onPressed: playerService.playPrevious,
                    ),
                    const SizedBox(width: 20),
                    Container(
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: playerService.loading
                          ? const Padding(
                              padding: EdgeInsets.all(16),
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : StreamBuilder<PlayerState>(
                              stream: playerService.player.playerStateStream,
                              builder: (context, snapshot) {
                                final playing = snapshot.data?.playing ?? false;
                                return IconButton(
                                  iconSize: 44,
                                  color: Colors.white,
                                  icon: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
                                  onPressed: playing ? playerService.pause : playerService.resume,
                                );
                              },
                            ),
                    ),
                    const SizedBox(width: 20),
                    IconButton(
                      iconSize: 36,
                      icon: const Icon(Icons.skip_next_rounded),
                      onPressed: playerService.playNext,
                    ),
                  ],
                ),
                if (_recommendations.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  Text('También te puede gustar', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ...List.generate(_recommendations.length, (index) {
                    final rec = _recommendations[index];
                    return TrackTile(
                      track: rec,
                      onTap: () => playerService.setQueue(_recommendations, startIndex: index),
                    );
                  }),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _artPlaceholder() => Container(
        height: 260,
        width: 260,
        color: AppColors.surfaceElevated,
        child: const Icon(Icons.music_note_rounded, size: 72, color: AppColors.textSecondary),
      );
}
