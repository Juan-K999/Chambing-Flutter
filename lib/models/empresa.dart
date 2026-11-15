import 'direccion.dart';

/// Espejo de `Chambing.demo.Model.Empresa` (colección "empresas" en Mongo).
class Empresa {
  const Empresa({
    this.idEmpresa,
    this.nit,
    required this.nombreEmpresa,
    required this.correo,
    this.contrasena,
    this.direccion,
  });

  final String? idEmpresa;
  final int? nit;
  final String nombreEmpresa;
  final String correo;
  final String? contrasena;
  final Direccion? direccion;

  factory Empresa.fromJson(Map<String, dynamic> json) => Empresa(
        idEmpresa: json['idEmpresa'] as String,
        nit: (json['nit'] as num?)?.toInt(),
        nombreEmpresa: json['nombreEmpresa']?.toString() ?? '',
        correo: json['correo']?.toString() ?? '',
        direccion: json['direccion'] is Map<String, dynamic>
            ? Direccion.fromJson(json['direccion'] as Map<String, dynamic>)
            : null,
      );

  /// Cuerpo de `POST /empresa`, igual al que arma register.html.
  Map<String, dynamic> toRegistroJson() => {
        'nit': nit,
        'nombreEmpresa': nombreEmpresa,
        'correo': correo,
        'contrasena': contrasena,
        'roles': ['EMPRESA'],
        'enabled': true,
        'direccion': direccion?.toJson(),
      };
}
