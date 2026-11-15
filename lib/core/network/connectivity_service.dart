import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Informa si el dispositivo tiene alguna red disponible.
/// Si el plugin falla (p. ej. en tests), asume que sí hay conexión y deja
/// que el propio intento de red decida.
class ConnectivityService {
  ConnectivityService([Connectivity? connectivity])
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  static bool _hayRed(List<ConnectivityResult> r) =>
      r.isEmpty || r.any((c) => c != ConnectivityResult.none);

  Future<bool> hayConexion() async {
    try {
      return _hayRed(await _connectivity.checkConnectivity());
    } catch (e) {
      debugPrint('[Chambing] no se pudo consultar la conectividad: $e');
      return true;
    }
  }

  /// Emite `true`/`false` cada vez que cambia el estado de la red.
  Stream<bool> get cambios {
    try {
      return _connectivity.onConnectivityChanged
          .map(_hayRed)
          .handleError((Object e) =>
              debugPrint('[Chambing] error de conectividad: $e'));
    } catch (e) {
      debugPrint('[Chambing] no se pudo escuchar la conectividad: $e');
      return const Stream.empty();
    }
  }
}
