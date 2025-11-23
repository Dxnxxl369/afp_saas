// movil/lib/models/solicitud_compra.dart

class SolicitudCompra {
  final String id;
  final String descripcion;
  final String estado;
  final double costoEstimado;
  final DateTime fechaSolicitud;
  final String solicitanteNombre;
  final String departamentoNombre;
  final String? ordenCompraId; // ID de la orden de compra si existe

  SolicitudCompra({
    required this.id,
    required this.descripcion,
    required this.estado,
    required this.costoEstimado,
    required this.fechaSolicitud,
    required this.solicitanteNombre,
    required this.departamentoNombre,
    this.ordenCompraId,
  });

  factory SolicitudCompra.fromJson(Map<String, dynamic> json) {
    return SolicitudCompra(
      id: json['id'],
      descripcion: json['descripcion'] ?? 'Sin descripción',
      estado: json['estado'] ?? 'DESCONOCIDO',
      costoEstimado: double.tryParse(json['costo_estimado'].toString()) ?? 0.0,
      fechaSolicitud: DateTime.parse(json['fecha_solicitud']),
      solicitanteNombre: json['solicitante']?['first_name'] ?? 'N/A',
      departamentoNombre: json['departamento']?['nombre'] ?? 'N/A',
      ordenCompraId: json['orden_compra'], // Puede ser null
    );
  }
}
