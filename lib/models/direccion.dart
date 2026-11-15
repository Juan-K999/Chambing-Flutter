class Direccion {
  const Direccion({this.calle = '', this.ciudad = '', this.departamento = ''});

  final String calle;
  final String ciudad;
  final String departamento;

  factory Direccion.fromJson(Map<String, dynamic> json) => Direccion(
        calle: json['calle']?.toString() ?? '',
        ciudad: json['ciudad']?.toString() ?? '',
        departamento: json['departamento']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => {
        'calle': calle,
        'ciudad': ciudad,
        'departamento': departamento,
      };
}
