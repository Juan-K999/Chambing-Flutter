import 'direccion.dart';

/// Espejo de `Chambing.demo.Model.Usuario` (colección "usuarios").
class Usuario {
  const Usuario({
    required this.tipoDocumento,
    required this.documento,
    required this.nombre,
    required this.apellido,
    required this.edad,
    required this.genero,
    required this.email,
    required this.contrasena,
    required this.direccion,
  });

  /// Código del catálogo MySQL `tipos_documento` (p. ej. "CC").
  final String tipoDocumento;
  final int documento;
  final String nombre;
  final String apellido;
  final int edad;

  /// Nombre del catálogo MySQL `generos`.
  final String genero;
  final String email;
  final String contrasena;
  final Direccion direccion;

  /// Cuerpo de `POST /usuario`, igual al que arma register.html.
  Map<String, dynamic> toRegistroJson() => {
        'tipoDocumento': tipoDocumento,
        'documento': documento,
        'nombre': nombre,
        'apellido': apellido,
        'edad': edad,
        'genero': genero,
        'email': email,
        'contrasena': contrasena,
        'roles': ['USER'],
        'direccion': direccion.toJson(),
      };
}
