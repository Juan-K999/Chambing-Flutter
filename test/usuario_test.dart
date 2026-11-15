import 'dart:convert';

import 'package:chambing_flutter/core/errors/app_exception.dart';
import 'package:chambing_flutter/core/network/api_client.dart';
import 'package:chambing_flutter/core/session/session_store.dart';
import 'package:chambing_flutter/models/postulacion.dart';
import 'package:chambing_flutter/services/servicios.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SessionStore session;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    session = SessionStore();
  });

  ApiClient cliente(MockClientHandler handler) => ApiClient(
        session: session,
        hayConexion: () async => true,
        client: MockClient(handler),
        baseUrl: 'http://test',
      );

  http.Response json(Object body, [int code = 200]) => http.Response.bytes(
      utf8.encode(jsonEncode(body)), code,
      headers: {'content-type': 'application/json'});

  http.Response texto(String body, int code) => http.Response.bytes(
      utf8.encode(body), code,
      headers: {'content-type': 'text/plain;charset=UTF-8'});

  group('loginUsuario', () {
    test('guarda token, id y nombre del usuario', () async {
      final auth = AuthService(
          cliente((req) async => switch (req.url.path) {
                '/api/auth/login' => json({'token': 'jwt'}),
                '/usuario/me' => json(
                    {'idUsuario': 'u1', 'nombre': 'Ana', 'apellido': 'Pérez'}),
                _ => texto('', 404),
              }),
          session);

      await auth.loginUsuario('  Ana@Mail.com ', '1234');

      expect(await session.token, 'jwt');
      expect(await session.idUsuario, 'u1');
      expect(await session.nombreUsuario, 'Ana Pérez');
    });

    test('cuenta de empresa (403 en /usuario/me) es AccesoDenegado y limpia',
        () async {
      final auth = AuthService(
          cliente((req) async => req.url.path == '/api/auth/login'
              ? json({'token': 'jwt'})
              : texto('', 403)),
          session);

      await expectLater(auth.loginUsuario('e@mail.com', '1234'),
          throwsA(isA<AccesoDenegado>()));
      expect(await session.token, isNull);
    });
  });

  test('cuenta de usuario en login de empresa (404 en /empresa/me) se explica',
      () async {
    final auth = AuthService(
        cliente((req) async => req.url.path == '/api/auth/login'
            ? json({'token': 'jwt'})
            : texto('Empresa no encontrada', 404)),
        session);

    await expectLater(
        auth.loginEmpresa('u@mail.com', '1234'),
        throwsA(isA<AccesoDenegado>().having(
            (e) => e.mensaje, 'mensaje', contains('no es de empresa'))));
    expect(await session.token, isNull);
  });

  group('PostulacionService', () {
    test('aplicar envía POST sin cuerpo con token y devuelve la postulación',
        () async {
      SharedPreferences.setMockInitialValues({'token': 'jwt'});
      late http.Request enviada;
      final s = PostulacionService(cliente((req) async {
        enviada = req;
        return json({
          'idPostulacion': 'po1',
          'propuestaId': 'p1',
          'propuestaTitulo': 'Dev',
          'estadoPostulacion': 'Pendiente',
          'fechaPostulacion': '2026-11-15T10:30:00',
        });
      }));

      final po = await s.aplicar('u1', 'p1');

      expect(enviada.method, 'POST');
      expect(enviada.url.path, '/usuario/aplicar/u1/p1');
      expect(enviada.headers['Authorization'], 'Bearer jwt');
      expect(po.estado, 'Pendiente');
      expect(po.fecha, DateTime(2026, 11, 15, 10, 30));
    });

    test('409 "ya aplicaste" llega como Validacion con el mensaje', () async {
      SharedPreferences.setMockInitialValues({'token': 'jwt'});
      final s = PostulacionService(cliente((_) async =>
          texto('Ya aplicaste a esta propuesta anteriormente', 409)));

      await expectLater(
          s.aplicar('u1', 'p1'),
          throwsA(isA<Validacion>().having((e) => e.mensaje, 'mensaje',
              'Ya aplicaste a esta propuesta anteriormente')));
    });

    test('propuesta borrada (400 no encontrados) es NoEncontrado', () async {
      SharedPreferences.setMockInitialValues({'token': 'jwt'});
      final s = PostulacionService(cliente(
          (_) async => texto('Usuario o propuesta no encontrados', 400)));

      await expectLater(s.aplicar('u1', 'p1'), throwsA(isA<NoEncontrado>()));
    });

    test('misPostulaciones ordena de la más reciente a la más antigua',
        () async {
      SharedPreferences.setMockInitialValues({'token': 'jwt'});
      final s = PostulacionService(cliente((_) async => json([
            {'idPostulacion': 'a', 'fechaPostulacion': '2026-01-01T00:00:00'},
            {'idPostulacion': 'b', 'fechaPostulacion': '2026-06-01T00:00:00'},
          ])));

      final lista = await s.misPostulaciones('u1');

      expect(lista.map((p) => p.idPostulacion), ['b', 'a']);
    });
  });

  test('fecha en formato arreglo de Jackson', () {
    expect(Postulacion.leerFecha([2026, 11, 15, 9, 5]),
        DateTime(2026, 11, 15, 9, 5));
    expect(Postulacion.leerFecha(null), isNull);
  });
}
