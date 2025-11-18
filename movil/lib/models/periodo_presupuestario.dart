// movil/lib/models/periodo_presupuestario.dart

class PeriodoPresupuestario {
  final String id;
  final String nombre;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final String estado;
  final double montoTotal;

  PeriodoPresupuestario({
    required this.id,
    required this.nombre,
    required this.fechaInicio,
    required this.fechaFin,
    required this.estado,
    required this.montoTotal,
  });

  factory PeriodoPresupuestario.fromJson(Map<String, dynamic> json) {
    return PeriodoPresupuestario(
      id: json['id'],
      nombre: json['nombre'],
      fechaInicio: DateTime.parse(json['fecha_inicio']),
      fechaFin: DateTime.parse(json['fecha_fin']),
      estado: json['estado'],
      montoTotal: double.tryParse(json['monto_total'].toString()) ?? 0.0,
    );
  }
}
