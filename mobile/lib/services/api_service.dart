import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/track.dart';

/// Cliente del backend (Fase 1: extracción de enlaces).
class ApiService {
  ApiService({required this.baseUrl});

  final String baseUrl;

  Future<List<Track>> search(String query, {int limit = 5}) async {
    final uri = Uri.parse('$baseUrl/search').replace(
      queryParameters: {'q': query, 'limit': '$limit'},
    );
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Búsqueda fallida (${res.statusCode})');
    }
    final List data = jsonDecode(res.body) as List;
    return data.map((e) => Track.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Pide una URL de streaming fresca. Llamar SIEMPRE justo antes de reproducir.
  Future<String> getStreamUrl(String videoId) async {
    final uri = Uri.parse('$baseUrl/stream/$videoId');
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('No se pudo obtener el stream (${res.statusCode})');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return data['stream_url'] as String;
  }

  Future<Track> getMetadata(String videoId) async {
    final uri = Uri.parse('$baseUrl/metadata/$videoId');
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('No se pudo obtener metadata (${res.statusCode})');
    }
    return Track.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  /// Cancións similares (mismo canal/artista) al video dado.
  Future<List<Track>> getRecommendations(String videoId, {int limit = 10}) async {
    final uri = Uri.parse('$baseUrl/recommendations/$videoId').replace(
      queryParameters: {'limit': '$limit'},
    );
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('No se pudieron obtener recomendaciones (${res.statusCode})');
    }
    final List data = jsonDecode(res.body) as List;
    return data.map((e) => Track.fromJson(e as Map<String, dynamic>)).toList();
  }
}
