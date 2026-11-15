import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../errors/app_exception.dart';
import '../session/session_store.dart';

/// Único punto de salida a la red. Convierte cualquier fallo (sin internet,
/// servidor caído, timeout, códigos HTTP, HTML inesperado) en una
/// [AppException] con mensaje amigable.
class ApiClient {
  ApiClient({
    required SessionStore session,
    required Future<bool> Function() hayConexion,
    http.Client? client,
    String? baseUrl,
    Duration? timeout,
  })  : _session = session, // ignore: prefer_initializing_formals
        _hayConexion = hayConexion, // ignore: prefer_initializing_formals
        _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? ApiConfig.baseUrl,
        _timeout = timeout ?? ApiConfig.timeout;

  final SessionStore _session;
  final Future<bool> Function() _hayConexion;
  final http.Client _client;
  final String _baseUrl;
  final Duration _timeout;

  /// [timeout] reemplaza el tiempo de espera por defecto (respuestas grandes).
  Future<dynamic> get(String path, {bool auth = false, Duration? timeout}) =>
      _enviar('GET', path, auth: auth, timeout: timeout);

  Future<dynamic> post(String path, Object? body, {bool auth = false}) =>
      _enviar('POST', path, body: body, auth: auth);

  Future<dynamic> delete(String path, {bool auth = false}) =>
      _enviar('DELETE', path, auth: auth);

  Future<dynamic> _enviar(
    String metodo,
    String path, {
    Object? body,
    required bool auth,
    Duration? timeout,
  }) async {
    final espera = timeout ?? _timeout;
    if (!await _hayConexion()) throw const SinConexion();

    final headers = <String, String>{'Accept': 'application/json'};
    if (body != null) headers['Content-Type'] = 'application/json';
    if (auth) {
      final token = await _session.token;
      if (token == null || token.isEmpty) throw const SesionExpirada();
      headers['Authorization'] = 'Bearer $token';
    }

    final http.Response res;
    try {
      final req = http.Request(metodo, Uri.parse('$_baseUrl$path'))
        ..headers.addAll(headers)
        // Spring redirige a /login cuando el token no sirve; queremos verlo.
        ..followRedirects = false;
      if (body != null) req.body = jsonEncode(body);

      final streamed = await _client.send(req).timeout(espera);
      res = await http.Response.fromStream(streamed).timeout(espera);
    } on TimeoutException {
      throw const TiempoAgotado();
    } catch (e) {
      // ClientException (servidor apagado, red caída, CORS en web) u otro.
      debugPrint('[Chambing] $metodo $path falló: $e');
      throw await _hayConexion()
          ? const ServidorNoDisponible()
          : const SinConexion();
    }

    return _procesar(res, auth: auth);
  }

  Future<dynamic> _procesar(http.Response res, {required bool auth}) async {
    final code = res.statusCode;
    final tipo = res.headers['content-type'] ?? '';
    final esHtml = tipo.contains('text/html');
    final texto = utf8.decode(res.bodyBytes, allowMalformed: true).trim();

    // Redirección o página HTML donde se esperaba JSON: Spring nos mandó a
    // /login. Con token = sesión vencida; sin token = el servidor falló
    // internamente (su página /error exige autenticación).
    if ((code >= 300 && code < 400) || (code < 300 && esHtml)) {
      if (auth) {
        await _session.limpiar();
        throw const SesionExpirada();
      }
      throw const ErrorServidor();
    }

    if (code >= 200 && code < 300) {
      if (texto.isEmpty) return null;
      if (tipo.contains('json')) {
        try {
          return jsonDecode(texto);
        } on FormatException {
          throw const RespuestaInvalida();
        }
      }
      return texto;
    }

    switch (code) {
      case 400:
        throw Validacion(_mensajeLegible(texto, esHtml));
      case 401:
        if (auth) {
          await _session.limpiar();
          throw const SesionExpirada();
        }
        throw Validacion(_mensajeLegible(texto, esHtml,
            porDefecto: 'Credenciales incorrectas.'));
      case 403:
        throw auth ? const AccesoDenegado() : const ErrorServidor();
      case 404:
        throw const NoEncontrado();
      case 409:
        // Conflicto, p. ej. "Ya aplicaste a esta propuesta anteriormente".
        throw Validacion(_mensajeLegible(texto, esHtml,
            porDefecto: 'La operación entra en conflicto con datos existentes.'));
      default:
        if (code >= 500) throw const ErrorServidor();
        throw const Desconocido();
    }
  }

  /// El backend responde los 400 en texto plano ("El correo ya está
  /// registrado"). Si llega JSON de Spring o HTML, usamos un texto genérico.
  static String _mensajeLegible(
    String texto,
    bool esHtml, {
    String porDefecto =
        'Los datos enviados no son válidos. Revísalos e intenta de nuevo.',
  }) {
    if (texto.isEmpty || esHtml || texto.startsWith('{') || texto.startsWith('<')) {
      return porDefecto;
    }
    return texto.length > 200 ? '${texto.substring(0, 200)}…' : texto;
  }
}
