import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/search_screen.dart';
import 'services/api_service.dart';
import 'services/player_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: cambia esto por la URL/IP real de tu backend.
    // 10.0.2.2 es el alias de "localhost de tu PC" desde el emulador Android.
    // En un dispositivo físico usa la IP local de tu PC (ej. http://192.168.1.50:8000)
    // o la URL pública de tu servidor una vez desplegado.
    const backendUrl = 'http://localhost:8000';

    final apiService = ApiService(baseUrl: backendUrl);

    return MultiProvider(
      providers: [
        Provider<ApiService>.value(value: apiService),
        ChangeNotifierProvider<PlayerService>(create: (_) => PlayerService(apiService)),
      ],
      child: MaterialApp(
        title: 'YT Audio Player',
        theme: ThemeData(colorSchemeSeed: Colors.deepPurple, useMaterial3: true),
        debugShowCheckedModeBanner: false,
        home: const SearchScreen(),
      ),
    );
  }
}
