/// Espejo de `Chambing.demo.Model.Postulacion` (colección "postulaciones").
class Postulacion {
  const Postulacion({
    required this.idPostulacion,
    required this.propuestaId,
    required this.propuestaTitulo,
    required this.estado,
    this.fecha,
  });

  final String idPostulacion;
  final String propuestaId;
  final String propuestaTitulo;

  /// "Pendiente", "Aprobado" o "Rechazado" (los que usa proposals-states.html).
  final String estado;
  final DateTime? fecha;

  factory Postulacion.fromJson(Map<String, dynamic> json) => Postulacion(
        idPostulacion: json['idPostulacion'] as String,
        propuestaId: json['propuestaId']?.toString() ?? '',
        propuestaTitulo: json['propuestaTitulo']?.toString() ?? '(Sin título)',
        estado: json['estadoPostulacion']?.toString() ?? 'Pendiente',
        fecha: leerFecha(json['fechaPostulacion']),
      );

  /// Jackson puede mandar `LocalDateTime` como texto ISO o como arreglo
  /// `[año, mes, día, hora, minuto, ...]`.
  static DateTime? leerFecha(Object? valor) {
    if (valor is String) return DateTime.tryParse(valor);
    if (valor is List && valor.length >= 3 && valor.every((v) => v is int)) {
      final v = valor.cast<int>();
      return DateTime(v[0], v[1], v[2], v.length > 3 ? v[3] : 0,
          v.length > 4 ? v[4] : 0, v.length > 5 ? v[5] : 0);
    }
    return null;
  }
}
