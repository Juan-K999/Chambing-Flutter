import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Guarda el token JWT y los datos básicos de la empresa o el usuario logueado.
/// Los errores de almacenamiento se registran y nunca llegan a la UI.
class SessionStore {
  static const _kToken = 'token';
  static const _kIdEmpresa = 'idEmpresa';
  static const _kNombreEmpresa = 'nombreEmpresa';
  static const _kIdUsuario = 'idUsuario';
  static const _kNombreUsuario = 'nombreUsuario';

  Future<SharedPreferences?> _prefs() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (e) {
      debugPrint('[Chambing] almacenamiento no disponible: $e');
      return null;
    }
  }

  Future<String?> get token async => (await _prefs())?.getString(_kToken);
  Future<String?> get idEmpresa async =>
      (await _prefs())?.getString(_kIdEmpresa);
  Future<String?> get nombreEmpresa async =>
      (await _prefs())?.getString(_kNombreEmpresa);

  Future<String?> get idUsuario async =>
      (await _prefs())?.getString(_kIdUsuario);
  Future<String?> get nombreUsuario async =>
      (await _prefs())?.getString(_kNombreUsuario);

  Future<void> guardarToken(String token) async {
    await (await _prefs())?.setString(_kToken, token);
  }

  Future<void> guardarEmpresa(String id, String nombre) async {
    final p = await _prefs();
    await p?.setString(_kIdEmpresa, id);
    await p?.setString(_kNombreEmpresa, nombre);
  }

  Future<void> guardarUsuario(String id, String nombre) async {
    final p = await _prefs();
    await p?.setString(_kIdUsuario, id);
    await p?.setString(_kNombreUsuario, nombre);
  }

  Future<void> limpiar() async {
    final p = await _prefs();
    await p?.remove(_kToken);
    await p?.remove(_kIdEmpresa);
    await p?.remove(_kNombreEmpresa);
    await p?.remove(_kIdUsuario);
    await p?.remove(_kNombreUsuario);
  }
}
