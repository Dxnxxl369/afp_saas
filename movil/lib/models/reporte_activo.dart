// movil/lib/models/reporte_activo.dart

class ReporteActivo {
  final String id;
  final String nombre;
  final String codigoInterno;
  final DateTime fechaAdquisicion;
  final double valorActual;
  final String departamentoNombre;
  final String ubicacionNombre;

  ReporteActivo({
    required this.id,
    required this.nombre,
    required this.codigoInterno,
    required this.fechaAdquisicion,
    required this.valorActual,
    required this.departamentoNombre,
    required this.ubicacionNombre,
  });

  factory ReporteActivo.fromJson(Map<String, dynamic> json) {
    return ReporteActivo(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      codigoInterno: json['codigo_interno'] as String,
      fechaAdquisicion: DateTime.parse(json['fecha_adquisicion'] as String),
      valorActual: (json['valor_actual'] as num).toDouble(), // num to handle both int and double
      departamentoNombre: json['departamento__nombre'] as String,
      ubicacionNombre: json['ubicacion__nombre'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'codigo_interno': codigoInterno,
      'fecha_adquisicion': fechaAdquisicion.toIso8601String(),
      'valor_actual': valorActual,
      'departamento__nombre': departamentoNombre,
      'ubicacion__nombre': ubicacionNombre,
    };
  }
}
