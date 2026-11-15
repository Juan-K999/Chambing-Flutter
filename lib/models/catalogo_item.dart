/// Registro de un catálogo MySQL (`generos` o `tipos_documento`).
class CatalogoItem {
  const CatalogoItem({required this.nombre, this.codigo, this.descripcion});

  final String nombre;

  /// Solo lo tienen los tipos de documento (p. ej. "CC", "TI").
  final String? codigo;
  final String? descripcion;

  factory CatalogoItem.fromJson(Map<String, dynamic> json) => CatalogoItem(
        nombre: json['nombre'] as String,
        codigo: json['codigo']?.toString(),
        descripcion: json['descripcion']?.toString(),
      );
}
