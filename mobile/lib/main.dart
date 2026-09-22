import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/auth_screen.dart';
import 'screens/home_shell.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/player_service.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

/// Resuelve la URL del backend.
///
/// En web, el backend sirve también la propia app (mismo origen), así que
/// usamos el origen actual; esto funciona igual en local, en LAN o detrás
/// de un túnel/dominio público sin tocar nada.
/// En nativo (Android/iOS) se usa el alias del host según el entorno.
String _resolveBackendUrl() {
  if (kIsWeb) {
    final origin = Uri.base.origin;
    if (origin.isNotEmpty) return origin;
  }
  return 'http://10.0.2.2:8000';
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final apiService = ApiService(baseUrl: _resolveBackendUrl());

    return MultiProvider(
      providers: [
        Provider<ApiService>.value(value: apiService),
        ChangeNotifierProvider<AuthService>(create: (_) => AuthService(apiService)),
        ChangeNotifierProvider<PlayerService>(create: (_) => PlayerService(apiService)),
      ],
      child: MaterialApp(
        title: 'ReproductorPersonal',
        theme: AppTheme.dark,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        debugShowCheckedModeBanner: false,
        home: const _RootRouter(),
      ),
    );
  }
}

/// Decide qué pantalla mostrar según el estado de la sesión guardada.
class _RootRouter extends StatefulWidget {
  const _RootRouter();

  @override
  State<_RootRouter> createState() => _RootRouterState();
}

class _RootRouterState extends State<_RootRouter> {
  @override
  void initState() {
    super.initState();
    context.read<AuthService>().restoreSession();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    switch (auth.status) {
      case AuthStatus.unknown:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case AuthStatus.authenticated:
        return const HomeShell();
      case AuthStatus.unauthenticated:
        return const AuthScreen();
    }
  }
}
