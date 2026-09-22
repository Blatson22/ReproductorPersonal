// Smoke test: sin una sesión guardada, la app debe arrancar en la
// pantalla de login/registro (no había test real antes; el que venía
// por defecto probaba un contador que no existe en esta app).

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:yt_audio_player/main.dart';

void main() {
  testWidgets('Sin sesión guardada, muestra la pantalla de login', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MyApp());
    // Deja resolver el Future de restoreSession().
    await tester.pumpAndSettle();

    expect(find.text('ReproductorPersonal'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
  });
}
