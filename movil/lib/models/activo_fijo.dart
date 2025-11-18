// movil/lib/models/activo_fijo.dart

class ActivoFijo {
  final String id;
  final String nombre;
  final String codigoInterno;
  final DateTime fechaAdquisicion;
  final double valorActual;
  final String? departamentoNombre;
  final String categoriaNombre;
  final String estadoNombre;
  final String? fotoActivoUrl;

  ActivoFijo({
    required this.id,
    required this.nombre,
    required this.codigoInterno,
    required this.fechaAdquisicion,
    required this.valorActual,
    this.departamentoNombre,
    required this.categoriaNombre,
    required this.estadoNombre,
    this.fotoActivoUrl,
  });

  factory ActivoFijo.fromJson(Map<String, dynamic> json) {
    return ActivoFijo(
      id: json['id'],
      nombre: json['nombre'],
      codigoInterno: json['codigo_interno'],
      fechaAdquisicion: DateTime.parse(json['fecha_adquisicion']),
      valorActual: double.tryParse(json['valor_actual'].toString()) ?? 0.0,
      departamentoNombre: json['departamento_detail']?['nombre'],
      categoriaNombre: json['categoria_detail']?['nombre'] ?? 'Sin categoría',
      estadoNombre: json['estado_detail']?['nombre'] ?? 'Sin estado',
      fotoActivoUrl: json['foto_activo'],
    );
  }
}
