import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/track.dart';

class AuthResult {
  AuthResult({required this.token, required this.username});
  final String token;
  final String username;
}

/// Cliente del backend: extracción de audio, autenticación, favoritos e historial.
class ApiService {
  ApiService({required this.baseUrl});

  final String baseUrl;

  /// Token de sesión actual. Lo gestiona [AuthService]; aquí solo se usa
  /// para adjuntar el header `Authorization` en los endpoints protegidos.
  String? token;

  Map<String, String> get _authHeaders =>
      token == null ? {} : {'Authorization': 'Bearer $token'};

  Map<String, String> get _jsonHeaders => {
        'Content-Type': 'application/json',
        ..._authHeaders,
      };

  Never _fail(String action, http.Response res) {
    String detail = res.body;
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map && decoded['detail'] != null) {
        detail = decoded['detail'].toString();
      }
    } catch (_) {
      // el cuerpo no era JSON, se deja el texto crudo
    }
    throw Exception('$action: $detail');
  }

  // --- Fase 1: búsqueda, metadata, stream ---

  Future<List<Track>> search(String query, {int limit = 8}) async {
    final uri = Uri.parse('$baseUrl/search').replace(
      queryParameters: {'q': query, 'limit': '$limit'},
    );
    final res = await http.get(uri, headers: _authHeaders);
    if (res.statusCode != 200) _fail('Búsqueda fallida', res);
    final List data = jsonDecode(res.body) as List;
    return data.map((e) => Track.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Pide una URL de streaming fresca. Llamar SIEMPRE justo antes de reproducir.
  Future<String> getStreamUrl(String videoId) async {
    final uri = Uri.parse('$baseUrl/stream/$videoId');
    final res = await http.get(uri, headers: _authHeaders);
    if (res.statusCode != 200) _fail('No se pudo obtener el stream', res);
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return data['stream_url'] as String;
  }

  Future<Track> getMetadata(String videoId) async {
    final uri = Uri.parse('$baseUrl/metadata/$videoId');
    final res = await http.get(uri, headers: _authHeaders);
    if (res.statusCode != 200) _fail('No se pudo obtener metadata', res);
    return Track.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  /// Canciones similares (mismo canal/artista) al video dado.
  Future<List<Track>> getRecommendations(String videoId, {int limit = 10}) async {
    final uri = Uri.parse('$baseUrl/recommendations/$videoId').replace(
      queryParameters: {'limit': '$limit'},
    );
    final res = await http.get(uri, headers: _authHeaders);
    if (res.statusCode != 200) _fail('No se pudieron obtener recomendaciones', res);
    final List data = jsonDecode(res.body) as List;
    return data.map((e) => Track.fromJson(e as Map<String, dynamic>)).toList();
  }

  // --- Auth ---

  Future<AuthResult> register(String username, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: _jsonHeaders,
      body: jsonEncode({'username': username, 'password': password}),
    );
    if (res.statusCode != 200) _fail('No se pudo crear la cuenta', res);
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return AuthResult(token: data['token'], username: data['username']);
  }

  Future<AuthResult> login(String username, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _jsonHeaders,
      body: jsonEncode({'username': username, 'password': password}),
    );
    if (res.statusCode != 200) _fail('No se pudo iniciar sesión', res);
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return AuthResult(token: data['token'], username: data['username']);
  }

  Future<void> logout() async {
    await http.post(Uri.parse('$baseUrl/auth/logout'), headers: _authHeaders);
  }

  Future<String> me() async {
    final res = await http.get(Uri.parse('$baseUrl/auth/me'), headers: _authHeaders);
    if (res.statusCode != 200) _fail('Sesión inválida', res);
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return data['username'] as String;
  }

  // --- Favoritos ---

  Future<List<Track>> getFavorites() async {
    final res = await http.get(Uri.parse('$baseUrl/favorites'), headers: _authHeaders);
    if (res.statusCode != 200) _fail('No se pudieron cargar los favoritos', res);
    final List data = jsonDecode(res.body) as List;
    return data.map((e) => Track.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> addFavorite(Track track) async {
    final res = await http.post(
      Uri.parse('$baseUrl/favorites'),
      headers: _jsonHeaders,
      body: jsonEncode(_trackToJson(track)),
    );
    if (res.statusCode != 200) _fail('No se pudo guardar el favorito', res);
  }

  Future<void> removeFavorite(String videoId) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/favorites/$videoId'),
      headers: _authHeaders,
    );
    if (res.statusCode != 200) _fail('No se pudo quitar el favorito', res);
  }

  Future<bool> isFavorite(String videoId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/favorites/check/$videoId'),
      headers: _authHeaders,
    );
    if (res.statusCode != 200) return false;
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return data['is_favorite'] as bool? ?? false;
  }

  // --- Historial ---

  Future<List<Track>> getHistory({int limit = 100}) async {
    final uri = Uri.parse('$baseUrl/history').replace(
      queryParameters: {'limit': '$limit'},
    );
    final res = await http.get(uri, headers: _authHeaders);
    if (res.statusCode != 200) _fail('No se pudo cargar el historial', res);
    final List data = jsonDecode(res.body) as List;
    return data.map((e) => Track.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> addHistory(Track track) async {
    final res = await http.post(
      Uri.parse('$baseUrl/history'),
      headers: _jsonHeaders,
      body: jsonEncode(_trackToJson(track)),
    );
    if (res.statusCode != 200) _fail('No se pudo registrar en el historial', res);
  }

  Future<void> clearHistory() async {
    final res = await http.delete(Uri.parse('$baseUrl/history'), headers: _authHeaders);
    if (res.statusCode != 200) _fail('No se pudo limpiar el historial', res);
  }

  Map<String, dynamic> _trackToJson(Track track) => {
        'id': track.id,
        'title': track.title,
        'thumbnail': track.thumbnail,
        'duration': track.duration,
        'uploader': track.uploader,
      };
}
