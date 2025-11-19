import 'package:activos_fijos/features/activos_fijos/domain/models/activo_fijo.dart';
import 'package:activos_fijos/features/auth/domain/models/user.dart';

class Depreciacion {
  final String id;
  final ActivoFijo activo;
  final DateTime fecha;
  final String valorAnterior;
  final String valorNuevo;
  final String montoDepreciado;
  final String depreciationTypeDisplay;
  final String? notas;
  final User? realizadoPor;

  Depreciacion({
    required this.id,
    required this.activo,
    required this.fecha,
    required this.valorAnterior,
    required this.valorNuevo,
    required this.montoDepreciado,
    required this.depreciationTypeDisplay,
    this.notas,
    this.realizadoPor,
  });

  factory Depreciacion.fromJson(Map<String, dynamic> json) {
    return Depreciacion(
      id: json['id'],
      activo: ActivoFijo.fromJson(json['activo']),
      fecha: DateTime.parse(json['fecha']),
      valorAnterior: json['valor_anterior'],
      valorNuevo: json['valor_nuevo'],
      montoDepreciado: json['monto_depreciado'],
      depreciationTypeDisplay: json['depreciation_type_display'],
      notas: json['notas'],
      realizadoPor: json['realizado_por'] != null
          ? User.fromJson(json['realizado_por'])
          : null,
    );
  }
}
