import 'package:activos_fijos/features/activos_fijos/domain/models/activo_fijo.dart';

class Disposicion {
  final String id;
  final ActivoFijo activo;
  final String tipoDisposicion;
  final String tipoDisposicionDisplay;
  final DateTime fechaDisposicion;
  final String? valorVenta;
  final String? razon;
  final String? realizadoPor;

  Disposicion({
    required this.id,
    required this.activo,
    required this.tipoDisposicion,
    required this.tipoDisposicionDisplay,
    required this.fechaDisposicion,
    this.valorVenta,
    this.razon,
    this.realizadoPor,
  });

  factory Disposicion.fromJson(Map<String, dynamic> json) {
    return Disposicion(
      id: json['id'],
      activo: ActivoFijo.fromJson(json['activo']),
      tipoDisposicion: json['tipo_disposicion'],
      tipoDisposicionDisplay: json['tipo_disposicion_display'],
      fechaDisposicion: DateTime.parse(json['fecha_disposicion']),
      valorVenta: json['valor_venta'],
      razon: json['razon'],
      realizadoPor: json['realizado_por'] != null ? json['realizado_por']['username'] : 'N/A',
    );
  }
}
