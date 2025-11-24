// movil/lib/models/periodo_presupuestario.dart
import 'partida_presupuestaria.dart';

class PeriodoPresupuestario {
  final String id;
  final String nombre;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final String estado;
  final double montoTotal;
  final List<PartidaPresupuestaria> partidas; // Campo añadido

  PeriodoPresupuestario({
    required this.id,
    required this.nombre,
    required this.fechaInicio,
    required this.fechaFin,
    required this.estado,
    required this.montoTotal,
    this.partidas = const [], // Valor por defecto
  });

  factory PeriodoPresupuestario.fromJson(Map<String, dynamic> json) {
    var partidasList = json['partidas'] as List? ?? [];
    List<PartidaPresupuestaria> partidas = partidasList
        .map((i) => PartidaPresupuestaria.fromJson(i))
        .toList();

    return PeriodoPresupuestario(
      id: json['id'],
      nombre: json['nombre'],
      fechaInicio: DateTime.parse(json['fecha_inicio']),
      fechaFin: DateTime.parse(json['fecha_fin']),
      estado: json['estado'],
      montoTotal: double.tryParse(json['monto_total'].toString()) ?? 0.0,
      partidas: partidas, // Parsear la lista
    );
  }
}
