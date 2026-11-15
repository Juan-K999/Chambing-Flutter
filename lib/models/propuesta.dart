/// Espejo de `Chambing.demo.Model.Propuesta` (colección "propuestas").
class Propuesta {
  const Propuesta({
    this.idPropuesta,
    required this.titulo,
    this.descripcion = '',
    this.requisitos = '',
    this.salario,
    this.categoria = '',
    this.estado,
    this.empresaNombre,
  });

  /// La web oculta el botón de aplicar cuando el estado es "Cerrada".
  bool get cerrada => (estado ?? '').toLowerCase() == 'cerrada';

  final String? idPropuesta;
  final String titulo;
  final String descripcion;
  final String requisitos;
  final double? salario;
  final String categoria;
  final String? estado;
  final String? empresaNombre;

  /// Mismas categorías que company-proposals.html.
  static const categorias = [
    'Tecnología y Desarrollo',
    'Marketing Digital',
    'Recursos Humanos',
    'Administración y Finanzas',
  ];

  factory Propuesta.fromJson(Map<String, dynamic> json) => Propuesta(
        idPropuesta: json['idPropuesta'] as String,
        titulo: json['titulo']?.toString() ?? '(Sin título)',
        descripcion: json['descripcion']?.toString() ?? '',
        requisitos: json['requisitos']?.toString() ?? '',
        salario: (json['salario'] as num?)?.toDouble(),
        categoria: json['categoria']?.toString() ?? '',
        estado: json['estado']?.toString(),
        empresaNombre: json['empresaNombre']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'titulo': titulo,
        'descripcion': descripcion,
        'requisitos': requisitos,
        'salario': salario,
        'categoria': categoria,
      };
}
