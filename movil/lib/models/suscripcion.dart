// lib/models/suscripcion.dart

class Suscripcion {
  final String id;
  final String plan;
  final String estado;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final int maxUsuarios;
  final int maxActivos;
  final String planDisplay;
  final String estadoDisplay;

  Suscripcion({
    required this.id,
    required this.plan,
    required this.estado,
    required this.fechaInicio,
    required this.fechaFin,
    required this.maxUsuarios,
    required this.maxActivos,
    required this.planDisplay,
    required this.estadoDisplay,
  });

  factory Suscripcion.fromJson(Map<String, dynamic> json) {
    return Suscripcion(
      id: json['id'],
      plan: json['plan'],
      estado: json['estado'],
      fechaInicio: DateTime.parse(json['fecha_inicio']),
      fechaFin: DateTime.parse(json['fecha_fin']),
      maxUsuarios: json['max_usuarios'],
      maxActivos: json['max_activos'],
      planDisplay: json['plan_display'],
      estadoDisplay: json['estado_display'],
    );
  }
}
