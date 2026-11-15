import 'package:flutter/foundation.dart';

/// Configuración de la conexión con el backend Spring Boot de Chambing.
/// Se puede sobreescribir al ejecutar:
///   flutter run --dart-define=API_URL=http://192.168.1.10:9999
class ApiConfig {
  ApiConfig._();

  static const String _override = String.fromEnvironment('API_URL');

  static String get baseUrl {
    if (_override.isNotEmpty) return _override;
    if (kIsWeb) return 'http://localhost:9999';
    // El emulador de Android ve el PC anfitrión en 10.0.2.2
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:9999';
    }
    return 'http://localhost:9999';
  }

  /// Tiempo máximo de espera por petición.
  static const Duration timeout = Duration(seconds: 15);
}
