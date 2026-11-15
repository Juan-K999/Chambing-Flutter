import 'package:flutter/foundation.dart';

/// Únicos errores que la interfaz conoce. Todos traen un [mensaje] listo
/// para mostrarse al usuario; nunca se muestra una excepción técnica.
sealed class AppException implements Exception {
  const AppException(this.mensaje);

  final String mensaje;

  @override
  String toString() => mensaje;
}

final class SinConexion extends AppException {
  const SinConexion()
      : super('No tienes conexión a internet. Revisa tu red e intenta de nuevo.');
}

final class TiempoAgotado extends AppException {
  const TiempoAgotado()
      : super('El servidor tardó demasiado en responder. Intenta de nuevo.');
}

final class ServidorNoDisponible extends AppException {
  const ServidorNoDisponible()
      : super('No se pudo conectar con el servidor de Chambing. '
            'Verifica que esté encendido e intenta más tarde.');
}

final class SesionExpirada extends AppException {
  const SesionExpirada() : super('Tu sesión expiró. Inicia sesión de nuevo.');
}

final class AccesoDenegado extends AppException {
  const AccesoDenegado(
      [super.mensaje = 'No tienes permiso para realizar esta acción.']);
}

final class NoEncontrado extends AppException {
  const NoEncontrado([super.mensaje = 'No se encontró lo que buscabas.']);
}

/// Error de datos (400). El mensaje viene del backend, p. ej.
/// "El correo ya está registrado".
final class Validacion extends AppException {
  const Validacion(super.mensaje);
}

final class ErrorServidor extends AppException {
  const ErrorServidor(
      [super.mensaje = 'Ocurrió un problema en el servidor. Intenta más tarde.']);
}

final class RespuestaInvalida extends AppException {
  const RespuestaInvalida()
      : super('El servidor respondió con datos inesperados. Intenta más tarde.');
}

final class Desconocido extends AppException {
  const Desconocido() : super('Ocurrió un error inesperado. Intenta de nuevo.');
}

/// Convierte una respuesta JSON en un modelo. Si el JSON no tiene la forma
/// esperada, lanza [RespuestaInvalida] en lugar de un TypeError.
T parsearRespuesta<T>(T Function() parsear) {
  try {
    return parsear();
  } catch (e, s) {
    debugPrint('[Chambing] respuesta inválida: $e\n$s');
    throw const RespuestaInvalida();
  }
}

/// Mensaje legible para cualquier error, sea o no [AppException].
String mensajeDeError(Object error) {
  if (error is AppException) return error.mensaje;
  debugPrint('[Chambing] error no controlado: $error');
  return const Desconocido().mensaje;
}
