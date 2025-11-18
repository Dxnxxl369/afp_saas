// movil/lib/models/solicitud_compra.dart

class SolicitudCompra {
  final String id;
  final String descripcion;
  final String estado;
  final double costoEstimado;
  final DateTime fechaSolicitud;
  final String solicitanteNombre;
  final String departamentoNombre;

  SolicitudCompra({
    required this.id,
    required this.descripcion,
    required this.estado,
    required this.costoEstimado,
    required this.fechaSolicitud,
    required this.solicitanteNombre,
    required this.departamentoNombre,
  });

  factory SolicitudCompra.fromJson(Map<String, dynamic> json) {
    // El backend suele enviar detalles de las claves foráneas
    // para no tener que hacer más peticiones.
    return SolicitudCompra(
      id: json['id'],
      descripcion: json['descripcion'] ?? 'Sin descripción',
      estado: json['estado'] ?? 'DESCONOCIDO',
      costoEstimado: double.tryParse(json['costo_estimado'].toString()) ?? 0.0,
      fechaSolicitud: DateTime.parse(json['fecha_solicitud']),
      solicitanteNombre: json['solicitante_detail']?['nombre_completo'] ?? 'N/A',
      departamentoNombre: json['departamento_detail']?['nombre'] ?? 'N/A',
    );
  }
}
