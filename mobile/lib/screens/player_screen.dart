import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

import '../models/track.dart';
import '../services/api_service.dart';
import '../services/player_service.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final playerService = context.watch<PlayerService>();
    final track = playerService.current;

    return Scaffold(
      appBar: AppBar(title: const Text('Reproduciendo')),
      body: track == null
          ? const Center(child: Text('No hay nada en cola'))
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                if (track.thumbnail != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(track.thumbnail!, height: 220),
                  ),
                const SizedBox(height: 24),
                Text(
                  track.title,
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                if (track.uploader != null)
                  Center(
                    child: Text(
                      track.uploader!,
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 16),
                if (playerService.error != null)
                  Text(playerService.error!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 8),
                StreamBuilder<Duration>(
                  stream: playerService.player.positionStream,
                  builder: (context, snapshot) {
                    final position = snapshot.data ?? Duration.zero;
                    final duration = playerService.player.duration ?? Duration.zero;
                    final maxSeconds = duration.inSeconds > 0 ? duration.inSeconds.toDouble() : 1.0;
                    final posSeconds = position.inSeconds.toDouble().clamp(0, maxSeconds).toDouble();
                    return Column(
                      children: [
                        Slider(
                          value: posSeconds,
                          max: maxSeconds,
                          onChanged: (value) =>
                              playerService.seek(Duration(seconds: value.toInt())),
                        ),
                        Text('${_fmt(position)} / ${_fmt(duration)}'),
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
                      icon: const Icon(Icons.skip_previous),
                      onPressed: playerService.playPrevious,
                    ),
                    const SizedBox(width: 16),
                    if (playerService.loading)
                      const SizedBox(
                        width: 48,
                        height: 48,
                        child: CircularProgressIndicator(),
                      )
                    else
                      StreamBuilder<PlayerState>(
                        stream: playerService.player.playerStateStream,
                        builder: (context, snapshot) {
                          final playing = snapshot.data?.playing ?? false;
                          return IconButton(
                            iconSize: 56,
                            icon: Icon(playing ? Icons.pause_circle_filled : Icons.play_circle_filled),
                            onPressed: playing ? playerService.pause : playerService.resume,
                          );
                        },
                      ),
                    const SizedBox(width: 16),
                    IconButton(
                      iconSize: 36,
                      icon: const Icon(Icons.skip_next),
                      onPressed: playerService.playNext,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _RecommendationsSection(
                  key: ValueKey(track.id),
                  seedId: track.id,
                ),
              ],
            ),
    );
  }
}

class _RecommendationsSection extends StatefulWidget {
  const _RecommendationsSection({super.key, required this.seedId});

  final String seedId;

  @override
  State<_RecommendationsSection> createState() => _RecommendationsSectionState();
}

class _RecommendationsSectionState extends State<_RecommendationsSection> {
  List<Track>? _recos;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final recos = await context.read<ApiService>().getRecommendations(widget.seedId);
      setState(() => _recos = recos);
    } catch (e) {
      setState(() => _error = 'No se pudieron cargar recomendaciones');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _play(List<Track> recos, int index) {
    context.read<PlayerService>().setQueue(recos, startIndex: index);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recomendaciones', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (_loading) const LinearProgressIndicator(),
        if (_error != null)
          Text(_error!, style: const TextStyle(color: Colors.grey)),
        if (_recos != null)
          ..._recos!.map(
            (t) => ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: t.thumbnail != null
                  ? Image.network(t.thumbnail!, width: 48, height: 48, fit: BoxFit.cover)
                  : const Icon(Icons.music_note),
              title: Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(t.uploader ?? ''),
              onTap: () => _play(_recos!, _recos!.indexOf(t)),
            ),
          ),
      ],
    );
  }
}