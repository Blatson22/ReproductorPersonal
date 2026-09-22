import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/track.dart';
import '../services/api_service.dart';
import '../services/player_service.dart';
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
  String? _error;

  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await context.read<ApiService>().search(query);
      setState(() => _results = results);
    } catch (e) {
      setState(() => _error = 'Error buscando: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _play(int index) {
    context.read<PlayerService>().setQueue(_results, startIndex: index);
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PlayerScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buscar')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Buscar canción...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(icon: const Icon(Icons.search), onPressed: _search),
              ],
            ),
          ),
          if (_loading) const LinearProgressIndicator(),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: _results.length,
              itemBuilder: (context, index) {
                final track = _results[index];
                return ListTile(
                  leading: track.thumbnail != null
                      ? Image.network(track.thumbnail!, width: 56, height: 56, fit: BoxFit.cover)
                      : const Icon(Icons.music_note),
                  title: Text(track.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                  subtitle: Text(track.uploader ?? ''),
                  onTap: () => _play(index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
