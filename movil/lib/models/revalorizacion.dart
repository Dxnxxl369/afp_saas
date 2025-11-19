import 'package:activos_fijos/features/activos_fijos/domain/models/activo_fijo.dart';
import 'package:activos_fijos/features/auth/domain/models/user.dart';

class Revalorizacion {
  final String id;
  final ActivoFijo activo;
  final DateTime fecha;
  final String valorAnterior;
  final String valorNuevo;
  final String factorAplicado;
  final String? notas;
  final User? realizadoPor;

  Revalorizacion({
    required this.id,
    required this.activo,
    required this.fecha,
    required this.valorAnterior,
    required this.valorNuevo,
    required this.factorAplicado,
    this.notas,
    this.realizadoPor,
  });

  factory Revalorizacion.fromJson(Map<String, dynamic> json) {
    return Revalorizacion(
      id: json['id'],
      activo: ActivoFijo.fromJson(json['activo']),
      fecha: DateTime.parse(json['fecha']),
      valorAnterior: json['valor_anterior'],
      valorNuevo: json['valor_nuevo'],
      factorAplicado: json['factor_aplicado'],
      notas: json['notas'],
      realizadoPor: json['realizado_por'] != null
          ? User.fromJson(json['realizado_por'])
          : null,
    );
  }
}
