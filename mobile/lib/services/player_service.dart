import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../models/track.dart';
import 'api_service.dart';

/// Fase 2 + Fase 3: reproductor de audio y cola de reproducción.
class PlayerService extends ChangeNotifier {
  PlayerService(this._api) {
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        playNext();
      }
      notifyListeners();
    });
  }

  final ApiService _api;
  final AudioPlayer _player = AudioPlayer();

  final List<Track> _queue = [];
  int _currentIndex = -1;
  bool _loading = false;
  String? _error;

  AudioPlayer get player => _player;
  List<Track> get queue => List.unmodifiable(_queue);
  bool get loading => _loading;
  String? get error => _error;

  Track? get current =>
      _currentIndex >= 0 && _currentIndex < _queue.length ? _queue[_currentIndex] : null;

  /// Reemplaza la cola y empieza a reproducir desde [startIndex].
  Future<void> setQueue(List<Track> tracks, {int startIndex = 0}) async {
    _queue
      ..clear()
      ..addAll(tracks);
    _currentIndex = startIndex;
    await _playCurrent();
  }

  Future<void> _playCurrent() async {
    final track = current;
    if (track == null) return;

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      // Se pide la URL de streaming justo antes de reproducir: nunca se cachea.
      final streamUrl = await _api.getStreamUrl(track.id);
      await _player.setUrl(streamUrl);
      await _player.play();
    } catch (e) {
      _error = 'No se pudo reproducir "${track.title}": $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> playNext() async {
    if (_currentIndex + 1 < _queue.length) {
      _currentIndex++;
      await _playCurrent();
    }
  }

  Future<void> playPrevious() async {
    if (_currentIndex - 1 >= 0) {
      _currentIndex--;
      await _playCurrent();
    }
  }

  Future<void> pause() => _player.pause();
  Future<void> resume() => _player.play();
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
