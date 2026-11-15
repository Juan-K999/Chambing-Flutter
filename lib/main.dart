import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'widgets/comunes.dart';

void main() {
  runZonedGuarded(() {
    WidgetsFlutterBinding.ensureInitialized();

    // Errores del framework (build, layout…): solo a la consola.
    FlutterError.onError = (details) {
      FlutterError.dumpErrorToConsole(details);
    };

    // Errores asíncronos no capturados: se registran y se marcan como manejados.
    PlatformDispatcher.instance.onError = (error, stack) {
      debugPrint('[Chambing] error asíncrono no controlado: $error\n$stack');
      return true;
    };

    // Reemplaza la pantalla roja de Flutter por un aviso neutro.
    ErrorWidget.builder = (details) => const _ErrorAmigable();

    runApp(const ChambingApp());
  }, (error, stack) {
    debugPrint('[Chambing] error de zona no controlado: $error\n$stack');
  });
}

class ChambingApp extends StatelessWidget {
  const ChambingApp({super.key});

  // Color principal de la web de Chambing (--main-color en styles.css).
  static const _morado = Color(0xFF2A0A5B);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chambing',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: _morado),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme:
            ColorScheme.fromSeed(seedColor: _morado, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      // El banner de "sin conexión" queda encima de todas las pantallas.
      builder: (context, child) => Column(children: [
        const OfflineBanner(),
        Expanded(child: child ?? const SizedBox.shrink()),
      ]),
      home: const HomeScreen(),
    );
  }
}

class _ErrorAmigable extends StatelessWidget {
  const _ErrorAmigable();

  @override
  Widget build(BuildContext context) {
    return const Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        color: Colors.transparent,
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.sentiment_dissatisfied_outlined, color: Colors.grey, size: 40),
              SizedBox(height: 8),
              Text(
                'No pudimos mostrar esta sección. Vuelve atrás e intenta de nuevo.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
