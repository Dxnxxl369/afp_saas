// movil/lib/models/partida_presupuestaria.dart
import 'departamento.dart';

class PartidaPresupuestaria {
  final String id;
  final String nombre;
  final double montoAsignado;
  final double montoGastado;
  final Departamento? departamento; // Puede ser un objeto anidado

  PartidaPresupuestaria({
    required this.id,
    required this.nombre,
    required this.montoAsignado,
    required this.montoGastado,
    this.departamento,
  });

  double get montoDisponible => montoAsignado - montoGastado;

  factory PartidaPresupuestaria.fromJson(Map<String, dynamic> json) {
    return PartidaPresupuestaria(
      id: json['id'],
      nombre: json['nombre'],
      montoAsignado: double.tryParse(json['monto_asignado'].toString()) ?? 0.0,
      montoGastado: double.tryParse(json['monto_gastado'].toString()) ?? 0.0,
      // El API puede devolver el objeto departamento completo o solo su ID.
      // Manejamos el caso donde viene anidado.
      departamento: json['departamento_detail'] != null
          ? Departamento.fromJson(json['departamento_detail'])
          : null,
    );
  }
}
