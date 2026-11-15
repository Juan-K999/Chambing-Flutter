import 'dart:convert';

import 'package:chambing_flutter/core/errors/app_exception.dart';
import 'package:chambing_flutter/core/network/api_client.dart';
import 'package:chambing_flutter/core/session/session_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SessionStore session;

  setUp(() {
    SharedPreferences.setMockInitialValues({'token': 'abc'});
    session = SessionStore();
  });

  ApiClient cliente(
    MockClientHandler handler, {
    bool conexion = true,
    Duration timeout = const Duration(seconds: 2),
  }) =>
      ApiClient(
        session: session,
        hayConexion: () async => conexion,
        client: MockClient(handler),
        baseUrl: 'http://test',
        timeout: timeout,
      );

  http.Response texto(String body, int code,
          {String tipo = 'text/plain;charset=UTF-8'}) =>
      http.Response.bytes(utf8.encode(body), code,
          headers: {'content-type': tipo});

  test('200 JSON devuelve el cuerpo decodificado', () async {
    final api = cliente((_) async =>
        texto('{"token":"t"}', 200, tipo: 'application/json'));
    expect(await api.post('/api/auth/login', {}), {'token': 't'});
  });

  test('envía el token Bearer cuando auth es true', () async {
    String? header;
    final api = cliente((req) async {
      header = req.headers['Authorization'];
      return texto('[]', 200, tipo: 'application/json');
    });
    await api.get('/empresa/1/propuestas', auth: true);
    expect(header, 'Bearer abc');
  });

  test('400 en texto plano llega como Validacion con el mensaje del backend',
      () async {
    final api = cliente((_) async => texto('El correo ya está registrado', 400));
    expect(
      () => api.post('/empresa', {}),
      throwsA(isA<Validacion>().having(
          (e) => e.mensaje, 'mensaje', 'El correo ya está registrado')),
    );
  });

  test('401 en login público es Validacion "Credenciales incorrectas"',
      () async {
    final api = cliente((_) async => texto('Credenciales incorrectas', 401));
    expect(
      () => api.post('/api/auth/login', {}),
      throwsA(isA<Validacion>()
          .having((e) => e.mensaje, 'mensaje', 'Credenciales incorrectas')),
    );
  });

  test('redirección a /login con token es SesionExpirada y limpia el token',
      () async {
    final api = cliente((_) async =>
        http.Response('', 302, headers: {'location': 'http://test/login'}));
    await expectLater(
        () => api.get('/empresa/me', auth: true), throwsA(isA<SesionExpirada>()));
    expect(await session.token, isNull);
  });

  test('HTML con 200 en endpoint protegido (web) es SesionExpirada', () async {
    final api = cliente(
        (_) async => texto('<html>login</html>', 200, tipo: 'text/html'));
    expect(() => api.get('/empresa/me', auth: true),
        throwsA(isA<SesionExpirada>()));
  });

  test('redirección en endpoint público es ErrorServidor', () async {
    final api = cliente((_) async => http.Response('', 302));
    expect(() => api.post('/empresa', {}), throwsA(isA<ErrorServidor>()));
  });

  test('403 con token es AccesoDenegado', () async {
    final api = cliente((_) async => texto('', 403));
    expect(() => api.get('/empresa/me', auth: true),
        throwsA(isA<AccesoDenegado>()));
  });

  test('500 es ErrorServidor', () async {
    final api = cliente((_) async => texto('boom', 500));
    expect(() => api.get('/api/catalogos/generos'),
        throwsA(isA<ErrorServidor>()));
  });

  test('sin red lanza SinConexion sin intentar la petición', () async {
    var llamadas = 0;
    final api = cliente((_) async {
      llamadas++;
      return texto('', 200);
    }, conexion: false);
    await expectLater(() => api.get('/x'), throwsA(isA<SinConexion>()));
    expect(llamadas, 0);
  });

  test('servidor apagado (ClientException) es ServidorNoDisponible', () async {
    final api = cliente((_) async => throw http.ClientException('refused'));
    expect(() => api.get('/x'), throwsA(isA<ServidorNoDisponible>()));
  });

  test('respuesta lenta es TiempoAgotado', () async {
    final api = cliente((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      return texto('', 200);
    }, timeout: const Duration(milliseconds: 50));
    expect(() => api.get('/x'), throwsA(isA<TiempoAgotado>()));
  });

  test('JSON malformado es RespuestaInvalida', () async {
    final api = cliente(
        (_) async => texto('{no es json', 200, tipo: 'application/json'));
    expect(() => api.get('/x'), throwsA(isA<RespuestaInvalida>()));
  });

  test('sin token guardado en endpoint protegido es SesionExpirada', () async {
    await session.limpiar();
    final api = cliente((_) async => texto('[]', 200, tipo: 'application/json'));
    expect(() => api.get('/empresa/me', auth: true),
        throwsA(isA<SesionExpirada>()));
  });
}
